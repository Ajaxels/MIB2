function result = alignDriftCorrectionHDD(obj, parameters)

%parameters.step = str2double(obj.View.handles.CorrelateStep,'string'));
tic
result = 0;
manualModeSwitch = 0;
if isempty(obj.shiftsX) && strcmp(obj.BatchOpt.Subarea{1}, 'Manually specified')
    x1 = str2double(obj.BatchOpt.minX);
    x2 = str2double(obj.BatchOpt.maxX);
    y1 = str2double(obj.BatchOpt.minY);
    y2 = str2double(obj.BatchOpt.maxY);
    manualModeSwitch = 1;
end

if obj.BatchOpt.showWaitbar
    pw = PoolWaitbar(1, sprintf('Setting datastore\nPlease wait...'), parameters.waitbar);
    pw.setIncrement(10);  % set increment step to 10
end

% make datastore for images
try
    switch lower(['.' obj.BatchOpt.HDD_InputFilenameExtension{1}])
        case '.am'
            getDataOptions.getMeta = false;     % do not process meta data in amiramesh files
            getDataOptions.verbose = false;     % do not display info about loaded image
            imgDS = imageDatastore(obj.BatchOpt.HDD_InputDir, ...
                'FileExtensions', lower(['.' obj.BatchOpt.HDD_InputFilenameExtension{1}]),...
                'IncludeSubfolders', false, ...
                'ReadFcn', @(fn)amiraMesh2bitmap(fn, getDataOptions));
        otherwise
            getDataOptions.mibBioformatsCheck = obj.BatchOpt.HDD_BioformatsReader;
            getDataOptions.verbose = false;
            getDataOptions.BioFormatsIndices = str2num(obj.BatchOpt.HDD_BioformatsIndex);
            imgDS = imageDatastore(obj.BatchOpt.HDD_InputDir, ...
                'FileExtensions', lower(['.' obj.BatchOpt.HDD_InputFilenameExtension{1}]), ...
                'IncludeSubfolders', false, ...
                'ReadFcn', @(fn)mibLoadImages(fn, getDataOptions));
    end
catch err
    errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
    return;
end

NumFiles = length(imgDS.Files);
if obj.BatchOpt.showWaitbar
    pw.updateMaxNumberOfIterations(NumFiles);
end

% calculate shifts
if isempty(obj.shiftsX)
    %     % define usage of parallel computing
%     if obj.BatchOpt.UseParallelComputing
%         parPool = parcluster('local'); % If no pool, do not create new one.
%         if isdeployed
%             parforArg = min([8 parPool.NumWorkers]);
%         else
%             parforArg = parPool.NumWorkers;
%         end
%     else
%         parforArg = 0;      % Maximum number of workers running in parallel
%     end
    
    % allocate space for shifts
    shiftX = zeros(NumFiles, 1);
    shiftY = zeros(NumFiles, 1);
    
    % Get the first reference frame
    fixedImg = readimage(imgDS, 1);
    if manualModeSwitch
        fixedImg = fixedImg(y1:y2,x1:x2,parameters.colorCh);
    else
        fixedImg = fixedImg(:,:,parameters.colorCh);
    end
    if obj.BatchOpt.IntensityGradient % generate intensity gradient
        % generate gradient image
        hy = fspecial('sobel');
        hx = hy';
        Iy = imfilter(double(fixedImg), hy, 'replicate');
        Ix = imfilter(double(fixedImg), hx, 'replicate');
        fixedImg = sqrt(Ix.^2 + Iy.^2);
    end
    Iref = fft2(fixedImg);
    
    %parfor (imgId=1:NumFiles, parforArg)
    for imgId=2:NumFiles
        [Height, Width] = size(Iref);
        % get center of the image 
        imgCenterX=floor((Width/2)+1);
        imgCenterY=floor((Height/2)+1);
        
        movingImg = readimage(imgDS, imgId);   % read image as [height, width, color, depth]
        if manualModeSwitch
            movingImg = movingImg(y1:y2,x1:x2,parameters.colorCh);
        else
            movingImg = movingImg(:,:,parameters.colorCh);
        end
        if obj.BatchOpt.IntensityGradient % generate intensity gradient
            Iy = imfilter(double(movingImg), hy, 'replicate');
            Ix = imfilter(double(movingImg), hx, 'replicate');
            movingImg = sqrt(Ix.^2 + Iy.^2);
        end
        Icur=fft2(movingImg);
            
        prod = Iref .* conj(Icur);
        cc = ifft2(prod);
        
        if strcmp(obj.BatchOpt.Algorithm{1}, 'Drift correction')
            [Yo, Xo] = find(fftshift(cc) == max(max(cc)));
            shiftX(imgId) = Xo(1) - imgCenterX;
            shiftY(imgId) = Yo(1) - imgCenterY;
            % Checks to see if there is an ambiguity problem with FFT because of the periodic boundary in FFT
            if abs(shiftX(imgId)-shiftX(imgId-1)) > Width/2
                shiftX(imgId)=shiftX(imgId)-sign(shiftX(imgId)-shiftX(imgId-1))*Width;
            end
            if abs(shiftY(imgId)-shiftY(imgId-1)) > Height/2
                shiftY(imgId)=shiftY(imgId)-sign(shiftY(imgId)-shiftY(imgId-1))*Height;
            end
        else
            [shiftY(imgId), shiftX(imgId)]=find(cc==max(max(cc)));
            % [cY, cX]=find(cc==max(max(cc)));
        end
        
        %if parameters.refFrame == 0
        Iref = Icur;
        %elseif parameters.refFrame < 0 && imgId > abs(parameters.refFrame)
        %    Iref = fft2(I(:,:,imgId+parameters.refFrame+1));
        %end
        if obj.BatchOpt.showWaitbar && mod(imgId,10)==0; pw.increment(); end
    end
    if isempty(shiftX); notify(obj.mibModel, 'stopProtocol'); return; end
    
    % recalculate shifts from relative to vs the first one
    if parameters.refFrame == 0
        shiftX = cumsum(shiftX);
        shiftY = cumsum(shiftY);
    elseif parameters.refFrame < 0
        shiftX2 = shiftX;
        shiftY2 = shiftY;
        step = -options.refFrame;
        
        %             % option 1
        %             for j=step+2:length(shiftY2)
        %                 shiftX2(j) = shiftX(j) + shiftX2(j-step);
        %                 shiftY2(j) = shiftY(j) + shiftY2(j-step);
        %             end
        %             shiftX2b = round(windv(shiftX2, step));
        %             shiftY2b = round(windv(shiftY2, step));
        %             % end of option 1
        
        % option 2
        refId = step;
        for j=step+2:length(shiftY2)
            if mod(j, step) == 0
                shiftX2(j) = shiftX(j) + shiftX2(refId);
                refId = j;
            else
                shiftX2(j) = shiftX(j) + shiftX2(refId-step+1);
            end
        end
        shiftX2 = round(windv(shiftX2, step));
        shiftY2 = round(windv(shiftY2, step));
        % end of option 2
        
        shiftX = shiftX2;
        shiftY = shiftY2;
    end
    
    %             % ---- start of drift problems correction
    fixDrifts = '';
    if parameters.useBatchMode == 0
        figure(155);
        %subplot(2,1,1);
        plot(1:length(shiftX), shiftX, 1:length(shiftY), shiftY);
        %plot(1:length(shiftX), shiftX, 1:length(shiftX), windv(shiftX, 25), 1:length(shiftX), shiftX2);
        legend('Shift X', 'Shift Y');
        %legend('Shift X', 'Smoothed 50 pnts window', 'Final shifts');
        grid;
        xlabel('Frame number');
        ylabel('Displacement');
        title('Before drift correction');
        
        fixDrifts = questdlg('Align the stack using detected displacements?','Fix drifts','Yes','Subtract running average','No','Yes');
        if strcmp(fixDrifts, 'No')
            if isdeployed == 0
                assignin('base', 'shiftX', shiftX);
                assignin('base', 'shiftY', shiftY);
                fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
            end
            if obj.BatchOpt.showWaitbar; pw.delete(); end
            return;
        end
    end
    
    % fix drifts
    if strcmp(fixDrifts, 'Subtract running average') || obj.BatchOpt.SubtractRunningAverage == 1
        halfwidth = str2double(obj.BatchOpt.SubtractRunningAverageStep);
        excludePeaks = str2double(obj.BatchOpt.SubtractRunningAverageExcludePeaks);
        [shiftX, shiftY, halfwidth, excludePeaks] = mibSubtractRunningAverage(shiftX, shiftY, halfwidth, excludePeaks, parameters.useBatchMode);
        
        if isempty(shiftX)
            if obj.BatchOpt.showWaitbar; pw.delete(); end
            notify(obj.mibModel, 'stopProtocol');
            return;
        end
        if halfwidth > 0
            obj.BatchOpt.SubtractRunningAverage = true;
            obj.BatchOpt.SubtractRunningAverageStep = num2str(halfwidth);
            obj.BatchOpt.SubtractRunningAverageExcludePeaks = num2str(excludePeaks);
        end
    end
    
    % exporting shifts to Matlab
    if isdeployed == 0
        assignin('base', 'shiftX', shiftX);
        assignin('base', 'shiftY', shiftY);
        fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
    end
    
    obj.shiftsX = shiftX;
    obj.shiftsY = shiftY;
end

if obj.BatchOpt.showWaitbar
    pw.updateText(sprintf('Aligning the images\nPlease wait...')); 
    pw.setCurrentIteration(0);  % reset the waitbar
end

shiftsX = obj.shiftsX;
shiftsY = obj.shiftsY;

minX = min(shiftsX);    % find minimal x shift for all stacks
minY = min(shiftsY);    % find minimal y shift for all stacks

maxX = max(shiftsX);    % find maximal x shift for all stacks
maxY = max(shiftsY);    % find maximal y shift for all stacks

% find how larger the dataset is going to be
deltaX = abs(minX) + maxX;
deltaY = abs(minY) + maxY;

% reset image datastore
imgDS.reset();
% create output directory
outputDir = fullfile(obj.BatchOpt.HDD_InputDir, obj.BatchOpt.HDD_OutputSubfolderName);
if ~isfolder(outputDir)
    mkdir(outputDir);
end

% settings for saving images
saveImageOptions.showWaitbar = false;
switch obj.BatchOpt.HDD_OutputFileExtension{1}
    case 'AM'
        saveImageOptions.Format = 'Amira Mesh binary (*.am)';
    case 'JPG'
        saveImageOptions.Format = 'Joint Photographic Experts Group (*.jpg)';
    case 'MRC'
        saveImageOptions.Format = 'MRC format for IMOD (*.mrc)';
    case 'NRRD'
        saveImageOptions.Format = 'NRRD Data Format (*.nrrd)';
    case 'PNG'
        saveImageOptions.Format = 'Portable Network Graphics (*.png)';
    case 'TIF'
        saveImageOptions.Format = 'TIF format uncompressed (*.tif)';
end
    
for imgId = 1:NumFiles
    [imgIn, fileinfo] = readimage(imgDS, imgId);   % read image as [height, width, color, depth]
    [height, width, color] = size(imgIn);
    
    if isnumeric(parameters.backgroundColor)
        imgOut = zeros([height+deltaY, width+deltaX, color], class(imgIn))+parameters.backgroundColor;
    else
        if strcmp(parameters.backgroundColor,'black')
            imgOut = zeros([height+deltaY, width+deltaX, color], class(imgIn));
        elseif strcmp(parameters.backgroundColor,'white')
            imgOut = zeros([height+deltaY, width+deltaX, color], class(imgIn)) + intmax(class(imgIn));
        else
            bgIntensity = mean(mean(mean(imgIn)));
            imgOut = zeros([height+deltaY, width+deltaX, color], class(imgIn)) + bgIntensity;
        end
    end
    
    Xo = shiftsX(imgId)-minX+1;
    Yo = shiftsY(imgId)-minY+1;
    
    imgOut(Yo:Yo+height-1,Xo:Xo+width-1,:) = imgIn;
    
    % saving results
    [pathIn, filenameIn, extIn] = fileparts(fileinfo.Filename);
    fnOut = fullfile(pathIn, obj.BatchOpt.HDD_OutputSubfolderName, [filenameIn lower(['.' obj.BatchOpt.HDD_OutputFileExtension{1}])]);
    mibImg = mibImage(imgOut);
    mibImg.saveImageAsDialog(fnOut, saveImageOptions);
    
    if obj.BatchOpt.showWaitbar && mod(imgId,10)==0; pw.increment(); end
end
if obj.BatchOpt.showWaitbar; pw.delete(); end
result = 1;

%img = mib_crossShiftStack(handles.I.img, obj.shiftsX, parameters.shiftsY, parameters);
%img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('image', NaN, 0)), obj.shiftsX, obj.shiftsY, parameters);
%if isempty(img); notify(obj.mibModel, 'stopProtocol'); return; end
%obj.mibModel.setData4D('image', img, NaN, 0);


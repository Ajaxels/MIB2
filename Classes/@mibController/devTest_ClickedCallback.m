function devTest_ClickedCallback(obj)
% function devTest_ClickedCallback(obj)
% for developmental purposes
%
% use for various tests
%
% Parameters:
% 
%
% Return values:
% 
%

%| 
% @b Examples:
% @code mibController.obj.devTest_ClickedCallback();     // call from mibController; start developer functions @endcode
 
% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
% %%
% 

%     
%     BatchOpt.Method = {'Median'};  
%       BatchOpt.Mode = {'3D, Stack'};  

% TO DO:
% 1. test inversion of EM datasets when padding is 'same', since it is
% extended with 0s, which are signal on EM images
obj.startController('mibPreferencesController', obj); % an old guide version
return

% Restore specific image regions
% performs coherence transport based inpainting for object removal and region filling in 2-D grayscale and RGB images.
% I = cell2mat(obj.mibModel.getData2D('image'));
% mask = cell2mat(obj.mibModel.getData2D('selection'));
% J = inpaintCoherent(I, logical(mask), 'SmoothingFactor', 4, 'Radius', 5);
% obj.mibModel.setData2D('image', J);
% obj.plotImage();
% return;

% add RGB to Lab
% rgb2lab
% labelvolshow
% detectORBFeatures
% imlocalbrighten, R2017b

% opt.z = [5 10];
% opt.x = 0;
% img = cell2mat(obj.mibModel.getData4D('image', NaN, NaN, opt));
% img = img /2;
% obj.mibModel.setData4D('image', img, NaN, NaN, opt);
% obj.plotImage();

% obj.mibModel.mibDoBackup('image', 1);
% tic
% I = cell2mat(obj.mibModel.getData2D('image'));
% [gradientThreshold,numberOfIterations] = imdiffuseest(I);
% I = imdiffusefilt(I, 'gradientThreshold', gradientThreshold, 'numberOfIterations', numberOfIterations);
% obj.mibModel.setData2D('image', I);
% toc
% obj.plotImage();
% return;

% M = cell2mat(obj.mibModel.getData2D('model'));
% O1 = zeros(size(M), 'uint8');
% O2 = zeros(size(M), 'uint8');
% O1(M==1) = 1;
% O2(M==2) = 1;
% 
% D1 = bwdistsc(O1, [1 1 1]);
% D2 = bwdistsc(O2, [1 1 1]);
% 
% I1 = uint16(D1+D2);
% I1(M>0) = 0;
% I2 = uint16(M*32000);
% figure(1)
% imshowpair(I1,I2);
% 
% I1i = I1;
% I1i(I1i>200) = 0;
% I1i = imcomplement(I1i);
% I1i(M>0) = -Inf;
% 
% L = watershed(I1i, 8);
% figure(1)
% imshowpair(L, I1i);


% % define 3D (Shape3D) or 2D (Shape2D) objects to get
% BatchOpt.Shape = {'Shape3D'};   
% % define the property to get 
% % it can also be multiple: set 
% % BatchOpt.Multiple=true; %  and
% % BatchOpt.MultipleProperty = 'Volume; FirstAxisLength; Orientation';
% BatchOpt.Property = {'Volume'};     
% % define units: 'um' or 'pixels'
% BatchOpt.Units = {'um'};
% % define index of material to quantify
% BatchOpt.MaterialIndex = '4';
% % start the controller
% h = mibStatisticsController(obj.mibModel, [], BatchOpt);
% % h-handle will have all the properties, for example h.STATS has
% % quantitation results
% % fetch Volume sorted by object Id
% Volume = [h.STATS.Volume];  % sorted by object Id
% % detele the handle
% delete(h);

%obj.startController('mibDeepController');
return;

%%
[height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
I = cell2mat(obj.mibModel.getData3D('image'));
index = 1;
xSteps = 2;
ySteps = 2;
zSteps = 1;
for y=1:floor(height/ySteps):height
    y = floor(y);
    y2 = y + floor(height/ySteps) - 1;
    dy = floor(height/ySteps);
    for x=1:width/xSteps:width
        x = floor(x);
        x2 = x + floor(width/xSteps) - 1;
        dx = floor(width/xSteps);
        for z=1:depth/zSteps:depth
            z = floor(z);
            z2 = z + floor(depth/zSteps) - 1;
            dz = floor(depth/zSteps);
            %I2 = I(y:y2, x:x2, :, z:z2);
            I2 = mibImage(I, obj.mibModel.I{obj.mibModel.Id}.meta);
            I2.cropDataset([x, y, dx, dy, z, dz]);
            fn = fullfile('d:\3View\1710_IntestinalTissue_Scharaw\180817_Crypt4\R01\bin80nm\delete_me\', sprintf('180817_Crypt4_R01_40nm_%.2d.am', index));
            options.Format = 'Amira Mesh binary (*.am)';
            I2.saveImageAsDialog(fn, options);
            
            index = index + 1;
        end
    end
end



return;

obj.mibModel.mibDoBackup('image', 1);
[height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
intensityThreshold = 100;
objSizeThreshold = 1480;
obj.mibModel.clearMask();
wb = waitbar(0, 'Please wait...', 'Name', 'Removing debris');
for z=2:depth-1
    waitbar(z/depth, wb);
    
    % get image
    if z > 2
        I1 = I2;
        I2 = I3;
        Iprev = Icurr;
        Icurr = Inext;
        
        Inext = cell2mat(obj.mibModel.getData2D('image', z+1));
        I3 = Inext + imbothat(Inext, strel('disk', 7, 0));
    else
        Iprev = cell2mat(obj.mibModel.getData2D('image', z-1));
        Icurr = cell2mat(obj.mibModel.getData2D('image', z));
        Inext = cell2mat(obj.mibModel.getData2D('image', z+1));
        
        I1 = Iprev + imbothat(Iprev, strel('disk', 7, 0));
        I2 = Icurr + imbothat(Icurr, strel('disk', 7, 0));
        I3 = Inext + imbothat(Inext, strel('disk', 7, 0));
    end
    
    % get difference
    dI1 = I1-I2;
    dI2 = I3-I2;
    dI = dI1+dI2;

    S = zeros(size(dI), 'uint8');
    S(dI > intensityThreshold) = 1;
    CC = bwconncomp(S, 8);
    STATS = regionprops(CC, {'Area','PixelIdxList'});
    if numel(STATS) == 0; continue; end
    
    for objId = 1:numel(STATS)
        if STATS(objId).Area < objSizeThreshold
            S(STATS(objId).PixelIdxList) = 0;
        end
    end
    S = imdilate(S, strel('disk', 5, 0));
    S = imfill(S);
    S = imerode(S, strel('disk', 3, 0));
    obj.mibModel.setData2D('mask', S, z);
    
    Iout = Icurr;
    Ipatch = Iprev/2+Inext/2;
    %Ipatch = Iprev+Inext;
    Iout(S==1) = Ipatch(S==1);
    obj.mibModel.setData2D('image', Iout, z);
end
obj.plotImage();
delete(wb);
return

%%
[height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
outDir = 'd:\3\imod_5k_20proc_overlap\tifs';
fnTemplate = 'test';
saveFileOptions.Format = 'TIF format uncompressed (*.tif)';
saveFileOptions.showWaitbar = false;

%for z = 1:depth
for z = [1 2 27 28 53 54]
    fn = fullfile(outDir, sprintf('%s_%.4d.tif', fnTemplate, z));
    img = cell2mat(obj.mibModel.getData2D('image', z));  % get image

    minV = obj.mibModel.I{obj.mibModel.Id}.viewPort.min(1);
    maxV = obj.mibModel.I{obj.mibModel.Id}.viewPort.max(1);
    img = uint8((img - minV)/((maxV-minV)/255));
    
    I = mibImage(img);
    I.meta('SliceName') = {'slice'};
    I.saveImageAsDialog(fn, saveFileOptions);
end
return;


% obj.mibModel.mibDoBackup('image', 1);
% img = cell2mat(obj.mibModel.getData3D('image'));
% img2 = zeros(size(img), 'uint8');
% for i=1:size(img,4)
%     %img2(:,:,:,i) = locallapfilt(img(:,:,:,i), .2, 2, .5);
% end
% %obj.mibModel.setData3D('image', c2);
% obj.mibModel.setData3D('selection', squeeze(img2));
% obj.plotImage();
% return;

% %sigma = 100;
% %img = imflatfield(img, sigma);
% img = histeq(img, 64);
% obj.mibModel.setData2D('image', img);
% obj.plotImage();


% to do 
%
% Fix import of models: graphcut slic
% Check of subgraph for the graphcut segmentation
%
%
% Filters:
% D. Texture Filtering
% E. Integral Image Domain Filtering
% F. Deblurring
% Morphological gradient: erosion-dilation or dilation-erosion
%
% Contrast:
% imhistmatch, Adjust histogram of 2-D image to match histogram of reference image


% obj.startController('mibImageArithmeticController');


%     BatchOpt.showWaitbar = true;
%     BatchOpt.InputA = {'Container 1'};  
%     BatchOpt.DestinationClass = {'uint8'};
%     BatchOpt.DestinationContainer = {'Container 1'};   
%     BatchOpt.Expression = 'A = A*2';     
% obj.startController('mibImageArithmeticController',[],BatchOpt);
return;

%matIndex = 1;
sheetsIndex = 1;
tubulesIndex = 2;
model = cell2mat(obj.mibModel.getData3D('model', 1, 4));
mask = cell2mat(obj.mibModel.getData3D('mask', 1, 4));
er_areas = zeros([size(model, 3), 1]);
er_tubules = zeros([size(model, 3), 1]);
cell_areas = zeros([size(model, 3), 1]);

pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
for z=1:size(model, 3)
    cSlice = model(:,:,z);
    mSlice = mask(:,:,z);
    er_tubules(z) = numel(cSlice(cSlice==tubulesIndex));
    er_areas(z) = numel(cSlice(cSlice==sheetsIndex)) + er_tubules(z);
    %er_areas(z) = sum(cSlice(:))*pixSize.x*pixSize.y;
    cell_areas(z) = sum(mSlice(:)); %*pixSize.x*pixSize.y;
end
ratio = er_areas./cell_areas;

er_tubules = er_tubules*pixSize.x*pixSize.y;
er_areas = er_areas*pixSize.x*pixSize.y;
cell_areas = cell_areas*pixSize.x*pixSize.y;


figure(1);
subplot(1,6,1);
boxplot(ratio);
set(gca, 'ylim', [0 1]);


% 
% % stretching, option A: the whole stack
% obj.mibModel.mibDoBackup('image', 1);
% mask = cell2mat(obj.mibModel.getData3D('mask', 1, 4));  % get the mask
% %for colCh = 1:obj.mibModel.I{obj.mibModel.Id}.colors  % loop across the color channels
% colCh = 1;
%     img = squeeze(cell2mat(obj.mibModel.getData3D('image', 1, 4, colCh)));  % get images
%     maxIntVal = double(intmax(class(img)));    
%     
%     indices = img(mask==1);     % extract image intensities inside the mask
%     [N, edges] = histcounts(indices, 100);   % calculate distribution 
% 
%     for z=1:size(img, 3)
%         cSlice = img(:,:,z);
%         img(:,:,z) = imadjust(cSlice, [edges(2)/maxIntVal edges(end-1)/maxIntVal],[]);
%     end
%     img = permute(img, [1,2,4,3]);
%     obj.mibModel.setData3D('image', img, 1, 4, colCh);    
% %end
% obj.plotImage();

% 
% % stretching, option B: slice by slice
% obj.mibModel.mibDoBackup('image', 1);
% img = cell2mat(obj.mibModel.getData3D('image', 1, 4));  % get images
% mask = cell2mat(obj.mibModel.getData3D('mask', 1, 4));  % get the mask
% maxIntVal = double(intmax(class(img)));     % max integer value
% 
% for colCh = 1:size(img, 3)  % loop across the color channels
%     for z=1:size(img, 4)    % loop across slices
%         cImg = img(:, :, colCh, z);     % get image
%         cMask = mask(:, :, z);          % get mask
%         indices = cImg(cMask==1);     % extract image intensities inside the mask
%         [N, edges] = histcounts(indices, 100);   % calculate distribution, 
%         
%         img(:, :, colCh, z) = imadjust(cImg, [edges(2)/maxIntVal edges(end-1)/maxIntVal],[]);
%     end
% end
% obj.mibModel.setData3D('image', img, 1, 4);
% obj.plotImage();

% figure
% subplot(1,2,1)
% boxplot(a)
% set(gca, 'ylim', [0 1]);
% subplot(1,2,2)
% boxplot(b)
% set(gca, 'ylim', [0 1]);

% tic
% obj.mibModel.mibDoBackup('image', 0);
% I = cell2mat(obj.mibModel.getData2D('image'));
% %I2 = imbilatfilt(I,1200,3,'NeighborhoodSize',7);
% %[gradThresh,numIter] = imdiffuseest(I)
% % I2 = imdiffusefilt(I, 'GradientThreshold', 20, 'NumberOfIterations', 10, ...
% %     'Connectivity', 'maximal', 'ConductionMethod', 'quadratic');
% obj.mibModel.setData2D('image', I2);
% toc
% obj.plotImage();
% return

% options.y = [10, 110];
% options.x = [1, 450];
% options.z = [100, 169];
% timePnt = 1;
% imOut = cell2mat(obj.mibModel.getData3D('image', timePnt, 4, 0, options));


% prompts = {'Enter a text Enter a text Enter a text Enter a text'; 'Select the option'; 'Are you sure?'; 'Are you sure again?'; 'This is very very very very very very very very very very long prompt:';...
%     'more checkboxes1'; 'more checkboxes2'; 'more checkboxes3'};
% defAns = {'my test string'; {'Option 1', 'Option 2', 'Option 3', 2}; true; true; []; true; true; true};
% title = 'multi line input diglog';
% options.WindowStyle = 'normal';
% options.PromptLines = [2, 1, 1, 1, 3, 1, 1, 1];
% options.Columns = 2;
% options.Title = 'You are going to change image contrast by Contrast-limited eq:';
% options.TitleLines = 1;
% options.WindowWidth = 1.5;
% 
% [output, selIndices] = mibInputMultiDlg([], prompts, defAns, title, options);
% output
% selIndices'
% return;

end



            

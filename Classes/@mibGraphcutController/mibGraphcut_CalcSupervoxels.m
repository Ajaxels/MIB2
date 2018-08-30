function Graphcut = mibGraphcut_CalcSupervoxels(Graphcut, img, parLoopOptions)
% function Graphcut = mibGraphcut_CalcSupervoxels(Graphcut, img, parLoopOptions)
    img = squeeze(img);   % get dataset
    % bin dataset
    if parLoopOptions.binVal(1) ~= 1 || parLoopOptions.binVal(2) ~= 1
        if ~isempty(parLoopOptions.waitbar); waitbar(05, parLoopOptions.waitbar, sprintf('Binning the dataset\nPlease wait...')); end
        resizeOptions.height = parLoopOptions.binHeight;
        resizeOptions.width = parLoopOptions.binWidth;
        resizeOptions.depth = parLoopOptions.binDepth;
        resizeOptions.method = 'bicubic';
        img = mibResize3d(img, [], resizeOptions);
    end
    
    % convert to 8bit
    currViewPort = parLoopOptions.viewPort;
    if isa(img, 'uint16')
        if parLoopOptions.mibLiveStretchCheck  % on fly mode
            for sliceId=1:size(img, 3)
                img(:,:,sliceId) = imadjust(img(:,:,sliceId) ,stretchlim(img(:,:,sliceId),[0 1]),[]);
            end
        else
            for sliceId=1:size(img, 3)
                img(:,:,sliceId) = imadjust(img(:,:,sliceId), [currViewPort.min/65535 currViewPort.max/65535],[0 1],currViewPort.gamma);
            end
        end
        img = uint8(img/255);
    else
        if currViewPort.min > 1 || currViewPort.max < 255
            for sliceId=1:size(img, 3)
                img(:,:,sliceId) = imadjust(img(:,:,sliceId), [currViewPort.min/255 currViewPort.max/255],[0 1],currViewPort.gamma);
            end
        end
    end
    
    % calculate number of supervoxels
    dims = size(img);
    if strcmp(parLoopOptions.superPixType, 'SLIC')     % generate SLIC superpixels
        Graphcut.noPix = ceil(dims(1)*dims(2)*dims(3)/parLoopOptions.superpixelSize);
        
        % calculate supervoxels
        if ~isempty(parLoopOptions.waitbar); waitbar(.05, parLoopOptions.waitbar, sprintf('Calculating  %d SLIC supervoxels\nPlease wait...', Graphcut.noPix)); end
        
        if parLoopOptions.tilesX > 1 || parLoopOptions.tilesY > 1
            [heightChop, widthChop, depthChop] = size(img);
            Graphcut.slic = zeros([heightChop widthChop depthChop], 'int32');
            noPix = 0;
            
            xStep = ceil(widthChop/parLoopOptions.tilesX);
            yStep = ceil(heightChop/parLoopOptions.tilesY);
            for x=1:parLoopOptions.tilesX
                for y=1:parLoopOptions.tilesY
                    yMin = (y-1)*yStep+1;
                    yMax = min([(y-1)*yStep+yStep, heightChop]);
                    xMin = (x-1)*xStep+1;
                    xMax = min([(x-1)*xStep+xStep, widthChop]);
                    
                    [slicChop, noPixChop] = slicsupervoxelmex_byte(img(yMin:yMax, xMin:xMax, :), round(Graphcut.noPix/(parLoopOptions.tilesX*parLoopOptions.tilesY)), parLoopOptions.superpixelCompact);
                    Graphcut.slic(yMin:yMax, xMin:xMax, :) = slicChop + noPix + 1;   % +1 to remove zero supervoxels
                    noPix = noPixChop + noPix;
                end
            end
            Graphcut.noPix = double(noPix);
        else
            [Graphcut.slic, Graphcut.noPix] = slicsupervoxelmex_byte(img, Graphcut.noPix, parLoopOptions.superpixelCompact);
            Graphcut.noPix = double(Graphcut.noPix);
            % remove superpixel with 0-index
            Graphcut.slic = Graphcut.slic + 1;
        end
        
        % calculate adjacent matrix for labels
        if ~isempty(parLoopOptions.waitbar); waitbar(.25, parLoopOptions.waitbar, sprintf('Calculating MeanIntensity for labels\nPlease wait...')); end
        %STATS = regionprops(Graphcut.slic, img, 'MeanIntensity','BoundingBox','PixelIdxList');
        STATS = regionprops(Graphcut.slic, img, 'MeanIntensity');
        
        if ~isempty(parLoopOptions.waitbar); waitbar(.3, parLoopOptions.waitbar, sprintf('Calculating adjacent matrix for labels\nPlease wait...')); end
        
        % a new procedure imRAG that is up to 10 times faster
        gap = 0;    % regions are connected, no gap in between
        Graphcut.Edges{1} = imRAG(Graphcut.slic, gap);
        Graphcut.Edges{1} = double(Graphcut.Edges{1});
        
        Graphcut.EdgesValues{1} = zeros([size(Graphcut.Edges{1},1), 1]);
        meanVals = [STATS.MeanIntensity];
        
        for i=1:size(Graphcut.Edges{1},1)
            %                 knownId = 2088;
            %                 if i==knownId
            %                     0;
            %                     vInd = find(Edges(:,1)==knownId);   % indices of edges
            %                     vInd2 = find(Edges(:,2)==knownId);   % indices of edges
            %                     vInd = sort([vInd; vInd2]);
            %                     [vInd, Edges(vInd,1), Edges(vInd,2)];  % connected superpixels
            %                 end
            Graphcut.EdgesValues{1}(i) = abs(meanVals(Graphcut.Edges{1}(i,1))-meanVals(Graphcut.Edges{1}(i,2)));     % should be low (--> 0) at the edges of objects
        end
    else    % generate WATERSHED supervoxels
        if parLoopOptions.blackOnWhite == 1
            if ~isempty(parLoopOptions.waitbar); waitbar(.05, parLoopOptions.waitbar, sprintf('Complementing the image\nPlease wait...')); end
            img = imcomplement(img);    % convert image that the ridges are white
        end
        if ~isempty(parLoopOptions.waitbar); waitbar(.1, parLoopOptions.waitbar, sprintf('Extended-minima transform\nPlease wait...')); end
        if parLoopOptions.superpixelSize > 0
            mask = imextendedmin(img, parLoopOptions.superpixelSize);
            if ~isempty(parLoopOptions.waitbar); waitbar(.15, parLoopOptions.waitbar, sprintf('Impose minima\nPlease wait...')); end
            mask = imimposemin(img, mask);
            if ~isempty(parLoopOptions.waitbar); waitbar(.2, parLoopOptions.waitbar, sprintf('Calculating watershed\nPlease wait...')); end
            Graphcut.slic = watershed(mask);       % generate supervoxels
            
        else
            if ~isempty(parLoopOptions.waitbar); waitbar(.2, parLoopOptions.waitbar, sprintf('Calculating watershed\nPlease wait...')); end
            Graphcut.slic = watershed(img);       % generate supervoxels
        end
        if ~isempty(parLoopOptions.waitbar); waitbar(.7, parLoopOptions.waitbar, sprintf('Calculating adjacency graph\nPlease wait...')); end
        
        % calculate adjacency matrix and mean intensity between each
        % two adjacent supervoxels
        [Graphcut.Edges{1}, Graphcut.EdgesValues{1}] = imRichRAG(Graphcut.slic, 1, img);
        Graphcut.noPix = double(max(max(max(Graphcut.slic))));
        
        % remove very small clusters that are accedently selected
        vec = sort(unique(Graphcut.Edges{1}));
        excludeSupervoxels = find(diff(vec)>1);
        if ~isempty(excludeSupervoxels)
            vec2 = 1:numel(excludeSupervoxels);
            excludeSupervoxels = excludeSupervoxels+vec2';
            
%             excludeIndices = find(ismember(Graphcut.slic, excludeSupervoxels)>0);
%             [height1, width1, depth1] = size(Graphcut.slic);
%             for exIndex = 1:numel(excludeIndices)
%                 [~, ~, Z1] = ind2sub([height1, width1, depth1], excludeIndices(exIndex));
%                 if excludeIndices(exIndex) > 1 
%                     % check the z-index of the previous pixel
%                     [~, ~, Z2] = ind2sub([height1, width1, depth1], excludeIndices(exIndex)-1); 
%                     if Z2 == Z1     % if it is on the same slice -> assign
%                         Graphcut.slic(excludeIndices(exIndex)) = Graphcut.slic(excludeIndices(exIndex)-1);
%                     else            % otherwise, take the following pixel
%                         Graphcut.slic(excludeIndices(exIndex)) = Graphcut.slic(excludeIndices(exIndex)+1);
%                     end
%                 else    % check for the first pixel of the dataset and fuse it to the second pixel
%                     Graphcut.slic(excludeIndices(exIndex)) = Graphcut.slic(excludeIndices(exIndex)+1);
%                 end
%             end
            % commented an old code, where the excluded pixels were
            % assigned to zero, now they are connected to a neighbouring
            % pixel
            Graphcut.slic(ismember(Graphcut.slic, excludeSupervoxels)) = 0;
        end
        
        if ~isempty(parLoopOptions.waitbar); waitbar(.9, parLoopOptions.waitbar, sprintf('Generating the final graph\nPlease wait...')); end
        % two modes for dilation: 'pre' and 'post'
        % in 'pre' the superpixels are dilated before the graphcut
        % segmentation, i.e. in this function
        % in 'post' the superpixels are dilated after the graphcut
        % segmentation
        Graphcut.dilateMode = 'pre';
        if strcmp(Graphcut.dilateMode, 'pre')
            Graphcut.slic = imdilate(Graphcut.slic, ones([3 3 3]));
        end
        
        excludeIndices = find(Graphcut.slic == 0);
        [height1, width1, depth1] = size(Graphcut.slic);
        for exIndex = 1:numel(excludeIndices)
            [~, ~, Z1] = ind2sub([height1, width1, depth1], excludeIndices(exIndex));
            if excludeIndices(exIndex) > 1
                % check the z-index of the previous pixel
                [~, ~, Z2] = ind2sub([height1, width1, depth1], excludeIndices(exIndex)-1);
                if Z2 == Z1     % if it is on the same slice -> assign
                    Graphcut.slic(excludeIndices(exIndex)) = Graphcut.slic(excludeIndices(exIndex)-1);
                else            % otherwise, take the following pixel
                    Graphcut.slic(excludeIndices(exIndex)) = Graphcut.slic(excludeIndices(exIndex)+1);
                end
            else    % check for the first pixel of the dataset and fuse it to the second pixel
                Graphcut.slic(excludeIndices(exIndex)) = Graphcut.slic(excludeIndices(exIndex)+1);
            end
        end
    end
        
    % convert to a proper class, to uint8 if below 255
    if max(Graphcut.noPix) < 256
        Graphcut.slic = uint8(Graphcut.slic);
    elseif max(Graphcut.noPix) < 65536
        Graphcut.slic = uint16(Graphcut.slic);
    elseif max(Graphcut.noPix) < 4294967295
        Graphcut.slic = uint32(Graphcut.slic);
    end
    
 end

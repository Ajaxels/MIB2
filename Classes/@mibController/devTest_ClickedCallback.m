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

obj.mibModel.I{obj.mibModel.Id}.addFrameToImage();
notify(obj.mibModel, 'newDataset');  % notify newDataset with the index of the dataset
obj.plotImage();

return;

% global mibPath;
% 
% if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
%     errordlg('Not yet implemented!');
%     return;
% end
% 
% options.blockModeSwitch = 0;
% [height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, 0, options);
%                 
% prompts = {'Position of the image:'; 'New image width:'; 'New image height:'; 'Frame color intensity:'};
% defAns = {{'Center', 'Left-upper corner', 'Right-upper corner', 'Left-bottom corner','Right-bottom corner', 1}; num2str(width); num2str(height); '0'};
% dlgTitle = 'Add frame to the image';
% options.WindowStyle = 'normal';       % [optional] style of the window
% options.PromptLines = [1, 1, 1, 1];   % [optional] number of lines for widget titles
% options.Focus = 1;      % [optional] define index of the widget to get focus
% [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
% if isempty(answer); return; end 
% 
% newWidth = str2double(answer{2});
% newHeight = str2double(answer{3});
% frameColor = str2double(answer{4});
% 
% if newWidth <= width || newHeight <= height
%     errordlg(sprintf('!!! Error !!!\n\nThe new width and height should be larger than the current width and height!'), 'Wrong dimensions', 'modal');
%     return;
% end
% 
% switch answer{1}
%     case 'Center'
%         leftFrame = round((newWidth-width)/2);
%         rightFrame = newWidth - width - leftFrame;
%         topFrame = round((newHeight-height)/2);
%         bottomFrame = newHeight - height - topFrame;
%         x1 = round((newWidth-width)/2);
%         x2 = width + x1 - 1;
%         y1 = round((newHeight-height)/2);
%         y2 = height + y1 - 1;
%     case 'Left-upper corner'
%         leftFrame = 0;
%         rightFrame = newWidth - width;
%         topFrame = 0;
%         bottomFrame = newHeight - height;
%         x1 = 1;
%         x2 = width;
%         y1 = 1;
%         y2 = height;
%     case 'Right-upper corner'
%         leftFrame = newWidth - width;
%         rightFrame = 0;
%         topFrame = 0;
%         bottomFrame = newHeight - height;
%         x1 = newWidth - width + 1;
%         x2 = newWidth;
%         y1 = 1;
%         y2 = height;
%     case 'Left-bottom corner'
%         leftFrame = 0;
%         rightFrame = newWidth - width;
%         topFrame = newHeight - height;
%         bottomFrame = 0;
%         x1 = 1;
%         x2 = width;
%         y1 = newHeight - height + 1;
%         y2 = newHeight;
%     case 'Right-bottom corner'
%         leftFrame = newWidth - width;
%         rightFrame = 0;
%         topFrame = newHeight - height;
%         bottomFrame = 0;
%         x1 = newWidth - width + 1;
%         x2 = newWidth;
%         y1 = newHeight - height + 1;
%         y2 = newHeight;
% end
% 
% 
% 
% imgOut = zeros([newHeight, newWidth, numel(colors), depth, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')) + frameColor;   %#ok<ZEROLIKE> % allocate space
% for t=1:time
%     img = cell2mat(obj.mibModel.getData3D('image', t, 4, 0, options));
%     imgOut(y1:y2,x1:x2,:,:,t) = img;
% end
% obj.mibModel.setData4D('image', imgOut, 4, 0, options);
% 
% if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
%     if obj.mibModel.I{obj.mibModel.Id}.modelExist % crop model
%         obj.model{1} = obj.model{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
%             cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
%     end
%     waitbar(.7, wb);
%     if obj.maskExist     % crop mask
%         obj.maskImg{1} = obj.maskImg{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
%             cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
%     end
%     if  ~isnan(obj.selection{1}(1))
%         obj.selection{1} = obj.selection{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
%             cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
%     end
% elseif ~isnan(obj.model{1}(1))     % crop model/selectio/mask layer
%     obj.model{1} = obj.model{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
%         cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
% end
% 
% imgOut = zeros([newHeight, newWidth, numel(colors), depth, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')) + frameColor;   %#ok<ZEROLIKE> % allocate space
% for t=1:time
%     img = cell2mat(obj.mibModel.getData3D('image', t, 4, 0, options));
%     imgOut(y1:y2,x1:x2,:,:,t) = img;
% end
% obj.mibModel.setData4D('image', imgOut, 4, 0, options);
% 


return

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
0

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


% % toggle center spot
% if obj.mibView.centerSpotHandle.enable == 0
%     % enable the spot
%     obj.mibView.centerSpotHandle.enable = 1;
%     if isempty(obj.mibView.centerSpotHandle.handle)
%         obj.mibView.centerSpotHandle.handle = drawpoint('Position', [mean(obj.mibView.handles.mibImageAxes.XLim) mean(obj.mibView.handles.mibImageAxes.YLim)], ...
%             'Deletable', false,...
%             'parent', obj.mibView.handles.mibImageAxes,...
%             'Color', 'y');
%     end
%     obj.mibView.centerSpotHandle.handle.Visible = 'on';
% else
%     % disable the spot
%     obj.mibView.centerSpotHandle.enable = 0;
%     obj.mibView.centerSpotHandle.handle.Visible = 'off';
%     %delete(obj.mibView.centerSpotHandle.handle);
%     %obj.mibView.centerSpotHandle.handle = [];
% end
% obj.plotImage();
% return;


% obj.mibModel.mibDoBackup('image', 1);
% img = cell2mat(obj.mibModel.getData3D('image', 1, 4));
% tic
% for z=1:size(img,4)
%     img(:,:,:,z) = pmdif(img(:,:,:,z), 10, .5, .25, 10);
%    %img(:,:,:,z) = pmdif(img(:,:,:,z), K,  .5, .25, Iter);
% end
% toc
% obj.mibModel.setData3D('image', img, 1, 4);
% obj.plotImage();
% 
% return;

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



            

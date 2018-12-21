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



            

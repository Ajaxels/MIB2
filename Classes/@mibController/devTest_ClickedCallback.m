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

dataset = obj.mibModel.I{obj.mibModel.Id}.getPixelIdxList('model', 1)



opt.x = [1 1000];
opt.y = [1 1000];
opt.z = [1 5];
obj.mibModel.I{obj.mibModel.Id}.clearMask(opt);
return;


button = questdlg(sprintf('!!! Development !!!\n\nWarning, you are going to start Matlab volume renderer\nPlease consider the downsampling of your dataset before use\nThis functionality is only available in R2017a'),'Volume rendering','Render','Cancel','Render');
if strcmp(button, 'Cancel'); return; end
if obj.matlabVersion < 9.2; return; end
I = obj.mibModel.getData3D('image');
volumeViewer(squeeze(I{1}));
return


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

% 3D distance map for Mark Peterzan
%
wb = waitbar(0, 'Please wait...');
mainObjId = 1;
secObjId = 2;
obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();

mainObjImg = cell2mat(obj.mibModel.getData3D('model', NaN, 4, mainObjId));
secObjImg = cell2mat(obj.mibModel.getData3D('model', NaN, 4, secObjId));
pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
aspect = [1 1 pixSize.z/pixSize.y];
[height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
waitbar(.1, wb);
D = bwdistsc(mainObjImg, aspect);
waitbar(.5, wb);
CC = bwconncomp(secObjImg, 26);
waitbar(.7, wb);
labelList = cell([CC.NumObjects, 1]);
positionList = zeros([CC.NumObjects, 4]);

for objId = 1:CC.NumObjects
    [minValue, minPos] = min(D(CC.PixelIdxList{objId}));
    minValue = minValue * pixSize.y;
    [y,x,z] = ind2sub([height, width, depth], CC.PixelIdxList{objId}(minPos));
    labelList{objId} = num2str(minValue);
    positionList(objId, :) = [z, x, y, 1];
end
waitbar(.9, wb);
obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelList, positionList);
obj.mibModel.mibShowAnnotationsCheck = 1;

disp('Export distance map to Matlab: variable D');
assignin('base', 'D', D);
               
waitbar(1, wb);

notify(obj.mibModel, 'plotImage');
delete(wb);
return;
           
% I2 = cell2mat(obj.mibModel.getData3D('mask'));
% x1 = 280;
% dx = 180;
% y1 = 370;
% dy = 148;
% z1 = 3;
% dz = 46;
% I = I2(y1:y1+dy-1, x1:x1+dx-1, z1:z1+dz-1);
% CC = bwconncomp(I, 26);
% %Ids = CC.PixelIdxList{ceil(rand(1)*3)};
% Ids = CC.PixelIdxList{1};
% PixelIdxListCrop = CC.PixelIdxList{1};
% options.x1 = x1;
% options.y1 = y1;
% options.dx = dx;
% options.dy = dy;
% options.z1 = z1;
% options.dz = dz;
% Ids = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(PixelIdxListCrop, options);
% 
% val = zeros([numel(Ids), 1], 'uint8')+3;
% 
% %obj.mibModel.I{obj.mibModel.Id}.clearSelection();
% 
% options.PixelIdxList = Ids;
% obj.mibModel.setData3D('model', val, NaN, NaN, NaN, options);
% % obj.model{1}(options.PixelIdxList) = bitor(obj.model{1}(options.PixelIdxList), uint8(dataset)*128);
% obj.plotImage();

% return

obj.mibModel.mibDoBackup('image', 1);
I = cell2mat(obj.mibModel.getData2D('image'));
I2 = double(I);

% ridge filter for valleys
[Dxx,Dxy,Dyy] = Hessian2D(I2, 0.5);
[~, Lambda2]=eig2image(Dxx,Dxy,Dyy);
%[Lambda1,Lambda2,Ix,Iy]=eig2image(Dxx,Dxy,Dyy);

% [eig_vec, eig_val] = eig(I2);
% Lambda2 = eig_vec * eig_val * inv(eig_vec);
% difff = max(eig_val(:)) - min(eig_val(:));
% Lambda2 = (eig_val-min(eig_val(:)))/difff*255;

% % alternative
% I2(:,:,1) = Dxx;
% I2(:,:,2) = Dyy;
% %I2(:,:,3) = Dyy;
% I2 = max(I2, [], 3);
% obj.mibModel.setData3D('image', uint8(I2), NaN, 4, 1);
if isa(I2, 'uint8')
    obj.mibModel.setData2D('image', uint8(Lambda2), NaN, 4, 1);
else
    obj.mibModel.setData2D('image', uint16(Lambda2), NaN, 4, 1);    
end
%I = I - uint8(Lambda2)*5;
%obj.mibModel.setData3D('image', I, NaN, 4, 1);

% step filter for edges
%[Ix, Iy] = gradient(255-I2);
%img2 = sqrt(Ix.^2 + Iy.^2);
%img2 = img2/max(max(max(img2)))*double(intmax(class(I)));

% % alternative
%Gmag = imgradient(I2, 'sobel');
%obj.mibModel.setData3D('image', uint8(Gdir));

obj.plotImage();
return;

tic
% script to calculate sheets/
getDataOptions.blockModeSwitch = 0;
Model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, 1, getDataOptions));
[height, width, depth] = size(Model);
% calculate total number of pixels of the object
TotalPixCount = sum(Model(:)); 

% define the strel size
% se_size(1) = 2;     % for y and x
% se_size(2) = 2;     % for z
% % calculate 2D strel element for XY
% se1 = zeros([se_size(1)*2+1 se_size(1)*2+1], 'uint8');
% se1(se_size(1)+1,se_size(1)+1) = 1;
% se1 = bwdist(se1); 
% se1 = uint8(se1 <= se_size(1));
% % calculate 2D strel element for YZ
% se2 = imresize(se1, [se_size(1)*2+1, se_size(2)*2+1], 'nearest');
% % 

se_size_xyz = [3 3 2];
%se_size_xyz = [8 8 2];
se3 = zeros(se_size_xyz(1)*2+1,se_size_xyz(2)*2+1,se_size_xyz(3)*2+1);    % do strel ball type in volume
[x,y,z] = meshgrid(-se_size_xyz(1):se_size_xyz(1),-se_size_xyz(2):se_size_xyz(2),-se_size_xyz(3):se_size_xyz(3));
ball = sqrt((x/se_size_xyz(1)).^2+(y/se_size_xyz(2)).^2+(z/se_size_xyz(3)).^2);
se3(ball<=1) = 1; 
se3 = se3(:,:,2:end-1);

M = zeros(size(Model), 'uint8');
angleStep = pi/2/5;
wb = waitbar(0, 'Calculating...');
iterNo = numel(0:angleStep:pi)*numel(0:angleStep:pi);
index = 0;
% fh1 = figure(1);
% fh1.Visible = 'off';
% clf;
% fh2 = figure(2);
% fh2.Visible = 'off';
% clf;
% fh3 = figure(3);
% fh3.Visible = 'off';
% clf;
for yAngle = 0:angleStep:pi-angleStep
    my = makehgtform('yrotate', yAngle);
    for xAngle = 0:angleStep:pi     % no need in parfor here, it seems to be optimized internally
        mx = makehgtform('xrotate', xAngle);
        m = mx*my;
        tform = affine3d(m);
        se3Rotated = imwarp(se3, tform, 'nearest');
        
%         if index < 16
%             figure(1);
%             subplot(4,4,index+1);
%             [faces, verts] = isosurface(se3Rotated, 0.5);
%             p = patch('Faces',faces,'Vertices',verts,'FaceColor',[1 0 0], 'EdgeColor','none');
%             p.AmbientStrength = .3;
%             set(gca,'projection','perspective');
%             lighting gouraud;
%             camlight('headlight');
%             axis tight;
%             axis equal;
%             grid;
%         elseif index < 32
%             figure(2);
%             subplot(4,4,index+1-16);
%             [faces, verts] = isosurface(se3Rotated, 0.5);
%             p = patch('Faces',faces,'Vertices',verts,'FaceColor',[1 0 0], 'EdgeColor','none');
%             p.AmbientStrength = .3;
%             set(gca,'projection','perspective');
%             lighting gouraud;
%             camlight('headlight');
%             axis tight;
%             axis equal;
%             grid;
%         elseif index < 48
%             figure(3);
%             subplot(4,4,index+1-32);
%             [faces, verts] = isosurface(se3Rotated, 0.5);
%             p = patch('Faces',faces,'Vertices',verts,'FaceColor',[1 0 0], 'EdgeColor','none');
%             p.AmbientStrength = .3;
%             set(gca,'projection','perspective');
%             lighting gouraud;
%             camlight('headlight');
%             axis tight;
%             axis equal;
%             grid;
%         end

        M2 = imerode(Model, se3Rotated);
        M2 = imdilate(M2, se3Rotated);
        M = M | M2;
        index = index + 1;
        waitbar(index/iterNo, wb);
    end
end

sheetsCount = sum(M(:));
ratio = sheetsCount/TotalPixCount;

obj.mibModel.setData3D('mask', M, NaN, 4, 1, getDataOptions);
obj.plotImage();
fprintf('Sheets: %d, Total: %d, Ratio: %f\n', sheetsCount, TotalPixCount, ratio);
delete(wb);
toc

% fh1.Visible = 'on';
% fh2.Visible = 'on';
% fh3.Visible = 'on';
return;



% % test code for mibImageSelectFrameController
% tic
% intensity = 255;
% threshold = 200;
% connectivity = 4;   % 4 or 8
% colCh = 1;
% wb = waitbar(0, 'Please wait...', 'Name', 'Detecting the boundaries');
% getDataOptions.blockModeSwitch = 0;
% [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
% obj.mibModel.I{obj.mibModel.Id}.clearMask();
% 
% for z = 1:depth
%     I = cell2mat(obj.mibModel.getData2D('image', z, NaN, colCh, getDataOptions));
%     M = zeros(size(I), 'uint8');
%     M(I == intensity) = 1;
%     
%     CC = bwconncomp(M, connectivity);  %    detect objects
%     STATS = regionprops(CC, 'PixelList', 'Area');   % calc their properties
%     
%     % find areas larger than the threshold value
%     vec = arrayfun(@(x) x.Area > threshold, STATS);
%     % keep only the areas that are larger than the threhold value
%     CC.PixelIdxList = CC.PixelIdxList(vec);
%     CC.NumObjects = sum(vec);
%     STATS = STATS(vec);
%     
%     % find border elements
%     vec1 = arrayfun(@(x) isempty(find(x.PixelList == 1, 1)), STATS);
%     vec2 = arrayfun(@(x) isempty(find(x.PixelList(:,2) == height, 1)), STATS);
%     vec3 = arrayfun(@(x) isempty(find(x.PixelList(:,1) == width, 1)), STATS);
%     vec = unique([find(vec1 == 0); find(vec2 == 0); find(vec3 == 0)]);
%     
%     % generate a new mask layer
%     M = zeros(size(I), 'uint8');
%     M(cat(1, CC.PixelIdxList{vec})) = 1;
%     
%     obj.mibModel.setData2D('mask', M, z, NaN, colCh, getDataOptions);
%     if mod(z, 10) == 0; waitbar(z/depth, wb); end
% end
% delete(wb);
% obj.mibModel.mibMaskShowCheck = 1;
% obj.plotImage();

toc

            

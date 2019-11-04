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
% obj.startController('mibHistThresController',[],BatchOpt);
% return

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

return;


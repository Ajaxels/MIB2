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


button = questdlg(sprintf('!!! Development !!!\n\nWarning, you are going to start Matlab volume renderer\nPlease consider the downsampling of your dataset before use\nThis functionality is only available in R2017a'),'Volume rendering','Render','Cancel','Render');
if strcmp(button, 'Cancel'); return; end
if obj.matlabVersion < 9.2; return; end
I = obj.mibModel.getData3D('image');
volumeViewer(squeeze(I{1}));
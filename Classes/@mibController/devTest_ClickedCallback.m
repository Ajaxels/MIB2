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

end



            

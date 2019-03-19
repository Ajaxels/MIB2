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

end



            

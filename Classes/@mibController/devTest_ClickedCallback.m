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


end



            

function mibCreateModelBtn_Callback(obj)
% function mibCreateModelBtn_Callback(obj)
% Create a new model, callback for press of the Create button in mibGUI
%
% Parameters:
% 
% Return values:
% 

%| 
% @b Examples:
% @code mibController.mibCreateModelBtn_Callback();     // create a new model @endcode
 
% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

%%

obj.mibModel.createModel();

end
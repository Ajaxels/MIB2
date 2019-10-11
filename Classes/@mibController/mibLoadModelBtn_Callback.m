function mibLoadModelBtn_Callback(obj)
% function mibLoadModelBtn_Callback(obj)
% callback to the obj.mibView.handles.mibLoadModelBtn, loads model to MIB from a file
%
%
% Parameters:
%
% Return values:
% 
%

%| 
% @b Examples:
% @code obj.mibLoadModelBtn_Callback();     // call from mibController; load a model @endcode
 
% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 02.09.2019, most stuff moved to mibModel.loadModel

obj.mibModel.loadModel();
end
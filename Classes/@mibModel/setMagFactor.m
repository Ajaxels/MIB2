function setMagFactor(obj, magFactor, id)
% function setMagFactor(obj, magFactor, id)
% set magnification for the currently shown or id dataset
%
% Parameters:
% magFactor: magnification factor
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.getMagFactor(2);     // call from mibController: set current magFactor to 2 @endcode
% @code obj.mibModel.getMagFactor(2, 4);     // call from mibController: set current magFactor to 2 for dataset 4 @endcode

% Copyright (C) 10.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
if nargin < 3; id = obj.Id; end 
if nargin < 2
    errordlg(sprintf('!!! Error !!!\n\nthe magFactor parameter is missing'),'mibModel.setMagFactor');
    return;
end;
obj.I{id}.magFactor = magFactor;
end



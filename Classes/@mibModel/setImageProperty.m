function setImageProperty(obj, propertyName, propertyValue, id)
% function setImageProperty(obj, propertyName, propertyValue, id)
% set desired property for the currently shown or id dataset
%
% Parameters:
% propertyName: a string with property name for mibImage class
% propertyValue: a value for the desired property
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.setImageProperty('orientation', 4);     // call from mibController: set current orientation to 4 @endcode
% @code obj.mibModel.setImageProperty(2, 4);     // call from mibController: set orientation to 4 to dataset 4 @endcode

% Copyright (C) 28.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
if nargin < 4; id = obj.Id; end 
if nargin < 3
    errordlg(sprintf('!!! Error !!!\n\nthe propertyName and propertyValue parameters are missing'),'mibModel.setImageProperty');
    return;
end;

if isprop(obj.I{id}, propertyName) == 0
    errordlg(sprintf('Error in mibModel: getImageProperty!\n\nWrong property name'),'Wrong property');
    return;
end

obj.I{id}.(propertyName) = propertyValue;
end



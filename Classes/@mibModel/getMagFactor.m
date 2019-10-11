function magFactor = getMagFactor(obj, id)
% function mag = getMagFactor(obj, id)
% get magnification for the currently shown or id dataset
%
% Parameters:
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% magFactor: magnification factor

%| 
% @b Examples:
% @code magFactor = obj.mibModel.getMagFactor();     // call from mibController: get current magFactor @endcode
% @code magFactor = obj.mibModel.getMagFactor(2);     // call from mibController: get magFactor for dataset 2 @endcode

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; id = obj.Id; end
magFactor = obj.I{id}.magFactor;

end



function meta = getMeta(obj)
% function meta = getMeta(obj)
% get meta data for the currently shown dataset, mibImage.meta
%
% Parameters:
%
% Return values:
% meta: information about the dataset, an instance of the 'containers'.'Map' class

%| 
% @b Examples:
% @code meta = obj.getMeta();      //  Call from mibController: get meta data  @endcode

% Copyright (C) 23.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

meta = obj.mibModel.I{obj.mibModel.Id}.meta;
end
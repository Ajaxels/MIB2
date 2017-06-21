function setMeta(obj, meta)
% function setMeta(obj, meta)
% set meta data for the currently shown dataset, mibImage.meta
%
% Parameters:
% meta: information about the dataset, an instance of the 'containers'.'Map' class
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.getMeta(meta);      //  Call from mibController: update meta information for the currently shown dataset @endcode

% Copyright (C) 23.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

obj.mibModel.I{obj.mibModel.Id}.meta = meta;
end
function slice_no = getCurrentSliceNumber(obj)
% function slice_no = getCurrentSliceNumber(obj)
% Get slice number of the currently shown image
%
% Parameters:
%
% Return values:
% slice_no: index of the currently shown slice

%| 
% @b Examples:
% @code slice_no = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();      // Call from mibController @endcode

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

slice_no = obj.slices{obj.orientation}(1);
end
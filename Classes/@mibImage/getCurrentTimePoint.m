function timePnt = getCurrentTimePoint(obj)
% function timePnt = getCurrentTimePoint(obj)
% Get time point of the currently shown image.
%
% Parameters:
%
% Return values:
% timePnt: index of the currently shown slice

%| 
% @b Examples:
% @code timePnt = mibImage.getCurrentTimePoint();      // get the time point  @endcode

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

timePnt = obj.slices{5}(1);
end
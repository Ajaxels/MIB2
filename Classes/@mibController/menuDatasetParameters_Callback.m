function result = menuDatasetParameters_Callback(obj, pixSize)
% function result = menuDatasetParameters_Callback(obj, pixSize)
% a callback for MIB->Menu->Dataset->Parameters

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

result = 0;
if nargin < 2
    result = obj.mibModel.updateParameters();
else
    result = obj.mibModel.updateParameters(pixSize);
end
if result == 1
    obj.plotImage(1);
end
end

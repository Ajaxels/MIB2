function updateDisplayParameters(obj)
% function updateDisplayParameters(obj)
% Update display parameters for visualization (mibImage.viewPort structure)
%
% Parameters:
%
% Return values:

%| 
% @b Examples:
% @code mibImage.updateDisplayParameters();  // do update @endcode

% Copyright (C) 23.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 


obj.viewPort = struct();
[obj.viewPort.min(1:obj.colors)] = deal(0);
if isa(obj.img{1},'single')
    [obj.viewPort.max(1:obj.colors)] = max(max(max(max(obj.img{1}))));
else
    if isa(obj.img{1},'uint32')
        [obj.viewPort.max(1:obj.colors)] = deal(65535);
    else
        [obj.viewPort.max(1:obj.colors)] = deal(obj.meta('MaxInt'));
    end
end
[obj.viewPort.gamma(1:obj.colors)] = deal(1);
end
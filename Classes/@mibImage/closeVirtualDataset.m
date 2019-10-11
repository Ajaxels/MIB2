function closeVirtualDataset(obj)
% function closeVirtualDataset(obj)
% Close opened virtual dataset readers.
%
% Parameters:
%
% Return values:
%

% Copyright (C) 14.08.2017, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% NOTE! this is an old script for MIB < 2.501
% it now should include delete of the memo files

% close open bio-format readers, otherwise the files locked
if iscell(obj.img) && isa(obj.img{1}, 'loci.formats.Memoizer')
    for imgId = 1:numel(obj.img)
        obj.img{imgId}.close();
    end
end
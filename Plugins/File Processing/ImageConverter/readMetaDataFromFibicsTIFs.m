function dataOut = readMetaDataFromFibicsTIFs(filename)
% function dataOut = readMetaDataFromFibicsTIFs(filename)
% read meta data from TIF files
%
% Parameters:
% filename: full path to TIF filename

% Copyright (C) 12.01.2022, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


info = imfinfo(filename);

if isfield(info, 'UnknownTags')
    if isfield(info, 'Software') && strcmp( info(1).Software(1:min([6 numel(info(1).Software)])), 'Fibics')
        dataOut = info(1).UnknownTags.Value;
    else
        dataOut = info(1).UnknownTags.Value;
    end
else
    dataOut = [];
end
end
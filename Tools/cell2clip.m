function outputString = cell2clip(cellArray)
% function outputString = cell2clip(cellArray)
% cell2clip copies contents of cell-array to the clipboard
%   
% Parameters:
% cellArray: cell array with text and/or numbers
% 
% Return values:
% outputString: the cell array converted to a string and exported to the
% system clipboard
%
% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.2005

outputString = repmat(' ', [1 2048]);  % allocate batch of space
maxStringSize = numel(outputString);
cPos = 1;
for lineId = 1:size(cellArray, 1)
    currLine = [strjoin(cellArray(lineId,:), '\t') sprintf('\n')];
    noChars = numel(currLine);
    if cPos+noChars > maxStringSize
        outputString = [outputString, repmat(' ', [1 2048])]; %#ok<AGROW>
        maxStringSize = numel(outputString);
    end
    outputString(cPos:cPos+noChars-1) = currLine;
    cPos = cPos + noChars;
end
outputString = strtrim(outputString);

clipboard('copy', outputString);
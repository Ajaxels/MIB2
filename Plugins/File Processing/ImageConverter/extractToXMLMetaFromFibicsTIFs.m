% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function extractToXMLMetaFromFibicsTIFs(data, writeInfo, outputType, wb)
% function extractToXMLMetaFromFibicsTIFs(data, writeInfo, outputType)
% extract metadata parameters from Zeiss Atlas Fibics TIF files and export
% them to XML text file
%
% Parameters:
% data: a string text containing metadata parameters in XML format,
% provided by readMetaDataFromFibicsTIFs function and imgDS =
% datastore(...) in ImageConverterController
% writeInfo: write info structure
%   .ReadInfo -> structure with Read info
%       .Filename -> full path to the input filename
%       .FileSize -> size of the file
%   .SuggestedOutputName -> full path to the suggested outout filename
%   .Location -> directory path to the root output location
% outputType: output type, not used
% wb: handle to waitbar (PoolWaitbar class) or empty

% Updates
% 

if nargin < 4; wb = []; end
if ~isempty(wb); wb.increment(); end

% return as metadata was not found
if isempty(data); return; end

if data(1) == '<'   % assuming xml input
    % generate output filename
    [pathStr, fnStr] = fileparts(writeInfo.SuggestedOutputName);
    outputXMLfilename = fullfile(pathStr, [char(fnStr) '.xml']);

    % save data to a temp file
    tempFnOutput = fullfile(tempdir, 'mibOutputTemp.xml');
    fid = fopen(tempFnOutput, 'w');
    fwrite(fid, data);
    fclose(fid);


    % read temp xml file and convert it to Matlab structure
    dataStruct = xml2struct(tempFnOutput);  
    % save structure to formatted XML
    struct2xml(dataStruct, outputXMLfilename);
else    % assume a text headers
    % generate output filename
    [pathStr, fnStr] = fileparts(writeInfo.SuggestedOutputName);
    outputXMLfilename = fullfile(pathStr, [char(fnStr) '.txt']);

    fid = fopen(outputXMLfilename, 'w');
    fwrite(fid, data);
    fclose(fid);
end
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

function result = mibImWrite(img, filename, parameters)
% function result = mibImWrite(img, filename, parameters)
% Save image to a file using Matlab imwrite function.
%
% Implemented for TIF files
%
% Parameters:
%   img: -> image (height:width:color)
%   filename: -> destination filename
%   parameters: -> optional structure with parameters
%
% Return values:
%   result: -> @b 1 - success; @b 0 - fail

% Updates
% 

result = 0; %#ok<NASGU>
[~, ~, ext] = fileparts(filename);
if nargin < 3;     parameters = struct();  end

fields = fieldnames(parameters);
formatOut = ext(2:end);

if numel(fields) > 0
    str2 = ['imwrite(img, filename, ''', formatOut, ''''];
    for fieldId = 1:numel(fields)
        if isa(parameters.(fields{fieldId}), 'char')
            str2 = sprintf('%s, ''%s'', ''%s''', str2, fields{fieldId}, parameters.(fields{fieldId}));
        else
            str2 = sprintf('%s, ''%s'', %d', str2, fields{fieldId}, parameters.(fields{fieldId}));
        end
    end
    str2 = sprintf('%s);', str2);
    eval(str2);
else
    imwrite(img,filename, formatOut);
end

fprintf('ib_imwrite: %s was saved.\n', filename);
result = 1;
end

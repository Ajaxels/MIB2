% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function result = mibGetMibVersionNumberic(relativePath, absolutePath, templateText)
% function result = convertRelativeToAbsolutePath(relativePath, absolutePath, templateText)
% convert relative path into absolute path, where the part of the relative
% path containing text template (templateText) will be replaced with the
% abosolute path
%
% Parameters:
% relativePath: string with the relative path, for example "[RELATIVE]\..\..\dir1\subdir1"
% absolutePath: string with the absolute path, for example "c:\myfiles\dir2\subdir2"
% templateText: string with the template text to be inserted instead of the relativePath, for example "[RELATIVE]"

%| 
% @ Note:
% The reverse operation is done using convertAbsoluteToRelativePath function

% @b Examples:
% @code 
% relativePath = '[RELATIVE]\..\..\dir1\subdir1'; 
% absolutePath = 'c:\myfiles\dir2\subdir2'; 
% templateText = '[RELATIVE]';
% result = convertRelativeToAbsolutePath(relativePath, absolutePath, templateText); // result = "c:\myfiles\dir1\subdir1"
% @endcode

parentDirsIndices = strfind(relativePath, '..');  % get number of times the parent directory needs to be called
parentDirsNo = numel(parentDirsIndices);  % get number of times the parent directory needs to be called
if parentDirsNo == 0
    result = strrep(relativePath, templateText, absolutePath);
else
    for dirIndex = 1:parentDirsNo
        absolutePath = fileparts(absolutePath);
    end
    result = fullfile(absolutePath, relativePath(parentDirsIndices+3:end));
end

% fix double slashes
result = strrep(result, '\\', '\');
result = strrep(result, '//', '/');

end
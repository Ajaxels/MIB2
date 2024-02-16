% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function result = convertAbsoluteToRelativePath(absolutePath, relativePath, templateText)
% function result = convertAbsoluteToRelativePath(absolutePath, relativePath, templateText)
% convert absolute path into relative path, where the part of the absolute
% path that is matching the relative path is replaced with the
% templateText.
%
% Parameters:
% absolutePath: string with the absolute path, for example "c:\myfiles\dir1\subdir1"
% relativePath: string with the relative path, for example "c:\myfiles\dir2\subdir2"
% templateText: string with the template text to be inserted instead of the relativePath, for example "[RELATIVE]"
%
% Return values:
% result: string with the replaced string. 
% When relativePath is not found in the absolutePath, result is equal to
% absolutePath. Otherwise, the result = "[RELATIVE]\..\..\dir1\subdir1"

%| 
% @ Note:
% The reverse operation is done using convertRelativeToAbsolutePath function

% @b Examples:
% @code 
% absolutePath = 'c:\myfiles\dir1\subdir1'; 
% relativePath = 'c:\myfiles\dir2\subdir2'; 
% templateText = '[RELATIVE]';
% result = convertAbsoluteToRelativePath(absolutePath, relativePath, templateText); // result = "[RELATIVE]\..\..\dir1\subdir1"
% @endcode

result = absolutePath;

% fix the slash characters 
absolutePath = strrep(absolutePath, '/', filesep);
absolutePath = strrep(absolutePath, '\', filesep);

if ispc
    % check whether the absolutePath and relativePath are on different logical drives
    % if they are on different drives return []
    if ~strcmpi(absolutePath(1:2), relativePath(1:2))
        return;
    end
end

if contains(absolutePath, relativePath, 'IgnoreCase', true)
    % relative path is included into the abosulte path
    result = strrep(absolutePath, relativePath, templateText);
else
    clippedPath = fileparts(relativePath);
    templateText = fullfile(templateText, '..');
    result = convertAbsoluteToRelativePath(absolutePath, clippedPath, templateText);

    if ispc
        % check for the root directory
        clippedPath = regexprep(clippedPath, '^[A-Za-z]+:', '');
        % return when the root directory is reached
        if clippedPath == '\'; return; end
    end

end


end
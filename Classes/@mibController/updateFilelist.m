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

function updateFilelist(obj, filename)
% function updateFilelist(obj, filename)
% Update list of files in the current working directory (obj.mibModel.myPath) 
%
% Parameters:
% filename: [optional], when specified highlight @b filename in the list of files

% Updates
% 

if nargin < 2; filename = NaN; end

extentions = obj.mibView.handles.mibFileFilterPopup.String;
extention = extentions(obj.mibView.handles.mibFileFilterPopup.Value);

mypath = obj.mibModel.myPath;
if mypath(end) == ':'   % change from c: to c:\, because somehow dir('c:') gives wrong result
    mypath = [mypath '\'];
end

fileList = dir(mypath);  % use mibDir to get sorted filenames: r01 R02 r03
fnames = {fileList.name};

if isempty(fnames)
    % fix of a rare case, when dir returns an empty structure
    fnames = {'[.]', '[..]'};
else
    dirs = fnames([fileList.isdir]);  % generate list of directories
    fileList = fnames(~[fileList.isdir]);     % generate structure with files
    [~, ~, fileList_ext] = cellfun(@fileparts, fileList, 'UniformOutput', false);   % get extensions
    
    if strcmp(extention,'all known')
        if verLessThan('matlab', '8.1') % obj.matlabVersion < 8.1    % strjoin appeared only in R2013a (8.1)
            extentions(2:end-1) = cellfun(@(x) sprintf('%s|',x),extentions(2:end-1),'UniformOutput', false);
            extensions = cell2mat(extentions(2:end)');
        else
            extensions = strjoin(extentions(2:end)','|');
        end
        files = fileList(~cellfun(@isempty, regexpi(fileList_ext, extensions)))';
    else
        files = fileList(~cellfun(@isempty, regexpi(fileList_ext, extention)))';
    end
    fnames = files;
    %fnames = sort(files);
    
    if ~isempty(dirs)
        dirs = strcat(repmat({'['}, 1, length(dirs)), dirs, repmat({']'}, 1, length(dirs)));
        fnames = {dirs{:}, fnames{:}}; %#ok<CCAT>
    end
end

if isempty(filename)
    return;
elseif isnan(filename(1))
    obj.mibView.handles.mibFilesListbox.String = fnames;
    obj.mibView.handles.mibFilesListbox.Value = 1;
else
    % find index of line to highlight
    highlightValue = find(ismember(fnames, filename));
    
    obj.mibView.handles.mibFilesListbox.String = fnames;
    if ~isempty(highlightValue)
        obj.mibView.handles.mibFilesListbox.Value = highlightValue;
    else
        obj.mibView.handles.mibFilesListbox.Value = 1;
    end
end
obj.mibView.handles.mibPathEdit.String = mypath;
end
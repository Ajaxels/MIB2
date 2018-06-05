function updateFilelist(obj, filename)
% function updateFilelist(obj, filename)
% Update list of files in the current working directory (obj.mibModel.myPath) 
%
% Parameters:
% filename: [optional], when specified highlight @b filename in the list of files

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; filename = NaN; end

extentions = obj.mibView.handles.mibFileFilterPopup.String;
extention = extentions(obj.mibView.handles.mibFileFilterPopup.Value);

mypath = obj.mibModel.myPath;
if mypath(end) == ':'   % change from c: to c:\, because somehow dir('c:') gives wrong result
    mypath = [mypath '\'];
end

fileList = dir(mypath);
fnames = {fileList.name};
dirs = fnames([fileList.isdir]);  % generate list of directories
fileList = fnames(~[fileList.isdir]);     % generate structure with files
[~,~,fileList_ext] = cellfun(@fileparts, fileList, 'UniformOutput', false);   % get extensions

if strcmp(extention,'all known')
    if obj.matlabVersion < 8.1    % strjoin appeared only in R2013a (8.1)
        extentions(2:end-1) = cellfun(@(x) sprintf('%s|',x),extentions(2:end-1),'UniformOutput', false);
        extensions = cell2mat(extentions(2:end)');
    else
        extensions = strjoin(extentions(2:end)','|');
    end
    files = fileList(~cellfun(@isempty, regexpi(fileList_ext, extensions)))';
else
    files = fileList(~cellfun(@isempty, regexpi(fileList_ext, extention)))';
end
fnames = sort(files);

if ~isempty(dirs)
    dirs = strcat(repmat({'['}, 1, length(dirs)), dirs, repmat({']'}, 1, length(dirs)));
    fnames = {dirs{:}, fnames{:}}; %#ok<CCAT>
end
if isnan(filename(1))
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
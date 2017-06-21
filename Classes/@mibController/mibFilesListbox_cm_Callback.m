function mibFilesListbox_cm_Callback(obj, parameter)
% function mibFilesListbox_cm_Callback(obj, parameter)
% a context menu to the to the handles.mibFilesListbox, the menu is called
% with the right mouse button
%
% Parameters:
% parameter: a string with parameters for the function
% @li 'load' - Combine selected datasets
% @li 'loadPart' - Load part of the dataset
% @li 'nth' - Load each N-th dataset
% @li 'insertData' - Insert into the open dataset
% @li 'combinecolors' - Combine files as color channels
% @li 'addchannel' - Add as a new color channel
% @li 'addchannel_nth' - Add each N-th dataset as a new color channel
% @li 'rename' - Rename selected file
% @li 'delete' - Delete selected files
% @li 'file_properties' - File properties

% Copyright (C) 10.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

global mibPath; % path to mib installation folder

% generate a dataset from the selected files
% generate list of files
val = obj.mibView.handles.mibFilesListbox.Value;
list = obj.mibView.handles.mibFilesListbox.String;
filename = list(val);
options.mibBioformatsCheck = obj.mibView.handles.mibBioformatsCheck.Value;
options.waitbar = 1;
options.mibPath = mibPath;
index = 1;

if (strcmp(parameter, 'nth') || strcmp(parameter, 'addchannel_nth')) && numel(filename) == 1     % combines all files in the directory starting from the selected
    filename = list(val:end);
else
    filename = list(val);       % take the selected datasets
end

for i=1:numel(filename)
    if ~strcmp(filename{i}, '.') && ~strcmp(filename{i}, '..') && filename{i}(1) ~= '['
        fn(index) = cellstr(fullfile(obj.mibModel.myPath, filename{i})); %#ok<AGROW>
        index = index + 1;
    end
end
if index <= 1
    errordlg(sprintf('No files were selected!!!\nPlease select desired files and try again!\nYou can use Ctrl and Shift for the selection.'),'Wrong selection!');
    return; 
end    % no files were selected

if strcmp(parameter, 'nth') || strcmp(parameter, 'addchannel_nth')
    answer = mibInputDlg({mibPath}, sprintf('Please enter the step:\n\nFor example when step is 2 \nMIB loads each second dataset'),'Enter the step','2');
    if isempty(answer); return; end
    step = str2double(cell2mat(answer));
    idx = 1;
    for i=1:step:numel(fn)
        fn2(idx) = fn(i);
        idx = idx + 1;
    end
    fn = fn2;
end

switch parameter
    case {'load' 'nth','loadPart','combinecolors'}
        if val < 3; return; end
        if strcmp(parameter, 'loadPart')
            options.customSections = 1;     % to load part of the dataset, for AM only
        end
        [img, img_info, pixSize] = mibLoadImages(fn, options);
        if isnan(img(1))
            errordlg(sprintf('!!! Error !!!\n\nIt is not possible to load the dataset...'),'Wrong file','modal');
            return;
        end
        if strcmp(parameter, 'combinecolors') 
            img = reshape(img, [size(img,1), size(img,2), size(img,3)*size(img,4)]);
            img_info('ColorType') = 'truecolor';
            if isKey(img_info, 'lutColors')
                currColors = img_info('lutColors');
                lutColors = currColors;
                index1 = size(lutColors,1);
                index2 = 1;
                while size(lutColors,1) < size(img,3)
                    lutColors(index1+1, :) = currColors(index2,:);
                    index1 = index1 + 1;
                    index2 = index2 + 1;
                    if index2 > size(currColors,1); index2 = 1; end
                end
                img_info('lutColors') = lutColors;
            end
        end
        obj.mibModel.I{obj.mibModel.Id}.clearContents(img, img_info, obj.mibModel.preferences.disableSelection);
        obj.mibModel.I{obj.mibModel.Id}.pixSize = pixSize;
        notify(obj.mibModel, 'newDataset');   % notify mibController about a new dataset; see function obj.Listner2_Callback for details
        obj.mibView.lastSegmSelection = 1;  % last selected contour for use with the 'e' button
        obj.plotImage(1);
        
        % update list of recent directories
        dirPos = ismember(obj.mibModel.preferences.recentDirs, obj.mibModel.myPath);
        if sum(dirPos) == 0
            obj.mibModel.preferences.recentDirs = [obj.mibModel.myPath obj.mibModel.preferences.recentDirs];    % add the new folder to the list of folders
            if numel(obj.mibModel.preferences.recentDirs) > 14    % trim the list
                obj.mibModel.preferences.recentDirs = obj.mibModel.preferences.recentDirs(1:14);
            end
        else
            % re-sort the list and put the opened folder to the top of
            % the list
            obj.mibModel.preferences.recentDirs = [obj.mibModel.preferences.recentDirs(dirPos==1) obj.mibModel.preferences.recentDirs(dirPos==0)];
        end
        obj.mibView.handles.mibRecentDirsPopup.String = obj.mibModel.preferences.recentDirs;
    case 'insertData'
        prompt = sprintf('Where the new dataset should be inserted?\n\n1 - beginning of the open dataset\n0 - end of the open dataset\n\nor type any number to define position');
        insertPosition = mibInputDlg({mibPath}, prompt, 'Insert dataset', '0');
        if isempty(insertPosition); return; end
        insertPosition = str2double(insertPosition{1});
        if insertPosition == 0; insertPosition = NaN; end
        [img, img_info, ~] = mibLoadImages(fn, options);
        obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, insertPosition, img_info);
        if obj.mibView.handles.mibLutCheckbox.Value == 1
            obj.mibModel.I{obj.mibModel.Id}.slices{3} = 1:size(obj.mibModel.I{obj.mibModel.Id}.img{1},3);
        else
            obj.mibModel.I{obj.mibModel.Id}.slices{3} = 1:min([size(obj.mibModel.I{obj.mibModel.Id}.img{1},3) 3]);
        end
        notify(obj.mibModel, 'newDataset');   % notify mibView about a new dataset; see function obj.mibView.Listner2_Callback for details
        obj.plotImage(1);
    case 'rename'
        if numel(fn) ~= 1
            msgbox('Please select a single file!', 'Rename file', 'warn');
            return;
        end
        %options.Resize='on';
        %options.WindowStyle='normal';
        %options.Interpreter='none';
        [path, filename, ext] = fileparts(fn{1});
        answer = mibInputDlg({obj.mibPath}, 'Please enter new file name','Rename file',[filename, ext]);
        if isempty(answer); return; end
        movefile(fn{1}, fullfile(path, answer{1}));
        obj.updateFilelist(answer{1});
    case 'delete'
        if numel(fn) == 1
            msg = sprintf('You are going to delete\n%s', fn{1});
        else
            msg = sprintf('You are going to delete\n%d files', numel(fn));
        end
        button =  questdlg(msg,'Delete file(s)?','Delete','Cancel','Cancel');
        if strcmp(button, 'Cancel') == 1; return; end
        for i=1:numel(fn)
            delete(fn{i});
        end
        obj.updateFilelist();
    case 'file_properties'
        if exist('fn','var') == 0; return; end
        properties = dir(fn{1});
        msgbox(sprintf('Filename: %s\nDate: %s\nSize: %.3f KB', properties.name, properties.date, properties.bytes/1000),...
            'File info');
    case {'addchannel' 'addchannel_nth'}   % add color channel
        [img, img_info, ~] = mibLoadImages(fn, options);
        if isnan(img(1)); return; end
        
        if isKey(img_info, 'lutColors')
            lutColors = img_info('lutColors');
            lutColors = lutColors(1:size(img,3),:);
        else
            lutColors = NaN;
        end
        
        result = obj.mibModel.I{obj.mibModel.Id}.addColorChannel(img, NaN, lutColors);
        if result == 0; return; end
        notify(obj.mibModel, 'newDataset');   % notify mibView about a new dataset; see function obj.mibView.Listner2_Callback for details
        obj.plotImage(1);
end
unFocus(obj.mibView.handles.mibFilesListbox);   % remove focus from hObject
end
function menuFileImportImage_Callback(obj, parameter)
% function menuFileImportImage_Callback(obj, parameter)
% a callback to Menu->File->Import Image, import image from Matlab main
% workspace or system clipboard
%
% Parameters:
% parameter: [@em optional] a string that defines image source:
% - 'matlab', [default] main workspace of Matlab
% - 'imaris', from imaris, requires ImarisXT
% - 'clipboard', from the system clipboard
% - 'url', from the provided URL address

% Copyright (C) 22.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

global mibPath;

if nargin < 2;     parameter = 'matlab'; end;
switch parameter
    case 'matlab'
        prompt = {'Image variable (h:w:color:index):','Image meta variable (containers.Map)'};
        options.Resize='on';
        answer = inputdlg(prompt(1:2), 'Import from Matlab', 1, {'I','I_meta'}, options);
        if size(answer) == 0; return; end;
        
        try
            img = evalin('base',answer{1});
        catch exception
            errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message),'Misssing variable!','modal');
            return;
        end
        if isstruct(img); img = img.data; end;  % check for Amira structures
    case 'clipboard'
        img = imclipboard('paste');
        answer{2} = '';
    case 'imaris'
        [img, answer{2}, viewPort, lutColors, obj.connImaris] = mibGetImarisDataset(obj.connImaris);
        if isnan(img(1)); return; end;
        obj.mibView.handles.mibLutCheckbox.Value = 1;
        obj.mibModel.useLUT = 1;
    case 'url'
        clipboardText = clipboard('paste');
        webLink = 'http://mib.helsinki.fi/images/im_browser_splash.jpg';
        if ~isempty(clipboardText)
            indeces = strfind(clipboardText, 'http://');
            if ~isempty(indeces)
                webLink = clipboardText;
            end
        end
        prompt = {sprintf('Please enter the URL\n(including the protocol type (e.g., http://))\nof an image to import:')};
        %options.Resize='on';
        %answer = inputdlg(prompt,'Open URL',1,{webLink},options);
        answer = mibInputDlg({mibPath}, prompt,'Open URL',webLink);
        if size(answer) == 0; return; end;
        answer{2} = containers.Map('URL', answer{1});
        try
            info = imfinfo(answer{1});
            % replace path http://filename to mibModel.myPath/filename
            [httppath, name, ext] = fileparts(info.Filename);   % 
            info.Filename = fullfile(obj.mibModel.myPath, [name, ext]);
        catch exception
            if strcmp(exception.identifier, 'MATLAB:wrongNumInDotAssign')
                if isdeployed == 0
                    button = questdlg(sprintf('The current version of Matlab has a bug that does not allow to get image information via URL for some image types.\nMIB will still try to get image.\nFor the multilayered TIFs only the first slice will be downloaded.\n\nTo Fix:\n1. Type in the command window: "edit imfinfo"\n2. Find "info.Filename = source;"\n3. Replace it with "[info.Filename] = deal(source);"'),'Some problems...','Edit imfinfo now?','Cancel','Edit imfinfo now?');
                    if strcmp(button, 'Edit imfinfo now?')
                        edit('imfinfo.m');
                    end
                else
                    warndlg(sprintf('The current version of Matlab has a bug that does not allow to get image information via URL for some image types.\nMIB will still try to get image.\nFor the multilayered TIFs only the first slice will be downloaded.\n\nTo Fix:\n1. Type in the command window: "edit imfinfo"\n2. Find "info.Filename = source;"\n3. Replace it with "[info.Filename] = deal(source);"'),'Some problems...');                    
                end
                info.Filename = 'imfinfo_with_errors';
            end
        end
        wb = waitbar(0, sprintf('Image URL:\n%s\nPlease wait...', answer{1}), 'Name', 'Downloading image');
        if numel(info) > 1
            [imgTemp, map] = imread(answer{1},1);
            img = zeros([size(imgTemp,1), size(imgTemp,2), size(imgTemp,3), numel(info)], class(imgTemp)); %#ok<ZEROLIKE>
            img(:,:,:,1) = imgTemp;
            for sliceNo = 2:numel(info)
                img(:,:,:,sliceNo) = imread(answer{1},sliceNo);
                waitbar(sliceNo/numel(info), wb);
            end
        else
            [img, map] = imread(answer{1});
        end
        if ~isempty(map)
            answer{2} = containers.Map({'URL','Colormap','ColorType'}, {answer{1}, map, 'indexed'});
        else
            answer{2} = containers.Map({'URL','Width','Height'}, {answer{1}, size(img,2), size(img,1)});
        end
        
        % info structure to containers.Map
        fields = sort(fieldnames(info));
        
        % convert cells to chars
        for fieldIdx = 1:numel(fields)
            if iscell(info(1).(fields{fieldIdx}))
                info.(fields{fieldIdx}) = cell2mat(info.(fields{fieldIdx}));
            end
        end
        % move Comment to the ImageDescription for jpg files
        [~,~,ext] = fileparts(answer{1});
        if strcmp(ext, '.jpg') || strcmp(ext, '.png')
            info.ImageDescription = info.Comment;
            info = rmfield(info, 'Comment');
            fields = sort(fieldnames(info));
        end
        for ind = 1:numel(fields)
            if strcmp(fields{ind},'StripByteCounts') || strcmp(fields{ind},'StripOffsets') || strcmp(fields{ind},'UnknownTags')% remove some unwanted fields
                continue;
            end
            answer{2}(fields{ind}) = info(1).(fields{ind});
        end
        
        delete(wb);
end

if isa(img, 'double')
    max_val = max(max(max(max(img))));
    if max_val <= intmax('uint8')
        class_id = 'uint8';
    elseif max_val <= intmax('uint16')
        class_id = 'uint16';
    elseif max_val <= intmax('uint32')
        class_id = 'uint32';
    else
        msgbox('Please convert your data to image!','Error!','error','modal');
        return;
    end
    button = questdlg(sprintf('The variable that you have entered is in the double format\n would you like to convert it to %s format and continue?',class_id),...
        'Warning','Proceed','Cancel','Proceed');
    if strcmp(button,'Cancel');  return; end;
    str2 = ['img = ' class_id '(img);'];
    eval(str2);
elseif islogical(img)   % convert logical data type to uint8
    img = uint8(img);
end

if numel(size(img)) == 3 && size(img, 3) > 3    % reshape original dataset to w:h:color:z
    button = questdlg(sprintf('The layer channel in the imported image is missing!\nWould you like to move the color channel to the layer channel?'),'Convert?','Yes','No','Yes');
    if strcmp(button,'Yes')
        img = reshape(img, size(img,1),size(img,2),1,size(img,3));
    end;
end

if (~isempty(answer{2})) 
    if strcmp(parameter, 'matlab')
        try
            info = evalin('base', answer{2});
        catch err
            errordlg(sprintf('!!! Error !!!\nWrong variable for metadata'), 'Wrong variable', 'modal');
            info = containers.Map('Filename', 'import.tif');
        end
    else
        info = answer{2};
    end
    obj.mibModel.I{obj.mibModel.Id}.meta = containers.Map(keys(info), values(info));  % create a copy of the containers.Map
    if isa(info, 'containers.Map')
        obj.mibModel.I{obj.mibModel.Id}.clearContents(img, obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.preferences.disableSelection);
    end
else
    obj.mibModel.I{obj.mibModel.Id}.clearContents(img, [], obj.mibModel.preferences.disableSelection);
    obj.mibModel.updateParameters();    % update pixels size, and resolution
    obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = 'import.tif';
end

% update viewport
if strcmp(parameter, 'imaris')
    obj.mibModel.I{obj.mibModel.Id}.viewPort = viewPort;
    obj.mibModel.I{obj.mibModel.Id}.lutColors = lutColors;
end

obj.mibView.lastSegmSelection = 1;  % last selected contour for use with the 'e' button
notify(obj.mibModel, 'newDataset');   % notify mibController about a new dataset; see function obj.Listner2_Callback for details
obj.plotImage(1);
end
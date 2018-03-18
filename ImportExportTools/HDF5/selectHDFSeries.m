function varargout = selectHDFSeries(varargin)
% function varargout = selectHDFSeries(varargin)
% selectHDFSeries function is responsible for selection of series in HDF files
%
% selectHDFSeries contains MATLAB code for selectHDFSeries.fig 

% Copyright (C) 21.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 31.03.2016, IB, update to allow import datasets from Ilastik

% Last Modified by GUIDE v2.5 31-Mar-2016 12:56:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @selectHDFSeries_OpeningFcn, ...
                   'gui_OutputFcn',  @selectHDFSeries_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before selectHDFSeries is made visible.
function selectHDFSeries_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to selectHDFSeries (see VARARGIN)

% Choose default command line output for selectHDFSeries
handles.output = 'Cancel';  
handles.output2 = 1;  % meta data switch
handles.output3 = [NaN NaN NaN NaN NaN]; % dimensions of the selected dataset xyczt
handles.output4 = NaN;  % transformation matrix

if iscell(varargin{1})
    handles.filename = cell2mat(varargin{1});    % file name to get image dataset
else
    handles.filename = varargin{1};
end

% get MIB font size
Font = varargin{2};

info = h5info(handles.filename);
index=1;

if ~isempty(info.Datasets)
    for dataset = 1:numel(info.Datasets)
        datasetName = info.Datasets(dataset).Name;
        if datasetName(1) ~= '/'; datasetName = ['/' datasetName]; end
        data(index, 1) = {datasetName};
        datadim = info.Datasets(dataset).Dataspace.Size;
        for dim=1:numel(datadim)
            data(index,1+dim) = {num2str(datadim(dim))};
        end
        data(index,7) = {info.Datasets(dataset).Datatype.Class};
        
        % check whether dataset is from Ilastik and populate dimensions
        % identifier handles.dataDim{index}
        if numel(info.Datasets(dataset).Attributes) > 0
            attrIndex = find(ismember({info.Datasets(dataset).Attributes.Name},'axistags')==1);
            if ~isempty(attrIndex)  % axistags are present -> i.e. Ilastik dataset
                if iscell(info.Datasets(dataset).Attributes(attrIndex).Value)
                    axistags = info.Datasets(dataset).Attributes(attrIndex).Value{:};
                else
                    axistags = info.Datasets(dataset).Attributes(attrIndex).Value;
                end
                % axistags = p_json(axistags);  % parse the axistags
                dimIds = strfind(axistags, '"key"');
                handles.dataDim{index} = '';
                if numel(dimIds) > 0
                    for dimId = 1:numel(dimIds)
                        strcut = axistags(dimIds(dimId)+6:dimIds(dimId)+15);
                        currIds = strfind(strcut, '"');
                        handles.dataDim{index} = [handles.dataDim{index} strcut(currIds(1)+1:currIds(1)+1)];
                    end
                end
                handles.dataDim{index} = fliplr(handles.dataDim{index}); % flip dimension
            end
        end
        index = index + 1;    
    end
end
for group=1:numel(info.Groups)
    for dataset=1:numel(info.Groups(group).Datasets)
        data(index,1) = {[info.Groups(group).Name '/' info.Groups(group).Datasets(dataset).Name]};
        datadim = info.Groups(group).Datasets(dataset).Dataspace.Size;
        for dim=1:numel(datadim)
            data(index,1+dim) = {num2str(datadim(dim))};
        end
        data(index,7) = {info.Groups(group).Datasets(dataset).Datatype.Class};
        
        % check whether dataset is from Ilastik and check dimensions
        if numel(info.Groups(group).Datasets(dataset).Attributes) > 0
            attrIndex = find(ismember({info.Groups(group).Datasets(dataset).Attributes.Name},'axistags')==1);
            if ~isempty(attrIndex)  % axistags are present -> i.e. Ilastik dataset
                axistags = info.Groups(group).Datasets(dataset).Attributes(attrIndex).Value{:};
                dimIds = strfind(axistags, '"key"');
                handles.dataDim{index} = '';
                if numel(dimIds) > 0
                    for dimId = 1:numel(dimIds)
                        strcut = axistags(dimIds(dimId)+6:dimIds(dimId)+15);
                        currIds = strfind(strcut, '"');
                        handles.dataDim{index} = [handles.dataDim{index} strcut(currIds(1)+1:currIds(1)+1)];
                    end
                end
                handles.dataDim{index} = fliplr(handles.dataDim{index}); % flip dimension
            end
        end
        index = index + 1;
    end
end
handles.seriesTable.Data = data;

% update font and size
if isstruct(Font)
    if handles.text2.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text2.FontName, Font.FontName)
        mibUpdateFontSize(handles.selectHDFSeries, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.selectHDFSeries);

% increase size for text2 and selectedSeriesText
handles.text2.FontSize = handles.text2.FontSize + 2;
handles.selectedSeriesText.FontSize = handles.text2.FontSize + 2;

if size(data,1) > 0
    eventdata.Indices = 1;
    seriesTable_CellSelectionCallback(hObject, eventdata, handles);
    handles = guidata(handles.selectHDFSeries);
end

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
set(handles.selectHDFSeries,'WindowStyle','modal')

% UIWAIT makes selectHDFSeries wait for user response (see UIRESUME)
uiwait(handles.selectHDFSeries);
end

% --- Outputs from this function are returned to the command line.
function varargout = selectHDFSeries_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = handles.output2;
for i = 1:numel(handles.output3)
    if isnan(handles.output3(i))
        handles.output3(i) = 0;
    end
end
varargout{3} = handles.output3;
varargout{4} = handles.output4;     % transformation matrix

% The figure can be deleted now
delete(handles.selectHDFSeries);
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
% hObject    handle to continueBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(handles.transposeEdit.Enable, 'on') && handles.transposeCheck.Value == 1
    transStr = handles.transposeEdit.String;
    outputDim = 'yxczt';    % dimensions listed in the table
    outputDim = outputDim(ismember(outputDim, transStr));     % clip outputDim for situations when some dimension is missing
    for i=1:numel(outputDim)
        [keyValue, transMatrix(i)] = find(outputDim==transStr(i));
    end
        
    
%     
%     [keyValue, transMatrix(1)] = find(outputDim==transStr(1));
%     [keyValue, transMatrix(2)] = find(outputDim==transStr(2));
%     [keyValue, transMatrix(3)] = find(outputDim==transStr(3));
%     [keyValue, transMatrix(4)] = find(outputDim==transStr(4));
%     [keyValue, transMatrix(5)] = find(outputDim==transStr(5));
    handles.output4 = transMatrix;
else
    handles.output4 = NaN;
end

% Update handles structure
guidata(hObject, handles);


% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.selectHDFSeries);
end


% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = 'Cancel';

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.selectHDFSeries);
end

% --- Executes when user attempts to close selectHDFSeries.
function selectHDFSeries_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to selectHDFSeries (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end
end


% --- Executes when selected cell(s) is changed in seriesTable.
function seriesTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to seriesTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
tableData = handles.seriesTable.Data;
rowData = tableData(eventdata.Indices(1),:);
handles.selectedSeriesText.String = rowData(1);
handles.output = rowData(1);

dim_yxczt = zeros(1,numel(rowData)-2);
for i=1:numel(rowData)-2
    dim_yxczt(i) = str2double(rowData{i+1});
end
handles.output3 = dim_yxczt;
transMatrix = NaN;
if isfield(handles, 'dataDim') && eventdata.Indices(1) <= numel(handles.dataDim)
    if ~isempty(handles.dataDim{eventdata.Indices(1)})
        outputDim = 'yxczt';    % dimensions listed in the table
        dataDim = handles.dataDim{eventdata.Indices(eventdata.Indices(1))}; % data dimensions reported by hdf5
        missingAxis = find(~ismember(outputDim, dataDim)==1);    % index of the missing axis
        
        %outputDim = outputDim(ismember(outputDim, dataDim));    % clip outputDim for situations when some dimension is missing
        missingIndex = 1;
        for i=1:numel(outputDim)
            %[keyValue, transMatrix(i)] = find(dataDim==outputDim(i));
            [keyValue, keyPosition] = find(dataDim==outputDim(i));
            if ~isempty(keyValue)
                transMatrix(i) = keyPosition;
            else
                transMatrix(i) = missingAxis(missingIndex);
                transMatrix(i) = numel(dataDim) + missingIndex;
                missingIndex = missingIndex + 1;
            end
        end
        
        
%         [keyValue, transMatrix(1)] = find(dataDim=='y');
%         [keyValue, transMatrix(2)] = find(dataDim=='x');
%         [keyValue, transMatrix(3)] = find(dataDim=='c');
%         [keyValue, transMatrix(4)] = find(dataDim=='z');
%         [keyValue, transMatrix(5)] = find(dataDim=='t');
        outputDim = outputDim(transMatrix);  % transformation matrix
        set(handles.transposeEdit, 'string', outputDim);
    end
end
handles.output4 = transMatrix;

% Update handles structure
guidata(hObject, handles);
end


% --- Executes on button press in parametersCheckbox.
function parametersCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to parametersCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output2 = hObject.Value;
% Update handles structure
guidata(hObject, handles);
end


% --- Executes on button press in transposeCheck.
function transposeCheck_Callback(hObject, eventdata, handles)
if handles.transposeCheck.Value
    handles.transposeEdit.Enable = 'on';
else
    handles.transposeEdit.Enable = 'off';
end
end


% --- Executes on key press with focus on selectHDFSeries and none of its controls.
function selectHDFSeries_KeyPressFcn(hObject, eventdata, handles)
if nargin < 3;    handles = guidata(hObject); end

% Check for "enter" or "escape"
if isequal(hObject.CurrentKey, 'escape')
    cancelBtn_Callback(hObject, eventdata, handles);
end    
if isequal(hObject.CurrentKey, 'return')
    continueBtn_Callback(hObject, eventdata, handles);
end  

end

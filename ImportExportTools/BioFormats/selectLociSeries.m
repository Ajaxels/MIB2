function varargout = selectLociSeries(varargin)
% SELECTLOCISERIES MATLAB code for selectLociSeries.fig
%      SELECTLOCISERIES by itself, creates a new SELECTLOCISERIES or raises the
%      existing singleton*.
%
%      H = SELECTLOCISERIES returns the handle to a new SELECTLOCISERIES or the handle to
%      the existing singleton*.
%
%      SELECTLOCISERIES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECTLOCISERIES.M with the given input arguments.
%
%      SELECTLOCISERIES('Property','Value',...) creates a new SELECTLOCISERIES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before selectLociSeries_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to selectLociSeries_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 25.06.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


% Edit the above text to modify the response to help selectLociSeries

% Last Modified by GUIDE v2.5 12-Dec-2013 09:53:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @selectLociSeries_OpeningFcn, ...
                   'gui_OutputFcn',  @selectLociSeries_OutputFcn, ...
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

% --- Executes just before selectLociSeries is made visible.
function selectLociSeries_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to selectLociSeries (see VARARGIN)

% Choose default command line output for selectLociSeries
handles.output = 'Cancel';  
handles.output2 = NaN;  % data object
handles.output3 = 1;  % read metadata switch
handles.output4 = [0 0 0 0 0]; % dimensions of the selected dataset xyczt
handles.output5 = {''}; % name of the image within the dataset
handles.filename = cell2mat(varargin{1});    % file name to get image dataset

% get MIB font size
Font = varargin{2};

handles.imagePreview.DataAspectRatio = [1 1 1];
handles.imagePreview.XTick = [];
handles.imagePreview.YTick = [];

% load the Bio-Formats library into the MATLAB environment
% For static loading, you can add the library to MATLAB's class path:
%     1. Type "edit classpath.txt" at the MATLAB prompt.
%     2. Go to the end of the file, and add the path to your JAR file
%        (e.g., C:/Program Files/MATLAB/work/loci_tools.jar).
%     3. Save the file and restart MATLAB.
%
% There are advantages to using the static approach over javaaddpath:
%     1. If you use bfopen within a loop, it saves on overhead
%        to avoid calling the javaaddpath command repeatedly.
%     2. Calling 'javaaddpath' may erase certain global parameters.
% javapath = javaclasspath('-static');
% loadLociJava = 0;
% for i=1:numel(javapath)
%     if ~isempty(strfind(javapath{i},'loci_tools.jar'))
%         loadLociJava = 1;
%         continue;
%     end
% end
% if loadLociJava==0
%     javaaddpath(fullfile(fileparts(mfilename('fullpath')),'loci_tools.jar'));
% end

if ~isdeployed
    javapath = javaclasspath('-all');
    if isempty(cell2mat(strfind(javapath, 'bioformats_package.jar')))
        javaaddpath(fullfile(fileparts(mfilename('fullpath')), 'bioformats_package.jar'));
    end
end

r = loci.formats.ChannelFiller();
r = loci.formats.ChannelSeparator(r);
%r = loci.formats.gui.BufferedImageReader(r);
r.setMetadataStore(loci.formats.MetadataTools.createOMEXMLMetadata());

r.setId(handles.filename);

numSeries = r.getSeriesCount();
data = cell(numSeries,6);  % prepare data for the table
for seriesIndex = 1:numSeries
    r.setSeries(seriesIndex-1);
    data{seriesIndex,1} = char(r.getMetadataStore().getImageName(seriesIndex - 1));
    data{seriesIndex,2} = r.getSizeX();
    data{seriesIndex,3} = r.getSizeY();
    data{seriesIndex,4} = r.getSizeC();    % number of color layers
    data{seriesIndex,5} = r.getSizeZ();
    data{seriesIndex,6} = r.getSizeT();    % number of time layers
end
handles.seriesTable.Data = data;

handles.output2 = r;

if numSeries > 0
    handles.output = 1;
    handles.output2.setSeries(handles.output-1);    % set desired series
    handles.output4 = cell2mat(data(1,2:6));
    handles.output5 = data(1,1);
    eventdata.Indices = 1;
    seriesTable_CellSelectionCallback(hObject, eventdata, handles);
end

% update font and size
if isstruct(Font)
    if handles.parametersCheckbox.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.parametersCheckbox.FontName, Font.FontName)
        mibUpdateFontSize(handles.selectLociSeries, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.selectLociSeries);

% increase size for text2 and selectedSeriesText
handles.text2.FontSize = handles.text2.FontSize + 2;
handles.selectedSeriesText.FontSize = handles.text2.FontSize + 2;

% Update handles structure
guidata(hObject, handles);

if numSeries==1
    continueBtn_Callback(handles.continueBtn, '', handles);
    return;
end

% Determine the position of the dialog - centered on the callback figure
% if available, else, centered on the screen
FigPos=get(0,'DefaultFigurePosition');
OldUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
OldPos = get(hObject,'Position');
FigWidth = OldPos(3);
FigHeight = OldPos(4);
if isempty(gcbf)
    ScreenUnits=get(0,'Units');
    set(0,'Units','pixels');
    ScreenSize=get(0,'ScreenSize');
    set(0,'Units',ScreenUnits);

    FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
    FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
else
    GCBFOldUnits = get(gcbf,'Units');
    set(gcbf,'Units','pixels');
    GCBFPos = get(gcbf,'Position');
    set(gcbf,'Units',GCBFOldUnits);
    FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                   (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
end
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);

% Make the GUI modal
set(handles.selectLociSeries,'WindowStyle','modal')

% UIWAIT makes selectLociSeries wait for user response (see UIRESUME)
uiwait(handles.selectLociSeries);
end

% --- Outputs from this function are returned to the command line.
function varargout = selectLociSeries_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = handles.output2;
varargout{3} = handles.output3;
varargout{4} = handles.output4;
varargout{5} = handles.output5;

% The figure can be deleted now
delete(handles.selectLociSeries);
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
% hObject    handle to continueBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.selectLociSeries);
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
uiresume(handles.selectLociSeries);
end

% --- Executes when user attempts to close selectLociSeries.
function selectLociSeries_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to selectLociSeries (see GCBO)
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
oldOutput = handles.output;
handles.selectedSeriesText.String = num2str(unique(eventdata.Indices(:,1)'));
handles.output = unique(eventdata.Indices(:,1));
handles.output2.setSeries(handles.output(1)-1);    % set desired series
tableData = get(handles.seriesTable,'Data');
%handles.output4 = tableData(eventdata.Indices(1),:);
handles.output4 = cell2mat(tableData(unique(eventdata.Indices(:,1)),2:6));
handles.output5 = tableData(unique(eventdata.Indices(:,1)),1);

set(handles.sliceNumberEdit, 'String', '1');
set(handles.sliceNumberSlider, 'Value', 1);
set(handles.sliceNumberSlider, 'Min', .99);
set(handles.sliceNumberSlider, 'Max', handles.output4(end, 4));
set(handles.sliceNumberSlider, 'SliderStep', [.1 .1]);

if oldOutput(1) ~= handles.output(1)
    updateImagePreview(handles);
end

% Update handles structure
guidata(hObject, handles);
end

function updateImagePreview(handles)
% update image preview
% load a slice for a thumbnail

sliceNumber = round(handles.sliceNumberSlider.Value);

templateImage = bfopen3(handles.output2, handles.output(1), sliceNumber);
templateImage = imresize(templateImage.img, 128/size(templateImage.img,1));
if size(templateImage,3) == 1
    templateImage2 = templateImage;
    imagesc(templateImage2, 'parent', handles.imagePreview);
    colormap('gray');
else
    templateImage2 = zeros([size(templateImage,1) size(templateImage,2) 3], class(templateImage));
    for color = 1:min([size(templateImage,3) 3])
        templateImage2(:,:,color) = templateImage(:,:,color);
    end
    imagesc(templateImage2, 'parent', handles.imagePreview);
end

handles.imagePreview.DataAspectRatio = [1 1 1];
handles.imagePreview.XTick = [];
handles.imagePreview.YTick = [];
end

% --- Executes on button press in parametersCheckbox.
function parametersCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to parametersCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output3 = get(hObject, 'Value');
% Update handles structure
guidata(hObject, handles);
end


% --- Executes on slider movement.
function sliceNumberSlider_Callback(hObject, eventdata, handles)
if strcmp(handles.output, 'Cancel')
    handles.sliceNumberSlider.Value = 1;
    return;
end
sliceNumber = round(handles.sliceNumberSlider.Value);
set(handles.sliceNumberEdit, 'String', num2str(sliceNumber));
updateImagePreview(handles);
end


function sliceNumberEdit_Callback(hObject, eventdata, handles)
if strcmp(handles.output, 'Cancel')
    handles.sliceNumberEdit.String = '1';
    return;
end
value = str2double(handles.sliceNumberEdit.String);
if value > handles.output4(end,4)
    value = handles.output4(end,4);
    handles.sliceNumberEdit.String = num2str(value);
end
handles.sliceNumberSlider.Value = value;
updateImagePreview(handles);
end


% --- Executes on key press with focus on selectLociSeries and none of its controls.
function selectLociSeries_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to selectLociSeries (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
if isequal(hObject.CurrentKey, 'escape')
    cancelBtn_Callback(handles.cancelBtn, eventdata, handles);
end    
    
if isequal(hObject.CurrentKey, 'return')
    continueBtn_Callback(handles.continueBtn, eventdata, handles)
end    

end

function varargout = mibSnapshotGUI(varargin)
% function varargout = mibSnapshotGUI(varargin)
% mibSnapshotGUI function is responsible for making snapshots of the shown dataset.
%
% mibSnapshotGUI contains MATLAB code for mibSnapshotGUI.fig

% Copyright (C) 10.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibSnapshotGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibSnapshotGUI_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT


% --- Executes just before mibSnapshotGUI is made visible.
function mibSnapshotGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibSnapshotGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% set Size of the window
winPos = handles.mibSnapshotGUI.Position;
handles.mibSnapshotGUI.Position = [winPos(1) winPos(1) 335 winPos(4)];

handles.jpgPanel.Parent = handles.tifPanel.Parent;
handles.bmpPanel.Parent = handles.tifPanel.Parent;

% update font and size
global Font;
if handles.text1.FontSize ~= Font.FontSize ...
        || ~strcmp(handles.text1.FontName, Font.FontName)
    mibUpdateFontSize(handles.mibSnapshotGUI, Font);
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibSnapshotGUI);

% Choose default command line output for mibSnapshotGUI
handles.output = hObject;

% Determine the position of the dialog - on a side of the main figure
% if available, else, centered on the main figure
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
    screenSize = get(0,'ScreenSize');
    if GCBFPos(1)-FigWidth > 0 % put figure on the left side of the main figure
        FigPos(1:2) = [GCBFPos(1)-FigWidth-10 GCBFPos(2)+GCBFPos(4)-FigHeight+59];
    elseif GCBFPos(1) + GCBFPos(3) + FigWidth < screenSize(3) % put figure on the right side of the main figure
        FigPos(1:2) = [GCBFPos(1)+GCBFPos(3)+10 GCBFPos(2)+GCBFPos(4)-FigHeight+59];
    else
        FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
            (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
    end
end
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);

settingsPanelPosition = handles.tifPanel.Position;
settingsPanelParent = handles.tifPanel.Parent;
handles.jpgPanel.Parent = settingsPanelParent;
handles.bmpPanel.Parent = settingsPanelParent;
handles.jpgPanel.Position = settingsPanelPosition;
handles.bmpPanel.Position = settingsPanelPosition;

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
% set(handles.mibSnapshotGUI,'WindowStyle','modal');

% UIWAIT makes mibSnapshotGUI wait for user response (see UIRESUME)
% uiwait(handles.mibSnapshotGUI);

end

% --- Outputs from this function are returned to the command line.
function varargout = mibSnapshotGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

end

function mibSnapshotGUI_CloseRequestFcn(hObject, eventdata, handles)
% --- Executes when user attempts to close mibSnapshotGUI.
handles.winController.closeWindow();
end

% --- Executes on button press in closelBtn.
function closelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function crop_Callback(hObject, eventdata, handles)
handles.winController.crop_Callback();
end

function outputDir_Callback(hObject, eventdata, handles)
handles.winController.outputDir_Callback();
end

% --- Executes on button press in selectFileBtn.
function selectFileBtn_Callback(hObject, eventdata, handles)
handles.winController.selectFileBtn_Callback();         
end

function tifRowsPerStrip_Callback(hObject, eventdata, handles)
val = str2double(handles.tifRowsPerStrip.String);
if mod(val, 8) ~= 0
    msgbox('The RowsPerStrip parameter should be a multiple of 8!','Wrong parameter','error');
    handles.tifRowsPerStrip.String = '8000';
    return;
end
end

% --- Executes on selection change in fileFormatPopup.
function fileFormatPopup_Callback(hObject, eventdata, handles)
handles.winController.fileFormatPopup_Callback();
end


function widthEdit_Callback(hObject, eventdata, handles)
handles.winController.widthEdit_Callback();
end

function heightEdit_Callback(hObject, eventdata, handles)
handles.winController.heightEdit_Callback();
end

function radioBtns_Callback(hObject, eventdata, handles)
if handles.toFileRadio.Value
    handles.filePanel.Visible = 'on';
elseif handles.clipboardRadio.Value
    handles.filePanel.Visible = 'off';
end
end

% --- Executes on button press in helpButton.
function helpButton_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_file_makesnapshot.html'), '-helpbrowser');
end

% --- Executes on key press with focus on mibSnapshotGUI and none of its controls.
function mibSnapshotGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibSnapshotGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% Check for "enter" or "escape"
if isequal(hObject.CurrentKey, 'escape')
    cancelBtn_Callback(handles.closelBtn, eventdata, handles);
end    
    
if isequal(hObject.CurrentKey, 'return')
    continueBtn_Callback(handles.snapshotBtn, eventdata, handles);
end   
end

% --- Executes on button press in snapshotBtn.
function snapshotBtn_Callback(hObject, eventdata, handles)
handles.winController.snapshotBtn_Callback();
end


% --- Executes on button press in scalebarCheck.
function scalebarCheck_Callback(hObject, eventdata, handles)
handles.winController.scalebarCheck_Callback();
end

% --- Executes on button press in measurementsCheck.
function measurementsCheck_Callback(hObject, eventdata, handles)
if handles.measurementsCheck.Value
    warndlg(sprintf('!!! Warning !!!\nAddition of measurements to the snapshot may add artifacts at the borders of the image (at least in R2014b)!\n\nAfter rendering please make sure that the snapshot is good enough for your purposes!'),'Adding measurements')
    handles.measurementsOptions.Enable = 'on';
else
    handles.measurementsOptions.Enable = 'off';
end
end


% --- Executes on button press in measurementsOptions.
function measurementsOptions_Callback(hObject, eventdata, handles)
handles.winController.measurementsOptions_Callback();
end


function bin2Btn_Callback(hObject, eventdata, handles)
% --- Executes on button press in bin2Btn.
switch hObject.Tag
    case 'bin2Btn'
        xFactor = 2;
    case 'bin4Btn'
        xFactor = 4;
    case 'bin8Btn'
        xFactor = 8;
end
width = str2double(handles.widthEdit.String);
height = str2double(handles.heightEdit.String);
width = ceil(width/xFactor);
height = ceil(height/xFactor);
handles.widthEdit.String = num2str(width);
handles.heightEdit.String = num2str(height);
end


function splitChannelsCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in splitChannelsCheck.
handles.winController.splitChannelsCheck_Callback();
end


% --- Executes on selection change in roiPopup.
function roiPopup_Callback(hObject, eventdata, handles)
handles.winController.roiPopup_Callback();
end

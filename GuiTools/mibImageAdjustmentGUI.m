function varargout = mibImageAdjustmentGUI(varargin)
% function varargout = mibImageAdjustmentGUI(varargin)
% mibImageAdjustmentGUI function allows to adjust contrast and gamma of the shown dataset.
%
% mibImageAdjustmentGUI contains MATLAB code for mibImageAdjustmentGUI.fig

% Copyright (C) 23.06.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 29.09.2015 - updated the way how the window is reinitialized 
% 24.01.2016 - updated for 4D

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibImageAdjustmentGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibImageAdjustmentGUI_OutputFcn, ...
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

% --- Executes just before mibImageAdjustmentGUI is made visible.
function mibImageAdjustmentGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibImageAdjustmentGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibImageAdjustmentGUI
handles.output = hObject;

% update font and size
global Font;
if ~isempty(Font)
    if handles.colorChannelText.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.colorChannelText.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibImageAdjustmentGUI, Font);
    end
end

% adding context menu for findMinBtn
handles.findMinBtn_cm = uicontextmenu('Parent',handles.mibImageAdjustmentGUI);
uimenu(handles.findMinBtn_cm, 'Label', 'Exclude 0%', 'Callback', {@findMinBtn_cm_Callback, 0});
uimenu(handles.findMinBtn_cm, 'Label', 'Exclude 0.5%', 'Callback', {@findMinBtn_cm_Callback, 0.5});
uimenu(handles.findMinBtn_cm, 'Label', 'Exclude 1%', 'Callback', {@findMinBtn_cm_Callback, 1});
uimenu(handles.findMinBtn_cm, 'Label', 'Exclude 2.5%', 'Callback', {@findMinBtn_cm_Callback, 2.5});
uimenu(handles.findMinBtn_cm, 'Label', 'Exclude 5%', 'Callback', {@findMinBtn_cm_Callback, 5});
uimenu(handles.findMinBtn_cm, 'Label', 'Custom value', 'Callback', {@findMinBtn_cm_Callback, NaN});
handles.findMinBtn.UIContextMenu = handles.findMinBtn_cm;

handles.findMaxBtn_cm = uicontextmenu('Parent',handles.mibImageAdjustmentGUI);
uimenu(handles.findMaxBtn_cm, 'Label', 'Exclude 0%', 'Callback', {@findMaxBtn_cm_Callback, 0});
uimenu(handles.findMaxBtn_cm, 'Label', 'Exclude 0.5%', 'Callback', {@findMaxBtn_cm_Callback, 0.5});
uimenu(handles.findMaxBtn_cm, 'Label', 'Exclude 1%', 'Callback', {@findMaxBtn_cm_Callback, 1});
uimenu(handles.findMaxBtn_cm, 'Label', 'Exclude 2.5%', 'Callback', {@findMaxBtn_cm_Callback, 2.5});
uimenu(handles.findMaxBtn_cm, 'Label', 'Exclude 5%', 'Callback', {@findMaxBtn_cm_Callback, 5});
uimenu(handles.findMaxBtn_cm, 'Label', 'Custom value', 'Callback', {@findMaxBtn_cm_Callback, NaN});
handles.findMaxBtn.UIContextMenu = handles.findMaxBtn_cm;

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibImageAdjustmentGUI);
% 
% Adding listeners if the window is opened for the first time
handles.minSliderListener = addlistener(handles.minSlider, 'ContinuousValueChange', @minSlider_Callback);
handles.maxSliderListener = addlistener(handles.maxSlider, 'ContinuousValueChange', @maxSlider_Callback);
handles.gammaSliderListener = addlistener(handles.gammaSlider, 'ContinuousValueChange', @gammaSlider_Callback);

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibImageAdjustmentGUI wait for user response (see UIRESUME)
% uiwait(handles.mibImageAdjustmentGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibImageAdjustmentGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibImageAdjustmentGUI.
function mibImageAdjustmentGUI_CloseRequestFcn(hObject, eventdata, handles) %#ok<DEFNU>
handles.winController.closeWindow();
end

% --- Executes on slider movement.
function minSlider_Callback(hObject, eventdata, handles)
handles = guidata(hObject);     % update handles for listener
handles.winController.minSlider_Callback();
end


function minEdit_Callback(hObject, eventdata, handles)
handles.winController.minEdit_Callback();
end

% --- Executes on slider movement.
function maxSlider_Callback(hObject, eventdata, handles)
handles = guidata(hObject);     % update handles for listener
handles.winController.maxSlider_Callback();
end

function maxEdit_Callback(hObject, eventdata, handles)
handles.winController.maxEdit_Callback();
end

% --- Executes on slider movement.
function gammaSlider_Callback(hObject, eventdata, handles)
handles = guidata(hObject);     % update handles for listener
handles.winController.gammaSlider_Callback();
end


function gammaEdit_Callback(hObject, eventdata, handles)
handles.winController.gammaEdit_Callback();
end

% --- Executes on button press in logViewCheck.
function logViewCheck_Callback(hObject, eventdata, handles)
handles.winController.updateHist();
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function mibImageAdjustmentGUI_WindowButtonDownFcn(hObject, eventdata, handles)
handles.winController.mibImageAdjustmentGUI_WindowButtonDownFcn();
end

function colorChannelCombo_Callback(hObject, eventdata, handles)
% --- Executes on selection change in colorChannelCombo.
handles.winController.colorChannelCombo_Callback();
end

function adjHelpBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in adjHelpBtn.
handles.winController.adjHelpBtn_Callback();
end

function findMinBtn_cm_Callback(hObject, eventdata, threshold)
% function findMinBtn_cm_Callback(hObject, eventdata, threshold)
% callback for popup menu of the findMinBtn
% Properties:
% threshold: [number], that indicates %% of points to be excluded from
% automatic calculation of min
global mibPath;

handles = guidata(hObject);
if isnan(threshold)
    prompt = {'Input %% (0-100) of data points to be excluded from the blacks:'};
    title = 'Exclude %%';
    answer = mibInputDlg({mibPath}, prompt, title, '1');
    if size(answer) == 0; return; end
    threshold = str2double(answer);
end
colorCh = [];
handles.winController.findMinBtn_Callback(colorCh, threshold);
end

function findMinBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in findMinBtn.
handles.winController.findMinBtn_Callback();
end

function findMaxBtn_cm_Callback(hObject, eventdata, threshold)
% function findMaxBtn_cm_Callback(hObject, eventdata, threshold)
% callback for popup menu of the findMaxBtn
% Properties:
% threshold: [number], that indicates %% of points to be excluded from
% automatic calculation of max
global mibPath;
handles = guidata(hObject);
if isnan(threshold)
    prompt = {'Input %% (0-100) of data points to be excluded from the whites:'};
    title = 'Exclude %%';
    answer = mibInputDlg({mibPath}, prompt, title, '1');
    if size(answer) == 0; return; end
    threshold = str2double(answer);
end
colorCh = [];
handles.winController.findMaxBtn_Callback(colorCh, threshold);
end

function findMaxBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in findMaxBtn.
handles.winController.findMaxBtn_Callback();
end

% --- Executes on button press in updateBtn.
function updateBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over minSlider.
function minSlider_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to minSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.minSlider_ButtonDownFcn();
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over maxSlider.
function maxSlider_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to maxSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.maxSlider_ButtonDownFcn();
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over gammaSlider.
function gammaSlider_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to gammaSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.gammaSlider.Value = 1;
handles.winController.gammaSlider_Callback();
end

function applyBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in applyBtn.
handles.winController.applyBtn_Callback();
end

% --- Executes on button press in stretchCurrent.
function stretchCurrent_Callback(hObject, eventdata, handles)
handles.winController.stretchCurrent_Callback();
end


% --- Executes on button press in autoHistCheck.
function autoHistCheck_Callback(hObject, eventdata, handles)
handles.winController.autoHistCheck_Callback();
end

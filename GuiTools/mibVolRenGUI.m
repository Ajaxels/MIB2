function varargout = mibVolRenGUI(varargin)
% function varargout = mibVolRenGUI(varargin)
% mibVolRenGUI function is responsible for morphological operations done with images.
%
% mibVolRenGUI contains MATLAB code for mibVolRenGUI.fig

% Copyright (C) 30.10.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.02.2016, IB, updated for 4D datasets


% Edit the above text to modify the response to help mibVolRenGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 17:27:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibVolRenGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibVolRenGUI_OutputFcn, ...
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

% --- Executes just before mibVolRenGUI is made visible.
function mibVolRenGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibVolRenGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibChildGUI
handles.output = hObject;

handles.mibVolRenGUI.Position([3 4]) = [490 374];
handles.isosurfacePanel.Parent = handles.volRenPanel.Parent;
handles.isosurfacePanel.Position = handles.volRenPanel.Position;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibVolRenGUI wait for user response (see UIRESUME)
% uiwait(handles.mibVolRenGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibVolRenGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibVolRenGUI.
function mibVolRenGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibVolRenGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on selection change in visualizationModePopup.
function visualizationModePopup_Callback(hObject, eventdata, handles)
% hObject    handle to visualizationModePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns visualizationModePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from visualizationModePopup

handles.winController.visualizationModePopup_Callback();
end

function isovalEdit_Callback(hObject, eventdata, handles)
% hObject    handle to isovalEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of isovalEdit as text
%        str2double(get(hObject,'String')) returns contents of isovalEdit as a double
handles.isovalSlider.Value = round(str2double(handles.isovalEdit.String));
handles.winController.isovalEdit_Callback();
end


% --- Executes on slider movement.
function isovalSlider_Callback(hObject, eventdata, handles)
% hObject    handle to isovalSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = round(handles.isovalSlider.Value);
handles.isovalEdit.String = num2str(val);
isovalEdit_Callback(hObject, eventdata, handles);
end


% --- Executes on button press in isoColor.
function isoColor_Callback(hObject, eventdata, handles)
% hObject    handle to isoColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.isoColor_Callback();
end


% --- Executes on button press in spinBtn.
function spinBtn_Callback(hObject, eventdata, handles)
handles.winController.spinBtn_Callback();
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function mibVolRenGUI_WindowButtonDownFcn(hObject, eventdata, handles)
handles.winController.mibVolRenGUI_WindowButtonDownFcn(eventdata);
end

function mibVolRenGUI_WindowButtonUpFcn(hObject, eventdata, handles)
handles.winController.mibVolRenGUI_WindowButtonUpFcn(eventdata);
end

% --- Executes on scroll wheel click while the figure is in focus.
function mibVolRenGUI_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to mibVolRenGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)
handles.winController.mibVolRenGUI_WindowScrollWheelFcn(eventdata);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% MENU ITEMS
% --------------------------------------------------------------------
% --------------------------------------------------------------------


% --------------------------------------------------------------------
function menuSettingsBackgroundColor_Callback(hObject, eventdata, handles)
% hObject    handle to menuSettingsBackgroundColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.menuSettingsBackgroundColor_Callback();
end

% --------------------------------------------------------------------
function menuSettingsIsosurfaceColor_Callback(hObject, eventdata, handles)
handles.winController.isoColor_Callback();
end


% --------------------------------------------------------------------
function menuSettingsSelectColormap_Callback(hObject, eventdata, handles)
% function menuSettingsSelectColormap_Callback(hObject, eventdata, handles)
% select one of the predefined colormaps
handles.winController.menuSettingsSelectColormap_Callback();
end

% --- Executes on button press in grabFrameBtn.
function grabFrameBtn_Callback(hObject, eventdata, handles)
handles.winController.grabFrameBtn_Callback();
end


% --- Executes when mibVolRenGUI is resized.
function mibVolRenGUI_SizeChangedFcn(hObject, eventdata, handles)
handles.winController.mibVolRenGUI_SizeChangedFcn();
end


% --------------------------------------------------------------------
function menuInvertAlphaCurve_Callback(hObject, eventdata, handles)
% invert alpha curve
handles.winController.menuInvertAlphaCurve_Callback();
end


% --------------------------------------------------------------------
function menuFileMakesnapshot_Callback(hObject, eventdata, handles)
handles.winController.menuFileMakesnapshot_Callback();
end

% --------------------------------------------------------------------
function menuFileMovie_Callback(hObject, eventdata, handles, mode)
handles.winController.menuFileMovie_Callback(mode);
end

% --------------------------------------------------------------------
function menuChangeView(hObject, eventdata, handles, parameter)
handles.winController.changeView(parameter);
end

% --------------------------------------------------------------------
function menuToolsAnimation_Callback(hObject, eventdata, handles)
handles.winController.menuToolsAnimation_Callback();
end


% --- Executes on button press in previewBtn.
function previewBtn_Callback(hObject, eventdata, handles)
handles.winController.previewAnimation();
end


% --------------------------------------------------------------------
function menuFileLoadAnimation_Callback(hObject, eventdata, handles)
handles.winController.menuFileLoadAnimation_Callback();
end

% --------------------------------------------------------------------
function menuFileSaveAnimation_Callback(hObject, eventdata, handles)
handles.winController.menuFileSaveAnimation_Callback();
end

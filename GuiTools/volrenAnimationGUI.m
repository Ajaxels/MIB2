function varargout = volrenAnimationGUI(varargin)
% VOLRENANIMATIONGUI MATLAB code for volrenAnimationGUI.fig
%      VOLRENANIMATIONGUI, by itself, creates a new VOLRENANIMATIONGUI or raises the existing
%      singleton*.
%
%      H = VOLRENANIMATIONGUI returns the handle to a new VOLRENANIMATIONGUI or the handle to
%      the existing singleton*.
%
%      VOLRENANIMATIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VOLRENANIMATIONGUI.M with the given input arguments.
%
%      VOLRENANIMATIONGUI('Property','Value',...) creates a new VOLRENANIMATIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before volrenAnimationGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to volrenAnimationGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help volrenAnimationGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 16:52:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @volrenAnimationGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @volrenAnimationGUI_OutputFcn, ...
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

% --- Executes just before volrenAnimationGUI is made visible.
function volrenAnimationGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to volrenAnimationGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% adding context menu for mibFileFilterPopup
handles.keyFrameTable_cm = uicontextmenu('Parent', handles.volrenAnimationGUI);
uimenu(handles.keyFrameTable_cm, 'Label', 'Jump to the keyframe', 'Callback', {@keyFrameTable_cm_Callback, 'jump'});
uimenu(handles.keyFrameTable_cm, 'Label', 'Insert a key frame', 'Separator','on', 'Callback', {@keyFrameTable_cm_Callback, 'insert'});
uimenu(handles.keyFrameTable_cm, 'Label', 'Replace the key frame', 'Callback', {@keyFrameTable_cm_Callback, 'replace'});
uimenu(handles.keyFrameTable_cm, 'Label', 'Remove the key frame', 'Callback', {@keyFrameTable_cm_Callback, 'remove'});
handles.keyFrameTable.UIContextMenu = handles.keyFrameTable_cm;

% Choose default command line output for volrenAnimationGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes volrenAnimationGUI wait for user response (see UIRESUME)
% uiwait(handles.volrenAnimationGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = volrenAnimationGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close volrenAnimationGUI.
function volrenAnimationGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to volrenAnimationGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end


% % ----------------------------------------------------------------------
% Callbacks for buttons
% % ----------------------------------------------------------------------
% --- Executes on button press in addFrameBtn.
function addFrameBtn_Callback(hObject, eventdata, handles)
handles.winController.addFrameBtn_Callback();
end


% --- Executes when volrenAnimationGUI is resized.
function volrenAnimationGUI_SizeChangedFcn(hObject, eventdata, handles)
handles.toolsPanel.Position(1) = 5;
handles.toolsPanel.Position(3) = handles.volrenAnimationGUI.Position(3)-10;
handles.keyFrameTable.Position(3) = handles.volrenAnimationGUI.Position(3)-10;
handles.keyFrameTable.Position(2) = handles.toolsPanel.Position(2) + handles.toolsPanel.Position(4) + 10;
handles.keyFrameTable.Position(4) = max([1 handles.volrenAnimationGUI.Position(4) - handles.keyFrameTable.Position(2) - 5]);
end

function keyFrameTable_cm_Callback(hObject, ~, parameter)
handles = guidata(hObject);
handles.winController.keyFrameTable_cm_Callback(parameter);
end

% --- Executes on button press in deleteAllBtn.
function deleteAllBtn_Callback(hObject, eventdata, handles)
handles.winController.deleteAllBtn_Callback();
end


% --- Executes when selected cell(s) is changed in keyFrameTable.
function keyFrameTable_CellSelectionCallback(hObject, eventdata, handles)
if ~isempty(eventdata.Indices)
    Indices = eventdata.Indices(1, 2);
else
    Indices = [];
end
handles.winController.keyFrameTable_CellSelectionCallback(Indices);
end


% --- Executes on button press in previewBtn.
function previewBtn_Callback(hObject, eventdata, handles)
handles.winController.previewBtn_Callback();
end

function noAnimationFramesEdit_Callback(hObject, eventdata, handles)
handles.winController.noAnimationFramesEdit_Callback();
end

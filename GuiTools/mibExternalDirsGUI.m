function varargout = mibExternalDirsGUI(varargin)
% MIBEXTERNALDIRSGUI MATLAB code for mibExternalDirsGUI.fig
%      MIBEXTERNALDIRSGUI, by itself, creates a new MIBEXTERNALDIRSGUI or raises the existing
%      singleton*.
%
%      H = MIBEXTERNALDIRSGUI returns the handle to a new MIBEXTERNALDIRSGUI or the handle to
%      the existing singleton*.
%
%      MIBEXTERNALDIRSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBEXTERNALDIRSGUI.M with the given input arguments.
%
%      MIBEXTERNALDIRSGUI('Property','Value',...) creates a new MIBEXTERNALDIRSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibExternalDirsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibExternalDirsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibExternalDirsGUI

% Last Modified by GUIDE v2.5 02-Mar-2017 17:51:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibExternalDirsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibExternalDirsGUI_OutputFcn, ...
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

% --- Executes just before mibExternalDirsGUI is made visible.
function mibExternalDirsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibExternalDirsGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibExternalDirsGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

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

% UIWAIT makes mibExternalDirsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibExternalDirsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibExternalDirsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibExternalDirsGUI.
function mibExternalDirsGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibExternalDirsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

function dirEdit_Callback(hObject, eventdata, handles)
% hObject    handle to dirEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dirEdit as text
%        str2double(get(hObject,'String')) returns contents of dirEdit as a double

handles.winController.dirEdit_Callback();
end

% --- Executes on button press in selectDirBtn.
function selectDirBtn_Callback(hObject, eventdata, handles)
% hObject    handle to selectDirBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.selectDirBtn_Callback();
end


% --- Executes when selected object is changed in radioButtons.
function radioButtons_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in radioButtons 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.radioButtons_SelectionChangedFcn(hObject.String);
end

% --- Executes on button press in acceptBtn.
function acceptBtn_Callback(hObject, eventdata, handles)
% hObject    handle to acceptBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.acceptBtn_Callback();
end

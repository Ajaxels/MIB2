function varargout = GuiTutorialGUI(varargin)
% GUITUTORIALGUI MATLAB code for GuiTutorialGUI.fig
%      GUITUTORIALGUI, by itself, creates a new GUITUTORIALGUI or raises the existing
%      singleton*.
%
%      H = GUITUTORIALGUI returns the handle to a new GUITUTORIALGUI or the handle to
%      the existing singleton*.
%
%      GUITUTORIALGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUITUTORIALGUI.M with the given input arguments.
%
%      GUITUTORIALGUI('Property','Value',...) creates a new GUITUTORIALGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GuiTutorialGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GuiTutorialGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiTutorialGUI

% Last Modified by GUIDE v2.5 15-Mar-2017 18:31:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GuiTutorialGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GuiTutorialGUI_OutputFcn, ...
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


% --- Executes just before GuiTutorialGUI is made visible.
function GuiTutorialGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GuiTutorialGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for GuiTutorialGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GuiTutorialGUI wait for user response (see UIRESUME)
% uiwait(handles.GuiTutorialGUI);


% --- Outputs from this function are returned to the command line.
function varargout = GuiTutorialGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();

% --- Executes when user attempts to close GuiTutorialGUI.
function GuiTutorialGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to GuiTutorialGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();


% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
% hObject    handle to continueBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% triggers the main function that does one of the following actions
if handles.cropRadio.Value == 1
    % do cropping
    handles.winController.cropDataset();
elseif handles.resizeRadio.Value == 1
    % do resizing
    handles.winController.resizeDataset();
elseif handles.convertRadio.Value == 1
    % do class convertsion
    handles.winController.convertDataset();
elseif handles.invertRadio.Value == 1
    % do invert
    handles.winController.invertDataset();
end



% --- Executes when selected object is changed in buttonGroup.
function buttonGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in buttonGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% enable all widgets
handles.xMinEdit.Enable = 'on';
handles.yMinEdit.Enable = 'on';
handles.widthEdit.Enable = 'on';
handles.heightEdit.Enable = 'on';
handles.convertPopup.Enable = 'on';
handles.colorPopup.Enable = 'on';

% switch off widgets that are not used in each of the following modes
switch hObject.Tag
    case 'cropRadio'    % crop mode
        handles.convertPopup.Enable = 'off';
        handles.colorPopup.Enable = 'off';
    case 'resizeRadio'  % resize mode
        handles.xMinEdit.Enable = 'off';
        handles.yMinEdit.Enable = 'off';
        handles.convertPopup.Enable = 'off';
        handles.colorPopup.Enable = 'off';
    case 'convertRadio' % convert mode
        handles.xMinEdit.Enable = 'off';
        handles.yMinEdit.Enable = 'off';
        handles.widthEdit.Enable = 'off';
        handles.heightEdit.Enable = 'off';
        handles.colorPopup.Enable = 'off';
    case 'invertRadio'  % invert mode
        handles.xMinEdit.Enable = 'off';
        handles.yMinEdit.Enable = 'off';
        handles.widthEdit.Enable = 'off';
        handles.heightEdit.Enable = 'off';
        handles.convertPopup.Enable = 'off';
end


function xMinEdit_Callback(hObject, eventdata, handles)
% hObject    handle to xMinEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xMinEdit as text
%        str2double(get(hObject,'String')) returns contents of xMinEdit as a double


function yMinEdit_Callback(hObject, eventdata, handles)
% hObject    handle to yMinEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yMinEdit as text
%        str2double(get(hObject,'String')) returns contents of yMinEdit as a double



function widthEdit_Callback(hObject, eventdata, handles)
% hObject    handle to widthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of widthEdit as text
%        str2double(get(hObject,'String')) returns contents of widthEdit as a double


function heightEdit_Callback(hObject, eventdata, handles)
% hObject    handle to heightEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of heightEdit as text
%        str2double(get(hObject,'String')) returns contents of heightEdit as a double

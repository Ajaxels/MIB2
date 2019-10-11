function varargout = mibTipsGUI(varargin)
% MIBTIPSGUI MATLAB code for mibTipsGUI.fig
%      MIBTIPSGUI, by itself, creates a new MIBTIPSGUI or raises the existing
%      singleton*.
%
%      H = MIBTIPSGUI returns the handle to a new MIBTIPSGUI or the handle to
%      the existing singleton*.
%
%      MIBTIPSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBTIPSGUI.M with the given input arguments.
%
%      MIBTIPSGUI('Property','Value',...) creates a new MIBTIPSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibTipsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibTipsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibTipsGUI

% Last Modified by GUIDE v2.5 05-Feb-2019 20:42:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibTipsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibTipsGUI_OutputFcn, ...
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


% --- Executes just before mibTipsGUI is made visible.
function mibTipsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibTipsGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibTipsGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibTipsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibTipsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibTipsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close mibTipsGUI.
function mibTipsGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibTipsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end


% % ----------------------------------------------------------------------
% Callbacks for buttons
% % ----------------------------------------------------------------------


% --- Executes on button press in nextTipBtn.
% start calculation of something
function nextTipBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call a corresponding method of the controller class
handles.winController.nextTipBtn_Callback();
end

% --- Executes on button press in previousTipBtn.
function previousTipBtn_Callback(hObject, eventdata, handles)
handles.winController.previousTipBtn_Callback();
end


% --- Executes on button press in closeBtn.
% close the plugin window
function closeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

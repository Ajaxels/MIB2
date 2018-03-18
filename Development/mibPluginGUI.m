function varargout = mibPluginGUI(varargin)
% MIBPLUGINGUI MATLAB code for mibPluginGUI.fig
%      MIBPLUGINGUI, by itself, creates a new MIBPLUGINGUI or raises the existing
%      singleton*.
%
%      H = MIBPLUGINGUI returns the handle to a new MIBPLUGINGUI or the handle to
%      the existing singleton*.
%
%      MIBPLUGINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBPLUGINGUI.M with the given input arguments.
%
%      MIBPLUGINGUI('Property','Value',...) creates a new MIBPLUGINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibPluginGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibPluginGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibPluginGUI

% Last Modified by GUIDE v2.5 16-Jan-2018 09:01:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibPluginGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibPluginGUI_OutputFcn, ...
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


% --- Executes just before mibPluginGUI is made visible.
function mibPluginGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibPluginGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibPluginGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibPluginGUI wait for user response (see UIRESUME)
% uiwait(handles.mibPluginGUI);


% --- Outputs from this function are returned to the command line.
function varargout = mibPluginGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes when user attempts to close mibPluginGUI.
function mibPluginGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibPluginGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();



% % ----------------------------------------------------------------------
% Callbacks for buttons
% % ----------------------------------------------------------------------

% --- Executes on button press in helpBtn
function helpBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global mibPath;
web(fullfile(mibPath, 'Plugins', 'MyPlugins', 'mibPlugin', 'Help', 'index.html'), '-helpbrowser');


% --- Executes on button press in calculateBtn.
% start calculation of something
function calculateBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call a corresponding method of the controller class
handles.winController.calculateBtn_Callback();


% --- Executes on button press in closeBtn.
% close the plugin window
function closeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();

function varargout = mibChildGUI(varargin)
% MIBCHILDGUI MATLAB code for mibChildGUI.fig
%      MIBCHILDGUI, by itself, creates a new MIBCHILDGUI or raises the existing
%      singleton*.
%
%      H = MIBCHILDGUI returns the handle to a new MIBCHILDGUI or the handle to
%      the existing singleton*.
%
%      MIBCHILDGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBCHILDGUI.M with the given input arguments.
%
%      MIBCHILDGUI('Property','Value',...) creates a new MIBCHILDGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibChildGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibChildGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibChildGUI

% Last Modified by GUIDE v2.5 04-Nov-2016 16:29:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibChildGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibChildGUI_OutputFcn, ...
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

% --- Executes just before mibChildGUI is made visible.
function mibChildGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibChildGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibChildGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibChildGUI wait for user response (see UIRESUME)
% uiwait(handles.mibChildGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibChildGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close mibChildGUI.
function mibChildGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibChildGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

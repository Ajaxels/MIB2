function varargout = CellWallThicknessGUI(varargin)
% CELLWALLTHICKNESSGUI MATLAB code for CellWallThicknessGUI.fig
%      CELLWALLTHICKNESSGUI, by itself, creates a new CELLWALLTHICKNESSGUI or raises the existing
%      singleton*.
%
%      H = CELLWALLTHICKNESSGUI returns the handle to a new CELLWALLTHICKNESSGUI or the handle to
%      the existing singleton*.
%
%      CELLWALLTHICKNESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CELLWALLTHICKNESSGUI.M with the given input arguments.
%
%      CELLWALLTHICKNESSGUI('Property','Value',...) creates a new CELLWALLTHICKNESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CellWallThicknessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CellWallThicknessGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CellWallThicknessGUI

% Last Modified by GUIDE v2.5 11-Oct-2018 08:28:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CellWallThicknessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CellWallThicknessGUI_OutputFcn, ...
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

% --- Executes just before CellWallThicknessGUI is made visible.
function CellWallThicknessGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CellWallThicknessGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for TripleAreaIntensityGUI
handles.output = hObject;

% move the window
%hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CellWallThicknessGUI wait for user response (see UIRESUME)
% uiwait(handles.CellWallThicknessGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = CellWallThicknessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close CellWallThicknessGUI.
function ProfileBranchesGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in saveResultsCheck.
function saveResultsCheck_Callback(hObject, eventdata, handles)
val = hObject.Value;
if val==1
    handles.exportResultsFilename.Enable = 'on';
    handles.filenameEdit.Enable = 'on';
    handles.saveCenterlineCheck.Enable = 'on';
else
    handles.exportResultsFilename.Enable = 'off';
    handles.filenameEdit.Enable = 'off';
    handles.saveCenterlineCheck.Enable = 'off';
end
end

% --- Executes on button press in exportResultsFilename.
function exportResultsFilename_Callback(hObject, eventdata, handles)
handles.winController.exportResultsFilename_Callback();
end

% --- Executes on button press in exportMatlabCheck.
function exportMatlabCheck_Callback(hObject, eventdata, handles)
handles.winController.exportMatlabCheck_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
%web(fullfile(mibPath, 'Plugins', 'Plasmodesmata', 'CellWallThickness', 'html/CellWallThickness_help.html'), '-helpbrowser');
web('https://andreapaterlini.github.io/Plasmodesmata_dist_wall/wall.html');
end

function profileThresholdEdit_Callback(hObject, eventdata, handles)
editbox_Callback(hObject, 'pfloat','0',[0, NaN]);
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end


% --- Executes on button press in thinBtn.
function thinBtn_Callback(hObject, eventdata, handles)
handles.winController.thinBtn_Callback();
end


% --- Executes on button press in useAnnotationsCheck.
function useAnnotationsCheck_Callback(hObject, eventdata, handles)
handles.winController.useAnnotationsCheck_Callback();
end


% --- Executes on button press in useRandomPoresCheck.
function useRandomPoresCheck_Callback(hObject, eventdata, handles)
handles.winController.useRandomPoresCheck_Callback();
end

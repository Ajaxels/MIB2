function varargout = mibImageArithmeticGUI(varargin)
% MIBIMAGEARITHMETICGUI MATLAB code for mibImageArithmeticGUI.fig
%      MIBIMAGEARITHMETICGUI, by itself, creates a new MIBIMAGEARITHMETICGUI or raises the existing
%      singleton*.
%
%      H = MIBIMAGEARITHMETICGUI returns the handle to a new MIBIMAGEARITHMETICGUI or the handle to
%      the existing singleton*.
%
%      MIBIMAGEARITHMETICGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBIMAGEARITHMETICGUI.M with the given input arguments.
%
%      MIBIMAGEARITHMETICGUI('Property','Value',...) creates a new MIBIMAGEARITHMETICGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibImageArithmeticGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibImageArithmeticGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibImageArithmeticGUI

% Last Modified by GUIDE v2.5 29-Sep-2019 14:48:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibImageArithmeticGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibImageArithmeticGUI_OutputFcn, ...
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

% --- Executes just before mibImageArithmeticGUI is made visible.
function mibImageArithmeticGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibImageArithmeticGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibImageArithmeticGUI
handles.output = hObject;

handles.infoText.String = sprintf('Enter an arithmetic expression. Images are referred as "I", models as "O", masks as "M", selection as "S". When letter is supplemented with a number, that number indicates MIB container from where the dataset should be taken (for example, I4 -> take image from container 4). If number is omitted, the currently selected container is used');
handles.examplesText.String = sprintf(...
    '"I = I * 2" - to multiply current image in 2 times\n"I2 = I2 + 50" - to increase image in container 2 by 50\n"I1 = I1 + I2" - to add image 2 to image 1\n"I1=I1-min(I1(:))" - shift image 1 by its minimum value\n"I1=I1+uint8(randi(20, size(I1)))" - add random noise\n"I1(M1==1) = 0" - replace masked area in the image 1 with 0');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibImageArithmeticGUI wait for user response (see UIRESUME)
% uiwait(handles.mibImageArithmeticGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibImageArithmeticGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibImageArithmeticGUI.
function mibImageArithmeticGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibImageArithmeticGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% % ----------------------------------------------------------------------
% Callbacks for buttons
% % ----------------------------------------------------------------------

% --- Executes on button press in helpBtn
function helpBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mibPath;
web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_image.html'), '-helpbrowser');
end

% --- Executes on button press in runExpressionBtn.
% start calculation of something
function runExpressionBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call a corresponding method of the controller class
handles.winController.runExpressionBtn_Callback();
end

% --- Executes on button press in closeBtn.
% close the plugin window
function closeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end


function updateBatchOpt(hObject, eventdata, handles)
% callback for multiple widgets of GUI to update BatchOpt
handles.winController.updateBatchOptFromGUI(hObject);
end

function Expression_Callback(hObject, eventdata, handles)
expression = handles.Expression.String;
expressionOut = [];
for lineId = 1:size(expression,1)
    expressionOut = sprintf('%s%s\n', expressionOut, strtrim(expression(lineId, :)));
end
expressionOut(end) = [];    % remove \n
handles.winController.BatchOpt.Expression = expressionOut;
end

% --- Executes on selection change in prevExpPopup.
function prevExpPopup_Callback(hObject, eventdata, handles)
handles.winController.prevExpPopup_Callback();
end

function varargout = MCcalcGUI(varargin)
% MCcalcGUI MATLAB code for MCcalcGUI.fig
%      MCcalcGUI, by itself, creates a new MCcalcGUI or raises the existing
%      singleton*.
%
%      H = MCcalcGUI returns the handle to a new MCcalcGUI or the handle to
%      the existing singleton*.
%
%      MCcalcGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MCcalcGUI.M with the given input arguments.
%
%      MCcalcGUI('Property','Value',...) creates a new MCcalcGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MCcalcGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MCcalcGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MCcalcGUI

% Last Modified by GUIDE v2.5 23-Jan-2019 17:14:18

% Begin initialization code - DO NOT EDIT


gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MCcalcGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MCcalcGUI_OutputFcn, ...
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

% --- Executes just before MCcalcGUI is made visible.
function MCcalcGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MCcalcGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for TripleAreaIntensityGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MCcalcGUI wait for user response (see UIRESUME)
% uiwait(handles.MCcalcGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = MCcalcGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close MCcalcGUI.
function MCcalcGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function probeDistanceEdit_Callback(hObject, eventdata, handles)
val = str2double(hObject.String);
defValue = NaN;
switch hObject.Tag
    case 'probeDistanceEdit'
        if val < 0
            defValue = '50';
            str = sprintf('!!! Error !!!\n\nthe number should be larger than 0');
        end
    case 'smoothEdit'
        if val < 0
            defValue = '3';
            str = sprintf('!!! Error !!!\n\nthe number can not be negative');
        end
    case 'showObjectEdit'
        if val < 1
            defValue = '1';
            str = sprintf('!!! Error !!!\n\nthe number should be larger than 0');
        end
end
if ~isnan(defValue)
    errordlg(str);
    hObject.String = defValue;
end
end


% --- Executes on button press in saveResultsCheck.
function saveResultsCheck_Callback(hObject, eventdata, handles)
val = hObject.Value;
if val==1
    handles.exportResultsFilename.Enable = 'on';
    handles.filenameEdit.Enable = 'on';
else
    handles.exportResultsFilename.Enable = 'off';
    handles.filenameEdit.Enable = 'off';
end
end

% --- Executes on button press in exportResultsFilename.
function exportResultsFilename_Callback(hObject, eventdata, handles)
formatText = {'*.xlsx', 'Microscoft Excel (*.xlsx)';...
              '*.mat',  'Matlab format (*.mat)'};
fn_out = handles.filenameEdit.String;
[FileName, PathName, FilterIndex] = ...
    uiputfile(formatText, 'Select filename', fn_out);
if isequal(FileName, 0) || isequal(PathName, 0); return; end
fn_out = fullfile(PathName, FileName);

handles.filenameEdit.String = fn_out;
handles.filenameEdit.TooltipString = fn_out;
end

% --- Executes on button press in resultsImagesCheck.
function resultsImagesCheck_Callback(hObject, eventdata, handles)
if hObject.Value == 1
    handles.resultImagesDirBtn.Enable = 'on';
    handles.resultImagesDirEdit.Enable = 'on';
    handles.outputResolutionEdit.Enable = 'on';
else
    handles.resultImagesDirBtn.Enable = 'off';
    handles.resultImagesDirEdit.Enable = 'off';
    handles.outputResolutionEdit.Enable = 'off';
end
end

% --- Executes on button press in resultImagesDirBtn.
function resultImagesDirBtn_Callback(hObject, eventdata, handles)
start_path = handles.resultImagesDirEdit.String;
folder_name = uigetdir(start_path, 'Select directory');
if folder_name(1)==0; return; end

handles.resultImagesDirEdit.String = folder_name;
handles.resultImagesDirEdit.TooltipString = folder_name;
end


% --- Executes on button press in calcPixelsCheck.
function calcPixelsCheck_Callback(hObject, eventdata, handles)
handles.winController.calcPixelsCheck_Callback();
end

% --- Executes on button press in exportMatlabCheck.
function exportMatlabCheck_Callback(hObject, eventdata, handles)
handles.winController.exportMatlabCheck_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'Plugins', 'Organelle Analysis', 'MCcalc', 'help/MCcalc_help.html'), '-helpbrowser');
end

% --- Executes on button press in detectContactsCheck.
function detectContactsCheck_Callback(hObject, eventdata, handles)
if handles.detectContactsCheck.Value
    handles.contactCutOffEdit.Enable = 'on';
    handles.contactGapWidthEdit.Enable = 'on';
else
    handles.contactCutOffEdit.Enable = 'off';
    handles.contactGapWidthEdit.Enable = 'off';
end
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end


% --- Executes on button press in extendRays.
function extendRays_Callback(hObject, eventdata, handles)
if handles.extendRays.Value == 1
    handles.extendRaysFactor.Enable = 'on';
else
    handles.extendRaysFactor.Enable = 'off';
end
end


function extendRaysFactor_Callback(hObject, eventdata, handles)
val = max([1 round(abs(str2double(handles.extendRaysFactor.String)))]);
handles.extendRaysFactor.String = num2str(val);
end

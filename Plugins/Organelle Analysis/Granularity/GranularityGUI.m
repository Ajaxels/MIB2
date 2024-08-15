% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function varargout = GranularityGUI(varargin)
% function varargout = GranularityGUI(varargin)
% GranularityGUI function is responsible for watershed operations.
%
% GranularityGUI contains MATLAB code for GranularityGUI.fig

% Updates
% 


% Edit the above text to modify the response to help GranularityGUI

% Last Modified by GUIDE v2.5 19-Feb-2018 17:33:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GranularityGUI_OpeningFcn, ...
    'gui_OutputFcn',  @GranularityGUI_OutputFcn, ...
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

% --- Executes just before GranularityGUI is made visible.
function GranularityGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GranularityGUI (see VARARGIN)

global mibPath;

% obtain controller
handles.winController = varargin{1};
%handles.GranularityGUI.Position = [389.25 594.0 256 471.75];

% define the current mode
handles.image2D.Value = 1;

% move the window
handles.GranularityGUI = moveWindowOutside(handles.GranularityGUI, 'left');

% Choose default command line output for mibChildGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GranularityGUI wait for user response (see UIRESUME)
% uiwait(handles.GranularityGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = GranularityGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes when user attempts to close GranularityGUI.
function GranularityGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in updateMaterialsBtn.
function updateMaterialsBtn_Callback(hObject, eventdata, handles)
handles.winController.updateMaterialsBtn_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'Plugins', 'EMU Tools', 'Granularity', 'Help', 'index.html'), '-helpbrowser');
end

% --- Executes on button press in timelapse2D.
function modeRadio_Callback(hObject, eventdata, handles)
handles.winController.modeRadio_Callback(hObject);
end

function subareaEdit_Callback(hObject, eventdata, handles)
handles.winController.updateSubarea(hObject);
end

% --- Executes on button press in resetDimsBtn.
function resetDimsBtn_Callback(hObject, eventdata, handles)
handles.winController.resetSubarea();
end

% --- Executes on button press in currentViewBtn.
function currentViewBtn_Callback(hObject, eventdata, handles)
handles.winController.currentViewBtn_Callback();
end

% --- Executes on button press in subAreaFromSelectionBtn.
function subAreaFromSelectionBtn_Callback(hObject, eventdata, handles)
handles.winController.subAreaFromSelectionBtn_Callback();
end

% --- Executes on button press in calculateBtn.
function calculateBtn_Callback(hObject, eventdata, handles)
handles.winController.calculateBtn_Callback();
end

function editboxes_Callback(hObject, eventdata, handles)
switch hObject.Tag
    case 'strelSizeEdit'
        res = editbox_Callback(hObject, 'pint', 2, [1 NaN], hObject);
    case 'strelSizeZEdit'
        res = editbox_Callback(hObject, 'pint', 1, [0 NaN], hObject);
    case 'strelRotationsEdit'
        res = editbox_Callback(hObject, 'pint', 10, [1 NaN], hObject);        
end
if res == 0; return; end
handles.winController.updateStrel_Callback();
end

function updateStrel_Callback(hObject, eventdata, handles)
handles.winController.updateStrel_Callback();
end


% --- Executes on button press in previewStrelBtn.
function previewStrelBtn_Callback(hObject, eventdata, handles)
handles.winController.previewStrelBtn_Callback();
end


% --- Executes on button press in exportFileCheck.
function exportFileCheck_Callback(hObject, eventdata, handles)
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
              '*.mat', 'Matlab format (*.mat)';};
fn_out = handles.filenameEdit.String;
[FileName, PathName, FilterIndex] = ...
    uiputfile(formatText, 'Select filename', fn_out);
if isequal(FileName, 0) || isequal(PathName, 0); return; end

fn_out = fullfile(PathName, FileName);
handles.filenameEdit.String = fn_out;
handles.filenameEdit.TooltipString = fn_out;
end


% --- Executes on button press in exportMatlabCheck.
function exportMatlabCheck_Callback(hObject, eventdata, handles)
handles.winController.exportMatlabCheck_Callback();
end

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

function varargout = mibWatershedGUI(varargin)
% function varargout = mibWatershedGUI(varargin)
% mibWatershedGUI function is responsible for watershed operations.
%
% mibWatershedGUI contains MATLAB code for mibWatershedGUI.fig

% Updates
% 06.11.2017, taken into a separate function


% Edit the above text to modify the response to help mibWatershedGUI

% Last Modified by GUIDE v2.5 09-Dec-2021 00:35:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibWatershedGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibWatershedGUI_OutputFcn, ...
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

% --- Executes just before mibWatershedGUI is made visible.
function mibWatershedGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibWatershedGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};
%handles.mibWatershedGUI.Position = [389.25 594.0 256 471.75];

% define the current mode
handles.mode2dCurrentRadio.Value = 1;

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibWatershedGUI wait for user response (see UIRESUME)
% uiwait(handles.mibWatershedGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibWatershedGUI_OutputFcn(hObject, eventdata, handles)
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

% --- Executes when user attempts to close mibWatershedGUI.
function mibWatershedGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in updateMaterialsBtn.
function updateMaterialsBtn_Callback(hObject, eventdata, handles)
handles.winController.updateMaterialsBtn_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_tools_watershed.html'), '-helpbrowser');
end

function aspectRatio_Callback(hObject, eventdata, handles)
handles.winController.aspectRatio_Callback();
end

% --- Executes on button press in clearPreprocessBtn.
function clearPreprocessBtn_Callback(hObject, eventdata, handles)
handles.winController.clearPreprocessBtn_Callback();
end

% --- Executes on button press in mode2dRadio.
function mode2dRadio_Callback(hObject, eventdata, handles)
handles.winController.mode2dRadio_Callback(hObject);
end

function eigenSigmaEdit_Callback(hObject, eventdata, handles)
handles.winController.eigenSigmaEdit_Callback();
end

function xSubareaEdit_Callback(hObject, eventdata, handles)
handles.winController.checkDimensions(hObject);
end

function ySubareaEdit_Callback(hObject, eventdata, handles)
handles.winController.checkDimensions(hObject);
end

function zSubareaEdit_Callback(hObject, eventdata, handles)
handles.winController.checkDimensions(hObject);
end

% --- Executes on button press in resetDimsBtn.
function resetDimsBtn_Callback(hObject, eventdata, handles)
handles.winController.resetDimsBtn_Callback();
end

% --- Executes on button press in currentViewBtn.
function currentViewBtn_Callback(hObject, eventdata, handles)
handles.winController.currentViewBtn_Callback();
end

% --- Executes on button press in subAreaFromSelectionBtn.
function subAreaFromSelectionBtn_Callback(hObject, eventdata, handles)
handles.winController.subAreaFromSelectionBtn_Callback();
end

function binSubareaEdit_Callback(hObject, eventdata, handles)
handles.winController.binSubareaEdit_Callback(hObject);
end

% --- Executes on button press in preprocessBtn.
function preprocessBtn_Callback(hObject, eventdata, handles)
handles.winController.preprocessBtn_Callback();
end

% --- Executes on button press in watershedBtn.
function watershedBtn_Callback(hObject, eventdata, handles)
handles.winController.watershedBtn_Callback();
end

% --- Executes on button press in importBtn.
function importBtn_Callback(hObject, eventdata, handles)
handles.winController.importBtn_Callback();
end


% --- Executes on key press with focus on mibWatershedGUI and none of its controls.
function mibWatershedGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibWatershedGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% call key press callback of MIB main window
% alternative solution is in
% mibMeasureToolController.mibMeasureToolController or 
% mibImageFiltersGUI.mlapp->FigureKeyPress
eventData = struct();
if isempty(eventdata.Character); return; end    % when only modifiers are pressed do not trigger the shortcuts
eventData.eventdata = eventdata;
eventData = ToggleEventData(eventData);
notify(handles.winController.mibModel, 'keyPressEvent', eventData);
end

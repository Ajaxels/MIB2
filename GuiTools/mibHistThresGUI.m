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

function varargout = mibHistThresGUI(varargin)
% function varargout = mibHistThresGUI(varargin)
% mibHistThresGUI function is responsible for morphological operations done with images.
%
% mibHistThresGUI contains MATLAB code for mibHistThresGUI.fig

% Updates
% 26.02.2016, IB, updated for 4D datasets


% Edit the above text to modify the response to help mibHistThresGUI

% Last Modified by GUIDE v2.5 09-Dec-2021 00:34:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibHistThresGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibHistThresGUI_OutputFcn, ...
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

% --- Executes just before mibHistThresGUI is made visible.
function mibHistThresGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibHistThresGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibChildGUI
handles.output = hObject;

currList = handles.Method.String;
handles.Method.String = sort(currList);

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibHistThresGUI wait for user response (see UIRESUME)
% uiwait(handles.mibHistThresGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibHistThresGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibHistThresGUI.
function mibHistThresGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibHistThresGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end


% --- Executes on selection change in Method.
function Method_Callback(hObject, eventdata, handles)
handles.winController.Method_Callback();
end

function autoPreviewCheck_Callback(hObject, eventdata, handles)
% use auto preview
if handles.autoPreviewCheck.Value == 1
    handles.winController.previewBtn_Callback();
end
end

% --- Executes on button press in previewBtn.
function previewBtn_Callback(hObject, eventdata, handles)
handles.winController.previewBtn_Callback();
end

function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end


% --- Executes on slider movement.
function foregroundSlider_Callback(hObject, eventdata, handles)
if strcmp(hObject.Tag, 'ForegroundFraction')    % edit box change
    val = str2double(hObject.String);
    if val > 1 || val < 0
        errordlg(sprintf('!!! Error !!!\n\nValue should be between 0 and 1'), 'Wrong value');
        return;
    end
    handles.foregroundSlider.Value = val;
else
    val = handles.foregroundSlider.Value;
    val = round(val*1000)/1000;
    handles.ForegroundFraction.String = num2str(val);
end
handles.winController.updateBatchOptFromGUI(handles.ForegroundFraction);
end

% --- Executes on selection change in Destination.
function updateBatchOpt(hObject, eventdata, handles)
if strcmp(hObject.Tag, 'ForegroundFraction')
    val = str2double(hObject.String);
    if val < 0; val = 0; end
    if val > 1; val = 1; end
    handles.foregroundSlider.Value = val;
    hObject.String = num2str(val);
end
handles.winController.updateBatchOptFromGUI(hObject);
end


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_tools_global_thresholding.html'), '-helpbrowser');
end


% --- Executes on key press with focus on mibHistThresGUI and none of its controls.
function mibHistThresGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibHistThresGUI (see GCBO)
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

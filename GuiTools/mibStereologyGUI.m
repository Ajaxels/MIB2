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

function varargout = mibStereologyGUI(varargin)
% MIBSTEREOLOGYGUI MATLAB code for mibstereologygui.fig
%      MIBSTEREOLOGYGUI, by itself, creates a new MIBSTEREOLOGYGUI or raises the existing
%      singleton*.
%
%      H = MIBSTEREOLOGYGUI returns the handle to a new MIBSTEREOLOGYGUI or the handle to
%      the existing singleton*.
%
%      MIBSTEREOLOGYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBSTEREOLOGYGUI.M with the given input arguments.
%
%      MIBSTEREOLOGYGUI('Property','Value',...) creates a new MIBSTEREOLOGYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibStereologyGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibStereologyGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Updates
%

% Last Modified by GUIDE v2.5 22-Sep-2025 15:28:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibStereologyGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibStereologyGUI_OutputFcn, ...
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

% --- Executes just before mibstereologygui is made visible.
function mibStereologyGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibstereologygui (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'right');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibstereologygui wait for user response (see UIRESUME)
% uiwait(handles.mibStereologyGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibStereologyGUI_OutputFcn(hObject, eventdata, handles) 
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

% --- Executes when user attempts to close mibStereologyGUI.
function mibStereologyGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in generateGrid.
function generateGrid_Callback(hObject, eventdata, handles)
handles.winController.generateGrid_Callback();
end

% --- Executes on button press in doStereologyBtn.
function doStereologyBtn_Callback(hObject, eventdata, handles)
handles.winController.doStereologyBtn_Callback();
end


% --- Executes on key press with focus on mibStereologyGUI and none of its controls.
function mibStereologyGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibStereologyGUI (see GCBO)
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


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)

global mibPath;
web(fullfile(mibPath, 'techdoc/html/user-interface/menu/tools/tools-stereology.html'), '-browser');

end

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

function varargout = SurfaceArea3DGUI(varargin)
% SURFACEAREA3DGUI MATLAB code for SurfaceArea3DGUI.fig
%      SURFACEAREA3DGUI, by itself, creates a new SURFACEAREA3DGUI or raises the existing
%      singleton*.
%
%      H = SURFACEAREA3DGUI returns the handle to a new SURFACEAREA3DGUI or the handle to
%      the existing singleton*.
%
%      SURFACEAREA3DGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SURFACEAREA3DGUI.M with the given input arguments.
%
%      SURFACEAREA3DGUI('Property','Value',...) creates a new SURFACEAREA3DGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SurfaceArea3DGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SurfaceArea3DGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SurfaceArea3DGUI

% Last Modified by GUIDE v2.5 13-Feb-2020 16:57:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SurfaceArea3DGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SurfaceArea3DGUI_OutputFcn, ...
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

% --- Executes just before SurfaceArea3DGUI is made visible.
function SurfaceArea3DGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SurfaceArea3DGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for TripleAreaIntensityGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SurfaceArea3DGUI wait for user response (see UIRESUME)
% uiwait(handles.SurfaceArea3DGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = SurfaceArea3DGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close SurfaceArea3DGUI.
function SurfaceArea3DGUI_CloseRequestFcn(hObject, eventdata, handles)
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
else
    handles.exportResultsFilename.Enable = 'off';
    handles.filenameEdit.Enable = 'off';
end
end

% --- Executes on button press in exportResultsFilename.
function exportResultsFilename_Callback(hObject, eventdata, handles)
formatText = {'*.csv', 'Comma-separated values (*.csv)';...
              '*.mat', 'Matlab format (*.mat)';              
              '*.xlsx', 'Microscoft Excel (*.xlsx)'};
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

% --- Executes on button press in exportMatlabCheck.
function exportMatlabCheck_Callback(hObject, eventdata, handles)
handles.winController.exportMatlabCheck_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/user-interface/plugins/organelle-analysis/surface-area-3d.html'), '-browser');
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end

function contactEditbox_Callback(hObject, eventdata, handles, par1, par2, par3)
res = editbox_Callback(hObject, par1, par2, par3);
if res == 0; return; end
end

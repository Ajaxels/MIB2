function varargout = mibObjSepGUI(varargin)
% function varargout = mibObjSepGUI(varargin)
% mibObjSepGUI function is responsible for watershed operations.
%
% mibObjSepGUI contains MATLAB code for mibObjSepGUI.fig

% Copyright (C) 13.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 05.11.2017, moved to a separate function


% Edit the above text to modify the response to help mibObjSepGUI

% Last Modified by GUIDE v2.5 05-Nov-2017 13:47:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibObjSepGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibObjSepGUI_OutputFcn, ...
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

% --- Executes just before mibObjSepGUI is made visible.
function mibObjSepGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibObjSepGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% radio button callbacks
handles.watershedSourcePanel.SelectionChangeFcn = @distanceRadio_Callback;
% define the current mode
handles.mode2dCurrentRadio.Value = 1;

handles.distanceRadio.Value = 1;

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibObjSepGUI wait for user response (see UIRESUME)
% uiwait(handles.mibObjSepGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibObjSepGUI_OutputFcn(hObject, eventdata, handles)
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

% --- Executes when user attempts to close mibObjSepGUI.
function mibObjSepGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in updateMaterialsBtn.
function updateMaterialsBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_tools_objseparation.html'), '-helpbrowser');
end

function aspectRatio_Callback(hObject, eventdata, handles)
handles.winController.aspectRatio_Callback();
end

% --- Executes on button press in mode2dRadio.
function mode2dRadio_Callback(hObject, eventdata, handles)
handles.winController.mode2dRadio_Callback(hObject);
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
% function binSubareaEdit_Callback(hObject, eventdata, handles)
% callback for selection of subarea for segmentation
%
% Parameters:
% hObject: handle to the object

val = str2num(hObject.String); %#ok<ST2NM>
if isempty(val)
    val = [1; 1];
elseif isnan(val(1)) || min(val) <= .5
    val = [1;1];
else
    val = round(val);
end

hObject.String = sprintf('%d; %d',val(1), val(2));
end

% --- Executes on button press in useSeedsCheck.
function useSeedsCheck_Callback(hObject, eventdata, handles)
val = handles.useSeedsCheck.Value;
if val == 1
    handles.seedsPanel.Visible = 'on';
    handles.reduiceOversegmCheck.Visible = 'off';
else
    handles.seedsPanel.Visible = 'off';
    handles.reduiceOversegmCheck.Visible = 'on';
end
end

% --- Executes on selection change in selectedMaterialPopup.
function selectedMaterialPopup_Callback(hObject, eventdata, handles)
handles.modelRadio.Value = 1;
end


% --- Executes on selection change in seedsSelectedMaterialPopup.
function seedsSelectedMaterialPopup_Callback(hObject, eventdata, handles)
handles.seedsModelRadio.Value = 1;
end

% --- Executes on button press in distanceRadio.
function distanceRadio_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
hObject = eventdata.NewValue;
tagId = hObject.Tag;
curVal = hObject.Value;
if curVal == 0 
    hObject.Value = 1; 
    return; 
end
handles.watSourceTxt1.Visible = 'off';
handles.watSourceTxt2.Visible = 'off';
handles.imageIntensityColorCh.Visible = 'off';
handles.imageIntensityInvert.Visible = 'off';

if strcmp(tagId, 'intensityRadio')
    handles.watSourceTxt1.Visible = 'on';
    handles.watSourceTxt2.Visible = 'on';
    handles.imageIntensityColorCh.Visible = 'on';
    handles.imageIntensityInvert.Visible = 'on';
end
end

% --- Executes on button press in separateBtn.
function separateBtn_Callback(hObject, eventdata, handles)
handles.winController.doObjectSeparation();
end

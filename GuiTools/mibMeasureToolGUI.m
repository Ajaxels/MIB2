function varargout = mibMeasureToolGUI(varargin)
% MIBMEASURETOOLGUI MATLAB code for mibMeasureToolGUI.fig
%      MIBMEASURETOOLGUI, by itself, creates a new MIBMEASURETOOLGUI or raises the existing
%      singleton*.
%
%      H = MIBMEASURETOOLGUI returns the handle to a new MIBMEASURETOOLGUI or the handle to
%      the existing singleton*.
%
%      MIBMEASURETOOLGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBMEASURETOOLGUI.M with the given input arguments.
%
%      MIBMEASURETOOLGUI('Property','Value',...) creates a new MIBMEASURETOOLGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibMeasureToolGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibMeasureToolGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibMeasureToolGUI

% Copyright (C) 12.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibMeasureToolGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibMeasureToolGUI_OutputFcn, ...
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


% --- Executes just before mibMeasureToolGUI is made visible.
function mibMeasureToolGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibMeasureToolGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

handles.measureTable_cm = uicontextmenu('Parent',handles.mibMeasureToolGUI);
uimenu(handles.measureTable_cm, 'Label', 'Jump to measurement...', 'Callback', {@measureTable_cm, 'Jump'});
uimenu(handles.measureTable_cm, 'Label', 'Modify measurement...', 'Callback', {@measureTable_cm, 'Modify'});
uimenu(handles.measureTable_cm, 'Label', 'Recalculate selected measurements...', 'Callback', {@measureTable_cm, 'Recalculate'});
uimenu(handles.measureTable_cm, 'Label', 'Duplicate measurement...', 'Callback', {@measureTable_cm, 'Duplicate'});
uimenu(handles.measureTable_cm, 'Label', 'Plot intensity profile...', 'Callback', {@measureTable_cm, 'Plot'});
uimenu(handles.measureTable_cm, 'Label', 'Delete measurement...', 'Callback', {@measureTable_cm, 'Delete'},'Separator','on');
handles.measureTable.UIContextMenu = handles.measureTable_cm;

% update font and size
global Font;
if ~isempty(Font)
    if handles.text1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibMeasureToolGUI, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibMeasureToolGUI);

% Choose default command line output for mibMeasureToolGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibMeasureToolGUI wait for user response (see UIRESUME)
% uiwait(handles.mibMeasureToolGUI);
end


% --- Outputs from this function are returned to the command line.
function varargout = mibMeasureToolGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close mibMeasureToolGUI.
function mibMeasureToolGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes when mibMeasureToolGUI is resized.
function mibMeasureToolGUI_ResizeFcn(hObject, eventdata, handles)
winPos = handles.mibMeasureToolGUI.Position;

measurePanelPos = handles.measurePanel.Position;
measurePanelPos(2) = winPos(4)-measurePanelPos(4);
measurePanelPos(3) = winPos(3)-6;
handles.measurePanel.Position = measurePanelPos;

plotPanelPos = handles.plotPanel.Position;
plotPanelPos(2) = winPos(4)-measurePanelPos(4)-plotPanelPos(4)-1;
plotPanelPos(3) = winPos(3)/2-6;
handles.plotPanel.Position = plotPanelPos;

voxelPanelPos = handles.voxelPanel.Position;
voxelPanelPos(2) = plotPanelPos(2);
voxelPanelPos(3) = plotPanelPos(3);
voxelPanelPos(1) = plotPanelPos(3)+9;
handles.voxelPanel.Position = voxelPanelPos;

buttonsPanelPos = handles.buttonsPanel.Position;
buttonsPanelPos(3) = winPos(3) - 7;
handles.buttonsPanel.Position = buttonsPanelPos;

resultsPanelPos = handles.resultsPanel.Position;
resultsPanelPos(3) = measurePanelPos(3);
resultsPanelPos(2) = buttonsPanelPos(2) + buttonsPanelPos(4);
resultsPanelPos(4) = winPos(4)-measurePanelPos(4)-plotPanelPos(4)-buttonsPanelPos(4)-5;
handles.resultsPanel.Position = resultsPanelPos;
end


function addBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in addBtn.
% add a new measurement
handles.winController.addBtn_Callback();
end

function measureTable_cm(hObject, eventdata, parameter)
% a context menu for measureTable
handles = guidata(hObject);
handles.winController.measureTable_cm(parameter);
end

function deleteAllBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in deleteAllBtn.
% delete all measurements
handles.winController.deleteAllBtn_Callback();
end

function measureTable_CellSelectionCallback(hObject, eventdata, handles)
% --- Executes when selected cell(s) is changed in measureTable.
handles.winController.measureTable_CellSelectionCallback(eventdata);
end

function updatePlotSettings(hObject, eventdata, handles)
% function updatePlotSettings(hObject, eventdata, handles)
% a callback for press of Markers, Lines, Text checkboxes
handles.winController.updatePlotSettings();
end


function optionsBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in optionsBtn.
handles.winController.optionsBtn_Callback();
end


function interpolationModePopup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in interpolationModePopup.
handles.winController.interpolationModePopup_Callback();
end

function measureTypePopup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in measureTypePopup.
typeString = handles.measureTypePopup.String;
handles.noPointsEdit.Enable = 'off';
handles.interpolationModePopup.Enable = 'off';
handles.integrateCheck.Enable = 'off';
handles.integrateCheck.Value = 0;
handles.previewIntensityCheck.Enable = 'off';

switch typeString{handles.measureTypePopup.Value}
    case 'Distance (linear)'
        handles.integrateCheck.Enable = 'on';
        handles.previewIntensityCheck.Enable = 'on';
    case 'Distance (polyline)'
        handles.noPointsEdit.Enable = 'on';
        handles.interpolationModePopup.Enable = 'on';
    case 'Distance (freehand)'        
        handles.interpolationModePopup.Enable = 'on';
end
integrateCheck_Callback(hObject, eventdata, handles);
end

% --- Executes on selection change in filterPopup.
function filterPopup_Callback(hObject, eventdata, handles)
handles.winController.updateTable();
end

% --- Executes on button press in loadBtn.
function loadBtn_Callback(hObject, eventdata, handles)
handles.winController.loadBtn_Callback();
end

% --- Executes on button press in saveBtn.
function saveBtn_Callback(hObject, eventdata, handles)
handles.winController.saveBtn_Callback();
end

% --- Executes on button press in refreshTableBtn.
function refreshTableBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_tools_measure.html'), '-helpbrowser');
end


% --- Executes on button press in updateVoxelsButton.
function updateVoxelsButton_Callback(hObject, eventdata, handles)
handles.winController.updateVoxelsButton_Callback();
end


% --- Executes on button press in integrateCheck.
function integrateCheck_Callback(hObject, eventdata, handles)
val = handles.integrateCheck.Value;
if val == 1
    handles.text2.String = 'Width, px:';
    handles.text2.TooltipString = 'define width for image intensity profile integration';
    handles.noPointsEdit.Enable = 'on';
else
    handles.text2.String = 'Number of points:';
    handles.text2.TooltipString = 'define number of points for polyline';
    if ~strcmp(handles.measureTypePopup.String{handles.measureTypePopup.Value}, 'Distance (polyline)')
        handles.noPointsEdit.Enable = 'off';
    end
end

end

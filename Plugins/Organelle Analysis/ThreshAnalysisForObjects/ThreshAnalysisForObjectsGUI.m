function varargout = ThreshAnalysisForObjectsGUI(varargin)
% THRESHANALYSISFOROBJECTSGUI MATLAB code for ThreshAnalysisForObjectsGUI.fig
%      THRESHANALYSISFOROBJECTSGUI, by itself, creates a new THRESHANALYSISFOROBJECTSGUI or raises the existing
%      singleton*.
%
%      H = THRESHANALYSISFOROBJECTSGUI returns the handle to a new THRESHANALYSISFOROBJECTSGUI or the handle to
%      the existing singleton*.
%
%      THRESHANALYSISFOROBJECTSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in THRESHANALYSISFOROBJECTSGUI.M with the given input arguments.
%
%      THRESHANALYSISFOROBJECTSGUI('Property','Value',...) creates a new THRESHANALYSISFOROBJECTSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ThreshAnalysisForObjectsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ThreshAnalysisForObjectsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 02.07.2015 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% Last Modified by GUIDE v2.5 25-Apr-2019 13:57:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ThreshAnalysisForObjectsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ThreshAnalysisForObjectsGUI_OutputFcn, ...
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

% --- Executes just before ThreshAnalysisForObjectsGUI is made visible.
function ThreshAnalysisForObjectsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ThreshAnalysisForObjectsGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for ThreshAnalysisForObjectsGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ThreshAnalysisForObjectsGUI wait for user response (see UIRESUME)
% uiwait(handles.ThreshAnalysisForObjectsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = ThreshAnalysisForObjectsGUI_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close ThreshAnalysisForObjectsGUI.
function ThreshAnalysisForObjectsGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end


function thresholdEdit_Callback(hObject, eventdata, handles, value)
% define thresholding value
val = str2double(hObject.String);
if val < 0
    errordlg(sprintf('!!! Error !!!\n\nThe threshold value should be a positive integer!'), 'Wrong number');
    hObject.String = value;
end
end

% --- Executes on button press in exportExcelCheck.
function exportExcelCheck_Callback(hObject, eventdata, handles)
val1 = handles.exportExcelCheck.Value;
val2 = handles.exportMatlabFileCheck.Value;
if val1+val2 > 0
    handles.filenameEdit.Enable = 'on';
    handles.selectFilenameBtn.Enable = 'on';
else
    handles.filenameEdit.Enable = 'off';
    handles.selectFilenameBtn.Enable = 'off';
end
end


% --- Executes on button press in selectFilenameBtn.
function selectFilenameBtn_Callback(hObject, eventdata, handles)
formatText = {'*.xls', 'Microscoft Excel (*.xls)';
              '*.mat', 'Matlab Format (*.mat)'};
fn_out = handles.filenameEdit.String;

[FileName, PathName, FilterIndex] = ...
    uiputfile(formatText, 'Select filename', fn_out);
if isequal(FileName,0) || isequal(PathName,0); return; end

fn_out = fullfile(PathName, FileName);
handles.filenameEdit.String = fn_out;
handles.filenameEdit.TooltipString = fn_out;
end

% --- Executes on button press in startBtn.
function startBtn_Callback(hObject, eventdata, handles)
handles.winController.startBtn_Callback();
end


% --- Executes on button press in makePlotCheck.
function makePlotCheck_Callback(hObject, eventdata, handles)
if hObject.Value == 1
    handles.figureId.Enable = 'on';
else
    handles.figureId.Enable = 'off';
end
end


% --- Executes on button press in triangulateCentroidsCheck.
function triangulateCentroidsCheck_Callback(hObject, eventdata, handles)
if hObject.Value
    handles.removeFreeBoundaryCheck.Enable = 'on';
    handles.saveTriangulation.Enable = 'on';
else
    handles.removeFreeBoundaryCheck.Enable = 'off';
    handles.saveTriangulation.Enable = 'off';
    handles.saveTriangulation.Value = false;
end
end

% --- Executes on button press in saveTriangulation.
function saveTriangulation_Callback(hObject, eventdata, handles)
if hObject.Value
    handles.winController.defineTriangulationOutputFormat();
    handles.filenameEdit.Enable = 'on';
    handles.selectFilenameBtn.Enable = 'on';
else
    if handles.exportExcelCheck.Value + handles.exportMatlabFileCheck.Value == 0
        handles.filenameEdit.Enable = 'off';
        handles.selectFilenameBtn.Enable = 'off';
    end
end
end


% --- Executes on button press in minDiameterCheck.
function minDiameterCheck_Callback(hObject, eventdata, handles)
if hObject.Value
    handles.highlightMinDiamterCheck.Enable = 'on';
else
    handles.highlightMinDiamterCheck.Enable = 'off';
    handles.highlightMinDiamterCheck.Value = false;
end
end


% --- Executes on button press in regenerateOutputPath.
function regenerateOutputPath_Callback(hObject, eventdata, handles)
handles.winController.generateOutputFilename();
end


% --- Executes on selection change in thresholdPolicyPopup.
function thresholdPolicyPopup_Callback(hObject, eventdata, handles)
if handles.thresholdPolicyPopup.Value == 1
    handles.relativeThresholdMethodPopup.Enable = 'off';
    handles.thresholdValueText.String = 'Threshold value:';
    handles.thresholdOffsetEdit.Enable = 'off';
    handles.thresholdEdit.Enable = 'on';
else
    handles.relativeThresholdMethodPopup.Enable = 'on';
    handles.thresholdValueText.String = 'Offset value:';
    handles.thresholdOffsetEdit.Enable = 'on';
    handles.thresholdEdit.Enable = 'off';
end
end

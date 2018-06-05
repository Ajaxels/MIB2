function varargout = TripleAreaIntensityGUI(varargin)
% TRIPLEAREAINTENSITYGUI MATLAB code for TripleAreaIntensityGUI.fig
%      TRIPLEAREAINTENSITYGUI, by itself, creates a new TRIPLEAREAINTENSITYGUI or raises the existing
%      singleton*.
%
%      H = TRIPLEAREAINTENSITYGUI returns the handle to a new TRIPLEAREAINTENSITYGUI or the handle to
%      the existing singleton*.
%
%      TRIPLEAREAINTENSITYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRIPLEAREAINTENSITYGUI.M with the given input arguments.
%
%      TRIPLEAREAINTENSITYGUI('Property','Value',...) creates a new TRIPLEAREAINTENSITYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TripleAreaIntensityGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TripleAreaIntensityGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 30.04.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% Edit the above text to modify the response to help TripleAreaIntensityGUI

% Last Modified by GUIDE v2.5 21-Dec-2017 15:15:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TripleAreaIntensityGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @TripleAreaIntensityGUI_OutputFcn, ...
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

% --- Executes just before TripleAreaIntensityGUI is made visible.
function TripleAreaIntensityGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TripleAreaIntensityGUI (see VARARGIN)

% Written by Ilya Belevich, 16.03.2014
% ilya.belevich @ helsinki.fi

% obtain controller
handles.winController = varargin{1};

strText = sprintf('Calculate image intensities of two materials of the opened model.\nSee details in the Help section.');
handles.helpText.String = strText;

% Choose default command line output for TripleAreaIntensityGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TripleAreaIntensityGUI wait for user response (see UIRESUME)
% uiwait(handles.TripleAreaIntensityGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = TripleAreaIntensityGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close TripleAreaIntensityGUI.
function TripleAreaIntensityGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function filenameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to filenameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filenameEdit as text
%        str2double(get(hObject,'String')) returns contents of filenameEdit as a double
end

% --- Executes on button press in selectFilenameBtn.
function selectFilenameBtn_Callback(hObject, eventdata, handles)
formatText = {'*.xls', 'Microscoft Excel (*.xls)'};
fn_out = handles.filenameEdit.String;
[FileName,PathName,FilterIndex] = ...
    uiputfile(formatText, 'Select filename', fn_out);
if isequal(FileName,0) || isequal(PathName,0); return; end;

fn_out = fullfile(PathName, FileName);
handles.filenameEdit.String = fn_out;
handles.filenameEdit.TooltipString = fn_out;
end


% --- Executes on button press in savetoExcel.
function savetoExcel_Callback(hObject, eventdata, handles)
val = handles.savetoExcel.Value;
if val==1
    handles.filenameEdit.Enable = 'on';
    handles.selectFilenameBtn.Enable = 'on';
else
    handles.filenameEdit.Enable = 'off';
    handles.selectFilenameBtn.Enable = 'off';
end
end


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
if isdeployed
     web(fullfile(fileparts(mfilename('fullpath')), 'html/TripleAreaIntensity_help.html'), '-helpbrowser');
else
    %path = fileparts(which('mib'));
    %web(fullfile(path, 'techdoc/html/ug_panel_bg_removal.html'), '-helpbrowser');
    web(fullfile(fileparts(mfilename('fullpath')), 'html/TripleAreaIntensity_help.html'), '-helpbrowser');
end

end

% --- Executes on button press in calculateRatioCheck.
function calculateRatioCheck_Callback(hObject, eventdata, handles)
% hObject    handle to calculateRatioCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of calculateRatioCheck
end

% --- Executes on button press in backgroundCheck.
function backgroundCheck_Callback(hObject, eventdata, handles)
val = handles.backgroundCheck.Value;
if val == 1
    handles.backgroundPopup.Enable = 'on';
    handles.subtractBackgroundCheck.Enable = 'on';
    handles.additionalThresholdingCheck.Enable = 'on';
else
    handles.backgroundPopup.Enable = 'off';
    handles.subtractBackgroundCheck.Enable = 'off';
    handles.additionalThresholdingCheck.Enable = 'off';
    handles.additionalThresholdingCheck.Value = 0;
end
additionalThresholdingCheck_Callback(handles.additionalThresholdingCheck, eventdata, handles);
end


% --- Executes on button press in additionalThresholdingCheck.
function additionalThresholdingCheck_Callback(hObject, eventdata, handles)
val = handles.additionalThresholdingCheck.Value;
if val == 1
    handles.thresholdingPopup.Enable = 'on';
    handles.thresholdEdit.Enable = 'on';
else
    handles.thresholdingPopup.Enable = 'off';
    handles.thresholdEdit.Enable = 'off';
end
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end

% --- Executes on button press in exportMatlabCheck.
function exportMatlabCheck_Callback(hObject, eventdata, handles)
handles.winController.exportMatlabCheck_Callback();
end

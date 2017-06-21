function varargout = mibMembraneDetectionGUI(varargin)
% function varargout = mibMembraneDetectionGUI(varargin)
% mibMembraneDetectionGUI function uses random forest classifier for segmentation.
% The function utilize Random Forest for Membrane Detection functions by Verena Kaynig
% see more http://www.kaynig.de/demos.html
%
% mibMembraneDetectionGUI contains MATLAB code for mibMembraneDetectionGUI.fig

% Copyright (C) 21.08.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @mibMembraneDetectionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibMembraneDetectionGUI_OutputFcn, ...
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

% --- Executes just before mibMembraneDetectionGUI is made visible.
function mibMembraneDetectionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibMembraneDetectionGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibChildGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibMembraneDetectionGUI wait for user response (see UIRESUME)
% uiwait(handles.mibMembraneDetectionGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibMembraneDetectionGUI_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibMembraneDetectionGUI.
function mibMembraneDetectionGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibMembraneDetectionGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

function tempDirEdit_Callback(hObject, eventdata, handles)
handles.winController.tempDirEdit_Callback();
end

% --- Executes on button press in tempDirSelectBtn.
function tempDirSelectBtn_Callback(hObject, eventdata, handles)
handles.winController.tempDirSelectBtn_Callback();
end

function classifierFilenameEdit_Callback(hObject, eventdata, handles)
handles.winController.classifierFilenameEdit_Callback();
end

% --- Executes on button press in classifierFilenameBtn.
function classifierFilenameBtn_Callback(hObject, eventdata, handles)
handles.winController.classifierFilenameBtn_Callback();
end

% --- Executes on button press in wipeTempDirBtn.
function wipeTempDirBtn_Callback(hObject, eventdata, handles)
handles.winController.wipeTempDirBtn_Callback();
end

% --- Executes on button press in trainClassifierBtn.
function trainClassifierBtn_Callback(hObject, eventdata, handles)
handles.winController.trainClassifierBtn_Callback();
end

% --- Executes on button press in predictSlice.
function predictSlice_Callback(hObject, eventdata, handles)
handles.winController.predictSlice_Callback();
end

% --- Executes on button press in saveClassifierBtn.
function saveClassifierBtn_Callback(hObject, eventdata, handles)
handles.winController.saveClassifierBtn_Callback();
end

% --- Executes on button press in trainClassifierToggle.
function trainClassifierToggle_Callback(hObject, eventdata, handles)
% hObject    handle to trainClassifierToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of trainClassifierToggle
btnTag = hObject.Tag;
switch btnTag
    case 'trainClassifierToggle'
        handles.objectText.Enable = 'on';
        handles.backgroundText.Enable = 'on';
        handles.objectPopup.Enable = 'on';
        handles.backgroundPopup.Enable = 'on';
        handles.membrThickText.Enable = 'on';
        handles.membraneThicknessEdit.Enable = 'on';
        handles.contextSizeEdit.Enable = 'on';
        handles.contextSizeText.Enable = 'on';   
        handles.trainClassifierBtn.String = 'Train classifier';
        handles.predictSlice.Visible = 'off';   
    case 'predictDatasetToggle'
        handles.objectText.Enable = 'off';
        handles.backgroundText.Enable = 'off';
        handles.objectPopup.Enable = 'off';
        handles.backgroundPopup.Enable = 'off';
        handles.membrThickText.Enable = 'off';
        handles.membraneThicknessEdit.Enable = 'off';
        handles.contextSizeEdit.Enable = 'off';
        handles.contextSizeText.Enable = 'off';
        handles.trainClassifierBtn.String = 'Predict dataset';
        handles.predictSlice.Visible = 'on';
end
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_tools_random_forest.html'), '-helpbrowser');
end


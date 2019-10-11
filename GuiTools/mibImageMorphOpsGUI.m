function varargout = mibImageMorphOpsGUI(varargin)
% function varargout = mibImageMorphOpsGUI(varargin)
% mibImageMorphOpsGUI function is responsible for morphological operations done with images.
%
% mibImageMorphOpsGUI contains MATLAB code for mibImageMorphOpsGUI.fig

% Copyright (C) 30.10.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.02.2016, IB, updated for 4D datasets


% Edit the above text to modify the response to help mibImageMorphOpsGUI

% Last Modified by GUIDE v2.5 29-May-2019 13:29:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibImageMorphOpsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibImageMorphOpsGUI_OutputFcn, ...
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

% --- Executes just before mibImageMorphOpsGUI is made visible.
function mibImageMorphOpsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibImageMorphOpsGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% define radio buttons callbacks
%set(handles.Connectivity, 'SelectionChangeFcn', @connectivityPanel_Callback);
%set(handles.ActionToResult, 'SelectionChangeFcn', @actionPanel_Callback);
handles.Connectivity.SelectionChangeFcn = @connectivityPanel_Callback;
handles.ActionToResult.SelectionChangeFcn = @actionPanel_Callback;

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibImageMorphOpsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibImageMorphOpsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibImageMorphOpsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibImageMorphOpsGUI.
function mibImageMorphOpsGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibImageMorphOpsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end


% --- Executes on selection change in MorphOperation.
function MorphOperation_Callback(hObject, eventdata, handles)
handles.winController.updateBatchOptFromGUI(hObject);
handles.winController.MorphOperation_Callback();
end

function modePanel_Callback(hObject, eventdata, handles)
handles.winController.modePanel_Callback();
end

function connectivityPanel_Callback(hObject, eventdata)
handles = guidata(hObject);
handles.winController.updateBatchOptFromGUI(hObject);
% use auto preview
if handles.autoPreviewCheck.Value == 1
    handles.winController.previewBtn_Callback();
end
end

function actionPanel_Callback(hObject, eventdata)
handles = guidata(hObject);
handles.winController.updateBatchOptFromGUI(hObject);
% use auto preview
if handles.autoPreviewCheck.Value == 1
    handles.winController.previewBtn_Callback();
end
end

function SmoothHSize_Callback(hObject, eventdata, handles)
val = str2double(handles.SmoothHSize.String);
handles.SmoothSigma.String = num2str(val/5);
handles.winController.updateBatchOptFromGUI(hObject);
handles.winController.updateBatchOptFromGUI(handles.SmoothSigma);
% use auto preview
if handles.autoPreviewCheck.Value == 1
    handles.winController.previewBtn_Callback();
end
end

% --- Executes on selection change in ColorChannel.
function widgets_Callback(hObject, eventdata, handles)
% use auto preview
if ~strcmp(hObject.Tag, 'autoPreviewCheck')
    handles.winController.updateBatchOptFromGUI(hObject);
end
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

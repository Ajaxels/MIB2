function varargout = mibResampleGUI(varargin)
% function varargout = mibResampleGUI(varargin)
% mibResampleGUI function is responsible for resampling of datasets.
%
% mibResampleGUI contains MATLAB code for mibResampleGUI.fig

% Copyright (C) 03.05.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 04.02.2016, IB, updated for 4D datasets
% 25.04.2016, IB, added tformarray method

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibResampleGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibResampleGUI_OutputFcn, ...
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

% --- Executes just before mibResampleGUI is made visible.
function mibResampleGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibResampleGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.text1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibResampleGUI, Font);
    end
end
% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibResampleGUI);

% Choose default command line output for mibSnapshotGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibResampleGUI wait for user response (see UIRESUME)
% uiwait(handles.mibResampleGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibResampleGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibResampleGUI.
function mibResampleGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in resampleBtn.
function resampleBtn_Callback(hObject, eventdata, handles)
handles.winController.resampleBtn_Callback();
end

function editbox_Callback(hObject, eventdata, handles)
handles.winController.editbox_Callback(hObject);
end

function radio_Callback(hObject, eventdata, handles)
if hObject.Value == 0
    hObject.Value = 1;
    return;
end;
handles.voxX.Enable = 'off';
handles.voxY.Enable = 'off';
handles.voxZ.Enable = 'off';
handles.dimX.Enable = 'off';
handles.dimY.Enable = 'off';
handles.dimZ.Enable = 'off';
handles.percEdit.Enable = 'off';

if handles.dimensionsRadio.Value
    handles.dimX.Enable = 'on';
    handles.dimY.Enable = 'on';
    handles.dimZ.Enable = 'on';
    uicontrol(handles.dimX);
elseif handles.voxelsRadio.Value
    handles.voxX.Enable = 'on';
    handles.voxY.Enable = 'on';
    handles.voxZ.Enable = 'on';
    uicontrol(handles.voxX);
else
    handles.percEdit.Enable = 'on';
    uicontrol(handles.percEdit);
end
end


% --- Executes on button press in resetBtn.
function resetBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end


% --- Executes on selection change in resamplingFunction.
function resamplingFunction_Callback(hObject, eventdata, handles)
val = handles.resamplingFunction.Value;
if val == 1     % interpn
    methods = {'nearest', 'linear', 'spline', 'cubic'};
    methodsModel = {'nearest', 'linear', 'spline', 'cubic'};
elseif val == 2     % imresize
    methods = {'nearest', 'box', 'triangle', 'cubic', 'lanczos2', 'lanczos3'};
    methodsModel = {'nearest'};
else
    methods = {'nearest', 'linear', 'cubic'};
    methodsModel = {'nearest', 'linear', 'cubic'};
end
if handles.imageMethod.Value > numel(methods); handles.imageMethod.Value = 1; end;
if handles.modelsMethod.Value > numel(methodsModel); handles.modelsMethod.Value = 1; end;
handles.imageMethod.String = methods;
handles.modelsMethod.String = methodsModel;
end

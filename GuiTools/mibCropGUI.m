function varargout = mibCropGUI(varargin)
% function varargout = mibCropGUI(varargin)
% mibCropGUI function is responsible for the crop of dataset.
%
% mibCropGUI contains MATLAB code for mibCropGUI.fig

% Copyright (C) 31.01.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 18.01.2016, IB, changed .slices() to .slices{:}; .slicesColor->.slices{3}
% 25.01.2016, IB, updated to 5D


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibCropGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibCropGUI_OutputFcn, ...
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

% --- Executes just before mibCropGUI is made visible.
function mibCropGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibCropGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.text2.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text2.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibCropGUI, Font);
    end
end
% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibCropGUI);

% Choose default command line output for mibSnapshotGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibCropGUI wait for user response (see UIRESUME)
% uiwait(handles.mibCropGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibCropGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibCropGUI.
function mibCropGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibCropGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in cropBtn.
function cropBtn_Callback(hObject, eventdata, handles)
handles.winController.cropBtn_Callback(hObject);
end

% --- Executes on button press in croptoBtn.
function cropToBtn_Callback(hObject, eventdata, handles)
handles.winController.cropToBtn_Callback();
end

function radio_Callback(hObject, eventdata, handles)
hObject.Value = 1;
handles.winController.radio_Callback(hObject);
end

% --- Executes on selection change in SelectROI.
function SelectROI_Callback(hObject, eventdata, handles)
handles.winController.SelectROI_Callback();
end

% --- Executes on button press in resetBtn.
function resetBtn_Callback(hObject, eventdata, handles)
handles.winController.resetBtn_Callback();
end

function editboxes_Callback(hObject, eventdata, handles)
handles.Manual.Value = 1;
handles.winController.editboxes_Callback();
handles.winController.updateBatchOptFromGUI(hObject);
end

function varargout = mibImageSelectFrameGUI(varargin)
% function varargout = mibImageSelectFrameGUI(varargin)
% mibImageSelectFrameGUI function is responsible for morphological operations done with images.
%
% mibImageSelectFrameGUI contains MATLAB code for mibImageSelectFrameGUI.fig

% Copyright (C) 30.10.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.02.2016, IB, updated for 4D datasets


% Edit the above text to modify the response to help mibImageSelectFrameGUI

% Last Modified by GUIDE v2.5 03-May-2018 17:09:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibImageSelectFrameGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibImageSelectFrameGUI_OutputFcn, ...
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

% --- Executes just before mibImageSelectFrameGUI is made visible.
function mibImageSelectFrameGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibImageSelectFrameGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibImageSelectFrameGUI wait for user response (see UIRESUME)
% uiwait(handles.mibImageSelectFrameGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibImageSelectFrameGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibImageSelectFrameGUI.
function mibImageSelectFrameGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibImageSelectFrameGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes when selected object is changed in destinationRadioGroup.
function destinationRadioGroup_SelectionChangedFcn(hObject, eventdata, handles)
switch hObject.String
    case {'Selection', 'Mask'}
        handles.intensityOutEdit.Enable = 'off';
    case 'Image'
        handles.intensityOutEdit.Enable = 'on';
end
end

function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end

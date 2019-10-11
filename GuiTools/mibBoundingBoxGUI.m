function varargout = mibBoundingBoxGUI(varargin)
% function output = mibBoundingBoxGUI(NaN, dlgText, dlgTitle, defAnswer)
% custom input dialog
%
%
% Parameters:
% NaN:  just use NaN here
% dlgText:  dialog test, a string
% dlgTitle: dialog title, a string
% defAnswer:    default answer, a string
%
% Return values:
% output: a cell with the entered value, or an empty cell, when cancelled

%| 
% @b Examples:
% @code 
% answer = mibBoundingBoxGUI(NaN,'Please enter a number in the edit box below','Test title','123');
% if size(answer) == 0; return; end; 
% @endcode

% Copyright (C) 04.03.2015, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @mibBoundingBoxGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibBoundingBoxGUI_OutputFcn, ...
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

% --- Executes just before mibBoundingBoxGUI is made visible.
function mibBoundingBoxGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibBoundingBoxGUI (see VARARGIN)

global mibPath;

% obtain controller
handles.winController = varargin{1};

% add icon
[IconData, IconCMap] = imread(fullfile(mibPath, 'Resources','mib_quest.gif'));
Img = image(IconData, 'Parent', handles.axes1);
IconCMap(IconData(1,1)+1,:) = handles.mibBoundingBoxGUI.Color;   % replace background color
handles.mibBoundingBoxGUI.Colormap = IconCMap;

set(handles.axes1, ...
    'Visible', 'off', ...
    'YDir'   , 'reverse'       , ...
    'XLim'   , get(Img,'XData'), ...
    'YLim'   , get(Img,'YData')  ...
    );

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% update WindowKeyPressFcn
handles.mibBoundingBoxGUI.WindowKeyPressFcn = {@mibBoundingBoxGUI_KeyPressFcn, handles};

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibBoundingBoxGUI wait for user response (see UIRESUME)
% uiwait(handles.mibBoundingBoxGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibBoundingBoxGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibBoundingBoxGUI.
function mibBoundingBoxGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibBoundingBoxGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on key press over mibBoundingBoxGUI with no controls selected.
function mibBoundingBoxGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibBoundingBoxGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%if nargin < 3;    handles = guidata(hObject); end;
handles = guidata(hObject);

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    cancelBtn_Callback(hObject, eventdata, handles);
elseif isequal(get(hObject,'CurrentKey'),'return')
    %okBtn_Callback(hObject, eventdata, handles);
end    
end

% --- Executes on button press in importBtn.
function importBtn_Callback(hObject, eventdata, handles)
handles.winController.importBtn_Callback();
end


% --- Executes on button press in okBtn.
function okBtn_Callback(hObject, eventdata, handles)
handles.winController.okBtn_Callback();
end

function editboxes_Callback(hObject, eventdata, handles)
% update BatchOpt structure in the controller
handles.winController.updateBatchOptFromGUI(hObject);
end

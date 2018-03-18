function varargout = mibImportOmeroGUI(varargin)
% function varargout = mibImportOmeroGUI(varargin)
% mibImportOmeroGUI function is responsible for a dialog to advanced opening images from OMERO servers.
%
% mibImportOmeroGUI contains MATLAB code for mibImportOmeroGUI.fig

% Last Modified by GUIDE v2.5 06-Mar-2017 15:57:42

% Copyright (C) 21.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @mibImportOmeroGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibImportOmeroGUI_OutputFcn, ...
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

% --- Executes just before mibImportOmeroGUI is made visible.
function mibImportOmeroGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibImportOmeroGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibExternalDirsGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
% set(handles.mibImportOmeroGUI,'WindowStyle','modal');

% UIWAIT makes mibImportOmeroGUI wait for user response (see UIRESUME)
% uiwait(handles.mibImportOmeroGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibImportOmeroGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
if isfield(handles, 'client')
    handles.client.closeSession();
end

handles.winController.closeWindow();
end


% --- Executes when user attempts to close mibImportOmeroGUI.
function mibImportOmeroGUI_CloseRequestFcn(hObject, eventdata, handles)
if isfield(handles, 'client')
    handles.client.closeSession();
end

handles.winController.closeWindow();
end

% --- Executes when selected cell(s) is changed in projectTable.
function projectTable_CellSelectionCallback(hObject, eventdata, handles)
handles.winController.projectTable_CellSelectionCallback(eventdata);
end

% --- Executes when selected cell(s) is changed in datasetTable.
function datasetTable_CellSelectionCallback(hObject, eventdata, handles)
handles.winController.datasetTable_CellSelectionCallback(eventdata);
end

% --- Executes when selected cell(s) is changed in imageTable.
function imageTable_CellSelectionCallback(hObject, eventdata, handles)
handles.winController.imageTable_CellSelectionCallback(eventdata);
end

% --- Executes on button press in omeroLoginBtn.
function omeroLoginBtn_Callback(hObject, eventdata, handles)
handles.winController.omeroLoginBtn_Callback();
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end
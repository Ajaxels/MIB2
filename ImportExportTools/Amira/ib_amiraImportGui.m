function varargout = ib_amiraImportGui(varargin)
% function varargout = ib_amiraImportGui(varargin)
% ib_amiraImportGui function is responsible for a dialog to advanced opening of Amira Mesh files.
%
% ib_amiraImportGui contains MATLAB code for ib_amiraImportGui.fig

% Copyright (C) 31.01.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @ib_amiraImportGui_OpeningFcn, ...
                   'gui_OutputFcn',  @ib_amiraImportGui_OutputFcn, ...
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

% --- Executes just before ib_amiraImportGui is made visible.
function ib_amiraImportGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ib_amiraImportGui (see VARARGIN)

handles.dim_xyczt = varargin{1};     % xyczt - dimensions of the Amira Mesh dataset

% Choose default command line output for ib_amiraImportGui
handles.output = NaN;

textString = sprintf('%d x %d x %d', handles.dim_xyczt(1),handles.dim_xyczt(2),handles.dim_xyczt(4));
set(handles.datasetDimensionsText, 'string', textString);
set(handles.endEdit,'string', num2str(handles.dim_xyczt(4)));

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.ib_amiraImportGui);

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
set(handles.ib_amiraImportGui,'WindowStyle','modal');

% UIWAIT makes ib_amiraImportGui wait for user response (see UIRESUME)
uiwait(handles.ib_amiraImportGui);
end

% --- Outputs from this function are returned to the command line.
function varargout = ib_amiraImportGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isstruct(handles)
    varargout{1} = handles.output;
    % The figure can be deleted now
    delete(handles.ib_amiraImportGui);
else
    varargout{1} = NaN;
end
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.output = NaN;
% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.ib_amiraImportGui);
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
result.startIndex = str2double(get(handles.startEdit,'string'));
result.endIndex = str2double(get(handles.endEdit,'string'));
result.zstep = str2double(get(handles.zStepEdit,'string'));
result.xystep = str2double(get(handles.binXYEdit,'string'));
methodList = get(handles.resizePopup,'string');
result.method = methodList{get(handles.resizePopup,'value')};

handles.output = result;

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.ib_amiraImportGui);
end

function zStepEdit_Callback(hObject, eventdata, handles)
val = get(hObject, 'string');
set(handles.binZEdit,'string', val);
set(handles.zStepEdit,'string', val);
end


% --- Executes on key press with focus on ib_amiraImportGui and none of its controls.
function ib_amiraImportGui_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ib_amiraImportGui (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = NaN;
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.ib_amiraImportGui);
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    continueBtn_Callback(hObject, eventdata, handles);
end

end

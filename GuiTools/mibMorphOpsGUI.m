function varargout = mibMorphOpsGUI(varargin)
% MIBMORPHOPSGUI MATLAB code for mibMorphOpsGUI.fig
%      MIBMORPHOPSGUI, by itself, creates a new MIBMORPHOPSGUI or raises the existing
%      singleton*.
%
%      H = MIBMORPHOPSGUI returns the handle to a new MIBMORPHOPSGUI or the handle to
%      the existing singleton*.
%
%      MIBMORPHOPSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBMORPHOPSGUI.M with the given input arguments.
%
%      MIBMORPHOPSGUI('Property','Value',...) creates a new MIBMORPHOPSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibMorphOpsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibMorphOpsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 31.01.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


% Edit the above text to modify the response to help mibMorphOpsGUI

% Last Modified by GUIDE v2.5 24-Mar-2018 14:11:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibMorphOpsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibMorphOpsGUI_OutputFcn, ...
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

% --- Executes just before mibMorphOpsGUI is made visible.
function mibMorphOpsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibMorphOpsGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% set panel positions
handles.ulterPanel.Parent = handles.iterPanel.Parent;
handles.ulterPanel.Position = handles.iterPanel.Position;

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
% set(handles.mibMorphOpsGUI,'WindowStyle','modal');

% UIWAIT makes mibMorphOpsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibMorphOpsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibMorphOpsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibMorphOpsGUI.
function mibMorphOpsGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibMorphOpsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on selection change in morphOpsPopup.
function morphOpsPopup_Callback(hObject, eventdata, handles)
handles.winController.morphOpsPopup_Callback();
end

function applyToRadio_Callback(hObject, eventdata, handles)
hObject.Value = 1;
end

function iterationsRadio_Callback(hObject, eventdata, handles)
tag = hObject.Tag;
hObject.Value = 1;
handles.removeBranchesCheck.Enable = 'off';
if strcmp(tag,'limitToRadio')
    handles.iterEdit.Enable = 'on';
else
    handles.iterEdit.Enable = 'off';
    if handles.morphOpsPopup.Value == 7     % thin
        handles.removeBranchesCheck.Enable = 'on';
    end
end
end

% --- Executes on button press in radioBtn2D.
function radioBtn2D_Callback(hObject, eventdata, handles)
if hObject.Value == 0
    hObject.Value = 1;
    return;
end;
if handles.radioBtn3D.Value     % 3D mode
    handles.auxPopup1.Value = 1;
    handles.auxPopup1.String = [{'6'},{'18'},{'26'}];
    handles.datasetRadio.Value = 1;
    handles.sliceRadio.Enable = 'off';
else    % 2D mode
    handles.sliceRadio.Enable = 'on';
    handles.auxPopup1.Value = 1;
    handles.auxPopup1.String = [{'4'},{'8'}];
end

end

% --- Executes on key press with focus on mibMorphOpsGUI and none of its controls.
function mibMorphOpsGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibMorphOpsGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    cancelBtn_Callback(handles.cancelBtn, eventdata, handles);
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    continueBtn_Callback(handles.continueBtn, eventdata, handles)
end   
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end

% --- Executes on button press in objects3D.
function objects3D_Callback(hObject, eventdata, handles)
if handles.objects3D.Value == 1
    list = {'branchpoints', 'clean', 'endpoints', 'fill', 'majority', 'remove', 'skel'};
else
    list = {'branchpoints','bwulterode','diag','endpoints','skel','spur','thin'};
end
handles.morphOpsPopup.String = list;

handles.winController.updateWidgets();
end

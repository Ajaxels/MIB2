function varargout = mibKeyShortcutsGUI(varargin)
% MIBKEYSHORTCUTSGUI MATLAB code for mibKeyShortcutsGUI.fig
%      MIBKEYSHORTCUTSGUI, by itself, creates a new MIBKEYSHORTCUTSGUI or raises the existing
%      singleton*.
%
%      H = MIBKEYSHORTCUTSGUI returns the handle to a new MIBKEYSHORTCUTSGUI or the handle to
%      the existing singleton*.
%
%      MIBKEYSHORTCUTSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBKEYSHORTCUTSGUI.M with the given input arguments.
%
%      MIBKEYSHORTCUTSGUI('Property','Value',...) creates a new MIBKEYSHORTCUTSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibKeyShortcutsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibKeyShortcutsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibKeyShortcutsGUI

% Last Modified by GUIDE v2.5 17-Jan-2017 18:20:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibKeyShortcutsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibKeyShortcutsGUI_OutputFcn, ...
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

% --- Executes just before mibKeyShortcutsGUI is made visible.
function mibKeyShortcutsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibKeyShortcutsGUI (see VARARGIN)

global Font;

% obtain controller
handles.winController = varargin{1};

% update font and size
if ~isempty(Font)
    if handles.text1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibKeyShortcutsGUI, Font);
    end
end
% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibKeyShortcutsGUI);

% Choose default command line output for mibdatasetinfogui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibKeyShortcutsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibKeyShortcutsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibKeyShortcutsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibKeyShortcutsGUI.
function mibKeyShortcutsGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibKeyShortcutsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in okBtn.
function okBtn_Callback(hObject, eventdata, handles)
handles.winController.okBtn_Callback();
end

% --- Executes on button press in fitTextBtn.
function fitTextBtn_Callback(hObject, eventdata, handles)
handles.winController.fitTextBtn_Callback();
end


% --- Executes when entered data in editable cell(s) in shortcutsTable.
function shortcutsTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to shortcutsTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

handles.winController.shortcutsTable_CellEditCallback(eventdata);
end


% --- Executes on key press with focus on mibKeyShortcutsGUI and none of its controls.
function mibKeyShortcutsGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibKeyShortcutsGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

handles.pressedKeyText.String = eventdata.Key;
end

% --- Executes on key press with focus on shortcutsTable and none of its controls.
function shortcutsTable_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to shortcutsTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

handles.pressedKeyText.String = eventdata.Key;

end


% --- Executes on button press in defaultBtn.
function defaultBtn_Callback(hObject, eventdata, handles)
handles.winController.defaultBtn_Callback();
end

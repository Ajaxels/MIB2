function varargout = mibBatchGUI(varargin)
% MIBBATCHGUI MATLAB code for mibBatchGUI.fig
%      MIBBATCHGUI, by itself, creates a new MIBBATCHGUI or raises the existing
%      singleton*.
%
%      H = MIBBATCHGUI returns the handle to a new MIBBATCHGUI or the handle to
%      the existing singleton*.
%
%      MIBBATCHGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBBATCHGUI.M with the given input arguments.
%
%      MIBBATCHGUI('Property','Value',...) creates a new MIBBATCHGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibBatchGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibBatchGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibBatchGUI

% Last Modified by GUIDE v2.5 10-Sep-2019 15:47:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibBatchGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibBatchGUI_OutputFcn, ...
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

% --- Executes just before mibBatchGUI is made visible.
function mibBatchGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibBatchGUI (see VARARGIN)

global mibPath;

% obtain controller
handles.winController = varargin{1};

handles.selectedActionTableCellEdit.Position(1) = handles.selectedActionTableCellCheck.Position(1);
handles.selectedActionTableCellEdit.Position(2) = handles.selectedActionTableCellCheck.Position(2);
handles.selectedActionTableCellNumericEdit.Position(1) = handles.selectedActionTableCellCheck.Position(1);
handles.selectedActionTableCellNumericEdit.Position(2) = handles.selectedActionTableCellCheck.Position(2);
handles.selectedActionTableCellPopup.Position(1) = handles.selectedActionTableCellCheck.Position(1);
handles.selectedActionTableCellPopup.Position(2) = handles.selectedActionTableCellCheck.Position(2);

% adding context menu to protocolList
handles.protocolList_cm = uicontextmenu('Parent', handles.mibBatchGUI);
uimenu(handles.protocolList_cm, 'Label', 'Show settings', 'Callback', {@protocolList_ContextCallback, 'show'});
uimenu(handles.protocolList_cm, 'Label', 'Duplicate', 'Separator', 'on', 'Callback', {@protocolList_ContextCallback, 'duplicate'});
uimenu(handles.protocolList_cm, 'Label', 'Insert STOP EXECUTION event', 'Callback', {@protocolList_ContextCallback, 'insertstop'});
uimenu(handles.protocolList_cm, 'Label', 'Move up', 'Separator', 'on', 'Callback', {@protocolList_ContextCallback, 'moveup'});
uimenu(handles.protocolList_cm, 'Label', 'Move down', 'Callback', {@protocolList_ContextCallback, 'movedown'});
uimenu(handles.protocolList_cm, 'Label', 'Delete from protocol', 'Separator', 'on', 'Callback', {@protocolList_ContextCallback, 'delete'});
set(handles.protocolList, 'uicontextmenu', handles.protocolList_cm);

% adding context menu to selectedActionTable
handles.selectedActionTable_cm = uicontextmenu('Parent', handles.mibBatchGUI);
uimenu(handles.selectedActionTable_cm, 'Label', 'Add parameter', 'Callback', {@selectedActionTable_ContextCallback, 'add'});
uimenu(handles.selectedActionTable_cm, 'Label', 'Delete parameter', 'Callback', {@selectedActionTable_ContextCallback, 'delete'});
uimenu(handles.selectedActionTable_cm, 'Label', 'Add directory', 'Separator', 'on', 'Callback', {@selectedActionTable_ContextCallback, 'Add directory'});
uimenu(handles.selectedActionTable_cm, 'Label', 'Modify directory', 'Callback', {@selectedActionTable_ContextCallback, 'Modify directory'});
uimenu(handles.selectedActionTable_cm, 'Label', 'Remove directory', 'Callback', {@selectedActionTable_ContextCallback, 'Remove directory'});
uimenu(handles.selectedActionTable_cm, 'Label', 'Set second column width', 'Separator', 'on', 'Callback', {@selectedActionTable_ContextCallback, 'Set second column width'});
set(handles.selectedActionTable, 'uicontextmenu', handles.selectedActionTable_cm);

% Choose default command line output for mibBatchGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibBatchGUI wait for user response (see UIRESUME)
% uiwait(handles.mibBatchGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibBatchGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibBatchGUI.
function mibBatchGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibBatchGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% % ----------------------------------------------------------------------
% Callbacks for buttons
% % ----------------------------------------------------------------------

% --- Executes on button press in helpBtn
function helpBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.helpBtn_Callback();
end

% --- Executes on button press in runProtocolBtn.
% start calculation of something
function runProtocolBtn_Callback(hObject, eventdata, handles, parameter)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call a corresponding method of the controller class
handles.winController.runProtocolBtn_Callback(parameter);
end


function protocolList_ContextCallback(hObject, ~, parameter)
% callbacks for context menu of protocolTable
handles = guidata(hObject);
handles.winController.protocolActions_Callback(parameter);
end

function selectedActionTable_ContextCallback(hObject, ~, parameter)
% callbacks for context menu of protocolTable
handles = guidata(hObject);
handles.winController.selectedActionTable_ContextCallback(parameter);
%guidata(hObject, handles);
end

% --- Executes on selection change in sectionPopup.
function selectAction_Callback(hObject, eventdata, handles)
handles.winController.selectAction_Callback(hObject);
end


% --- Executes when selected cell(s) is changed in selectedActionTable.
function selectedActionTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to selectedActionTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

%fprintf('%s: selectedActionTable_CellSelectionCallback\n', char(datetime(now,'ConvertFrom','datenum')));
if ~isempty(eventdata.Indices)
    handles.winController.selectedActionTableIndex  = eventdata.Indices(1);
%else
%    handles.winController.selectedActionTableIndex = 0;
end
handles.winController.displaySelectedActionTableItems();
end


% --- Executes on button press in selectedActionTableCellCheck.
function selectedActionTableItem_Update(hObject, eventdata, handles)
% update selected action in selectedActionTable

%fprintf('%s: selectedActionTableItem_Update\n', char(datetime(now,'ConvertFrom','datenum')));
handles.winController.selectedActionTableItem_Update(hObject);
end


% --- Executes on button press in addToListButton.
function protocolActions_Callback(hObject, eventdata, handles, options)
% callback to handle actions with the protocol
handles.winController.protocolActions_Callback(options);
end


% --- Executes on selection change in protocolList.
function protocolList_Callback(hObject, eventdata, handles)
if isempty(handles.protocolList.Value); return; end
handles.winController.protocolListIndex  = handles.protocolList.Value;
if handles.showOptionsCheck.Value == 1  % display the settings for the selected action
    handles.winController.protocolList_SelectionCallback();
end
end


% --- Executes on button press in redoBtn.
function backup_Callback(hObject, eventdata, handles)
switch hObject.Tag
    case 'undoBtn'
        handles.winController.BackupProtocolRestore('undo');
    case 'redoBtn'
        handles.winController.BackupProtocolRestore('redo');
end
end


% --- Executes on button press in loadProtocolBtn.
function loadProtocolBtn_Callback(hObject, eventdata, handles)
handles.winController.loadProtocol();
end

% --- Executes on button press in saveProtocolBtn.
function saveProtocolBtn_Callback(hObject, eventdata, handles)
handles.winController.saveProtocol();
end

% --- Executes on button press in deleteProtocolBtn.
function deleteProtocolBtn_Callback(hObject, eventdata, handles)
handles.winController.deleteProtocol();
end


% --- Executes when mibBatchGUI is resized.
function mibBatchGUI_SizeChangedFcn(hObject, eventdata, handles)
mainFigPos = handles.mibBatchGUI.Position;
if mainFigPos(4) < 372
    handles.mibBatchGUI.Position(4) = 372;
    handles.mibBatchGUI.Position(2) = mainFigPos(2)-(372-mainFigPos(4));
    return; 
end
handles.actionListPanel.Position(2:3) = [mainFigPos(4)-handles.actionListPanel.Position(4), ...
                mainFigPos(3) - 10];
handles.selectActionPanel.Position(3:4) = [mainFigPos(3) - 10, ...
                handles.actionListPanel.Position(2) - handles.selectActionPanel.Position(2)];

handles.StepsSubpanelUp.Position(2) = handles.selectActionPanel.Position(4) - handles.StepsSubpanelUp.Position(4) - 10;
handles.selectedActionTable.Position(3:4) = [(handles.selectActionPanel.Position(3) - handles.selectedActionTable.Position(2))/2, ...
                handles.StepsSubpanelUp.Position(2) - 10];
handles.ParametersText.Position(2) = handles.selectedActionTable.Position(2)+handles.selectedActionTable.Position(4)-handles.ParametersText.Position(4);
handles.StepsSubpanelRight.Position(2) = handles.StepsSubpanelUp.Position(2) - handles.StepsSubpanelRight.Position(4);
handles.StepsSubpanelRight.Position(1) = handles.selectedActionTable.Position(1)+handles.selectedActionTable.Position(3) + 10;
handles.StepsSubpanelRight.Position(3) = handles.selectActionPanel.Position(3)-handles.StepsSubpanelRight.Position(1);
end


% --- Executes on button press in listenMIB.
function listenMIB_Callback(hObject, eventdata, handles)
handles.winController.listenMIB_Callback();
end

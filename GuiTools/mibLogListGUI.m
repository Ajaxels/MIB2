function varargout = mibLogListGUI(varargin)
% function varargout = mibLogListGUI(varargin)
% mibLogListGUI function calls a window with Log list of actions that were performed with the dataset.
%
% The log is stored in imageData.img_info(''ImageDescription'') key.
%
% mibLogListGUI contains MATLAB code for mibLogListGUI.fig

% Copyright (C) 22.05.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
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
    'gui_OpeningFcn', @mibLogListGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibLogListGUI_OutputFcn, ...
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

% --- Executes just before mibLogListGUI is made visible.
function mibLogListGUI_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibLogListGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

repositionSwitch = 1; % reposition the figure, when creating a new figure

% Choose default command line output for mibLogListGUI
handles.output = hObject;

% update font and size
global Font;
if handles.logPrint.FontSize ~= Font.FontSize ...
        || ~strcmp(handles.logPrint.FontName, Font.FontName)
    mibUpdateFontSize(handles.mibLogListGUI, Font);
end

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibLogListGUI);

% Update handles structure
guidata(hObject, handles);

% Determine the position of the dialog - outside of the main figure, at the
% bottom if available, else, centered on the main figure
if repositionSwitch
    FigPos=get(0,'DefaultFigurePosition');
    OldUnits = get(hObject, 'Units');
    set(hObject, 'Units', 'pixels');
    OldPos = get(hObject,'Position');
    FigWidth = OldPos(3);
    FigHeight = OldPos(4);
    if isempty(gcbf)
        ScreenUnits=get(0,'Units');
        set(0,'Units','pixels');
        ScreenSize=get(0,'ScreenSize');
        set(0,'Units',ScreenUnits);
        
        FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
        FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
    else
        GCBFOldUnits = get(gcbf,'Units');
        set(gcbf,'Units','pixels');
        GCBFPos = get(gcbf,'Position');
        set(gcbf,'Units',GCBFOldUnits);
        screenSize = get(0,'ScreenSize');
        if GCBFPos(1)-FigWidth > 0 % put figure on the left side of the main figure
            FigPos(1:2) = [GCBFPos(1)-FigWidth-16 GCBFPos(2)];
        elseif GCBFPos(1) + GCBFPos(3) + FigWidth < screenSize(3) % put figure on the right side of the main figure
            FigPos(1:2) = [GCBFPos(1)+GCBFPos(3)+16 GCBFPos(2)];
        else
            FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
        end
    end
    FigPos(3:4)=[FigWidth FigHeight];
    set(hObject, 'Position', FigPos);
    set(hObject, 'Units', OldUnits);
end
% UIWAIT makes mibLogListGUI wait for user response (see UIRESUME)
%uiwait(handles.mibLogListGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibLogListGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibLogListGUI.
function mibLogListGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in update.
function updateBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end

% --- Executes on selection change in mibLogListGUI.
function logList_Callback(hObject, eventdata, handles)
end


% --- Executes on button press in logPrint.
function logPrint_Callback(hObject, eventdata, handles)
% display the log contents in the matlab command window
logText = handles.logList.String;
if strcmp(class(logText), 'char')
    disp(logText);
else
    for line=1:numel(logText)
        disp(logText{line});
    end
end
end


% --- Executes on button press in clipboardBtn.
function clipboardBtn_Callback(hObject, eventdata, handles)
% copy contents of the log list to the system clipboard
logText = handles.logList.String;
str1 = '';
for line_idx = 1:numel(logText)
    str1 = sprintf('%s%s\n', str1, logText{line_idx});
end
clipboard('copy', str1);
end

% --- Executes on button press in deleteBtn.
function deleteBtn_Callback(hObject, eventdata, handles)
% delete selected entry from the log list
handles.winController.deleteBtn_Callback();
end

% --- Executes on button press in insertBtn.
function insertBtn_Callback(hObject, eventdata, handles)
% % insert an entry to the log list
handles.winController.insertBtn_Callback();
end

% --- Executes on button press in modifyBtn.
function modifyBtn_Callback(hObject, eventdata, handles)
% modify selected entry
handles.winController.modifyBtn_Callback();
end

function varargout = mibInputDlg(varargin)
% function output = mibInputDlg(mibPath, dlgText, dlgTitle, defAnswer)
% custom input dialog
%
%
% Parameters:
% mibPath:  [optional] a cell string with a path to MIB installation, use
% @code global mibPath; @endcode to get it, or just an empty cell: {[]}
% dlgText:  dialog test, a string
% dlgTitle: dialog title, a string
% defAnswer:    default answer, a string
%
% Return values:
% output: a cell with the entered value, or an empty cell, when cancelled

%| 
% @b Examples:
% @code answer = mibInputDlg({[]}, 'Text of dialog','Title', num2str(defaultValue));
% if size(answer) == 0; return; end; @endcode
% @code
% global mibPath;
% answer = mibInputDlg({mibPath}, 'Text of dialog','Title', num2str(defaultValue));
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
                   'gui_OpeningFcn', @mibInputDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @mibInputDlg_OutputFcn, ...
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

% --- Executes just before mibInputDlg is made visible.
function mibInputDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibInputDlg (see VARARGIN)

global mibPath;     % path to mib installation directory

if nargin < 7
    inputStr = handles.textEdit.String;
else
    inputStr = varargin{4};
end

if nargin < 6
    titleStr = handles.mibInputDlg.Name;
else
    titleStr = varargin{3};
end
textString = varargin{2};

if isempty(varargin{1})
    handles.mibPath = mibPath;
else
    handles.mibPath = cell2mat(varargin{1});
end

set(handles.mibInputDlg,'Name', titleStr);
set(handles.textString,'String', textString);
set(handles.textEdit,'String', inputStr);

% Choose default command line output for mibInputDlg
handles.output = {inputStr};

% update font and size
global Font;
if ~isempty(Font)
    if handles.textString.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.textString.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibInputDlg, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibInputDlg);

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

pos = handles.mibInputDlg.Position;
handles.dialogHeight = pos(4);

% add icon
if ~isempty(handles.mibPath)
    [IconData, IconCMap] = imread(fullfile(handles.mibPath, 'Resources', 'mib_quest.gif'));        
else
    if isdeployed % Stand-alone mode.
        [~, result] = system('path');
        currentDir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    else % MATLAB mode.
        currentDir = fileparts(which('mib'));
    end
    [IconData, IconCMap] = imread(fullfile(currentDir, 'Resources', 'mib_quest.gif'));    
end

Img=image(IconData, 'Parent', handles.axes1);
IconCMap(IconData(1,1)+1,:) = handles.mibInputDlg.Color;   % replace background color
handles.mibInputDlg.Colormap = IconCMap;

set(handles.axes1, ...
    'Visible', 'off', ...
    'YDir'   , 'reverse'       , ...
    'XLim'   , Img.XData, ...
    'YLim'   , Img.YData  ...
    );

% update WindowKeyPressFcn
handles.mibInputDlg.WindowKeyPressFcn = {@mibInputDlg_KeyPressFcn, handles};

% Make the GUI modal
handles.mibInputDlg.WindowStyle = 'modal';

% Update handles structure
guidata(hObject, handles);

handles.mibInputDlg.Visible = 'on';
drawnow;

% highlight text in the edit box
uicontrol(handles.textEdit);

% UIWAIT makes mibInputDlg wait for user response (see UIRESUME)
uiwait(handles.mibInputDlg);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibInputDlg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles = guidata(handles.mibInputDlg);

% Get default command line output from handles structure
if isempty(handles.output)
    varargout{1} = {};
else
    varargout{1} = {get(handles.textEdit,'String')};
end
%varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.mibInputDlg);

end

% --- Executes when user attempts to close mibInputDlg.
function mibInputDlg_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibInputDlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    cancelBtn_Callback(hObject, eventdata, handles);
    % The GUI is still in UIWAIT, us UIRESUME
    %uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end
end

% --- Executes on button press in okBtn.
function okBtn_Callback(hObject, eventdata, handles)
% hObject    handle to okBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

drawnow;     % needed to fix callback after the key press
handles.output = {handles.textEdit.String};

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibInputDlg);
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = {};

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibInputDlg);
end

% --- Executes on key press over mibInputDlg with no controls selected.
function mibInputDlg_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibInputDlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if nargin < 3;    handles = guidata(hObject); end;

% Check for "enter" or "escape"
if isequal(hObject.CurrentKey, 'escape')
    cancelBtn_Callback(hObject, eventdata, handles);
end    
if isequal(hObject.CurrentKey, 'return')
    okBtn_Callback(hObject, eventdata, handles);
end    
end


function textEdit_Callback(hObject, eventdata, handles)
% hObject    handle to textEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textEdit as text
%        str2double(get(hObject,'String')) returns contents of textEdit as a double
end


% --- Executes when mibInputDlg is resized.
function mibInputDlg_ResizeFcn(hObject, eventdata, handles)
if isfield(handles, 'dialogHeight')     % to skip this part during initialization of the dialog
    pos = handles.mibInputDlg.Position;
    pos(4) = handles.dialogHeight;
    handles.mibInputDlg.Position = pos;
end
end

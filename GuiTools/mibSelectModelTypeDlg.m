function varargout = mibSelectModelTypeDlg(varargin)
% function output = mibSelectModelTypeDlg(mibPath)
% a dialog to select type of the model
%
%
% Parameters:
% mibPath:  [optional] a cell string with a path to MIB installation, use
% @code global mibPath; @endcode to get it, or just an empty cell: {[]}
%
% Return values:
% output: a number with the selected model type, or an empty cell, when cancelled

%| 
% @b Examples:
% @code answer = mibSelectModelTypeDlg({[]});
%       if size(answer) == 0; return; end; @endcode
% @code global mibPath;
% answer = mibSelectModelTypeDlg({mibPath});
%       if size(answer) == 0; return; end; @endcode

% Copyright (C) 26.04.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @mibSelectModelTypeDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @mibSelectModelTypeDlg_OutputFcn, ...
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

% --- Executes just before mibSelectModelTypeDlg is made visible.
function mibSelectModelTypeDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibSelectModelTypeDlg (see VARARGIN)

global mibPath;     % path to mib installation directory
if isempty(varargin{1})
    handles.mibPath = mibPath;
else
    handles.mibPath = cell2mat(varargin{1});
end

% Choose default command line output for mibSelectModelTypeDlg
handles.output = 63;

% update font and size
global Font;
if ~isempty(Font)
    if handles.modelDescriptionText.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.modelDescriptionText.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibSelectModelTypeDlg, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibSelectModelTypeDlg);

handles.modelDescriptionText.String = sprintf('This model type is recommended for general use.\nIt is limited to 63 materials but fastest in performance and takes less space than all other model types');

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

pos = handles.mibSelectModelTypeDlg.Position;
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
IconCMap(IconData(1,1)+1,:) = handles.mibSelectModelTypeDlg.Color;   % replace background color
handles.mibSelectModelTypeDlg.Colormap = IconCMap;

set(handles.axes1, ...
    'Visible', 'off', ...
    'YDir'   , 'reverse'       , ...
    'XLim'   , Img.XData, ...
    'YLim'   , Img.YData  ...
    );

% update WindowKeyPressFcn
handles.mibSelectModelTypeDlg.WindowKeyPressFcn = {@mibSelectModelTypeDlg_KeyPressFcn, handles};

% Make the GUI modal
handles.mibSelectModelTypeDlg.WindowStyle = 'modal';

% Update handles structure
guidata(hObject, handles);

handles.mibSelectModelTypeDlg.Visible = 'on';
drawnow;

% UIWAIT makes mibSelectModelTypeDlg wait for user response (see UIRESUME)
uiwait(handles.mibSelectModelTypeDlg);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibSelectModelTypeDlg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles = guidata(handles.mibSelectModelTypeDlg);

% Get default command line output from handles structure
if isempty(handles.output)
    varargout{1} = [];
else
    varargout{1} = handles.output;
end
%varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.mibSelectModelTypeDlg);

end

% --- Executes when user attempts to close mibSelectModelTypeDlg.
function mibSelectModelTypeDlg_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibSelectModelTypeDlg (see GCBO)
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
switch handles.modelTypeRadio.SelectedObject.Tag
    case 'material63'
        handles.output = 63;
    case 'material255'
        handles.output = 255;
    case 'material65535'
        handles.output = 65535;
    case 'material4294967295'
        handles.output = 4294967295;
end

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibSelectModelTypeDlg);
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = [];

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibSelectModelTypeDlg);
end

% --- Executes on key press over mibSelectModelTypeDlg with no controls selected.
function mibSelectModelTypeDlg_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibSelectModelTypeDlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if nargin < 3;    handles = guidata(hObject); end

% Check for "enter" or "escape"
if isequal(hObject.CurrentKey, 'escape')
    cancelBtn_Callback(hObject, eventdata, handles);
end    
if isequal(hObject.CurrentKey, 'return')
    okBtn_Callback(hObject, eventdata, handles);
end    
end


% --- Executes when selected object is changed in modelTypeRadio.
function modelTypeRadio_SelectionChangedFcn(hObject, eventdata, handles)
switch handles.modelTypeRadio.SelectedObject.Tag
    case 'material63'
        descText = sprintf('This model type is recommended for general use.\nIt is limited to 63 materials but fastest in performance and takes less space than all other model types');
    case 'material255'
        descText = sprintf('This model type is limited to 255 materials\nIt requires additionally the same amount of memory as the loaded 8-bit dataset');
    case 'material65535'
        descText = sprintf('This model type is limited to 65535 materials\nIt requires additionally the same amount of memory as the loaded 16-bit dataset');
    case 'material4294967295'
        descText = sprintf('This model type is limited to 4294967295 materials\nIt requires additionally the same amount of memory as the loaded 32-bit dataset');
end
handles.modelDescriptionText.String = descText;
end

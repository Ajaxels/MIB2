function varargout = mibStatisticsGUI(varargin)
% function varargout = mibstatisticsgui(varargin)
% mibstatisticsgui is a GUI tool to generate statistics of 2D or 3D objects in the Model or Mask layers
%
% mibstatisticsgui contains MATLAB code for mibstatisticsgui.fig

% Copyright (C) 01.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% Last Modified by GUIDE v2.5 06-Aug-2019 11:39:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibStatisticsGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibStatisticsGUI_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT

% --- Executes just before mibstatisticsgui is made visible.
function mibStatisticsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibstatisticsgui (see VARARGIN)

% Choose default command line output for mibstatisticsgui
% obtain controller
handles.winController = varargin{1};

repositionSwitch = 1; % reposition the figure, when creating a new figure

handles.statTable_cm = uicontextmenu('Parent',handles.mibStatisticsGUI);
uimenu(handles.statTable_cm, 'Label', 'New selection', 'Callback', {@tableContextMenu_cb, 'Replace'});
uimenu(handles.statTable_cm, 'Label', 'Add to selection', 'Callback', {@tableContextMenu_cb, 'Add'});
uimenu(handles.statTable_cm, 'Label', 'Remove from selection', 'Callback', {@tableContextMenu_cb, 'Remove'});
uimenu(handles.statTable_cm, 'Label', 'Copy column(s) to clipboard', 'Callback', {@tableContextMenu_cb, 'copyColumn'}, 'Separator','on');
uimenu(handles.statTable_cm, 'Label', 'New annotations', 'Callback', {@tableContextMenu_cb, 'newLabel'}, 'Separator','on');
uimenu(handles.statTable_cm, 'Label', 'Add to annotations', 'Callback', {@tableContextMenu_cb, 'addLabel'});
uimenu(handles.statTable_cm, 'Label', 'Remove from annotations', 'Callback', {@tableContextMenu_cb, 'removeLabel'});
uimenu(handles.statTable_cm, 'Label', 'Calculate Mean value', 'Callback', {@tableContextMenu_cb, 'mean'}, 'Separator','on');
uimenu(handles.statTable_cm, 'Label', 'Calculate Sum value', 'Callback', {@tableContextMenu_cb, 'sum'});
uimenu(handles.statTable_cm, 'Label', 'Calculate Min value', 'Callback', {@tableContextMenu_cb, 'min'});
uimenu(handles.statTable_cm, 'Label', 'Calculate Max value', 'Callback', {@tableContextMenu_cb, 'max'});
uimenu(handles.statTable_cm, 'Label', 'Crop to a file/matlab...', 'Callback', {@tableContextMenu_cb, 'crop'}, 'Separator','on');
uimenu(handles.statTable_cm, 'Label', 'Objects to a new model', 'Callback', {@tableContextMenu_cb, 'obj2model'});
uimenu(handles.statTable_cm, 'Label', 'Plot histogram', 'Callback', {@tableContextMenu_cb, 'hist'}, 'Separator','on');
set(handles.statTable,'UIContextMenu',handles.statTable_cm);

% % Add sorting to the table:
% % http://undocumentedmatlab.com/blog/uitable-sorting
% % Display the uitable and get its underlying Java object handle
jscrollpane = findjobj(handles.statTable);
jtable = jscrollpane.getViewport.getView;
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);

%  
% % Now turn the JIDE sorting on
% jtable.setSortable(true);		% or: set(jtable,'Sortable','on');
% jtable.setAutoResort(true);
% jtable.setMultiColumnSortable(true);
% jtable.setPreserveSelectionsAfterSorting(true);

% % update font and size
global Font;
if ~isempty(Font)
    if handles.autoHighlightCheck.FontSize ~= Font.FontSize ...
             || ~strcmp(handles.autoHighlightCheck.FontName, Font.FontName)
         mibUpdateFontSize(handles.mibStatisticsGUI, Font);
    end
end

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibStatisticsGUI);

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibstatisticsgui wait for user response (see UIRESUME)
% uiwait(handles.mibStatisticsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibStatisticsGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.h;

varargout{1} = handles.output;

% The figure can be deleted now
%delete(handles.mibStatisticsGUI);
end


function closeBtn_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% --- Executes on button press in closeBtn.
handles.winController.closeWindow();
end

function mibStatisticsGUI_CloseRequestFcn(hObject, eventdata, handles)
% --- Executes when user attempts to close mibStatisticsGUI.
handles.winController.closeWindow();
end

function runStatAnalysis_Callback(hObject, eventdata, handles)
% --- Executes on button press in runStatAnalysis.
handles.winController.runStatAnalysis_Callback();
end

function tableContextMenu_cb(hObject, eventdata, parameter)
handles = guidata(hObject);
handles.winController.tableContextMenu_cb(parameter);
end

function highlightBtn_Callback(hObject, eventdata, handles)
value(1) = str2double(handles.highlight1.String);
value(2) = str2double(handles.highlight2.String);
value = sort(value);
data = handles.statTable.Data;
indeces = find(data(:,2) >= value(1) & data(:,2) <= value(2));
object_list = data(indeces, 1);
handles.winController.highlightSelection(object_list);
end

% --- Executes on button press in histScale.
function histScale_Callback(hObject, eventdata, handles)
handles.winController.histScale_Callback();
end


% --- Executes when selected cell(s) is changed in statTable.
function statTable_CellSelectionCallback(hObject, eventdata, handles, parameter)
% hObject    handle to statTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

Indices = eventdata.Indices;
handles.winController.statTable_CellSelectionCallback(Indices, parameter);
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function mibStatisticsGUI_WindowButtonDownFcn(hObject, eventdata, handles)
handles.winController.mibStatisticsGUI_WindowButtonDownFcn();
end

% --------------------------------------------------------------------
function statTable_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to statTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%statTable_CellSelectionCallback(hObject, eventdata, handles, 'proceed')
end

% --- Executes on button press in Object.
function radioButton_Callback(hObject, eventdata, handles)
handles.winController.radioButton_Callback(hObject);
end


% --- Executes on button press in exportButton.
function exportButton_Callback(hObject, eventdata, handles)
handles.winController.exportButton_Callback();
end


% --- Executes on button press in helpButton.
function helpButton_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_mask_statistics.html'), '-helpbrowser');
end


% --- Executes on selection change in Property.
function Property_Callback(hObject, eventdata, handles)
handles.winController.Property_Callback();
end

function Multiple_Callback(hObject, eventdata, handles)
handles.winController.Multiple_Callback();
end

% --- Executes on button press in multipleBtn.
function multipleBtn_Callback(hObject, eventdata, handles)
handles.winController.multipleBtn_Callback();
end


% --- Executes on selection change in Material.
function Material_Callback(hObject, eventdata, handles)
handles.winController.Material_Callback();
end


% --- Executes on selection change in DatasetType.
function DatasetType_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end


% --- Executes on button press in updateBtn.
function updateBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end


% --- Executes when mibStatisticsGUI is resized.
function mibStatisticsGUI_SizeChangedFcn(hObject, eventdata, handles)
checkH = handles.autoHighlightCheck.Position(4);    % height of a checkbox to use for internal shifts
winPos = handles.mibStatisticsGUI.Position;

handles.parametersPanel.Position(2) = winPos(4)-handles.parametersPanel.Position(4);

handles.statisticsResultsPanel.Position(2) = handles.histPanel.Position(2)+handles.histPanel.Position(4);
handles.statisticsResultsPanel.Position(4) = handles.parametersPanel.Position(2)-handles.statisticsResultsPanel.Position(2);
handles.statisticsResultsPanel.Position(3) = winPos(3)-handles.statisticsResultsPanel.Position(1)*2;

end

% --- Executes on selection change in Units.
function Units_Callback(hObject, eventdata, handles)
handles.winController.Units_Callback();
end


% --- Executes on selection change in ColorChannel1.
function ColorChannel1_Callback(hObject, eventdata, handles)
handles.winController.Property_Callback();
handles.winController.updateBatchOptFromGUI(hObject);
end

% --- Executes on selection change in sortingPopup.
function sortingPopup_Callback(hObject, eventdata, handles)
handles.winController.updateSortingSettings();
end

% --- Executes on selection change in ColorChannel.
function widgets_Callback(hObject, eventdata, handles)
handles.winController.updateBatchOptFromGUI(hObject);
end

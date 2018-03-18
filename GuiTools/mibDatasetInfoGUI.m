function varargout = mibDatasetInfoGUI(varargin)
% function varargout = mibdatasetinfogui(varargin)
% mibdatasetinfogui is a GUI window that shows parameters of the dataset
%
%
% mibdatasetinfogui.m contains MATLAB code for mibdatasetinfogui.fig
%

% Copyright (C) 07.11.2013, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 22.04.2016, IB, updated to use uiTree class instead of a table
% 11.10.2016, fix of structures in sub elements

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibDatasetInfoGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibDatasetInfoGUI_OutputFcn, ...
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

% --- Executes just before mibdatasetinfogui is made visible.
function mibDatasetInfoGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibdatasetinfogui (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibdatasetinfogui
handles.output = hObject;

% [handles.winController.uiTree, handles.uiTreeContainer] = uitree('v0');    % allocate variable for uiTreeContainer
% handles.uiTreeContainer.Parent = handles.uiTreePanel;    % assign to the parent panel
% handles.uiTreeContainer.Units = 'points';
% uiTreePanelPos = handles.uiTreePanel.Position;
% handles.uiTreeContainer.Position = [5, 5, uiTreePanelPos(3)-8, uiTreePanelPos(4)-8]; % resize uiTree

% update font and size
global Font;
if ~isempty(Font)
    if handles.uipanel1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.uipanel1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibDatasetInfoGUI, Font);
    end
end

% resize in the controller
% resize all elements x1.25 times for macOS
%mibRescaleWidgets(handles.mibDatasetInfoGUI);

% if repositionSwitch == 1
%     % setup uiTree
%     % based on description by Yair Altman:
%     % http://undocumentedmatlab.com/blog/customizing-uitree
%     warning('off','MATLAB:uitreenode:DeprecatedFunction');
%     warning('off','MATLAB:uitree:DeprecatedFunction');
%     
%     import javax.swing.*
%     import javax.swing.tree.*;
%     handles.rootNode = uitreenode('v0','root', 'img_info', [], false);  % initialize the root node
%     handles.treeModel = DefaultTreeModel(handles.rootNode);     % set the tree Model
%     [handles.uiTree, handles.uiTreeContainer] = uitree('v0');   % create the uiTree
%     handles.uiTree.setModel(handles.treeModel);
%     
%     set(handles.uiTreeContainer, 'parent', handles.uiTreePanel);    % assign to the parent panel
%     set(handles.uiTreeContainer, 'units', 'points');
%     uiTreePanelPos = get(handles.uiTreePanel,'Position');
%     set(handles.uiTreeContainer,'Position', [5, 5, uiTreePanelPos(3)-8, uiTreePanelPos(4)-8]); % resize uiTree
%     handles.uiTree.setSelectedNode(handles.rootNode);   % make root the initially selected node
%     
%     handles.uiTree.setMultipleSelectionEnabled(1);  % enable multiple selections
% end

% move the window
hObject = moveWindowOutside(hObject, 'right');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibdatasetinfogui wait for user response (see UIRESUME)
% uiwait(handles.mibdatasetinfogui);
end


% --- Outputs from this function are returned to the command line.
function varargout = mibDatasetInfoGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
% delete(handles.mibdatasetinfogui);
end

% --- Executes when user attempts to close mibdatasetinfogui.
function mibDatasetInfoGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in refreshBtn.
function refreshBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end

% --- Executes when mibdatasetinfogui is resized.
function mibDatasetInfoGUI_ResizeFcn(hObject, eventdata, handles)
if isstruct(handles) == 0; return; end;
guiPos = handles.mibDatasetInfoGUI.Position;
vSize = handles.refreshBtn.Position(4); % use height of the refresh button as an internal measure
handles.uipanel1.Position(3) = guiPos(3)-vSize/4;
handles.uipanel1.Position(4) = guiPos(4)-handles.uipanel2.Position(1)-handles.uipanel2.Position(4)-vSize;
handles.selectedText.Position(2) = handles.uipanel1.Position(4)-handles.selectedText.Position(4)-vSize;
handles.selectedText.Position(3) = handles.uipanel1.Position(3)-vSize;

handles.uiTreePanel.Position(3) = handles.uipanel1.Position(3)-vSize;
handles.uiTreePanel.Position(4) = handles.uipanel1.Position(4) - handles.selectedText.Position(4)-vSize*2;

if isfield(handles, 'uiTreeContainer')
    handles.uiTreeContainer.Position(3) = handles.uiTreePanel.Position(3)-vSize/2;
    handles.uiTreeContainer.Position(4) = handles.uiTreePanel.Position(4)-vSize/2;
end
end



% --- Executes on button press in insertBtn.
function insertBtn_Callback(hObject, eventdata, handles)
handles.winController.insertBtn_Callback();
end

% --- Executes on button press in modifyBtn.
function modifyBtn_Callback(hObject, eventdata, handles)
handles.winController.modifyBtn_Callback();
end

% --- Executes on button press in deleteBtn.
function deleteBtn_Callback(hObject, eventdata, handles)
handles.winController.deleteBtn_Callback();
end

function searchEdit_Callback(hObject, eventdata, handles)
handles.winController.searchEdit_Callback('new');
end

% --- Executes on button press in FindNextBtn.
function FindNextBtn_Callback(hObject, eventdata, handles)
handles.winController.searchEdit_Callback('next');
end

% --- Executes on button press in simplifyBtn.
function simplifyBtn_Callback(hObject, eventdata, handles)
handles.winController.simplifyBtn_Callback();
end

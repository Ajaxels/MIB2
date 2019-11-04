function varargout = mibGUI(varargin)
% MIBGUI MATLAB code for mibGUI.fig
%      MIBGUI, by itself, creates a new MIBGUI or raises the existing
%      singleton*.
%
%      H = MIBGUI returns the handle to a new MIBGUI or the handle to
%      the existing singleton*.
%
%      MIBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBGUI.M with the given input arguments.
%
%      MIBGUI('Property','Value',...) creates a new MIBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibGUI

% Last Modified by GUIDE v2.5 06-Oct-2019 23:29:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibGUI_OutputFcn, ...
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

% --- Executes just before mibGUI is made visible.
function mibGUI_OpeningFcn(hObject, ~, handles, varargin)
% Choose default command line output for mibGUI
handles.output = hObject;

if isa(varargin{1}, 'mibController');    handles.mibController = varargin{1}; end

if handles.mibController.matlabVersion >= 8.4 % R2014b
    handles.mibGUI.GraphicsSmoothing = 'off';  % turn off smoothing and turn opengl renderer
    handles.mibGUI.Renderer = 'opengl';
    handles.mibImageAxes.FontSmoothing = 'off';
else
    handles.mibGUI.Renderer = 'opengl';
end
title = ['Microscopy Image Browser ' handles.mibController.mibVersion];
if isdeployed
    title = [title ' deployed version']; 
end
handles.mibGUI.Name = title;

% disable widgets that are not compatible with mac and linux
if ~ispc()
    handles.mibDrivePopup.Enable = 'off';
end

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibGUI);
% update font and size
global Font;
if ~isempty(Font)
    if handles.mibPixelInfoText.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.mibPixelInfoText.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibGUI, Font);
    end
end

% Set the font size for mibFilesListbox
handles.mibFilesListbox.FontSize = handles.mibController.mibModel.preferences.fontSizeDir;

handles.mibFileFilterPopup.UserData = 1;  % last selected file extention for use when swap bio/standard file reader
mibUpdateDrives(handles, handles.mibController.mibModel.preferences.lastpath);  % get available disk drives

%% Adding Context menus
% adding context menu for buffer toggles
for i=1:9
    eval(sprintf('handles.mibBufferToggle%d_cm = uicontextmenu(''Parent'', handles.mibGUI);', i));
    eval(sprintf('uimenu(handles.mibBufferToggle%d_cm, ''Label'', ''Duplicate dataset'', ''Callback'', {@mibBufferToggleContext_Callback, ''duplicate'',%d});', i, i));
    eval(sprintf('uimenu(handles.mibBufferToggle%d_cm, ''Label'', ''Sync view (x,y) with...'', ''Separator'',''on'',''Callback'', {@mibBufferToggleContext_Callback, ''sync_xy'',%d});', i, i));
    eval(sprintf('uimenu(handles.mibBufferToggle%d_cm, ''Label'', ''Sync view (x,y,z) with...'', ''Callback'', {@mibBufferToggleContext_Callback, ''sync_xyz'',%d});', i, i));
    eval(sprintf('uimenu(handles.mibBufferToggle%d_cm, ''Label'', ''Sync view (x,y,z,t) with...'', ''Callback'', {@mibBufferToggleContext_Callback, ''sync_xyzt'',%d});', i, i));
    eval(sprintf('uimenu(handles.mibBufferToggle%d_cm, ''Label'', ''Close dataset'', ''Separator'',''on'',''Callback'', {@mibBufferToggleContext_Callback, ''close'',%d});', i, i));
    eval(sprintf('uimenu(handles.mibBufferToggle%d_cm, ''Label'', ''Close all stored datasets'', ''Callback'', {@mibBufferToggleContext_Callback, ''closeAll'',%d});', i, i));
    eval(sprintf('set(handles.mibBufferToggle%d,''uicontextmenu'',handles.mibBufferToggle%d_cm);', i, i));
end

% adding context menu for filesListbox
handles.mibFilesListbox_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibFilesListbox_cm, 'Label', 'Combine selected datasets...', 'Callback', {@mibFilesListbox_cm_Callback, 'Combine datasets'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Load part of the dataset (*.am only)...', 'Callback', {@mibFilesListbox_cm_Callback, 'Load part of dataset'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Load each N-th dataset...', 'Callback', {@mibFilesListbox_cm_Callback, 'Load each N-th dataset'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Insert into the open dataset...', 'Callback', {@mibFilesListbox_cm_Callback, 'Insert into open dataset'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Combine files as color channels...', 'Separator', 'on', 'Callback', {@mibFilesListbox_cm_Callback, 'Combine files as color channels'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Add as a new color channel...', 'Callback', {@mibFilesListbox_cm_Callback, 'Add as new color channel'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Add each N-th dataset as a new color channel...', 'Callback', {@mibFilesListbox_cm_Callback, 'Add each N-th dataset as new color channel'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Rename selected file...', 'Separator', 'on', 'Callback', {@mibFilesListbox_cm_Callback, 'rename'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'Delete selected files...', 'Callback', {@mibFilesListbox_cm_Callback, 'delete'});
uimenu(handles.mibFilesListbox_cm, 'Label', 'File properties', 'Separator', 'on', 'Callback', {@mibFilesListbox_cm_Callback, 'file_properties'});
handles.mibFilesListbox.UIContextMenu = handles.mibFilesListbox_cm;

% adding context menu for mibPathEdit
handles.mibPathEdit_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibPathEdit_cm, 'Label', 'Copy path to clipboard', 'Callback', {@mibPathEdit_cm_Callback, 'clipboard'});
uimenu(handles.mibPathEdit_cm, 'Label', 'Open directory in the file explorer', 'Callback', {@mibPathEdit_cm_Callback, 'fileexplorer'});
handles.mibPathEdit.UIContextMenu = handles.mibPathEdit_cm;

% adding context menu for mibFileFilterPopup
handles.mibFileFilterPopup_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibFileFilterPopup_cm, 'Label', 'Register extension', 'Callback', {@mibFileFilterPopup_cm, 'register'});
uimenu(handles.mibFileFilterPopup_cm, 'Label', 'Remove selected extension', 'Callback', {@mibFileFilterPopup_cm, 'remove'});
handles.mibFileFilterPopup.UIContextMenu = handles.mibFileFilterPopup_cm;

% adding context menus for change layer slider
UserData.sliderStep = 1;     % parameters for slider movement
UserData.sliderShiftStep = 10;
handles.mibChangeLayerSlider.UserData = UserData;
handles.mibChangeLayer_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibChangeLayer_cm, 'Label', 'Default', 'Callback', {@mibChangeLayerSliderContext_cb, 'def'});
uimenu(handles.mibChangeLayer_cm, 'Label', 'Set step...', 'Callback', {@mibChangeLayerSliderContext_cb, 'set'});
handles.mibChangeLayerSlider.UIContextMenu = handles.mibChangeLayer_cm;

% adding context menus for change time slider
handles.mibChangeTimeSlider.UserData = UserData;
handles.mibChangeTime_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibChangeTime_cm, 'Label', 'Default', 'Callback', {@mibChangeTimeSliderContext_cb, 'def'});
uimenu(handles.mibChangeTime_cm, 'Label', 'Set step...', 'Callback', {@mibChangeTimeSliderContext_cb, 'set'});
handles.mibChangeTimeSlider.UIContextMenu = handles.mibChangeTime_cm;

% adding context menu to pixel information
handles.mibPixelInfo_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibPixelInfo_cm, 'Label', 'Jump to...', 'Callback', {@mibPixelInfo_Callback, 'jump'});
set(handles.mibPixelInfoText, 'uicontextmenu', handles.mibPixelInfo_cm);
set(handles.mibPixelInfoTxt2, 'uicontextmenu', handles.mibPixelInfo_cm);

% adding context menus for Materials table
handles.mibSegmentationTable_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Show selected material only', 'Callback', {@mibSegmentationTable_cm_Callback, 'showselected'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Rename...', 'Separator', 'on', 'Callback', {@mibSegmentationTable_cm_Callback, 'rename'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Set color...', 'Callback', {@mibSegmentationTable_cm_Callback, 'set color'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Get statistics...', 'Callback', {@mibSegmentationTable_cm_Callback, 'statistics'});
h1=uimenu(handles.mibSegmentationTable_cm,'label','Material to Selection...','Separator','on');
uimenu(h1,'label','NEW (2D, Slice)', 'callback', {@mibGUI_moveLayers, NaN, 'model', 'selection', '2D, Slice', 'replace'});
uimenu(h1,'label','ADD (2D, Slice)','callback', {@mibGUI_moveLayers, NaN, 'model','selection','2D, Slice','add'});
uimenu(h1,'label','REMOVE (2D, Slice)','callback', {@mibGUI_moveLayers, NaN,'model','selection','2D, Slice','remove'});
uimenu(h1,'label','NEW (3D, Stack)','Separator','on','callback', {@mibGUI_moveLayers, NaN,'model','selection','3D, Stack','replace'});
uimenu(h1,'label','ADD (3D, Stack)','callback', {@mibGUI_moveLayers, NaN, 'model','selection','3D, Stack','add'});
uimenu(h1,'label','REMOVE (3D, Stack)','callback', {@mibGUI_moveLayers, NaN,'model','selection','3D, Stack','remove'});
uimenu(h1,'label','NEW (4D, Dataset)','Separator','on','callback', {@mibGUI_moveLayers, NaN,'model','selection','4D, Dataset','replace'});
uimenu(h1,'label','ADD (4D, Dataset)','callback', {@mibGUI_moveLayers, NaN, 'model','selection','4D, Dataset','add'});
uimenu(h1,'label','REMOVE (4D, Dataset)','callback', {@mibGUI_moveLayers, NaN,'model','selection','4D, Dataset','remove'});
h2=uimenu(handles.mibSegmentationTable_cm,'label','Material to Mask...');
uimenu(h2,'label','NEW (2D, Slice)','callback', {@mibGUI_moveLayers, NaN,'model','mask','2D, Slice','replace'});
uimenu(h2,'label','ADD (2D, Slice)','callback', {@mibGUI_moveLayers, NaN, 'model','mask','2D, Slice','add'});
uimenu(h2,'label','REMOVE (2D, Slice)','callback', {@mibGUI_moveLayers, NaN,'model','mask','2D, Slice','remove'});
uimenu(h2,'label','NEW (3D, Stack)','Separator','on','callback', {@mibGUI_moveLayers, NaN,'model','mask','3D, Stack','replace'});
uimenu(h2,'label','ADD (3D, Stack)','callback', {@mibGUI_moveLayers, NaN, 'model','mask','3D, Stack','add'});
uimenu(h2,'label','REMOVE (3D, Stack)','callback', {@mibGUI_moveLayers, NaN,'model','mask','3D, Stack','remove'});
uimenu(h2,'label','NEW (4D, Dataset)','Separator','on','callback', {@mibGUI_moveLayers, NaN,'model','mask','4D, Dataset','replace'});
uimenu(h2,'label','ADD (4D, Dataset)','callback', {@mibGUI_moveLayers, NaN, 'model','mask','4D, Dataset','add'});
uimenu(h2,'label','REMOVE (4D, Dataset)','callback', {@mibGUI_moveLayers, NaN,'model','mask','4D, Dataset','remove'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Show as volume (MIB)...', 'Separator', 'on', 'Callback', {@mibSegmentationTable_cm_Callback, 'mib'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Show isosurface (Matlab)...', 'Callback', {@mibSegmentationTable_cm_Callback, 'isosurface'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Show as volume (Fiji)...', 'Callback', {@mibSegmentationTable_cm_Callback, 'volumeFiji'});
uimenu(handles.mibSegmentationTable_cm, 'Label', 'Unlink material from Add to', 'Separator', 'on', 'Callback', {@mibSegmentationTable_cm_Callback, 'unlinkaddto'});
handles.mibSegmentationTable.UIContextMenu = handles.mibSegmentationTable_cm;

% adding context menu for Color channels table
handles.mibChannelMixerTable_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Insert empty channel', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'Insert empty channel'});
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Copy channel', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'Copy channel'});
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Invert channel', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'Invert channel'});
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Rotate channel', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'Rotate channel'});
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Swap channels', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'Swap channels'});
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Delete channel', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'Delete channel'});
uimenu(handles.mibChannelMixerTable_cm, 'Label', 'Set LUT color', 'Callback', {@mibChannelMixerTable_Callback, NaN, 'set color'}, 'Separator','on');
handles.mibChannelMixerTable.UIContextMenu = handles.mibChannelMixerTable_cm;

% adding context menu to ROI List
handles.mibRoiList_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibRoiList_cm, 'Label', 'Rename', 'Callback', {@mibRoiList_cm_Callback, 'rename'});
uimenu(handles.mibRoiList_cm, 'Label', 'Edit', 'Callback', {@mibRoiList_cm_Callback, 'edit'});
uimenu(handles.mibRoiList_cm, 'Label', 'Remove', 'Callback', {@mibRoiList_cm_Callback, 'remove'}, 'Separator','on');
handles.mibRoiList.UIContextMenu = handles.mibRoiList_cm;

% adding context menus for Min and Max threshold sliders
handles.mibThresholdSliders_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mibThresholdSliders_cm, 'Label', 'Default', 'Callback', {@mibChangeThresholdValueContext_cb, 'def'});
uimenu(handles.mibThresholdSliders_cm, 'Label', 'Set step...', 'Callback', {@mibChangeThresholdValueContext_cb, 'set'});
handles.mibSegmLowSlider.UIContextMenu = handles.mibThresholdSliders_cm;
handles.mibSegmHighSlider.UIContextMenu = handles.mibThresholdSliders_cm;

% adding context menus for Mask Do it button
handles.mask_cm = uicontextmenu('Parent',handles.mibGUI);
uimenu(handles.mask_cm, 'Label', 'Do new mask', 'Callback', {@mibMaskGenBtn_Callback, NaN, 'new'});
uimenu(handles.mask_cm, 'Label', 'Generate new mask and add it to the existing mask', 'Callback', {@mibMaskGenBtn_Callback, NaN, 'add'});
handles.mibMaskGenBtn.UIContextMenu = handles.mask_cm;

handles.mibSegmDragDropInfoText.String = sprintf('Control+Mouse -> move selected object\nShift+Mouse -> move all objects');

%%
% Populate the recent directories popupmenu
if ~isempty(handles.mibController.mibModel.preferences.recentDirs)
    handles.mibRecentDirsPopup.String = handles.mibController.mibModel.preferences.recentDirs;
end

handles.mibEraserEdit.String = num2str(handles.mibController.mibModel.preferences.eraserRadiusFactor);

if ~isempty(find(handles.mibController.mibModel.preferences.lastSegmTool == 3,1))  % set background for the brush when it is fast access tool
    handles.mibSegmFavToolCheck.Value = 1;
    handles.mibSegmentationToolPopup.BackgroundColor = [1 .69 .39];
end

% update transparency sliders
handles.mibSelectionTransparencySlider.Value = handles.mibController.mibModel.preferences.mibSelectionTransparencySlider;
handles.mibMaskTransparencySlider.Value = handles.mibController.mibModel.preferences.mibMaskTransparencySlider;
handles.mibModelTransparencySlider.Value = handles.mibController.mibModel.preferences.mibModelTransparencySlider;

%% Placing panels
handles.mibRoiPanel.Parent = handles.mibSegmentationPanel.Parent;
handles.mibRoiPanel.Position = handles.mibSegmentationPanel.Position;
%set(handles.strelPanel,'parent',get(handles.frangiPanel,'parent'));
%set(handles.bwFilterPanel,'parent',get(handles.frangiPanel,'parent'));
%set(handles.morphPanel,'parent',get(handles.frangiPanel,'parent'));
%set(handles.corrPanel,'parent',get(handles.imageFiltersPanel,'parent'));
handles.mibFijiPanel.Parent = handles.mibImageFiltersPanel.Parent;
handles.mibMaskGeneratorsPanel.Parent = handles.mibImageFiltersPanel.Parent;
%set(handles.backgroundPanel,'parent',get(handles.imageFiltersPanel,'parent'));

%set(handles.bgRemoveSubPanel2, 'parent',get(handles.bgRemoveSubPanel1, 'parent'));
%set(handles.bgRemoveSubPanel2, 'Position',get(handles.bgRemoveSubPanel1, 'Position'));

frangiPos = handles.mibFrangiPanel.Position;
imageFiltersPos = handles.mibImageFiltersPanel.Position;

%set(handles.strelPanel,'Position',frangiPos);
%set(handles.bwFilterPanel,'Position',frangiPos);
%set(handles.morphPanel,'Position',frangiPos);
%set(handles.corrPanel,'Position',imageFiltersPos);
handles.mibFijiPanel.Position = imageFiltersPos;
%set(handles.backgroundPanel,'Position',imageFiltersPos);
handles.mibMaskGeneratorsPanel.Position = imageFiltersPos;

% segmentation tools panels
pos = handles.mibSegmSpotPanel.Position;
handles.mibSegmMembTracerPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmMembTracerPanel.Position = pos;
handles.mibSegmThresPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmThresPanel.Position = pos;
handles.mibSegmMagicPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmMagicPanel.Position = pos;
handles.mibSegmAnnPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmAnnPanel.Position = pos;
handles.mibSegmDragDropPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmDragDropPanel.Position = pos;
handles.mibSegmLines3DPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmLines3DPanel.Position = pos;
handles.mibSegmObjectPickerPanel.Parent = handles.mibSegmentationPanel;
handles.mibSegmObjectPickerPanel.Position = pos;
handles.mibSegmObjectPickerPanelSub2.Parent = handles.mibSegmObjectPickerPanelSub.Parent;
handles.mibSegmObjectPickerPanelSub2.Position = handles.mibSegmObjectPickerPanelSub.Position;

% Mask generator panels
handles.mibStrelPanel.Parent = handles.mibFrangiPanel.Parent;
handles.mibMorphPanel.Parent = handles.mibFrangiPanel.Parent;
handles.mibBwFilterPanel.Parent = handles.mibFrangiPanel.Parent;
handles.mibStrelPanel.Position = handles.mibFrangiPanel.Position;
handles.mibMorphPanel.Position = handles.mibFrangiPanel.Position;
handles.mibBwFilterPanel.Position = handles.mibFrangiPanel.Position;

% updating positions of childs of pathSubPanel to normalized
childrenPans = handles.mibPathSubPanel.Children;
for i=1:numel(childrenPans)
    childrenPans(i).Units = 'normalized';
end

%% add plugins to the menu
func_dir = fullfile(handles.mibController.mibPath, 'Plugins');

if ~isdeployed(); addpath(func_dir); end

customContents1 = dir(func_dir);

if numel(customContents1) > 2
    for customDirIdx = 3:numel(customContents1)
        if customContents1(customDirIdx).isdir
            hSubmenu = uimenu(handles.menuPlugins,'Label', customContents1(customDirIdx).name);
            
            custom_dir = fullfile(func_dir, customContents1(customDirIdx).name);
            customContents2 = dir(custom_dir);
            
            if numel(customContents2) > 2
                for customDirIdx2 = 3:numel(customContents2)
                    if customContents2(customDirIdx2).isdir
                        custom_dir2 = fullfile(custom_dir, customContents2(customDirIdx2).name);
                        
                        if ~isdeployed
                            addpath(custom_dir2);
                        end
                        uimenu(hSubmenu,'Label', customContents2(customDirIdx2).name, 'Callback', (@(src, event) handles.mibController.startPlugin(customContents2(customDirIdx2).name)));
                    end
                end
            end
        end
    end
end

%% define data for the mibSegmentationTable
tableData = cell([2, 3]);
tableData{1, 1} = sprintf('<html><table border=0 width=25 bgcolor=rgb(%d,%d,%d)><TR><TD>&nbsp;</TD></TR></table></html>', ...
    round(handles.mibController.mibModel.preferences.maskcolor(1)*255), round(handles.mibController.mibModel.preferences.maskcolor(2)*255), round(handles.mibController.mibModel.preferences.maskcolor(3)*255));
tableData{1, 2} = '<html><table border=0 width=300 bgcolor=rgb(255,255,255)><TR><TD>Mask</TD></TR></table></html>';
tableData{1, 3} = true;
tableData{2, 1} = '<html><table border=0 width=25 bgcolor=rgb(255,255,255)><TR><TD>&nbsp;</TD></TR></table></html>';
tableData{2, 2} = '<html><table border=0 width=300 bgcolor=rgb(255,255,255)><TR><TD>Exterior</TD></TR></table></html>';
tableData{2, 3} = false;
handles.mibSegmentationTable.Data = tableData;
handles.mibSegmentationTable.ColumnEditable = logical([0, 0, 0]);
userData.unlink = 0;       % switch to unlink selected material from the Add to

% find java object for the segmentation table
userData.jScroll = findjobj(handles.mibSegmentationTable);
try
    userData.jTable = userData.jScroll.getViewport.getComponent(0);
catch err
    warndlg('Please wait for MIB to load completely before interacting with the main window!');
end
userData.jScroll.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);  % add vertical scroll bar
userData.jTable.setAutoResizeMode(userData.jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);

handles.mibSegmentationTable.UserData = userData;

% resize the column width
handles.mibSegmentationTable.Units = 'pixels';
tablePosition = handles.mibSegmentationTable.Position;
currentColWidth =  {25, 'auto', 50};
currentColWidth{2} = tablePosition(3)-currentColWidth{1}-currentColWidth{3}-6;
handles.mibSegmentationTable.ColumnWidth = currentColWidth;
handles.mibSegmentationTable.Units = 'Points';

%% set background for last and first slice buttons of the image view panel
bg = get(handles.mibLastSliceBtn, 'background');
btn1 = ones([6 5 3]);
btn2 = ones([6 5 3]);
for color=1:3
    btn1(:,:,color) = btn1(:,:,color).*bg(color);
    btn2(:,:,color) = btn2(:,:,color).*bg(color);
end
btn1(6,1,:) = [0 0 0]; btn1(3,1,:) = [0 0 0];
btn1(5,2,:) = [0 0 0]; btn1(2,2,:) = [0 0 0];
btn1(4,3,:) = [0 0 0]; btn1(1,3,:) = [0 0 0];
btn1(5,4,:) = [0 0 0]; btn1(2,4,:) = [0 0 0];
btn1(6,5,:) = [0 0 0]; btn1(3,5,:) = [0 0 0];

btn2(1,1,:) = [0 0 0]; btn2(4,1,:) = [0 0 0];
btn2(2,2,:) = [0 0 0]; btn2(5,2,:) = [0 0 0];
btn2(3,3,:) = [0 0 0]; btn2(6,3,:) = [0 0 0];
btn2(2,4,:) = [0 0 0]; btn2(5,4,:) = [0 0 0];
btn2(1,5,:) = [0 0 0]; btn2(4,5,:) = [0 0 0];

set(handles.mibLastSliceBtn,'cdata',btn1);
set(handles.mibFirstSliceBtn,'cdata',btn2);

%% Add icons to menu
pause(.1);

% Disable items in the menu that are not available in the deployed version
if isdeployed
    %handles.menuFileImportImageMatlab.Enable = 'off';
    %handles.menuFileExportImageMatlab.Enable = 'off';
    %handles.menuModelsImport.Enable = 'off';
    %handles.menuModelsExportMatlab.Enable = 'off';
    %handles.menuMaskImportMatlab.Enable = 'off';
    %handles.menuMaskExportMatlab.Enable = 'off';
    %handles.menuFileImportImageImaris.Enable = 'off';
    %handles.menuFileExportImageImaris.Enable = 'off';
    %handles.menuModelsRenderImaris.Enable = 'off';
end

%% add listeners to sliders
%handles.mibChangeLayerSliderListener =
%addlistener(handles.mibChangeLayerSlider, 'ContinuousValueChange', @mibChangeLayerSlider_Callback);    % does not pass handles
handles.mibChangeLayerSliderListener = addlistener(handles.mibChangeLayerSlider, 'ContinuousValueChange', @(hObject, eventdata) mibChangeLayerSlider_Callback(hObject, eventdata, handles)); % pass also handles
handles.mibChangeLayerSliderListener.Enabled = 1;  % disactivate the listener for Z=1;
handles.mibChangeTimeSliderListener = addlistener(handles.mibChangeTimeSlider, 'ContinuousValueChange', @(hObject, eventdata) mibChangeTimeSlider_Callback(hObject, eventdata, handles));
handles.mibChangeTimeSliderListener.Enabled = 1;  % disactivate the listener for T=1;

% to transparency sliders
obj.mibModelTransparencySliderListener = addlistener(handles.mibModelTransparencySlider, 'ContinuousValueChange', @imageRedraw);
obj.mibMaskTransparencySliderListener = addlistener(handles.mibMaskTransparencySlider, 'ContinuousValueChange', @imageRedraw);
obj.mibSelectionTransparencySliderListener = addlistener(handles.mibSelectionTransparencySlider, 'ContinuousValueChange', @imageRedraw);
% to the LowLim and HighLim sliders of the BW thresholding
obj.mibSegmLowSliderListener = addlistener(handles.mibSegmLowSlider, 'ContinuousValueChange', @mibSegmentationBW_Update);
obj.mibSegmHighSliderListener = addlistener(handles.mibSegmHighSlider, 'ContinuousValueChange', @mibSegmentationBW_Update);

% add right mouse click callbacks for the sliders of the widgets,
% see more http://undocumentedmatlab.com/blog/setting-listbox-mouse-actions
try
    jFilesListbox = findjobj(handles.mibFilesListbox); % jScrollPane
    jFilesListbox = jFilesListbox.getVerticalScrollBar;
    jFilesListbox = handle(jFilesListbox, 'CallbackProperties');
    set(jFilesListbox, 'MousePressedCallback',{@scrollbarClick_Callback, handles.mibFilesListbox, 1});
catch err
    err;
end

% add icons to menu entries
mibAddIcons(handles);

%% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibGUI wait for user response (see UIRESUME)
% uiwait(handles.mibGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibGUI_OutputFcn(~, ~, handles, varargin) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibGUI.
function mibGUI_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to mibGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

choice = questdlg('You are about to close Microsopy Image Browser?', 'Microscopy Image Browser', 'Close', 'Cancel','Cancel');
if strcmp(choice, 'Cancel'); return; end

% Hint: delete(hObject) closes the figure
delete(hObject);
handles.mibController.exitProgram();
end

%% --------------------- GUI GLOBAL CALLBACKS ---------------------
function mibGUI_WindowButtonDownFcn(~, ~, handles)
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
handles.mibController.mibGUI_WindowButtonDownFcn();
end

function editbox_Callback(hObject, eventdata, handles, chtype, default_val, variation)
% a callback for update of some edit boxes
if nargin < 5
    handles.mibController.mibView.editbox_Callback(hObject, chtype);
elseif nargin < 6
    handles.mibController.mibView.editbox_Callback(hObject, chtype, default_val);
else
    handles.mibController.mibView.editbox_Callback(hObject, chtype, default_val, variation);
end
end

%% --------------------- TOOLBAR CALLBACKS ---------------------
function devTest_ClickedCallback(~, ~, handles)
% kept for developmental purposes
handles.mibController.devTest_ClickedCallback();
end

function toolbarVirtualMode_ClickedCallback(hObject, eventdata, handles)
% switch between loading datasets to memory or reading from HDD modes
handles.mibController.toolbarVirtualMode_ClickedCallback();
end

function zoomPush_ClickedCallback(hObject, ~, handles)
% callback for push of zoom buttons in the toolbar
parameter = hObject.Tag;
handles.mibController.mibToolbar_ZoomBtn_ClickedCallback(parameter);
end

% --------------------------------------------------------------------
function toolbarUndo_ClickedCallback(hObject, eventdata, handles)
handles.mibController.toolbarUndo_ClickedCallback();
end

% --------------------------------------------------------------------
function toolbarRedo_ClickedCallback(hObject, eventdata, handles)
handles.mibController.toolbarRedo_ClickedCallback();
end

% --------------------------------------------------------------------
function toolbarPlaneToggle_ClickedCallback(hObject, eventdata, handles)
handles.mibController.mibToolbarPlaneToggle(hObject);
end

% --------------------------------------------------------------------
function toolbarResizingMethod_ClickedCallback(hObject, eventdata, handles, options)
% callback for press of handles.toolbarResizingMethod button
if nargin < 4
    handles.mibController.toolbarResizingMethod_ClickedCallback();
else
    handles.mibController.toolbarResizingMethod_ClickedCallback(options);
end
end

function toolbarCenterPointShow_ClickedCallback(hObject, eventdata, handles)
% callback for press of handles.toolbarCenterPointShow
    handles.mibController.toolbarCenterPointShow_ClickedCallback();
end

% --------------------------------------------------------------------
function toolbarShowROISwitch_ClickedCallback(hObject, eventdata, handles)
if strcmp(handles.toolbarShowROISwitch.State, 'on')
    handles.mibRoiShowCheck.Value = 1;
else
    handles.mibRoiShowCheck.Value = 0;
end
handles.mibController.mibRoiShowCheck_Callback();
end

% --------------------------------------------------------------------
function toolbarInterpolation_ClickedCallback(hObject, eventdata, handles, options)
% callback for press of handles.toolbarInterpolation button
if nargin < 4
    handles.mibController.toolbarInterpolation_ClickedCallback();
else
    handles.mibController.toolbarInterpolation_ClickedCallback(options);
end
end

function toolbarBlockModeSwitch_ClickedCallback(hObject, eventdata, handles)
% callback for press of the block mode button
handles.mibController.toolbarBlockModeSwitch_ClickedCallback();
end

% --------------------------------------------------------------------
function volrenToolbarSwitch_ClickedCallback(hObject, eventdata, handles)
handles.mibController.volrenToolbarSwitch_ClickedCallback('toolbar');
end

% --------------------------------------------------------------------
function toolbarParProcBtn_ClickedCallback(hObject, eventdata, handles)
if handles.mibController.matlabVersion < 8.4
    cores = matlabpool('size'); %#ok<DPOOL>
    if cores == 0
        matlabpool(feature('numCores')); %#ok<DPOOL>
        handles.toolbarParProcBtn.Selected = 'on';
    else
        matlabpool close; %#ok<DPOOL>
        handles.toolbarParProcBtn.Selected = 'off';
        %disp(['Already connected to ' num2str(cores) ' cores!']);
        %disp('To terminate the existing session, use: "matlabpool close"');
    end
else
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        parpool(feature('numCores'));
        handles.toolbarParProcBtn.State = 'on';
    else
        poolobj.delete();
        handles.toolbarParProcBtn.State = 'off';
    end
end

end

%% --------------------- PATH PANEL CALLBACKS --------------------- 
function mibDrivePopup_Callback(~, ~, handles)
% --- Executes on selection change in mibDrivePopup.
listOfDrives = handles.mibDrivePopup.String;
newPath = listOfDrives{handles.mibDrivePopup.Value};
handles.mibController.updateMyPath(newPath);
end

function mibFolderSelectBtn_Callback(~, ~, handles)
% --- Executes on button press in mibFolderSelectBtn, directory selection via a GUI tool
newPath = uigetdir(handles.mibPathEdit.String,'Choose Directory');
if newPath == 0; return; end
handles.mibController.updateMyPath(newPath);
end

function mibPathEdit_Callback(~, ~, handles)
% update mibModel.myPath variable
new_path = handles.mibPathEdit.String;
[fpath, ~, fext] = fileparts(new_path);
if ~isempty(fext)
    new_path = fpath; 
end
handles.mibController.updateMyPath(new_path);
end

function mibRecentDirsPopup_Callback(~, eventdata, handles)
% a callback for selection of recent directories using handles.mibRecentDirsPopup
listStr = handles.mibRecentDirsPopup.String;
if isempty(listStr); return; end
val = handles.mibRecentDirsPopup.Value;
selectedDir = listStr{val};
handles.mibPathEdit.String = selectedDir;
mibPathEdit_Callback(handles.mibPathEdit, eventdata, handles);
end

function mibSegmentationTable_cm_Callback(hObject, ~, parameter)
% a callback for context menu for handles.mibSegmentationTable_cm
handles = guidata(hObject);
if isstruct(parameter)   % call from the Models menu entry
    parameter = 'statistics';
end
handles.mibController.mibSegmentationTable_cm_Callback(hObject, parameter);
end

function mibPixelInfo_Callback(hObject, ~, parameter)
% a context menu for handles.mibPixelInfoText
handles = guidata(hObject);
handles.mibController.mibPixelInfo_Callback(parameter);
end

function mibLogBtn_Callback(~, ~, handles)
% --- Executes on button press in handles.mibLogBtn.
handles.mibController.startController('mibLogListController');
end

function mibInfoBtn_Callback(~, ~, handles)
% --- Executes on button press in handles.mibInfoBtn
handles.mibController.startController('mibDatasetInfoController');
end

function mibZoomEdit_Callback(~, ~, handles)
% callback for handles.mibZoomEdit - change of the magnification value
handles.mibController.mibZoomEdit_Callback();
end

%% --------------------- DIRECTORY CONTENTS PANEL CALLBACKS ---------------------
function mibBufferToggle_Callback(~, ~, handles, Id)
% --- Executes on button press in mibBufferToggle1.
handles.mibController.mibBufferToggle_Callback(Id);
end

function mibBufferToggleContext_Callback(hObject, ~, parameter, buttonID)
% callback for the context menu of the handles.mibBufferToggle
handles = guidata(hObject);
handles.mibController.mibBufferToggleContext_Callback(parameter, buttonID);
end

function mibFilesListbox_Callback(~, ~, handles)
% --- Executes on selection change in mibFilesListbox.
handles.mibController.mibFilesListbox_Callback();
end

function mibFilesListbox_cm_Callback(hObject, ~, parameter)
% callback for the context menu of handles.mibFilesListbox
handles = guidata(hObject);
handles.mibController.mibFilesListbox_cm_Callback(parameter);
end

function mibFileFilterPopup_cm(hObject, ~, parameter)
% callback for the context menu of handles.mibFileFilterPopup
handles = guidata(hObject);
handles.mibController.mibFileFilterPopup_cm(parameter);
end


function mibPathEdit_cm_Callback(hObject, ~, parameter)
handles = guidata(hObject);
switch parameter
    case 'clipboard'
        clipboard('copy', handles.mibPathEdit.String);
    case 'fileexplorer'
        if isdir(handles.mibPathEdit.String)
            if ispc
                system(sprintf('explorer.exe "%s"', handles.mibPathEdit.String));
            elseif ismac
                system(sprintf('open %s &', handles.mibPathEdit.String));
            else
                unix(sprintf('xterm -e cd %s &', handles.mibPathEdit.String));
            end
        else
            errordlg(sprintf('Wrong directory!\n\n%s', handles.mibPathEdit.String));
        end
end

end

function mibFileFilterPopup_Callback(~, ~, handles)
% --- Executes on selection change in mibFileFilterPopup.
handles.mibController.updateFilelist();
end

function mibUpdatefilelistBtn_Callback(~, ~, handles)
% --- Executes on button press in mibUpdatefilelistBtn.
handles.mibController.updateFilelist();
end

function mibBioformatsCheck_Callback(~, ~, handles)
% --- Executes on button press in mibBioformatsCheck.
handles.mibController.mibBioformatsCheck_Callback();
end

% --- Executes on selection change in mibMainPanelPopup.
function mibMainPanelPopup_Callback(~, ~, handles)
% update panels after mibMainPanelPopup change, i.e. selection of either
% Segmentation or ROI panel
pos = handles.mibMainPanelPopup.Value;  % get selected panel id
switch pos
    case 1  % Segmentation
        handles.mibSegmentationPanel.Visible = 'on';
        handles.mibRoiPanel.Visible = 'off';
    case 2  % ROI
        handles.mibSegmentationPanel.Visible = 'off';
        handles.mibRoiPanel.Visible = 'on';
end
end

% --- Executes on selection change in mibFilterTypePopup.
function mibFilterTypePopup_Callback(~, ~, handles)
% update panels after mibFilterTypePopup change
pos = handles.mibFilterTypePopup.Value;
fulllist = handles.mibFilterTypePopup.String;
text_str = fulllist{pos};
handles.mibMaskGeneratorsPanel.Visible = 'off';
handles.mibFijiPanel.Visible = 'off';
handles.mibImageFiltersPanel.Visible = 'off';

switch text_str
    case 'Image Filters'
        handles.mibImageFiltersPanel.Visible = 'on';
    case 'Mask generators'
        handles.mibMaskGeneratorsPanel.Visible = 'on';
    case 'Fiji connect'  % connect to Fiji
        handles.mibFijiPanel.Visible = 'on';
end
end

%% --------------------- IMAGE VIEW PANEL CALLBACKS ---------------------
function mibChangeLayerSlider_Callback(hObject, ~, handles)
% callback for change of displayed z value using handles.mibChangeLayerSlider
if round(hObject.Value) == str2double(handles.mibChangeLayerEdit.String)    % return is slider value was not changed
    return;
end
handles.mibController.mibChangeLayerSlider_Callback();
end

function mibChangeLayerEdit_Callback(hObject, ~, handles) %#ok<*DEFNU>
% a callback for change of displayed z value using handles.mibChangeLayerEdit
switch hObject.Tag
    case 'mibChangeLayerEdit'   % callback for update of handles.mibChangeLayerEdit
        handles.mibController.mibChangeLayerEdit_Callback();
    case 'mibFirstSliceBtn'     % callback for update of handles.mibFirstSliceBtn
        handles.mibController.mibChangeLayerEdit_Callback(1);
    case 'mibLastSliceBtn'      % callback for update of handles.mibLastSliceBtn
        handles.mibController.mibChangeLayerEdit_Callback(0);
end
end

function mibChangeLayerSliderContext_cb(hObject, ~, parameter)
% a context menu for handles.mibChangeLayerSlider
handles = guidata(hObject);
switch parameter
    case 'def'  % set brightness on the screen to be the same as in the image
        options.sliderStep = 1;     % parameters for slider movement
        options.sliderShiftStep = 10;
    case 'set'
        options = handles.mibChangeLayerSlider.UserData;
        prompt = {'Enter step for use with arrows or Q/W buttons:', 'Enter step for use with Shift+arrows or Shift+Q/W buttons:'};
        defAns = {num2str(options.sliderStep),num2str(options.sliderShiftStep)};
        mibInputMultiDlgOpt.PromptLines = [1, 2];
        answer = mibInputMultiDlg([], prompt, defAns, 'Set step...', mibInputMultiDlgOpt);
        if isempty(answer); return; end

        options.sliderStep = round(str2double(cell2mat(answer(1))));     % parameters for slider movement
        options.sliderShiftStep = round(str2double(cell2mat(answer(2))));
end
handles.mibChangeLayerSlider.UserData = options;
guidata(handles.mibGUI, handles);
end

function mibChangeTimeSlider_Callback(hObject, ~, handles)
% callback for change of displayed time point using handles.mibChangeTimeSlider
if round(hObject.Value) == str2double(handles.mibChangeLayerEdit.String)    % return is slider value was not changed
    return;
end
handles.mibController.mibChangeTimeSlider_Callback();
end

function mibChangeTimeEdit_Callback(hObject, ~, handles)
% callback for change of displayed time point using handles.mibChangeTimeEdit
switch hObject.Tag
    case 'mibChangeTimeEdit'   % callback for update of handles.mibChangeTimeSlider
        handles.mibController.mibChangeTimeEdit_Callback();
    case 'mibFirstTimeBtn'     % callback for update of handles.mibFirstTimeBtn
        handles.mibController.mibChangeTimeEdit_Callback(1);
    case 'mibLastTimeBtn'      % callback for update of handles.mibLastTimeBtn
        handles.mibController.mibChangeTimeEdit_Callback(0);
end
end

function mibChangeTimeSliderContext_cb(hObject, ~, parameter)
% a context menu for handles.mibChangeTimeSlider
handles = guidata(hObject);
switch parameter
    case 'def'  % set brightness on the screen to be the same as in the image
        options.sliderStep = 1;     % parameters for slider movement
        options.sliderShiftStep = 10;
    case 'set'
        options = handles.mibChangeTimeSlider.UserData;
        prompt = {'Enter step for use with arrows or Q/W buttons:','Enter step for use with Shift+arrows or Shift+Q/W buttons:'};
        defAns = {num2str(options.sliderStep),num2str(options.sliderShiftStep)};
        mibInputMultiDlgOpt.PromptLines = [1, 2];
        answer = mibInputMultiDlg([], prompt, defAns, 'Set step...', mibInputMultiDlgOpt);
        if isempty(answer); return; end
        
        options.sliderStep = round(str2double(cell2mat(answer(1))));     % parameters for slider movement
        options.sliderShiftStep = round(str2double(cell2mat(answer(2))));
end
handles.mibChangeTimeSlider.UserData = options;
guidata(handles.mibGUI, handles);
end

%% --------------------- SEGMENTATION PANEL CALLBACKS ---------------------
function mibCreateModelBtn_Callback(~, ~, handles)
% --- Executes on button press in mibCreateModelBtn.
handles.mibController.mibCreateModelBtn_Callback();
end

function mibLoadModelBtn_Callback(~, ~, handles)
% --- Executes on button press in mibLoadModelBtn.
handles.mibController.mibLoadModelBtn_Callback();
end

function mibAddMaterialBtn_Callback(~, ~, handles)
% --- Executes on button press in mibAddMaterialBtn.
handles.mibController.mibAddMaterialBtn_Callback();
end

function mibRemoveMaterialBtn_Callback(~, ~, handles)
% --- Executes on button press in mibRemoveMaterialBtn.
handles.mibController.mibRemoveMaterialBtn_Callback();
end

function mibSegmentationTable_CellSelectionCallback(~, eventdata, handles)
% --- Executes when selected cell(s) is changed in mibSegmentationTable.
handles.mibController.mibSegmentationTable_CellSelectionCallback(eventdata);
end

function mibSegmSelectedOnlyCheck_Callback(~, ~, handles)
handles.mibController.mibSegmSelectedOnlyCheck_Callback();
end

function mibSegmFavToolCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibSegmFavToolCheck.
handles.mibController.mibSegmFavToolCheck_Callback();
end

function mibMaskedAreaCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibMaskedAreaCheck.
handles.mibController.mibMaskedAreaCheck_Callback();
end

% --- Executes on selection change in mibSegmentationToolPopup.
function mibSegmentationToolPopup_Callback(~, ~, handles)
handles.mibController.mibSegmentationToolPopup_Callback();
mibFilterSelectionPopup_Callback(handles.mibFilterSelectionPopup, [], handles);
end

% --- Executes when mibGUI is resized.
function mibGUI_SizeChangedFcn(hObject, eventdata, handles)
if ~isfield(handles, 'mibController'); return; end
handles.mibController.mibGUI_SizeChangedFcn()
end

function mibGUI_moveLayers(hObject, ~, ~, obj_type_from, obj_type_to, layers_id, action_type)
% move data between layers, a callback to the context menu of mibSegmentationTable
handles = guidata(hObject);
handles.mibController.mibModel.moveLayers(obj_type_from, obj_type_to, layers_id, action_type);
end

function mibEraserEdit_Callback(hObject, eventdata, handles)
% callback for update of handles.mibEraserEdit to change size of magnifier
% of the erase tool
handles.mibController.mibEraserEdit_Callback();
end

% --- Executes on button press in mibBrushPanelInterpolationSettingsBtn.
function mibBrushPanelInterpolationSettingsBtn_Callback(hObject, eventdata, handles)
handles.mibController.mibBrushPanelInterpolationSettingsBtn_Callback();
end

function mibBrushSuperpixelsWatershedCheck_Callback(hObject, eventdata, handles)
handles.mibController.mibBrushSuperpixelsWatershedCheck_Callback(hObject);
end

function mibBrushSuperpixelsEdit_Callback(hObject, eventdata, handles)
handles.mibController.mibBrushSuperpixelsEdit_Callback(hObject);
end

function mibSegmLabelsBtn_Callback(hObject, eventdata, handles, controllerId)
% --- Executes on button press in mibSegmLabelsBtn and mibSegmLines3DTableViewButton
switch controllerId
    case 'mibAnnotationsController'
        handles.mibController.startController('mibAnnotationsController');
        handles.mibShowAnnotationsCheck.Value = 1;
    case 'mibLines3DController'
        handles.mibController.startController('mibLines3DController');
end
end

% --- Executes on selection change in mibAnnMarkerEdit.
function mibAnnMarkerEdit_Callback(hObject, eventdata, handles)
handles.mibController.mibAnnMarkerEdit_Callback();
end

% --- Executes on button press in mibSegmAnnDeleteAllBtn.
function mibSegmAnnDeleteAllBtn_Callback(hObject, eventdata, handles)
handles.mibController.mibSegmAnnDeleteAllBtn_Callback();
end

function mibSegmentationBW_Update(hObject, eventdata, handles)
% function mibSegmentationBW_Update(hObject, eventdata, handles)
% do black and white thresholding
handles = guidata(hObject);
if strcmp(hObject.Tag, 'mibSegmBWthres4D')
    if hObject.Value == 1
        button = questdlg(sprintf('!!! Warning !!!\n\nYou are going to do black-and-white thresholding over complete dataset\nThis may take a lot of time, are you sure?'),'Warning','Continue','Cancel','Cancel');
        if strcmp(button, 'Cancel'); hObject.Value = 0; return; end
    end
end

% uncheck the 3D box
if strcmp(hObject.Tag, 'mibSegmBWthres3D') && handles.mibSegmBWthres4D.Value == 1 && hObject.Value == 1
    handles.mibSegmBWthres4D.Value = 0;
end

handles.mibController.mibSegmentationBlackWhiteThreshold(hObject.Tag);
handles.mibController.plotImage();
unFocus(hObject);   % remove focus from hObject
end

function mibChangeThresholdValueContext_cb(hObject, eventdata, parameter)
handles = guidata(hObject);
global mibPath;
switch parameter
    case 'def'  % set brightness on the screen to be the same as in the image
        handles.mibSegmLowSlider.SliderStep = [0.01 0.1];
        handles.mibSegmHighSlider.SliderStep = [0.01 0.1];
    case 'set'
        sliderStep = handles.mibSegmLowSlider.SliderStep;
        prompt = {'Enter step the step for the slider:'};
        
        if strcmp(handles.menuImage8bit.Checked, 'on')
            maxVal = 255;
        elseif strcmp(handles.menuImage16bit.Checked, 'on')
            maxVal = 65535;
        else
            maxVal = 4294967295;
        end
        defaultAnswer = {num2str(round(sliderStep(1)*maxVal))};
        answer = mibInputDlg({mibPath}, prompt, 'Set step...', defaultAnswer);
        if isempty(answer); return; end;
        
        if str2double(answer{1})/maxVal > 1 || str2double(answer{1}) <= 0
            errordlg(sprintf('The step should be between 1 and %d!', maxVal),'Wrong step!');
            return;
        end
        handles.mibSegmLowSlider.SliderStep = [str2double(answer{1})/maxVal str2double(answer{1})/maxVal*10];
        handles.mibSegmHighSlider.SliderStep = [str2double(answer{1})/maxVal str2double(answer{1})/maxVal*10];
end
end

% --- Executes on button press in mibSegmObjectPickerPanelSub2Manual.
function mibSegmObjectPickerPanelSub2Manual_Callback(hObject, eventdata, handles)
if hObject.Value == 1 && strcmp(hObject.Enable, 'on')
    handles.mibSegmObjectPickerPanelSub2Select.Enable = 'on';
    handles.mibSegmObjectPickerPanelSub2X1.Enable = 'on';
    handles.mibSegmObjectPickerPanelSub2Y1.Enable = 'on';
    handles.mibSegmObjectPickerPanelSub2Width.Enable = 'on';
    handles.mibSegmObjectPickerPanelSub2Height.Enable = 'on';
    handles.mibSegmObjectPickerPanelSub2Select.Enable = 'on';
else
    handles.mibSegmObjectPickerPanelSub2Select.Enable = 'off';
    handles.mibSegmObjectPickerPanelSub2X1.Enable = 'off';
    handles.mibSegmObjectPickerPanelSub2Y1.Enable = 'off';
    handles.mibSegmObjectPickerPanelSub2Width.Enable = 'off';
    handles.mibSegmObjectPickerPanelSub2Height.Enable = 'off';
    handles.mibSegmObjectPickerPanelSub2Select.Enable = 'off';
end
end

% --- Executes on button press in mibSegmObjectPickerPanelSub2Select.
function mibSegmObjectPickerPanelSub2Select_Callback(hObject, eventdata, handles)
modifier = '';
if handles.mibSegmObjectPickerPanelAddPopup.Value == 2
    modifier = 'control';
end
handles.mibController.mibSegmentationLassoManual(modifier);
end


function mibFilterSelectionPopup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in mibFilterSelectionPopup.
curList = handles.mibFilterSelectionPopup.String;
if strcmp(curList{handles.mibFilterSelectionPopup.Value}, 'Rectangle')
    handles.mibSegmObjectPickerPanelSub2Manual.Enable = 'on';
else
    handles.mibSegmObjectPickerPanelSub2Manual.Enable = 'off';
end

if ismember(curList{handles.mibFilterSelectionPopup.Value}, {'Lasso','Rectangle','Ellipse','Polyline'})
    handles.mibSegmObjectPickerPanelAddPopup.Enable = 'on';
else
    handles.mibSegmObjectPickerPanelAddPopup.Enable = 'off';
end
mibSegmObjectPickerPanelSub2Manual_Callback(handles.mibSegmObjectPickerPanelSub2Manual, eventdata, handles);
end

function mibSegmObjectPickerPanelAddPopup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in mibSegmObjectPickerPanelAddPopup.
if handles.mibSegmObjectPickerPanelAddPopup.Value == 1
    handles.mibSegmObjectPickerPanelSub2Select.String = 'Select';
else
    handles.mibSegmObjectPickerPanelSub2Select.String = 'Unselect';
end
end

function mibMagicwandConnectCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibMagicwandConnectCheck.
val = hObject.Value;
handles.mibMagicwandConnectCheck.Value = 0;
handles.mibMagicwandConnectCheck4.Value = 0;
hObject.Value = val;
end

% --- Executes on selection change in mibMagicwandMethodPopup.
function mibMagicwandMethodPopup_Callback(hObject, eventdata, handles)
if handles.mibMagicwandMethodPopup.Value == 1   % magic wand
    handles.mibMagicUpThresEdit.Visible = 'on';
    handles.mibMagicdashTxt.Visible = 'on';
else        % region growing
    handles.mibMagicUpThresEdit.Visible = 'off';
    handles.mibMagicdashTxt.Visible = 'off';
end
end


% --- Executes on button press in mibSegmDragDropShift buttons.
function mibSegmDragDropShift_Callback(hObject, eventdata, handles)
modifier = handles.mibGUI.CurrentModifier;   % change size of the brush tool, when the Ctrl key is pressed
if isempty(modifier); modifier = ''; end
shift = str2double(handles.mibSegmDragDropShift.String);
dX = 0;
dY = 0;
switch hObject.Tag
    case 'mibSegmDragDropShiftLeft'
        dX = -shift;
    case 'mibSegmDragDropShiftRight'
        dX = shift;
    case 'mibSegmDragDropShiftUp'
        dY = -shift;
    case 'mibSegmDragDropShiftDown'
        dY = shift;
end

if handles.mibActions3dCheck.Value == 1 || strcmp(modifier, 'shift')
    handles.mibController.mibGUI_WindowButtonUpDragAndDropFcn('3D, Stack', dX, dY);
else
    handles.mibController.mibGUI_WindowButtonUpDragAndDropFcn('2D, Slice', dX, dY);
end
end

%% --------------------- ROI PANEL CALLBACKS ---------------------
function mibRoiAddBtn_Callback(~, ~, handles)
% --- Executes on button press in mibRoiAddBtn.
handles.mibController.mibRoiAddBtn_Callback();
end

function mibRoiRemoveBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiRemoveBtn.
handles.mibController.mibRoiRemoveBtn_Callback();
end

function mibRoiShowCheck_Callback(~, ~, handles)
% --- Executes on button press in mibRoiShowCheck.
handles.mibController.mibRoiShowCheck_Callback();
end

function mibRoiTypePopup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in mibRoiTypePopup.
val = handles.mibRoiTypePopup.Value;

handles.mibRoiManualCheck.Visible = 'on';
handles.mibManuallyROIText1.Visible = 'on';
handles.mibManuallyROIText2.Visible = 'on';
handles.mibRoiWidthTxt.Visible = 'on';
handles.mibRoiHeightTxt.Visible = 'on';
handles.mibRoiX1Edit.Visible = 'on';
handles.mibRoiY1Edit.Visible = 'on';
handles.mibRoiWidthEdit.Visible = 'on';
handles.mibRoiHeightEdit.Visible = 'on';

if val == 1 || val == 2 % rectangle or ellipse
    handles.mibManuallyROIText2.String = 'Y1:';
    if handles.mibRoiManualCheck.Value
        handles.mibRoiY1Edit.Enable = 'on';
    else
        handles.mibRoiY1Edit.Enable = 'off';
    end
elseif val == 3 % polyline
    handles.mibManuallyROIText2.String = 'Number of vertices:';
    handles.mibRoiY1Edit.String = '5';
    handles.mibRoiY1Edit.Enable = 'on';
    handles.mibRoiManualCheck.Visible = 'off';
    handles.mibManuallyROIText1.Visible = 'off';
    handles.mibManuallyROIText2.Visible = 'on';
    handles.mibRoiWidthTxt.Visible = 'off';
    handles.mibRoiHeightTxt.Visible = 'off';
    handles.mibRoiX1Edit.Visible = 'off';
    handles.mibRoiY1Edit.Visible = 'on';
    handles.mibRoiWidthEdit.Visible = 'off';
    handles.mibRoiHeightEdit.Visible = 'off';
elseif val == 4 % freehand
    handles.mibRoiManualCheck.Visible = 'off';
    handles.mibManuallyROIText1.Visible = 'off';
    handles.mibManuallyROIText2.Visible = 'off';
    handles.mibRoiWidthTxt.Visible = 'off';
    handles.mibRoiHeightTxt.Visible = 'off';
    handles.mibRoiX1Edit.Visible = 'off';
    handles.mibRoiY1Edit.Visible = 'off';
    handles.mibRoiWidthEdit.Visible = 'off';
    handles.mibRoiHeightEdit.Visible = 'off';
end
end

function mibRoiManualCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiManualCheck.
if handles.mibRoiManualCheck.Value
    handles.mibRoiX1Edit.Enable = 'on';
    handles.mibRoiY1Edit.Enable = 'on';
    handles.mibRoiWidthEdit.Enable = 'on';
    handles.mibRoiHeightEdit.Enable ='on';
else
    handles.mibRoiX1Edit.Enable = 'off';
    handles.mibRoiY1Edit.Enable = 'off';
    handles.mibRoiWidthEdit.Enable = 'off';
    handles.mibRoiHeightEdit.Enable = 'off';
end
end

function mibRoiList_Callback(hObject, eventdata, handles)
% --- Executes on selection change in mibRoiList.
% show selected ROI
handles.mibRoiShowCheck.Value = 1;
handles.mibController.mibRoiShowCheck_Callback();
end

function mibRoiToSelectionBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiToSelectionBtn.
handles.mibController.mibRoiToSelectionBtn_Callback();
end

function mibRoiShowLabelCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiShowLabelCheck.
handles.mibController.mibRoiShowCheck_Callback();
end

function mibRoiOptionsBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiOptionsBtn.
handles.mibController.mibRoiOptionsBtn_Callback();
end


function mibRoiLoadBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiLoadBtn.
handles.mibController.mibRoiLoadBtn_Callback();
end

function mibRoiSaveBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibRoiSaveBtn.
handles.mibController.mibRoiSaveBtn_Callback();
end

function mibRoiList_cm_Callback(hObject, ~, parameter)
% a callback for context menu of handles.mibRoiList
handles = guidata(hObject);
handles.mibController.mibRoiList_cm_Callback(parameter);
end

%% --------------------- SELECTION PANEL CALLBACKS ---------------------
function mibSelectionClearBtn_Callback(~, ~, handles)
% --- Executes on button press in mibSelectionClearBtn.
handles.mibController.mibSelectionClearBtn_Callback();
end

function mibSelectionFillBtn_Callback(~, ~, handles)
% --- Executes on button press in mibSelectionFillBtn.
handles.mibController.mibSelectionFillBtn_Callback();
end

function mibSelectionErodeBtn_Callback(~, ~, handles)
% --- Executes on button press in mibSelectionErodeBtn.
handles.mibController.mibSelectionErodeBtn_Callback();
end

function mibSelectionDilateBtn_Callback(~, ~, handles)
% --- Executes on button press in mibSelectionDilateBtn.
handles.mibController.mibSelectionDilateBtn_Callback();
end

function mibSelectionButton_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibSelectionAddBtn.
switch hObject.Tag
    case 'mibSelectionAddBtn'
        action = 'add';
    case 'mibSelectionSubtractBtn'
        action = 'subtract';
    case 'mibSelectionReplaceBtn'
        action = 'replace';
end
handles.mibController.mibSelectionButton_Callback(action);
end

function mibActions3dCheck_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibActions3dCheck.
if handles.mibActions3dCheck.Value == 1
    BatchOpt.Checkbox3D = {'Checked'};
else
    BatchOpt.Checkbox3D = {'Unchecked'};
end
handles.mibController.mibSelectionPanelCheckboxes(BatchOpt);
end

% --- Executes on button press in mibAdaptiveDilateCheck.
function mibAdaptiveDilateCheck_Callback(hObject, eventdata, handles)
% Enable/disable adaptive coefficient edit box
if handles.mibAdaptiveDilateCheck.Value == 1
    handles.mibDilateAdaptCoefEdit.Enable = 'on';
    handles.mibAdaptiveSmoothCheck.Enable = 'on';
else
    handles.mibDilateAdaptCoefEdit.Enable = 'off';
    handles.mibAdaptiveSmoothCheck.Enable = 'off';
end
end


% --- Executes on selection change in mibColChannelCombo.
function mibColChannelCombo_Callback(hObject, eventdata, handles)
% update selected color channel
handles.mibController.mibColChannelCombo_Callback();
end

%% --------------------- VIEW SETTINGS PANEL CALLBACKS ---------------------
function mibLutCheckbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibLutCheckbox.
handles.mibController.mibLutCheckbox_Callback();
end

function mibChannelMixerTable_Callback(hObject, eventdata, handles, type)
% a callback for the context menu of handles.mibChannelMixerTable
handles = guidata(hObject);
handles.mibController.mibChannelMixerTable_Callback(type);
end

function mibChannelMixerTable_CellEditCallback(hObject, eventdata, handles)
% --- Executes when entered data in editable cell(s) in mibChannelMixerTable.
% hObject    handle to mibChannelMixerTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

Indices = eventdata.Indices;
PreviousData = eventdata.PreviousData;
modifier = handles.mibGUI.CurrentModifier;
handles.mibController.mibChannelMixerTable_CellEditCallback(Indices, PreviousData, modifier);

end


function mibChannelMixerTable_CellSelectionCallback(hObject, eventdata, handles)
% --- Executes when selected cell(s) is changed in mibChannelMixerTable.
% hObject    handle to mibChannelMixerTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

Indices = eventdata.Indices;
handles.mibController.mibChannelMixerTable_CellSelectionCallback(Indices);
end

function mibMaskShowCheck_Callback(~, ~, handles)
% --- Executes on button press in mibMaskShowCheck.
handles.mibController.mibMaskShowCheck_Callback();
end

function mibModelShowCheck_Callback(~, ~, handles)
% --- Executes on button press in mibModelShowCheck.
handles.mibController.mibModelShowCheck_Callback();
end

% --- Executes on button press in mibHideImageCheck.
function mibModelPropertyUpdate(hObject, eventdata, handles, parameter)
% update switches in the obj.mibModel class that describe states of GUI
% widgets
% parameter: a string with the parameter name
handles.mibController.mibModelPropertyUpdate(parameter);
end

% --- Executes on button press in mibLiveStretchCheck.
function mibLiveStretchCheck_Callback(hObject, eventdata, handles)

end

function imageRedraw(hObject, eventdata, handles)
% redraw image in the handles.mibImageAxes after press of
% handles.mibHideImageCheck or transparency sliders

handles = guidata(hObject);     % get handles for listeners
handles.mibController.imageRedraw();
end

function mibDisplayBtn_Callback(~, ~, handles)
% --- Executes on button press in mibDisplayBtn.
handles.mibController.startController('mibImageAdjController');
end

function mibAutoBrightnessBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibAutoBrightnessBtn.
handles.mibController.mibAutoBrightnessBtn_Callback();
end

%% --------------------- IMAGE FILTERS PANEL CALLBACKS ---------------------
function mibImageFilterPopup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in mibImageFilterPopup.
returnFromFrangi = handles.mibImfiltPar4Edit.Enable;

handles.mibImageFilterDoitBtn.Enable = 'on';

% change type of image filter
handles.mibImageFiltersTypePopup.Enable = 'off';
handles.mibImfiltPar1Edit.Enable = 'on';
handles.mibImfiltPar2Edit.Enable = 'on';
handles.mibImfiltPar3Edit.Enable = 'off';
handles.mibImfiltPar4Edit.Enable = 'off';
handles.mibImfiltPar5Edit.Enable = 'off';
handles.mibImageFilters3DCheck.Enable = 'off';
handles.mibImfiltPar1Edit.TooltipString = 'Kernel size in pixels, use two semicolon separated numbers for custom kernels';
handles.mibImfiltPar2Edit.TooltipString = '';
handles.mibImageFiltersTypeText.String = 'Type:';
%handles.coherenceFilterPanel.Visible = 'off';

% replace 512 with 3 when switching from DNN to other filters
if strcmp(handles.mibImfiltPar1Edit.String, '512');    handles.mibImfiltPar1Edit.String = '3'; end

selval = handles.mibImageFilterPopup.Value;
list = handles.mibImageFilterPopup.String;
selfilter = cell2mat(list(selval));

if strcmp(returnFromFrangi, 'on')   % reinitialize default values when returning back from Frangi filter
    handles.mibImfiltPar1Edit.String = '3';
    handles.mibImfiltPar2Edit.String = '0.6';
    handles.mibImfiltPar3Edit.String = '0.25';
end

switch selfilter
    case {'Gaussian'}
        handles.mibImageFiltersHSizeText.String = 'HSize:';
        handles.mibImageFiltersSigmaText.String = 'Sigma:';
        handles.mibImfiltPar2Edit.String = '0.6';
        handles.mibImageFilters3DCheck.Enable = 'on';
    case 'DNN Denoise'
        handles.mibImageFiltersHSizeText.String = 'GPU block:';
        handles.mibImfiltPar1Edit.TooltipString = 'Define size of the block in pixels to fit into GPU memory';
        handles.mibImfiltPar1Edit.String = '512';
        handles.mibImfiltPar2Edit.Enable = 'off';
    case 'Unsharp'
            handles.mibImageFiltersHSizeText.String = 'Radius:';
            handles.mibImageFiltersSigmaText.String = 'Amount:';
            handles.mibImageFiltersLambdaText.String = 'Threshold:';
            handles.mibImfiltPar3Edit.Enable = 'on';
            handles.mibImfiltPar1Edit.TooltipString = 'Standard deviation of the Gaussian lowpass filter, float';
            handles.mibImfiltPar2Edit.TooltipString = 'Strength of the sharpening effect, float [0-2]';
            handles.mibImfiltPar3Edit.TooltipString = 'Minimum contrast required for a pixel to be considered an edgepixel, specified as a float in the range [0 1]';
    case 'Motion'
        handles.mibImageFiltersHSizeText.String = 'Length:';
        handles.mibImageFiltersSigmaText.String = 'Angle:';
    case {'Average', 'Disk', 'Median', 'Wiener'}
        handles.mibImageFiltersHSizeText.String = 'HSize:';
        handles.mibImfiltPar2Edit.Enable = 'off';
        if strcmp(selfilter, 'Median')
            handles.mibImageFilters3DCheck.Enable = 'on';
            handles.mibImageFiltersTypeText.String = 'Padding:';
            handles.mibImageFiltersTypePopup.String = {'replicate', 'symmetric', 'zeros'};
            handles.mibImageFiltersTypePopup.Enable = 'on';
        end
    case 'Gradient'
        handles.mibImfiltPar1Edit.Enable = 'off';
        handles.mibImfiltPar2Edit.Enable = 'off';
        handles.mibImageFilters3DCheck.Enable = 'on';
    case 'Frangi'
        handles.mibImageFiltersHSizeText.String = 'Range';
        handles.mibImfiltPar1Edit.String = '1-6';
        handles.mibImfiltPar1Edit.TooltipString = 'The range of sigmas used, default [1-6]';
        handles.mibImageFiltersSigmaText.String = 'Ratio';
        handles.mibImfiltPar2Edit.String = '2';
        handles.mibImfiltPar2Edit.TooltipString = 'Step size between sigmas, default 2';
        handles.mibImageFiltersLambdaText.String = 'beta1';
        handles.mibImfiltPar3Edit.String = '0.9';
        handles.mibImfiltPar3Edit.Enable = 'on';
        handles.mibImfiltPar4Edit.Enable = 'on';
        handles.mibImageFiltersTypePopup.Enable = 'On';
        handles.mibImageFiltersTypePopup.Value = min([handles.mibImageFiltersTypePopup.Value 2]); 
        handles.mibImageFiltersTypePopup.String = {'Black on White','White on Black'};
        handles.mibImageFiltersTypePopup.TooltipString = 'black-on-white for EM images; white-on-black for LM images';
        handles.mibImageFilters3DCheck.Enable = 'on';
    case 'Laplacian'
        handles.mibImageFiltersSigmaText.String = 'Alpha:';
        handles.mibImfiltPar2Edit.String = '0.5';
        handles.mibImfiltPar1Edit.Enable = 'off';
    case 'Perona Malik anisotropic diffusion'
        handles.mibImfiltPar1Edit.TooltipString = 'Number of Iterations';
        handles.mibImfiltPar2Edit.TooltipString = 'Edge-stopping parameter (4% of the image''s range is a good start). Default=4';
        handles.mibImfiltPar3Edit.TooltipString = 'Diffusion step (<1, smaller + more iterations = more accurate). Default=0.25';
        handles.mibImageFiltersHSizeText.String = 'Iter:';
        handles.mibImageFiltersSigmaText.String = 'K (%):';
        handles.mibImfiltPar3Edit.Enable = 'on';
        handles.mibImfiltPar3Edit.TooltipString = 'Diffusion step (<1, smaller + more iterations = more accurate). Default=0.25';
        handles.mibImfiltPar2Edit.String = '4';
        handles.mibImageFiltersTypePopup.Enable = 'on';
        handles.mibImageFiltersTypePopup.Value = min([handles.mibImageFiltersTypePopup.Value 2]);
        handles.mibImageFiltersTypePopup.String = {'Edges','Regions'};
        handles.mibImageFiltersTypePopup.TooltipString = 'Edges: favours high contrast edges over low contrast ones; Region: favours wide regions over smaller ones';
    case 'External: BMxD'
        if isempty(handles.mibController.mibModel.preferences.dirs.bm3dInstallationPath) || exist(fullfile(handles.mibController.mibModel.preferences.dirs.bm3dInstallationPath, 'BM3D.m'), 'file') ~= 2
            handles.mibImageFilterDoitBtn.Enable = 'off';
        else
            res = which('bm4d');
            if ~isempty(res)
                handles.mibImageFilters3DCheck.Enable = 'on';
            end
            handles.mibImageFiltersTypePopup.Enable = 'on';
            handles.mibImageFiltersSigmaText.String = 'K (%)';
            handles.mibImfiltPar2Edit.String = '6';
            if handles.mibImageFilters3DCheck.Value == 1
                handles.mibImageFiltersTypePopup.String = {'mp, Gauss: modified','mp, Rice: modified',...
                    'np, Gauss: normal', 'np, Rice: normal',...
                    'lc, Gauss: low complexity', 'lc, Rice: low complexity'};
                handles.mibImfiltPar1Edit.Enable = 'off';
            else
                handles.mibImageFiltersTypePopup.Value = min([handles.mibImageFiltersTypePopup.Value 2]);
                handles.mibImageFiltersTypePopup.String = {'np: normal','lc: low complexity'};
                handles.mibImfiltPar1Edit.Enable = 'off';
            end
            handles.mibImageFiltersTypePopup.TooltipString = 'filtering profile';
        end
%     case {'Edge Enhancing Coherence Filter'}
%         handles.mibImfiltPar1Edit.Enable = 'off';
%         handles.mibImfiltPar2Edit.Enable = 'off';
%         handles.mibImfiltPar3Edit.Enable = 'off';
%         handles.coherenceFilterPanel.Visible = 'on';
%     case 'Diplib: Perona Malik anisotropic diffusion'
%         handles.mibImfiltPar1Edit.TooltipString = 'Number of Iterations';
%         handles.mibImageFiltersHSizeText.String = 'Iter:';
%         handles.mibImageFiltersSigmaText.String = 'K:';
%         handles.mibImfiltPar2Edit.TooltipString = 'Edge-stopping parameter (4% of the image''s range is a good start). Default=10';
%         handles.mibImfiltPar3Edit.TooltipString = 'Diffusion step (<1, smaller + more iterations = more accurate). Default=0.25';
%     case 'Diplib: Robust Anisotropic Diffusion'
%         handles.mibImageFiltersHSizeText.String = 'Iter:';
%         handles.mibImageFiltersSigmaText.String = 'Sigma:';
%         handles.mibImfiltPar2Edit.TooltipString = 'Scale parameter on the psiFunction. Choose this number to be bigger than the noise but small than the real discontinuties. Default=20';
%         handles.mibImfiltPar3Edit.TooltipString = 'Rate parameter. To approximage a continuous-time PDE, make lambda small and increase the number of iterations. Default=0.25';
%     case {'Diplib: Mean Curvature Diffusion', 'Diplib: Corner Preserving Diffusion'}
%         handles.mibImageFiltersHSizeText.String = 'Iter:';
%         handles.mibImageFiltersSigmaText.String = 'Sigma:';
%         handles.mibImfiltPar3Edit.Enable = 'off';
%         handles.mibImfiltPar2Edit.TooltipString = 'For Gaussian derivative, should increase with noise level. Default=1';
%     case 'Diplib: Kuwahara filter for edge-preserving smoothing'
%         handles.mibImageFiltersHSizeText.String = 'Shape:';
%         handles.mibImfiltPar1Edit.TooltipString = 'filterShape: 1:rectangular, 2:elliptic, 3:diamond');
%         handles.mibImfiltPar3Edit.String = '2';
%         handles.mibImageFiltersSigmaText.String = 'Size:';
%         handles.mibImfiltPar3Edit.Enable = 'off';
end
mibImageFilters3DCheck_Callback(hObject, eventdata, handles);
mibImfiltPar1Edit_Callback(handles.mibImfiltPar1Edit, eventdata, handles);
end


% --- Executes on button press in mibImageFilters3DCheck.
function mibImageFilters3DCheck_Callback(hObject, eventdata, handles)
if strcmp(handles.mibImageFilters3DCheck.Enable, 'off')
    handles.mibImageFilters3DCheck.Value = 0;
    return;
end

selval = handles.mibImageFilterPopup.Value;
list = handles.mibImageFilterPopup.String;
selfilter = cell2mat(list(selval));

if handles.mibImageFilters3DCheck.Value == 1
    switch selfilter
        case 'Frangi'
            handles.mibImfiltPar5Edit.Enable = 'on';
            handles.mibImfiltPar3Edit.TooltipString = 'Frangi vesselness constant, treshold on Lambda2/Lambda3 determines if its a line(vessel) or a plane like structure, default .5;';
            handles.mibImfiltPar4Edit.TooltipString = 'Frangi vesselness constant, which determines the deviation from a blob like structure, default .5;';
            handles.mibImfiltPar5Edit.TooltipString = 'Frangi vesselness constant which gives the threshold between eigenvalues of noise and vessel structure. A thumb rule is dividing the the greyvalues of the vessels by 4 till 6';
        case 'External: BMxD'
            handles.mibImageFiltersTypePopup.String = {'mp, Gauss: modified','mp, Rice: modified',...
                    'np, Gauss: normal', 'np, Rice: normal',...
                    'lc, Gauss: low complexity', 'lc, Rice: low complexity'};
    end
    % update the mode from 2D to 3D when using the 3D filters
    if handles.mibImageFiltersModePopup.Value == 1
        handles.mibImageFiltersModePopup.Value = 2;
    end
else
    switch selfilter
        case 'Frangi'
            handles.mibImfiltPar5Edit.Enable = 'off';
            handles.mibImfiltPar3Edit.TooltipString = 'Frangi correction constant, default 0.5';
            handles.mibImfiltPar4Edit.TooltipString = 'Frangi correction constant, default 15';
        case 'External: BMxD'
            handles.mibImageFiltersTypePopup.Value = min([handles.mibImageFiltersTypePopup.Value 2]);
            handles.mibImageFiltersTypePopup.String = {'np: normal','lc: low complexity'};
    end
end
end

function mibImfiltPar1Edit_Callback(hObject, eventdata, handles)
% a call back for update of handles.mibImfiltPar1Edit
list = handles.mibImageFilterPopup.String;
val = handles.mibImageFilterPopup.Value;
switch cell2mat(list(val))
    case {'Gaussian', 'Average', 'Log', 'Wiener', 'Median'}
        editbox_Callback(handles.mibImfiltPar1Edit, eventdata, handles, 'posintx2', '3', [1,NaN]);
    case {'Disk','Motion'}
        editbox_Callback(handles.mibImfiltPar1Edit, eventdata, handles, 'pint', '3', [1,NaN]);
    case {'Unsharp'}
        editbox_Callback(handles.mibImfiltPar1Edit, eventdata, handles, 'pfloat', '1', [0.0001,NaN]);
    case {'Frangi'}
        editbox_Callback(handles.mibImfiltPar1Edit,eventdata,handles,'intrange','1-6');
        editbox_Callback(handles.mibImfiltPar2Edit,eventdata,handles,'pint','2',[1,NaN]);
        editbox_Callback(handles.mibImfiltPar3Edit,eventdata,handles,'pfloat', '0.9');
        editbox_Callback(handles.mibImfiltPar4Edit,eventdata,handles,'pfloat','15');
        editbox_Callback(handles.mibImfiltPar5Edit,eventdata,handles,'pint','500',[1,NaN]);
    case {'Perona Malik anisotropic diffusion','Diplib: Perona Malik anisotropic diffusion','Diplib: Robust Anisotropic Diffusion',...
            'Diplib: Mean Curvature Diffusion','Diplib: Corner Preserving Diffusion','Diplib: Kuwahara filter for edge-preserving smoothing'}
        editbox_Callback(handles.mibImfiltPar1Edit,eventdata,handles,'pint','10',[1,NaN]);
        editbox_Callback(handles.mibImfiltPar2Edit,eventdata,handles,'pint','10',[1,NaN]);
        editbox_Callback(handles.mibImfiltPar3Edit,eventdata,handles,'pfloat','.25',[0,NaN]);
end
end


function mibImfiltPar2Edit_Callback(hObject, eventdata, handles)
% a callback to the handles.mibImfiltPar2Edit, checks parameters for image filters

list = handles.mibImageFilterPopup.String;
val = handles.mibImageFilterPopup.Value;
switch cell2mat(list(val))
    case 'Unsharp'
        editbox_Callback(handles.mibImfiltPar2Edit,eventdata,handles,'pfloat','1.2',[0.001,10]);
    case 'External: BMxD'
        editbox_Callback(handles.mibImfiltPar2Edit,eventdata,handles,'pint', '4', [0,100]);
    otherwise
        editbox_Callback(handles.mibImfiltPar2Edit,eventdata,handles,'pfloat','1',[0.001,NaN]);
end
end


function mibImageFilterDoitBtn_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibImageFilterDoitBtn.
% start image filtering
handles.mibController.mibImageFilterDoitBtn_Callback();
end

%% --------------------- MASK GENERATOR PANEL CALLBACKS ---------------------
% --- Executes on selection change in mibMaskGenTypePopup.
function mibMaskGenTypePopup_Callback(hObject, eventdata, handles)

pos = handles.mibMaskGenTypePopup.Value;
fulllist = handles.mibMaskGenTypePopup.String;
text_str = fulllist{pos};
handles.mibFrangiPanel.Visible = 'off';
handles.mibStrelPanel.Visible = 'off';
handles.mibBwFilterPanel.Visible = 'off';
handles.mibMorphPanel.Visible = 'off';
handles.mibMaskGenPanel3DAllRadio.Enable = 'on';
handles.mibMaskGenBtn.Enable = 'on';
switch text_str
    case 'Frangi filter'
        handles.mibMaskGeneratorsPanel.Title = 'Mask generators (Frangi filter)';
        handles.mibFrangiPanel.Visible = 'on';
    case 'Strel filter'
        handles.mibMaskGeneratorsPanel.Title = 'Mask generators (Strel filter)';
        handles.mibStrelPanel.Visible = 'on';
    case 'BW thresholding'
        handles.mibMaskGeneratorsPanel.Title = 'Mask generators (BW threshold filter)';
        handles.mibBwFilterPanel.Visible = 'on';
        handles.mibMaskGenPanel3DAllRadio.Enable = 'off';
        handles.mibMaskGenPanel2DCurrentRadio.Value = 1;
        handles.mibMaskGenBtn.Enable = 'off';
    case 'Morphological filters'
        handles.mibMaskGeneratorsPanel.Title = 'Mask generators (Morphological filters)';
        handles.mibMorphPanel.Visible = 'on';
end

end

% --- Executes when mibMaskGenPanelModeRadioPanel is resized.
function mibMaskGenPanelModeRadioPanel_SizeChangedFcn(hObject, eventdata, handles)
% update settings for the filters
handles.mibFrangiBeta3.Enable = 'off';
handles.mibFrangiBeta1.TooltipString = 'Frangi correction constant, default 0.5';
handles.mibFrangiBeta2.TooltipString = 'Second Frangi correction constant, default 15';
handles.mibFrangiBeta1.String = '0.9';
handles.mibFrangiBeta2.String = '15';

switch eventdata.Source.SelectedObject.Tag
    case 'mibMaskGenPanel2DCurrentRadio'
        handles.mibMorphPanelConnectivityEdit.String = '4';
    case 'mibMaskGenPanel2DAllRadio'
        handles.mibMorphPanelConnectivityEdit.String = '4';
    case 'mibMaskGenPanel3DAllRadio'
        % Frangi
        handles.mibFrangiBeta3.Enable = 'on';
        handles.mibFangiBeta1.TooltipString = 'Frangi vesselness constant, 0 - a line (vessel) or 1 - a plane like structure, default 0.5';
        handles.mibFrangiBeta2.TooltipString = 'Frangi vesselness constant, which determines the deviation from a blob like structure, default .5;';
        handles.mibFrangiBeta1.String = '0';
        handles.mibFrangiBeta2.String = '1';
        handles.mibMorphPanelConnectivityEdit.String = '6';
end
end

% --- Executes on selection change in mibMorphPanelTypeSelectPopup.
function mibMorphPanelTypeSelectPopup_Callback(hObject, eventdata, handles)
currList = handles.mibMorphPanelTypeSelectPopup.String;
currValue = handles.mibMorphPanelTypeSelectPopup.Value;

handles.mibMorphPanelHThresholdEdit.Visible = 'off';
handles.mibMorphPanelHThresholdText.Visible = 'off';
handles.mibMorphPanelThresholdEdit.Visible = 'off';
handles.mibMorphPanelThresholdText.Visible = 'off';
switch currList{currValue}
    case {'H-maxima transform', 'H-minima transform'}
        handles.mibMorphPanelHThresholdEdit.Visible = 'on';
        handles.mibMorphPanelHThresholdText.Visible = 'on';
        handles.mibMorphPanelThresholdEdit.Visible = 'on';
        handles.mibMorphPanelThresholdText.Visible = 'on';
    case {'Extended-minima transform','Extended-maxima transform'}
        handles.mibMorphPanelThresholdEdit.Visible = 'on';
        handles.mibMorphPanelThresholdText.Visible = 'on';
end
end


% --- Executes on button press in mibMaskGenBtn.
function mibMaskGenBtn_Callback(hObject, eventdata, handles, type)
handles = guidata(hObject);
handles.mibController.mibMaskGenerator(type);
end


% --- Executes on button press in mibSegmThresPanelAdaptiveCheck.
function mibSegmThresPanelAdaptiveCheck_Callback(hObject, eventdata, handles)
if handles.mibSegmThresPanelAdaptiveCheck.Value == 1    % adaptive mode
    handles.mibSegmThresPanelAdaptivePopup.Enable = 'on';
    handles.mibSegmThresPanelAdaptiveInvert.Enable = 'on';
    handles.mibSegmThresPanelLowText.String = 'Sensibility:';
    handles.mibSegmThresPanelHighText.String = 'Width:';
    handles.mibSegmLowEdit.TooltipString = 'specify sensibility for adaptive thresholding';
    handles.mibSegmHighEdit.TooltipString = 'specify size of neighborhood used to compute local statistic around each pixel';
else
    handles.mibSegmThresPanelAdaptivePopup.Enable = 'off';
    handles.mibSegmThresPanelAdaptiveInvert.Enable = 'off';
    handles.mibSegmThresPanelLowText.String = 'Low:';
    handles.mibSegmThresPanelHighText.String = 'High:';
    handles.mibSegmLowEdit.TooltipString = 'specify the low limit for the thresholding:';
    handles.mibSegmHighEdit.TooltipString = 'specify the high limit for the thresholding';
end
end



%% --------------------- FIJI CONNECT PANEL CALLBACKS ---------------------
% --- Executes on button press in mibFijiSelectFileBtn.
function mibFijiSelectFileBtn_Callback(hObject, eventdata, handles)
% Select a text file with list of macro functions for Fiji
[filename, path] = uigetfile(...
    {'*.txt;',  'Text file (*.txt)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Select file...', handles.mibPathEdit.String);
if isequal(filename,0); return; end; % check for cancel
handles.mibFijiMacroEdit.String = fullfile(path, filename);
end

% --- Executes on button press in mibExportFijiBtn.
function mibExportFijiBtn_Callback(hObject, eventdata, handles)
handles.mibController.mibFijiExport();
end

% --- Executes on button press in mibImportFijiBtn.
function mibImportFijiBtn_Callback(hObject, eventdata, handles)
handles.mibController.mibFijiImport();
end

% --- Executes on button press in mibFijiRunMacroBtn.
function mibFijiRunMacroBtn_Callback(hObject, eventdata, handles)
handles.mibController.mibFijiRunMacro();
end

% --- Executes on button press in mibStartFijiBtn.
function mibStartFijiBtn_Callback(hObject, eventdata, handles)
mibStartFiji();
end

% --- Executes on button press in mibStopFijiBtn.
function mibStopFijiBtn_Callback(hObject, eventdata, handles)
mibStopFiji();
end

%% --------------------- MENU CALLBACKS ---------------------
%% ------------------ File menu ------------------ 
function menuFileImportImage_Callback(hObject, eventdata, handles, parameter)
% a callback from Menu->File->Import 
if nargin < 4;     parameter = 'matlab'; end
handles.mibController.menuFileImportImage_Callback(parameter);
end

function menuFileExportImage_Callback(hObject, eventdata, handles, parameter)
% a callback from Menu->File->Export
if nargin < 4;     parameter = 'matlab'; end
handles.mibController.menuFileExportImage_Callback(parameter);
end

function menuFileOmeroImport_Callback(hObject, eventdata, handles)
% import from OMERO
handles.mibController.startController('mibImportOmeroController');
end

function menuFileBatchProcessing_Callback(hObject, eventdata, handles)
% callback to start batch processing tool
handles.mibController.startController('mibBatchController', handles.mibController);
end

function menuFileChoppedImage_Callback(hObject, eventdata, handles, parameter)
% callback to start chop dataset dialog
% parameter: 'import' or 'export'

handles.mibController.menuFileChoppedImage_Callback(parameter);
end

% --------------------------------------------------------------------
function menuFileRandomize_Callback(hObject, eventdata, handles)
% callback for Menu->File->Randomize files
switch hObject.Tag
    case 'menuFileRandomizeRand'
        handles.mibController.startController('mibRandomDatasetController');
    case 'menuFileRandomizeRestore'
        handles.mibController.startController('mibRandomRestoreDatasetController');
end
end

function menuFileSaveImageAs_Callback(~, ~, handles)
% callback for press of Save Image as
handles.mibController.menuFileSaveImageAs_Callback();
end

% --------------------------------------------------------------------
function menuFileMakeMovie_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibDisplayBtn.
handles.mibController.startController('mibMakeMovieController');
end

% --------------------------------------------------------------------
function menuFileSnapshot_Callback(hObject, eventdata, handles)
% --- Executes on button press in mibDisplayBtn.
handles.mibController.startController('mibSnapshotController');
end

function menuFileRender_Callback(hObject, eventdata, handles, parameter)
% render model with Fiji
handles.mibController.menuFileRender_Callback(parameter);
end

function menuFilePreference_Callback(hObject, eventdata, handles)
% start preferences dialog
handles.mibController.menuFilePreference_Callback();
end


%% ------------------ Dateset menu ------------------ 
function menuDatasetAlignDatasets_Callback(hObject, eventdata, handles)
if strcmp(handles.toolbarBlockModeSwitch.State,'on')
    handles.toolbarBlockModeSwitch.State = 'off';
    toolbarBlockModeSwitch_ClickedCallback(hObject, eventdata, handles);
end
handles.mibController.startController('mibAlignmentController');
end

function menuDatasetCrop_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibCropController', handles.mibImageAxes);
end

function menuDatasetResample_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibResampleController');
end

function menuDatasetTrasform_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuDatasetTrasform_Callback(parameter);
end

% --------------------------------------------------------------------
function menuDatasetSlice_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuDatasetSlice_Callback(parameter);
end

% --------------------------------------------------------------------
function menuDatasetScalebar_Callback(hObject, eventdata, handles)
handles.mibController.menuDatasetScalebar_Callback();
end

% --------------------------------------------------------------------
function menuDatasetBoundingBox_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibBoundingBoxController');
end

function menuDatasetParameters_Callback(~, ~, handles)
% callback for press of Parameters
handles.mibController.menuDatasetParameters_Callback();
end

%% ------------------ Image menu ------------------ 
% --------------------------------------------------------------------
function menuImageMode_Callback(hObject, eventdata, handles)
handles.mibController.menuImageMode_Callback(hObject);
end

% --------------------------------------------------------------------
function menuImageColorCh_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuImageColorCh_Callback(parameter);
end

% --------------------------------------------------------------------
function menuImageContrast_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuImageContrast_Callback(parameter);
end

% --------------------------------------------------------------------
function menuImageInvert_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuImageInvert_Callback(parameter);
end

% --------------------------------------------------------------------
function menuImageToolsProjection_Callback(hObject, eventdata, handles)
handles.mibController.menuImageToolsProjection_Callback();
end

% --------------------------------------------------------------------
function menuImageToolsContentAware_Callback(hObject, eventdata, handles)
handles.mibController.menuImageToolsContentAware_Callback();
end

% --------------------------------------------------------------------
function menuImageToolsBorder_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibImageSelectFrameController');
end

% --------------------------------------------------------------------
function menuImageToolsDebris_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibDebrisRemovalController');
end

% --------------------------------------------------------------------
function menuImageToolsArithmetics_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibImageArithmeticController');
end

% --------------------------------------------------------------------
function menuImageMorph_Callback(hObject, eventdata, handles, parameter)
handles.mibController.startController('mibImageMorphOpsController', parameter);
end

% --------------------------------------------------------------------
function menuImageIntensity_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuImageIntensity_Callback(parameter)
end

%% ------------------ Models menu ------------------ 
% --------------------------------------------------------------------
function menuModelsNew_Callback(hObject, eventdata, handles)
% create a new model
handles.mibController.mibCreateModelBtn_Callback();
end

function menuModelsType_Callback(hObject, eventdata, handles)
% create a new model
switch hObject.Tag
    case 'menuModelsType63'
        modelType = 63;
    case 'menuModelsType255'
        modelType = 255;
    case 'menuModelsType65535'
        modelType = 65535;
    case 'menuModelsType4294967295'
        modelType = 4294967295;        
end
handles.mibController.mibModel.convertModel(modelType);
end

% --------------------------------------------------------------------
function menuModelsLoad_Callback(hObject, eventdata, handles)
% load model from a file
handles.mibController.mibLoadModelBtn_Callback();
end

% --------------------------------------------------------------------
function menuModelsImport_Callback(hObject, eventdata, handles)
% import a model from Matlab workspace
handles.mibController.menuModelsImport_Callback();
end

% --------------------------------------------------------------------
function menuModelsExport_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuModelsExport_Callback(parameter);
end


% --------------------------------------------------------------------
function menuModelsSaveAs_Callback(hObject, eventdata, handles, parameter)
% parameter: 'save' or 'saveas'
handles.mibController.menuModelsSaveAs_Callback(parameter);
end


% --------------------------------------------------------------------
function menuModelsRender_Callback(hObject, eventdata, handles, type)
% render model
handles.mibController.menuModelsRender_Callback(type);
end

% --------------------------------------------------------------------
function menuModelAnn_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuModelAnn_Callback(parameter);  
end

% --------------------------------------------------------------------
function menuModelsStatistics_Callback(hObject, eventdata, handles)
switch hObject.Tag
    case 'menuMaskStats'
        handles.mibController.startController('mibStatisticsController', 1);        
    case 'menuModelsStatistics'
        handles.mibController.startController('mibStatisticsController', 2);        
end
end

%% ------------------ Mask menu ------------------ 
% --------------------------------------------------------------------
function menuMaskClear_Callback(hObject, eventdata, handles)
handles.mibController.mibModel.clearMask();
end

% --------------------------------------------------------------------
function menuMaskLoad_Callback(hObject, eventdata, handles)
handles.mibController.menuMaskLoad_Callback();
end

% --------------------------------------------------------------------
function menuMaskImport_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuMaskImport_Callback(parameter);
end

% --------------------------------------------------------------------
function menuMaskExport_Callback(hObject, eventdata, handles, parameter)
handles.mibController.menuMaskExport_Callback(parameter);
end

% --------------------------------------------------------------------
function menuMaskSaveAs_Callback(hObject, eventdata, handles)
handles.mibController.menuMaskSaveAs_Callback();
end

% --------------------------------------------------------------------
function menuMaskInvert_Callback(hObject, eventdata, handles)
if strcmp(hObject.Tag, 'menuMaskInvert')
    handles.mibController.menuMaskInvert_Callback('mask');
else
    handles.mibController.menuMaskInvert_Callback('selection');
end
end

% --------------------------------------------------------------------
function menuMaskImageReplace_Callback(hObject, eventdata, handles)
if strcmp(hObject.Tag, 'menuMaskImageReplace')
    handles.mibController.menuMaskImageReplace_Callback('mask');
else
    handles.mibController.menuMaskImageReplace_Callback('selection');
end
end

% --------------------------------------------------------------------
function menuMaskSmooth_Callback(hObject, eventdata, handles)
if strcmp(hObject.Tag, 'menuMaskSmooth')
    handles.mibController.mibModel.smoothImage('mask');
elseif strcmp(hObject.Tag, 'menuSelectionSmooth')
    handles.mibController.mibModel.smoothImage('selection');
end
end

%% ------------------ Selection menu ------------------ 
function menuSelectionBuffer_Callback(~, ~, handles, parameter)
% callback for press Selection to Buffer
handles.mibController.menuSelectionBuffer_Callback(parameter);
end

% --------------------------------------------------------------------
function menuSelection2Mask_Callback(hObject, eventdata, handles, obj_type_from, obj_type_to, layers_id, action_type)
handles.mibController.mibModel.moveLayers(obj_type_from, obj_type_to, layers_id, action_type);
end

% --------------------------------------------------------------------
function menuSelectionInterpolate_Callback(hObject, eventdata, handles)
handles.mibController.menuSelectionInterpolate();
end

% --------------------------------------------------------------------
function menuSelectionMorphOps_Callback(hObject, eventdata, handles, parameter)
handles.mibController.startController('mibMorphOpsController', parameter);       
end

% --------------------------------------------------------------------
function menuSelectionToMaskBorder_Callback(hObject, eventdata, handles)
handles.mibController.menuSelectionToMaskBorder_Callback();
end

% --- Executes on button press in mibMaskRecalcStatsBtn.
function mibMaskRecalcStatsBtn_Callback(hObject, eventdata, handles)
handles.mibController.mibMaskRecalcStatsBtn_Callback();
end

%% ------------------ Tools menu ------------------ 
% --------------------------------------------------------------------
function menuToolsMeasure_Callback(hObject, eventdata, handles, parameter)
% callback for selection of handles.menuToolsMeasure entries
% parameter: a string with parameter for the tool
% @li 'tool', start a measure tool
% @li 'line', start a simple line measure tool
% @li 'freehand', start a simple freehand measure tool
handles.mibController.menuToolsMeasure_Callback(parameter)
end

% --------------------------------------------------------------------
function menuToolsStereology_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibStereologyController');   
end

% --------------------------------------------------------------------
function menuToolsClassifiers_Callback(hObject, eventdata, handles, parameter)
switch parameter
    case 'membrane'
        handles.mibController.startController('mibMembraneDetectionController');
    case 'supervoxels'
        handles.mibController.startController('mibSupervoxelClassifierController');
        
end
end

% --------------------------------------------------------------------
function menuToolsSemiAuto_Callback(hObject, eventdata, handles, parameter)
switch parameter
    case 'thresh'
        % alterative call for the batch mode:
        % BatchOpt.colChannel = 1;    % color channel for thresholding
        % BatchOpt.Mode = '3D, Stack';     % mode to use
        % BatchOpt.Method = 'Otsu';       % thresholding algorithm
        % %BatchOpt.t = [1 1];     % time points, [t1, t2]
        % BatchOpt.z = [10 20];    % slices, [z1, z2]
        % BatchOpt.x = [10 120];    % slices, [z1, z2]
        % BatchOpt.Orientation = 2;
        % obj.startController('mibHistThresController', [], BatchOpt);
        
        handles.mibController.startController('mibHistThresController');
    case 'graphcut'
        handles.mibController.startController('mibGraphcutController');
    case 'watershed'
        handles.mibController.startController('mibWatershedController');
        
end
end

% --------------------------------------------------------------------
function menuToolsObjSep_Callback(hObject, eventdata, handles)
handles.mibController.startController('mibObjSepController');
end

%% ------------------ Help menu ------------------ 
% --------------------------------------------------------------------
function menuHelpHelp_Callback(hObject, eventdata, handles, page)
% open help pages

global mibPath;
if isdeployed
    web(fullfile(mibPath, sprintf('techdoc/html/%s.html', page)), '-helpbrowser');
else
    v = ver('matlab');
    if v.Version < 8
        if strcmp(page, 'im_browser_product_page')
            docsearch '"Microscopy Image Browser"'
        elseif strcmp(page, 'im_browser_license')
            docsearch '"Microscopy Image Browser License"'
        end
    else
        web(fullfile(mibPath,'techdoc','html',[page '.html']));
    end
end
end

function menuHelp_Callbacks(hObject, eventdata, handles, parameter)
switch parameter
    case 'tip'
        handles.mibController.mibModel.preferences.tips.showTips = 1;
        handles.mibController.startController('mibTipsController');
    case 'support'
        web('https://forum.image.sc/tags/mib', '-browser');
    case 'update'
        handles.mibController.startController('mibUpdateCheckController', handles.mibController);
    case 'about'
        handles.mibController.startController('mibAboutController', handles.mibGUI.Name);
end
end


% --- Executes on button press in mibPathPanelHelpBtn.
function mibHelpBtn_Callback(hObject, eventdata, handles)
global mibPath;
switch hObject.Tag
    %case 'backRem_panel';            web(fullfile(mibPath, 'techdoc/html/ug_panel_bg_removal.html'), '-helpbrowser');
    case 'menuHelpClassRef'
        if exist(fullfile(mibPath, 'techdoc', 'ClassReference','index.html'), 'file')
            web(fullfile(mibPath, 'techdoc/ClassReference/index.html'), '-helpbrowser');
        else
            web('http://mib.helsinki.fi/help/api2/index.html', '-helpbrowser');
        end
        %case 'coherence_filter';            web(fullfile(mibPath, 'techdoc/html/ug_panel_filters_coherence.html'), '-helpbrowser');
        %case 'corr_panel';            web(fullfile(mibPath, 'techdoc/html/ug_panel_corr.html'), '-helpbrowser');
    case 'mibDirPanelHelpBtn';            web(fullfile(mibPath, 'techdoc/html/ug_panel_dir.html'), '-helpbrowser');
    case 'mibFijiPanelHelpBtn';            web(fullfile(mibPath, 'techdoc/html/ug_panel_fiji_connect.html'), '-helpbrowser');
    case 'mibImageFiltersPanelHelpBtn';             web(fullfile(mibPath, 'techdoc/html/ug_panel_image_filters.html'), '-helpbrowser');
    case 'mibMaskGeneratorsPanelHelpBtn';             web(fullfile(mibPath, 'techdoc/html/ug_panel_mask_generators.html'), '-helpbrowser');
    case 'mibPathPanelHelpBtn';            web(fullfile(mibPath, 'techdoc/html/ug_panel_path.html'), '-helpbrowser');
    case 'mibRoiPanelHelpBtn';            web(fullfile(mibPath, 'techdoc/html/ug_panel_roi.html'), '-helpbrowser');
    case 'mibSegmentationPanelHelpBtn';            web(fullfile(mibPath, 'techdoc/html/ug_panel_segm.html'), '-helpbrowser');
        %case 'segmAn_panel';            web(fullfile(mibPath, 'techdoc/html/ug_panel_segm_analysis.html'), '-helpbrowser');
    case 'mibSelectionPanelHelpBtn';            web(fullfile(mibPath, 'techdoc/html/ug_panel_selection.html'), '-helpbrowser');
    case 'mibViewSettingsPanelHelpBtn';             web(fullfile(mibPath, 'techdoc/html/ug_panel_view_settings.html'), '-helpbrowser');
end
end

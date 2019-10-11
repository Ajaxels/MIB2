function varargout = mibAlignmentGUI(varargin)
% MIBALIGNMENTGUI M-file for mibalignmentgui.fig
%      MIBALIGNMENTGUI by itself, creates a new MIBALIGNMENTGUI or raises the
%      existing singleton*.
%
%      H = MIBALIGNMENTGUI returns the handle to a new MIBALIGNMENTGUI or the handle to
%      the existing singleton*.
%
%      MIBALIGNMENTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBALIGNMENTGUI.M with the given input arguments.
%
%      MIBALIGNMENTGUI('Property','Value',...) creates a new MIBALIGNMENTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibAlignmentGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibAlignmentGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 25.02.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% Edit the above text to modify the response to help mibalignmentgui

% Last Modified by GUIDE v2.5 24-Sep-2019 12:59:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibAlignmentGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibAlignmentGUI_OutputFcn, ...
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

% --- Executes just before mibalignmentgui is made visible.
function mibAlignmentGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibalignmentgui (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.existingFnText1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.existingFnText1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibAlignmentGUI, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibAlignmentGUI);

% set size of the window, because in Guide it is bigger
winPos = handles.mibAlignmentGUI.Position;
handles.mibAlignmentGUI.Position = [winPos(1) winPos(2) handles.uipanel1.Position(3)+handles.uipanel1.Position(3)*.02 winPos(4)];

% setting panels
panelPosition = handles.secondDatasetPanel.Position;
panelParent = handles.secondDatasetPanel.Parent;
handles.currStackOptionsPanel.Parent = panelParent;
handles.currStackOptionsPanel.Position = panelPosition;
handles.currStackOptionsPanel.Visible = 'on';


featuresList{1} = 'Blobs: Speeded-Up Robust Features (SURF) algorithm';
featuresList{2} = 'Regions: Maximally Stable Extremal Regions (MSER) algorithm';
featuresList{3} = 'Corners: Harris-Stephens algorithm';
featuresList{4} = 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)';
featuresList{5} = 'Corners: Features from Accelerated Segment Test (FAST)';
featuresList{6} = 'Corners: Minimum Eigenvalue algorithm';
if ~verLessThan('matlab', '9.6')
    featuresList{7} = 'Oriented FAST and rotated BRIEF (ORB)';
end
handles.FeatureDetectorType.String = featuresList;

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
%set(handles.mibAlignmentGUI,'WindowStyle','modal')

% UIWAIT makes mibalignmentgui wait for user response (see UIRESUME)
%uiwait(handles.mibAlignmentGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibAlignmentGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% --- Executes when user attempts to close mibAlignmentGUI.
function mibAlignmentGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibAlignmentGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

function SecondDatasetPath_Callback(hObject, eventdata, handles)
handles.winController.selectButton_Callback();
path = handles.SecondDatasetPath.String;
if handles.dirRadio.Value
    if ~isdir(path)
        msgbox('Wrong directory name!','Error!','err');
    end
elseif handles.fileRadio.Value
    if ~exist(path, 'file')
        msgbox('Wrong file name!','Error!','err');
    end
end
end

% --- Executes on button press in selectButton.
function handles = selectButton_Callback(hObject, eventdata, handles)
handles.winController.selectButton_Callback();
end

function radioButton_Callback(hObject, eventdata, handles)
if hObject.Value == 0; hObject.Value = 1; return; end
handles.winController.radioButton_Callback();
end

function modeRadioButton_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
hObject = eventdata.NewValue;
tagId = hObject.Tag;
curVal = hObject.Value;
if curVal == 0; hObject.Value = 1; return; end

handles.Algorithm.Value = 1;
if strcmp(tagId, 'TwoStacks')
    handles.Algorithm.String = {'Drift correction','Template matching'};

    handles.secondDatasetPanel.Visible = 'on';
    handles.saveShiftsPanel.Visible = 'off';
    handles.currStackOptionsPanel.Visible = 'off';
    
    handles.CorrelateWith.Enable = 'off';
    handles.correlateWithText.Enable = 'off';
else
    handles.Algorithm.String = {'Drift correction','Template matching','Automatic feature-based','Single landmark point',...
                                    'Landmarks, multi points', 'Three landmark points', 'Color channels, multi points'};
    handles.secondDatasetPanel.Visible = 'off';
    handles.saveShiftsPanel.Visible = 'on';
    handles.currStackOptionsPanel.Visible = 'on';
    
    handles.CorrelateWith.Enable = 'on';
    handles.correlateWithText.Enable = 'on';
end
handles.winController.updateBatchOptFromGUI(hObject.Parent);   % update BatchOpt parameters
end


% --- Executes on button press in getSearchWindow.
function getSearchWindow_Callback(hObject, eventdata, handles)
handles.winController.getSearchWindow_Callback();
end


% --- Executes on button press in SaveShiftsToFile.
function SaveShiftsToFile_Callback(hObject, eventdata, handles)
if handles.SaveShiftsToFile.Value
    startingPath = handles.saveShiftsXYpath.String;
    [FileName, PathName] = uiputfile({'*.coefXY','*.coefXY (Matlab format)'; '*.*','All Files'}, 'Select file...', startingPath);
    if FileName == 0; handles.SaveShiftsToFile.Value = 0; return; end
    handles.saveShiftsXYpath.String = fullfile(PathName, FileName);
    handles.saveShiftsXYpath.Enable = 'on';
else
    handles.saveShiftsXYpath.Enable = 'off';
end
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end

% --- Executes on button press in loadShiftsCheck.
function loadShiftsCheck_Callback(hObject, eventdata, handles)
handles.winController.loadShiftsCheck_Callback();
end


% --- Executes on button press in TwoStacksAutomaticMode.
function TwoStacksAutomaticMode_Callback(hObject, eventdata, handles)
if handles.TwoStacksAutomaticMode.Value
    handles.TwoStacksShiftX.Enable = 'off';
    handles.TwoStacksShiftY.Enable = 'off';
else
    handles.TwoStacksShiftX.Enable = 'on';
    handles.TwoStacksShiftY.Enable = 'on';
end
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end


function CorrelateStep_Callback(hObject, eventdata, handles)
val = round(str2double(handles.CorrelateStep.String));
if val < 1
    msgbox('Step should be an integer positive number!', 'Error!','error');
    handles.CorrelateStep.String = '1';
else
    handles.CorrelateStep.String = num2str(val);
end
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end

% --- Executes on selection change in Algorithm.
function Algorithm_Callback(hObject, eventdata, handles)
methodsList = handles.Algorithm.String;
methodSelected = methodsList{handles.Algorithm.Value};
textStr = '';
handles.ColorChannel.Enable = 'off';
handles.IntensityGradient.Enable = 'off';
handles.TransformationType.Enable = 'off';
handles.TransformationMode.Enable = 'off';
handles.CorrelateWith.Enable = 'off';
handles.TransformationDegree.Enable = 'off';
handles.FeatureDetectorType.Enable = 'off';
handles.previewFeaturesBtn.Enable = 'off';

switch methodSelected
    case 'Drift correction'
        textStr = sprintf('Use the Drift correction mode for small shifts or comparably sized images');
        handles.ColorChannel.Enable = 'on';
        handles.IntensityGradient.Enable = 'on';
        handles.CorrelateWith.Enable = 'on';
    case 'Template matching'
        textStr = sprintf('Use the Template matching mode for when aligning two stacks with one of the stacks smaller in size');
        handles.ColorChannel.Enable = 'on';
        handles.IntensityGradient.Enable = 'on';
        handles.CorrelateWith.Enable = 'on';
    case 'Automatic feature-based'
        if handles.TransformationType.Value > 3; handles.TransformationType.Value = 1; end
        textStr = sprintf('Use automatic feature detection to align slices');
        handles.TransformationType.Enable = 'on';
        handles.TransformationMode.Enable = 'on';
        handles.FeatureDetectorType.Enable = 'on';
        handles.TransformationType.String = {'similarity', 'affine', 'projective'};
        handles.previewFeaturesBtn.Enable = 'on';
        handles.ColorChannel.Enable = 'on';
        handles.winController.updateBatchOptFromGUI(handles.TransformationType);   % update BatchOpt parameters
    case 'Single landmark point'
        textStr = sprintf('Use the brush tool to mark two corresponding spots on consecutive slices. The dataset will be translated to align the marked spots');
    case 'Three landmark points'
        textStr = sprintf('Use the brush tool to mark corresponding spots on two consecutive slices. The dataset will be transformed to align the marked spots. The Landmark mode recommended instead!');
    case 'Landmarks, multi points'
        textStr = sprintf('Use annotations or selection with brush to mark corresponding spots on consecutive slices. The dataset will be transformed to align the marked areas');
        handles.TransformationType.Enable = 'on';
        handles.TransformationMode.Enable = 'on';
        handles.TransformationType.String = {'non reflective similarity', 'similarity', 'affine', 'projective'};
        %handles.TransformationDegree.Enable = 'on';
        handles.winController.updateBatchOptFromGUI(handles.TransformationType);   % update BatchOpt parameters
    case 'Color channels, multi points'
        textStr = sprintf('Select the color channel to be moved and use annotations identify corresponding spots, text for id of a point and value for id of the color channel (1 and 2)');
        handles.TransformationType.Enable = 'on';
        handles.TransformationMode.Enable = 'on';
        handles.TransformationType.String = {'non reflective similarity', 'similarity', 'affine', 'projective'};
        %handles.TransformationDegree.Enable = 'on';
        handles.winController.updateBatchOptFromGUI(handles.TransformationType);   % update BatchOpt parameters        
        handles.ColorChannel.Enable = 'on';
        handles.TransformationMode.Value = 2;
        handles.winController.updateBatchOptFromGUI(handles.TransformationMode);   % update BatchOpt parameters        
end
handles.landmarkHelpText.String = textStr;
handles.landmarkHelpText.TooltipString = textStr;
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end


function subwindowEdit_Callback(hObject, eventdata, handles)
handles.winController.subwindowEdit_Callback(hObject);
end

% --- Executes on selection change in CorrelateWith.
function CorrelateWith_Callback(hObject, eventdata, handles)
if ismember(handles.CorrelateWith.Value, [3,4])    % relative/relative hybrid to mode
    handles.CorrelateStep.Enable = 'on';
    handles.stepText.Enable = 'on';
else
    handles.CorrelateStep.Enable = 'off';
    handles.stepText.Enable = 'off';
end
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_dataset_alignment.html'), '-helpbrowser');

%web('http://mib.helsinki.fi/help/main/ug_gui_menu_dataset_alignment.html', '-helpbrowser');
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end


% --- Executes on button press in previewFeaturesBtn.
function previewFeaturesBtn_Callback(hObject, eventdata, handles)
handles.winController.previewFeaturesBtn_Callback();
end


% --- Executes on selection change in Subarea.
function Subarea_Callback(hObject, eventdata, handles)
switch hObject.String{hObject.Value}
    case 'Manually specified'
        handles.searchWinMinXText.Enable = 'on';
        handles.searchWinMinYText.Enable = 'on';
        handles.searchWinMaxXText.Enable = 'on';
        handles.searchWinMaxYText.Enable = 'on';
        handles.minX.Enable = 'on';
        handles.minY.Enable = 'on';
        handles.maxX.Enable = 'on';
        handles.maxY.Enable = 'on';
        handles.getSearchWindow.Enable = 'on';
    otherwise
        handles.searchWinMinXText.Enable = 'off';
        handles.searchWinMinYText.Enable = 'off';
        handles.searchWinMaxXText.Enable = 'off';
        handles.searchWinMaxYText.Enable = 'off';
        handles.minX.Enable = 'off';
        handles.minY.Enable = 'off';
        handles.maxX.Enable = 'off';
        handles.maxY.Enable = 'off';
        handles.getSearchWindow.Enable = 'off';
end
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end

function updateBatch(hObject, eventdata, handles)
% update BatchOpt structure of mibAlignmentController
handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
end


% --- Executes on button press in White.
function BackgroundColor(hObject, eventdata, handles)
% callback for press of radio buttons for Background color
switch hObject.Style
    case 'edit'
        handles.Custom.Value = 1;
        handles.winController.updateBatchOptFromGUI(hObject);   % update BatchOpt parameters
        handles.winController.updateBatchOptFromGUI(handles.BackgroundColor);   % update BatchOpt parameters
    otherwise
        handles.winController.updateBatchOptFromGUI(handles.BackgroundColor);   % update BatchOpt parameters
end
end

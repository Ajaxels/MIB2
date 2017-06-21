function varargout = mibSupervoxelClassifierGUI(varargin)
% function varargout = mibSupervoxelClassifierGUI(varargin)
% mibSupervoxelClassifierGUI function uses random forest classifier for segmentation.
% The function utilize Random Forest for Membrane Detection functions by Verena Kaynig
% see more http://www.kaynig.de/demos.html
%
% mibSupervoxelClassifierGUI contains MATLAB code for mibSupervoxelClassifierGUI.fig

% Copyright (C) 18.09.2015 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @mibSupervoxelClassifierGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibSupervoxelClassifierGUI_OutputFcn, ...
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

% --- Executes just before mibSupervoxelClassifierGUI is made visible.
function mibSupervoxelClassifierGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibSupervoxelClassifierGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% superpixelTypeRadio radio button callbacks
set(handles.superpixelTypeRadio, 'SelectionChangeFcn', {@superpixelTypeRadio_Callback, handles});

% Choose default command line output for mibChildGUI
handles.output = hObject;

% set panels
handles.trainClassifierPanel.Parent = handles.preprocessPanel.Parent;
handles.trainClassifierPanel.Position = handles.preprocessPanel.Position;
pos = handles.mibSupervoxelClassifierGUI.Position;
pos(3) = 420;
pos(4) = 315;
handles.mibSupervoxelClassifierGUI.Position = pos;

% set types of available classifiers
matVer = ver;
classList{1} = 'Random Forest';
if ~isempty(strfind([matVer.Name], 'Statistics Toolbox')) || ~isempty(strfind([matVer.Name], 'Statistics and Machine Learning Toolbox'))
    classList2 = {'AdaBoostM1'; 'LogitBoost'; 'GentleBoost';'RUSBoost';'Bag';'Support Vector Machine'};
    if ~isempty(strfind([matVer.Name], 'Optimization Toolbox'))
        classList2 = [classList2; 'RobustBoost'; 'LPBoost'; 'TotalBoost'];
    end
    classList2 = sort(classList2);
    classList = [classList; classList2];
end
handles.classifierPopup.String = classList;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibSupervoxelClassifierGUI wait for user response (see UIRESUME)
% uiwait(handles.mibSupervoxelClassifierGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibSupervoxelClassifierGUI_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibSupervoxelClassifierGUI.
function mibSupervoxelClassifierGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibMembraneDetectionGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

function tempDirEdit_Callback(hObject, eventdata, handles)
currTempPath = handles.tempDirEdit.String;
if exist(currTempPath,'dir') == 0     % make directory
    mkdir(currTempPath);
end 
end

function tempDirSelectBtn_Callback(hObject, eventdata, handles)
handles.winController.tempDirSelectBtn_Callback();
end

function classifierFilenameEdit_Callback(hObject, eventdata, handles)
handles.winController.classifierFilenameEdit_Callback();
end

function resetDimsBtn_Callback(hObject, eventdata, handles)
handles.winController.resetDimsBtn_Callback();
end

function checkDimensions(hObject, eventdata, handles, parameter)
handles.winController.checkDimensions(hObject, parameter);
end

function binSubareaEdit_Callback(hObject, eventdata, handles)
val = str2num(hObject.String); %#ok<ST2NM>
if isempty(val)
    val = [1; 1];
elseif isnan(val(1)) || min(val) <= .5
    val = [1;1];
else
    val = round(val);
end
hObject.String = sprintf('%d; %d',val(1), val(2));
end

function subAreaFromSelectionBtn_Callback(hObject, eventdata, handles)
handles.winController.subAreaFromSelectionBtn_Callback();
end

function currentViewBtn_Callback(hObject, eventdata, handles)
handles.winController.currentViewBtn_Callback();
end

function superpixelsBtn_Callback(hObject, eventdata, handles)
handles.winController.superpixelsBtn_Callback();
end

function previewSuperpixelsBtn_Callback(hObject, eventdata, handles)
handles.winController.previewSuperpixelsBtn_Callback();
end

function calcFeaturesBtn_Callback(hObject, eventdata, handles)
handles.winController.calcFeaturesBtn_Callback();
end

function trainClassifierToggle_Callback(hObject, eventdata, handles)
% hObject    handle to trainClassifierToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

btnTag = hObject.Tag;
switch btnTag
    case 'preprocessToggle'
        handles.preprocessPanel.Visible = 'on';
        handles.trainClassifierPanel.Visible = 'off';
    case 'trainClassifierToggle'
        handles.trainClassifierPanel.Visible = 'on';
        handles.preprocessPanel.Visible = 'off';
        if handles.mode2dRadio.Value % enable predict the current slice button
            handles.predictSlice.Enable = 'on';
        else        % disable predict the current slice button
            handles.predictSlice.Enable = 'off';
        end
end
end

function trainClassifierBtn_Callback(hObject, eventdata, handles)
handles.winController.trainClassifierBtn_Callback();
end

function wipeTempDirBtn_Callback(hObject, eventdata, handles)
handles.winController.wipeTempDirBtn_Callback();
end

function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_tools_random_forest_superpixels.html'), '-helpbrowser');
end


% --- Executes on button press in predictDatasetBtn.
function predictDatasetBtn_Callback(hObject, eventdata, handles)
handles.winController.predictDatasetBtn_Callback();
end


% --- Executes on selection change in classifierPopup.
function classifierPopup_Callback(hObject, eventdata, handles)
val = hObject.Value;
if val > 1
    handles.classCyclesEdit.Enable = 'on';
else
    handles.classCyclesEdit.Enable = 'off';
end
end


% --- Executes on button press in loadClassifierBtn.
function loadClassifierBtn_Callback(hObject, eventdata, handles)
handles.winController.loadClassifierBtn_Callback();
end


% --- Executes on button press in updateMaterialsBtn.
function updateMaterialsBtn_Callback(hObject, eventdata, handles)
% populating lists of materials
handles.winController.updateWidgets();
end


% --------------------------------------------------------------------
function superpixelTypeRadio_Callback(hObject, eventdata, handles)
if handles.slicSuperpixelsRadio.Value   % use SLIC superpixels
    handles.superpixelText.TooltipString = 'number of superpixels, larger number gives more precision, but slower';
    handles.superpixelEdit.TooltipString = 'number of superpixels, larger number gives more precision, but slower';
    handles.superpixelEdit.String = '500';
    handles.superpixelsCompactText.String = 'Compact';
    handles.superpixelsCompactText.TooltipString = 'compactness factor, the larger the number more square resulting superpixels';
    handles.superpixelsCompactEdit.TooltipString = 'compactness factor, the larger the number more square resulting superpixels';
else                                            % use Watershed superpixels
    handles.superpixelText.TooltipString = 'factor to modify size of superpixels, the larger number gives bigger superpixels, use 15 as a starting value';
    handles.superpixelEdit.TooltipString = 'factor to modify size of superpixels, the larger number gives bigger superpixels, use 15 as a starting value';
    handles.superpixelEdit.String = '15';
    handles.superpixelsCompactText.String = 'Black on white';
    handles.superpixelsCompactText.TooltipString = 'put 0 if objects have bright boundaries or 1 if objects have dark boundaries';
    handles.superpixelsCompactEdit.TooltipString = 'put 0 if objects have bright boundaries or 1 if objects have dark boundaries';
end

end

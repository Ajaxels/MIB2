function varargout = mibSaveHDF5Dlg(varargin)
% MIBSAVEHDF5DLG MATLAB code for mibSaveHDF5Dlg.fig
%      MIBSAVEHDF5DLG, by itself, creates a new MIBSAVEHDF5DLG or raises the existing
%      singleton*.
%
%      H = MIBSAVEHDF5DLG returns the handle to a new MIBSAVEHDF5DLG or the handle to
%      the existing singleton*.
%
%      MIBSAVEHDF5DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBSAVEHDF5DLG.M with the given input arguments.
%
%      MIBSAVEHDF5DLG('Property','Value',...) creates a new MIBSAVEHDF5DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibSaveHDF5Dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibSaveHDF5Dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mibSaveHDF5Dlg

% Last Modified by GUIDE v2.5 25-Dec-2016 14:11:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibSaveHDF5Dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @mibSaveHDF5Dlg_OutputFcn, ...
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

% --- Executes just before mibSaveHDF5Dlg is made visible.
function mibSaveHDF5Dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibSaveHDF5Dlg (see VARARGIN)

% get handles structure
handles.mibImage = varargin{1};

% Choose default command line output for mibSaveHDF5Dlg
handles.output = {};

% get MIB font size
global Font;
% update font and size
if ~isempty(Font)
    if handles.text1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibSaveHDF5Dlg, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibSaveHDF5Dlg);

options.blockModeSwitch = 0;
[height, width, ~, depth] = handles.mibImage.getDatasetDimensions('image', 4, 0, options); 

chunk(1) = min([height, 64]);
chunk(2) = min([width, 64]);
chunk(3) = min([depth, 64]);
set(handles.chunkEdit, 'string', sprintf('%d, %d, %d;', chunk(1), chunk(2), chunk(3)));

templatePopup_Callback(hObject, eventdata, handles);

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

pos = get(handles.mibSaveHDF5Dlg, 'position');
handles.dialogHeight = pos(4);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibSaveHDF5Dlg wait for user response (see UIRESUME)
uiwait(handles.mibSaveHDF5Dlg);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibSaveHDF5Dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    varargout{1} = {};
else
    varargout{1} = handles.output;
end
delete(hObject);
end

% --- Executes when user attempts to close mibSaveHDF5Dlg.
function mibSaveHDF5Dlg_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibSaveHDF5Dlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.output = struct();
list = handles.templatePopup.String;
selEntry = strtrim(list{handles.templatePopup.Value});
switch selEntry
    case 'Fiji Big Data Viewer'
        handles.output.Format = 'bdv.hdf5';
    case 'Ordinary HDF5'
        handles.output.Format = 'matlab.hdf5';
end
handles.output.SubSampling = str2num(handles.subsamplingEdit.String)'; %#ok<ST2NM>
if handles.chunkCheckbox.Value
    handles.output.ChunkSize = str2num(handles.chunkEdit.String)'; %#ok<ST2NM>
end
handles.output.Deflate = str2double(handles.deflateEdit.String); 
handles.output.xmlCreate = handles.xmlCheck.Value; 

% Update handles structure
guidata(hObject, handles);

uiresume(handles.mibSaveHDF5Dlg);
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
delete(handles.mibSaveHDF5Dlg);
end

% --- Executes on selection change in templatePopup.
function templatePopup_Callback(hObject, eventdata, handles)
list = handles.templatePopup.String;
selEntry = strtrim(list{handles.templatePopup.Value});
switch selEntry
    case 'Fiji Big Data Viewer'
        handles.chunkCheckbox.Enable = 'off';
        handles.chunkCheckbox.Value = 1;
        handles.xmlCheck.Enable = 'off';
        handles.xmlCheck.Value = 1;
        handles.infoText.String = ...
            sprintf('Export for Fiji Big Data Viewer:\n1. resulting images are 16-bit\n2. additional processing for data conversion to Java classes');
        handles.subsamplingEdit.Enable = 'on';
    case 'Ordinary HDF5'
        handles.chunkCheckbox.Enable = 'on';
        handles.xmlCheck.Enable = 'on';
        handles.infoText.String = sprintf('Export as ordinary HDF5:\nno limitations');
        handles.subsamplingEdit.Enable = 'off';
end
end


% --- Executes on button press in chunkCheckbox.
function chunkCheckbox_Callback(hObject, eventdata, handles)
if handles.chunkCheckbox.Value
    handles.chunkEdit.Enable = 'on';
else
    handles.chunkEdit.Enable = 'off';
end
end



function deflateEdit_Callback(hObject, eventdata, handles)
val = str2double(handles.deflateEdit.String);
if val < 0 || val > 9
    errordlg(sprintf('!!! Error !!!\n\nThe value for compression should be between 0 (no compression) and 9 (maximal)'),'Wrong value');
    handles.deflateEdit.String = '6';
end
end

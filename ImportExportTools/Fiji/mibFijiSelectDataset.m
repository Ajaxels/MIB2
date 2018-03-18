function varargout = mibFijiSelectDataset(varargin)
% function varargout = mibFijiSelectDataset(varargin)
% mibFijiSelectDataset function is a dialog for selection of datasets from Fiji
%
% mibFijiSelectDataset contains MATLAB code for mibFijiSelectDataset

% Last Modified by GUIDE v2.5 02-Mar-2017 18:32:00

% Copyright (C) 21.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
                   'gui_OpeningFcn', @mibFijiSelectDataset_OpeningFcn, ...
                   'gui_OutputFcn',  @mibFijiSelectDataset_OutputFcn, ...
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

% --- Executes just before mibFijiSelectDataset is made visible.
function mibFijiSelectDataset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibFijiSelectDataset (see VARARGIN)

global Font;

% Choose default command line output for ib_cropGui
handles.output = NaN;

% check for MIJ
if exist('MIJ','class') ~= 8
    msgbox(sprintf('Miji was not started!\n\nPress the Start Fiji button in the Fiji connect panel'),...
        'Missing Miji!','error');
    return;
end

% get list of available datasets:
try
    list = MIJ.getListImages;
catch err
    errordlg(sprintf('Error!!!\n\nNothing is available for the import\nPlease open a dataset in Fiji and try again!'));
    cancelBtn_Callback(hObject, eventdata, handles);
    return;
end
  
for i=1:numel(list)
    list2(i) = cellstr(char(list(i)));
end

% update font and size
if ~isempty(Font)
    if get(handles.text1, 'fontsize') ~= Font.FontSize ...
            || ~strcmp(get(handles.text1, 'fontname'), Font.FontName)
        mibUpdateFontSize(handles.mibFijiSelectDataset, Font);
    end
end

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibFijiSelectDataset);

handles.fijidatasetsPopup.String = list2;

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
handles.mibFijiSelectDataset.WindowStyle = 'modal';

% UIWAIT makes ib_cropGui wait for user response (see UIRESUME)
uiwait(handles.mibFijiSelectDataset);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibFijiSelectDataset_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isstruct(handles)
    varargout{1} = handles.output;
    % The figure can be deleted now
    delete(handles.mibFijiSelectDataset);
else
    varargout{1} = NaN;
end
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
val = handles.fijidatasetsPopup.Value;
lst = handles.fijidatasetsPopup.String;

handles.output = lst{val};

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibFijiSelectDataset);
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)

handles.output = NaN;

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibFijiSelectDataset);
end

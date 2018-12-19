function varargout = mibUpdateCheckGUI(varargin)
% MIBUPDATECHECKGUI MATLAB code for mibUpdateCheckGUI.fig
%      MIBUPDATECHECKGUI, by itself, creates a new MIBUPDATECHECKGUI or raises the existing
%      singleton*.
%
%      H = MIBUPDATECHECKGUI returns the handle to a new MIBUPDATECHECKGUI or the handle to
%      the existing singleton*.
%
%      MIBUPDATECHECKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBUPDATECHECKGUI.M with the given input arguments.
%
%      MIBUPDATECHECKGUI('Property','Value',...) creates a new MIBUPDATECHECKGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibUpdateCheckGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibUpdateCheckGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 21.11.2013, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 29.04.2015 - changed to a new update server


% Edit the above text to modify the response to help mibUpdateCheckGUI

% Last Modified by GUIDE v2.5 05-Mar-2017 23:05:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibUpdateCheckGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibUpdateCheckGUI_OutputFcn, ...
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

% --- Executes just before mibUpdateCheckGUI is made visible.
function mibUpdateCheckGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibUpdateCheckGUI (see VARARGIN)

global mibPath;

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for mibdatasetinfogui
handles.output = hObject;

% add icon
[IconData, IconCMap] = imread(fullfile(mibPath, 'Resources', 'mib_update_wide.gif'));
Img=image(IconData, 'Parent', handles.axes1);
IconCMap(IconData(1,1)+1, :) = handles.mibUpdateCheckGUI.Color;   % replace background color
handles.mibUpdateCheckGUI.Colormap = IconCMap;

handles.axes1.Visible = 'off';
handles.axes1.YDir = 'reverse';
handles.axes1.XLim = Img.XData;
handles.axes1.YLim = Img.YData;

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibUpdateCheckGUI wait for user response (see UIRESUME)
% uiwait(handles.mibUpdateCheckGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibUpdateCheckGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibUpdateCheckGUI.
function mibUpdateCheckGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in listofchangesBtn.
function listofchangesBtn_Callback(hObject, eventdata, handles)
web('http://mib.helsinki.fi/downloads.html', '-browser');
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function informationEdit_Callback(hObject, eventdata, handles)
end


% --- Executes on button press in mibWebsiteBtn.
function mibWebsiteBtn_Callback(hObject, eventdata, handles)
web('http://mib.helsinki.fi', '-browser');
end


% --- Executes on button press in downloadBtn.
function downloadBtn_Callback(hObject, eventdata, handles)
% function downloadBtn_Callback(obj)
% download MIB
if isdeployed
    if ismac()
        web('http://mib.helsinki.fi/web-update/MIB2_Mac.dmg', '-browser');
    elseif ispc()
        answer = questdlg('Would you like to download MIB compiled for the current or recent release of Matlab?', 'Matlab version', 'Current', 'Recent', 'Cancel', 'Current');
        switch answer
            case 'Cancel' 
                return;
            case 'Current'
                web('http://mib.helsinki.fi/web-update/MIB2_Win.exe', '-browser');
            case 'Recent'
                web('http://mib.helsinki.fi/web-update/MIB2_Win_Recent.exe', '-browser');
        end
    end
else
    web('http://mib.helsinki.fi/web-update/MIB2_Matlab.zip', '-browser');
end
end

% --- Executes on button press in updateBtn.
function updateBtn_Callback(hObject, eventdata, handles)
% function updateBtn_Callback(obj)
% update MIB
global mibPath;

answer = mibInputDlg({mibPath}, sprintf('Please check MIB installation directory for:\n'), 'Update MIB', mibPath);
if isempty(answer); return; end

destination = answer{1};
wb = waitbar(0,sprintf('Updating Microscopy Image Browser...\nIt may take up to few minutes \ndepending on network connection.\n\nPlease wait...'), 'Name', 'Updating...');

waitbar(0.05, wb);
unzip('http://mib.helsinki.fi/web-update/MIB2_Matlab.zip', destination);
waitbar(0.9, wb);
% close MIB
delete(handles.winController.mibController.mibView.gui);
handles.winController.mibController.exitProgram(); 
drawnow;
waitbar(0.95, wb);
rehash;     % update list of known functions
waitbar(1, wb);
delete(wb);
mib;    % start MIB
end
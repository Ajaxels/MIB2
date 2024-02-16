% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function varargout = myPluginNameGUI(varargin)
% MYPLUGINNAMEGUI MATLAB code for myPluginNameGUI.fig
%      MYPLUGINNAMEGUI, by itself, creates a new MYPLUGINNAMEGUI or raises the existing
%      singleton*.
%
%      H = MYPLUGINNAMEGUI returns the handle to a new MYPLUGINNAMEGUI or the handle to
%      the existing singleton*.
%
%      MYPLUGINNAMEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MYPLUGINNAMEGUI.M with the given input arguments.
%
%      MYPLUGINNAMEGUI('Property','Value',...) creates a new MYPLUGINNAMEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before myPluginNameGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to myPluginNameGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help myPluginNameGUI

% Last Modified by GUIDE v2.5 22-Aug-2017 14:13:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @myPluginNameGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @myPluginNameGUI_OutputFcn, ...
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

% --- Executes just before myPluginNameGUI is made visible.
function myPluginNameGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to myPluginNameGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% Choose default command line output for myPluginNameGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes myPluginNameGUI wait for user response (see UIRESUME)
% uiwait(handles.myPluginNameGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = myPluginNameGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close myPluginNameGUI.
function myPluginNameGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to myPluginNameGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

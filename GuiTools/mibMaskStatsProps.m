function varargout = mibMaskStatsProps(varargin)
% MIBMASKSTATSPROPS MATLAB code for mibMaskStatsProps.fig
%      MIBMASKSTATSPROPS, by itself, creates a new MIBMASKSTATSPROPS or raises the existing
%      singleton*.
%
%      H = MIBMASKSTATSPROPS returns the handle to a new MIBMASKSTATSPROPS or the handle to
%      the existing singleton*.
%
%      MIBMASKSTATSPROPS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBMASKSTATSPROPS.M with the given input arguments.
%
%      MIBMASKSTATSPROPS('Property','Value',...) creates a new MIBMASKSTATSPROPS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibMaskStatsProps_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibMaskStatsProps_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 01.06.2015 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% Last Modified by GUIDE v2.5 25-Mar-2018 16:39:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibMaskStatsProps_OpeningFcn, ...
                   'gui_OutputFcn',  @mibMaskStatsProps_OutputFcn, ...
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

% --- Executes just before mibMaskStatsProps is made visible.
function mibMaskStatsProps_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibMaskStatsProps (see VARARGIN)

global Font;

% Choose default command line output for mibMaskStatsProps
handles.output = varargin{1};   % parameters that should be calculated
handles.properties = varargin{1};   % parameters that should be calculated
handles.obj3d = varargin{2};    % switch to define 3D or 2D objects

if handles.obj3d
    parent = get(handles.shape2dPanel, 'parent');
    set(handles.shape3dPanel, 'parent', parent);
    pos = get(handles.shape2dPanel, 'position');
    set(handles.shape3dPanel, 'position', pos);
    set(handles.shape2dPanel, 'visible', 'off');
    set(handles.shape3dPanel, 'visible', 'on');

    matlabVersion = ver('Matlab');
    matlabVersion = str2double(matlabVersion.Version);
    if matlabVersion >= 9.3
        handles.ConvexVolume3d.Enable = 'on';
        handles.EquivDiameter3d.Enable = 'on';
        handles.Extent3d.Enable = 'on';
        handles.Solidity3d.Enable = 'on';
        handles.SurfaceArea3d.Enable = 'on';
    end
end

handles.mibMaskStatsProps.Position(3) = handles.uipanel1.Position(3)+handles.uipanel1.Position(1)*2;
if ~isempty(Font)
    if handles.Area.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.Area.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibMaskStatsProps, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibMaskStatsProps);

% move the window
hObject = moveWindowOutside(hObject, 'center');

% Make the GUI modal
set(handles.mibMaskStatsProps,'WindowStyle','modal')

% Update handles structure
guidata(hObject, handles);

updateWidgets(handles);

% UIWAIT makes mibMaskStatsProps wait for user response (see UIRESUME)
uiwait(handles.mibMaskStatsProps);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibMaskStatsProps_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles. mibMaskStatsProps);
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.output = {};

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibMaskStatsProps);

end

% --- Executes when user attempts to close mibMaskStatsProps.
function mibMaskStatsProps_CloseRequestFcn(hObject, eventdata, handles)
handles.output = {};
if isfield(handles, 'mibMaskStatsProps')
    guidata(handles.mibMaskStatsProps, handles);
    uiresume(hObject);
else
    delete(hObject);
end

end

% --- Executes on button press in checkallBtn.
function checkallBtn_Callback(hObject, eventdata, handles)
excludeList = {'CurveLength','EndpointsLength','EndpointsLength3d','Correlation'};
if handles.obj3d == 1
    %list = findall(handles.mibMaskStatsProps, 'parent', handles.shape3dPanel,'style','checkbox');
    list = findall(handles.mibMaskStatsProps, 'parent', handles.shape3dPanel, 'Enable', 'on');
    for i=1:numel(list)
        if sum(ismember(get(list(i),'tag'), excludeList)) == 0
            set(list(i),'value', 1);
        end
    end
else
    list = findall(handles.mibMaskStatsProps, 'parent', handles.shape2dPanel,'style','checkbox');
    for i=1:numel(list)
        if sum(ismember(get(list(i),'tag'), excludeList)) == 0
            set(list(i),'value', 1);
        end
    end
end
list = findall(handles.mibMaskStatsProps, 'parent', handles.intensityPanel,'style','checkbox');
for i=1:numel(list)
    if sum(ismember(get(list(i),'tag'), excludeList)) == 0
        set(list(i),'value', 1);
    end
end
end


% --- Executes on button press in uncheckBtn.
function uncheckBtn_Callback(hObject, eventdata, handles)
list = findall(handles.mibMaskStatsProps, 'parent', handles.shape3dPanel,'style','checkbox');
set(list,'value', 0);
list = findall(handles.mibMaskStatsProps, 'parent', handles.shape2dPanel,'style','checkbox');
set(list,'value', 0);
list = findall(handles.mibMaskStatsProps, 'parent', handles.intensityPanel,'style','checkbox');
set(list,'value', 0);
end

function updateWidgets(handles)
% select defined checkboxes
properties = handles.properties;

if handles.obj3d == 1       % add 3d to the end of each property
    for i = 1:numel(properties)
        if ~ismember(properties(i),{'Correlation', 'MinIntensity', 'MaxIntensity', 'MeanIntensity', 'SumIntensity', 'StdIntensity'})
            properties{i} = [properties{i} '3d'];
        end
    end
end

if sum(ismember(properties, 'HolesArea')) > 0
   properties(ismember(properties, 'HolesArea')) = [];
end

for i = 1:numel(properties)
    set(handles.(properties{i}), 'value', 1);
end
end

% --- Executes on button press in okBtn.
function okBtn_Callback(hObject, eventdata, handles)
index = 1;
if handles.obj3d == 1
    list = findall(handles.mibMaskStatsProps, 'parent', handles.shape3dPanel,'style','checkbox');
    for i=1:numel(list)
        if get(list(i),'value') == 1
            tagStr = get(list(i),'tag');
            properties{index} = tagStr(1:end-2);    % remove 3d from the end of the tag
            index = index + 1;
        end
    end
else
    list = findall(handles.mibMaskStatsProps, 'parent', handles.shape2dPanel,'style','checkbox');
    for i=1:numel(list)
        if get(list(i),'value') == 1
            properties{index} = get(list(i),'tag');
            index = index + 1;
        end
    end

end
list = findall(handles.mibMaskStatsProps, 'parent', handles.intensityPanel,'style','checkbox');
for i=1:numel(list)
    if get(list(i),'value') == 1
        properties{index} = get(list(i),'tag');
        index = index + 1;
    end
end
if exist('properties', 'var')
    handles.output = properties;
    guidata(handles.mibMaskStatsProps, handles);
end
uiresume(handles.mibMaskStatsProps);
end

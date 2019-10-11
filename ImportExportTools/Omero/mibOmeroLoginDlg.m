function varargout = mibOmeroLoginDlg(varargin)
% varargout = mibOmeroLoginDlg(varargin)
% mibOmeroLoginDlg function is responsible for login to OMERO server.
%
% mibOmeroLoginDlg contains MATLAB code for mibOmeroLoginDlg.fig

% Copyright (C) 05.03.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 17.08.2018, updated to Java password edit box

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibOmeroLoginDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @mibOmeroLoginDlg_OutputFcn, ...
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

% --- Executes just before mibOmeroLoginDlg is made visible.
function mibOmeroLoginDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibOmeroLoginDlg (see VARARGIN)

global Font;

% Choose default command line output for mibOmeroLoginDlg
handles.output = struct();
handles.password = '';

% update font and size
if ~isempty(Font)
    if get(handles.text1, 'fontsize') ~= Font.FontSize ...
            || ~strcmp(get(handles.text1, 'fontname'), Font.FontName)
        mibUpdateFontSize(handles.mibOmeroLoginDlg, Font);
    end
end
% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibOmeroLoginDlg);

%% Restore preferences from the last time
prefdir = getPrefDir();
omeroFn = fullfile(prefdir, 'mib_omero.mat');
if exist(omeroFn, 'file') ~= 0
    load(omeroFn);  % load omero structure with .servers, .port .username fields
    handles.servers = omeroSettings.servers;
    handles.serverIdx = omeroSettings.serverIdx;
    handles.username = omeroSettings.username;
    handles.port = omeroSettings.port;
    fprintf('Loading omero settings from %s\n', omeroFn);
else
    handles.servers = {'demo.openmicroscopy.org', 'omerovm-1.it.helsinki.fi'};
    handles.serverIdx = 1;
    handles.username = char(java.lang.System.getProperty('user.name'));
    handles.port = 4064;
end

set(handles.serverPopup,'String',handles.servers);
set(handles.serverPopup,'Value',handles.serverIdx);
set(handles.omeroServerPortEdit,'String',handles.port);
set(handles.usernameEdit,'String',handles.username);

% Create Password Entry Box
% based on example by Jesse Lai from  
% https://se.mathworks.com/matlabcentral/fileexchange/19729-passwordentrydialog
handles.passwordEdit.Units = 'pixels';
handles.java_Password = javax.swing.JPasswordField();
handles.passwordEdit.Visible = 'off';

warn = warning();
warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');
[handles.java_Password, handles.edit_Password] = javacomponent(handles.java_Password, handles.passwordEdit.Position, handles.mibOmeroLoginDlg);
handles.java_Password.setFocusable(true);
warning(warn);

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibOmeroLoginDlg wait for user response (see UIRESUME)
uiwait(handles.mibOmeroLoginDlg);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibOmeroLoginDlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.mibOmeroLoginDlg);
end

% --- Executes on button press in loginBtn.
function loginBtn_Callback(hObject, eventdata, handles)
serverList = get(handles.serverPopup,'string');
serverIdx = get(handles.serverPopup,'value');

handles.output.server = serverList{serverIdx};
handles.output.port = str2double(get(handles.omeroServerPortEdit,'String'));
handles.output.username = get(handles.usernameEdit,'String');
%handles.output.password = handles.password;
handles.output.password = handles.java_Password.Password';

omeroSettings.servers = handles.servers;
omeroSettings.serverIdx = handles.serverIdx;
omeroSettings.port = handles.output.port;
omeroSettings.username = handles.output.username; %#ok<STRNU>

prefdir = getPrefDir();
omeroFn = fullfile(prefdir, 'mib_omero.mat');
try
    save(omeroFn, 'omeroSettings');
    fprintf('Saving Omero settings to %s\n', omeroFn);
catch err
    errordlg(sprintf('There is a problem with saving OMERO settings to\n%s\n%s', omeroFn, err.identifier), 'Error');
end

guidata(hObject, handles);
uiresume(handles.mibOmeroLoginDlg);
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.output = struct();
guidata(hObject, handles);
uiresume(handles.mibOmeroLoginDlg);
end


% --- Executes on key press with focus on passwordEdit and none of its controls.
function passwordEdit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to passwordEdit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(handles.mibOmeroLoginDlg);
switch eventdata.Key
    case {'backspace', 'delete'}
        if numel(handles.password) == 0; return; end
        handles.password = handles.password(1:end-1);
    case {'leftarrow','rightarrow','downarrow',  'uparrow', 'shift', 'alt', 'control',...
            'escape', 'insert', 'home', 'pageup', 'pagedown', 'end'}
    case 'return'
        loginBtn_Callback(handles.loginBtn, eventdata, handles);
        return;
    otherwise
        handles.password = [handles.password eventdata.Character];
end
set(handles.passwordEdit,'String', sprintf('%s', repmat('*',[1 numel(handles.password)])));
guidata(hObject, handles);
end


% --- Executes on key press with focus on mibOmeroLoginDlg and none of its controls.
function mibOmeroLoginDlg_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibOmeroLoginDlg (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    cancelBtn_Callback(handles.cancelBtn, eventdata, handles);
    return;
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    loginBtn_Callback(handles.loginBtn, eventdata, handles);
    return;
end    

end


% --- Executes on button press in addServerBtn.
function addServerBtn_Callback(hObject, eventdata, handles)
%answer = inputdlg('Enter server address','Add server',1,{''});
answer = mibInputDlg([],'Enter server address','Add server','');
if isempty(answer); return; end
handles.servers = [handles.servers, answer];
set(handles.serverPopup,'string',handles.servers);
handles.serverIdx = numel(handles.servers);
set(handles.serverPopup,'value',handles.serverIdx);
guidata(hObject, handles);
end

% --- Executes on button press in removeServerBtn.
function removeServerBtn_Callback(hObject, eventdata, handles)
serverList = get(handles.serverPopup,'string');
serverValue = get(handles.serverPopup,'value');
button = questdlg(sprintf('You are going to remove:\n%s\nfrom the list!', serverList{serverValue}),'Remove server','Cancel','Remove','Cancel');
if strcmp(button, 'Cancel'); return; end
i = 1:numel(serverList);
handles.servers = serverList(i~=serverValue)';
set(handles.serverPopup,'string',handles.servers);
handles.serverIdx = 1;
set(handles.serverPopup,'value',handles.serverIdx);
guidata(hObject, handles);
end

% --- Executes on selection change in serverPopup.
function serverPopup_Callback(hObject, eventdata, handles)
handles.serverIdx = get(handles.serverPopup, 'value');
guidata(hObject, handles);
end

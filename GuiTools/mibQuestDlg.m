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
% Date: 07.03.2025

function varargout = mibQuestDlg(varargin)
% function answer = mibQuestDlg(mibPath, prompt, buttons, dlgTitle, options)
% custom button input dialog
%
%
% Parameters:
% mibPath:  [optional] a cell string with a path to MIB installation, use
% @code global mibPath; @endcode to get it, or just an empty cell: {[]}
% prompt:  string with dialog prompt
% buttons: a cell array {n x 1} with labels of buttons in order from right size of the dialog
% dlgTitle: a string with the name of the dialog
% options: an @em optional structure with additional options
% .WindowStyle - a string, can be either 'normal' (default) or 'modal'.
% .WindowWidth - a number scales the standard width of the dialog x times
% .WindowHeight - height of the window in points, default = 95.25
% .ButtonWidth - vector with width of buttons in points
% .helpBtnText -  text for the Help button
% .HelpUrl - URL to the help page, when provided a Help button is displayed, 
% .Icon - string ('question'-default, 'celebrate', 'call4help', 'warning'), an icon to use
%
% Return values:
% answer: name of the pressed button

%| 
% @b Examples:
% @code
% global mibPath;
% prompt = sprintf('Press one of the buttons\nnext line');
% buttons = {'Right button'; 'Middle button'; 'Left button'};
% dlgTitle = 'multi button dialog';
% options.WindowStyle = 'normal';       // [optional] style of the window
% options.Icon = 'question'; // [optional] icon to use: "question" (default), "celebrate", "call4help"
% options.ButtonWidth = [50 75 75]; // [optional] width of buttons
% options.WindowWidth = 1.4; // [optional] width multiplier for the dialog
% options.WindowHeight = 250; // [optional] height of the dialog in points
% answer = mibQuestDlg({mibPath}, prompt, buttons, dlgTitle, options);
% if isempty(answer); return; end // cancel
% @endcode

% Updates

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibQuestDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @mibQuestDlg_OutputFcn, ...
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

% --- Executes just before mibQuestDlg is made visible.
function mibQuestDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibQuestDlg (see VARARGIN)

global mibPath;     % path to mib installation directory

if nargin < 8   % check for missing options structure
    options = struct;
else
    options = varargin{5};
end

if nargin < 7   % check for missing or empty title string
    titleStr = 'Multi button dialog';
else
    if isempty(varargin{4})
        titleStr = 'Multi button dialog';
    else
        titleStr = varargin{4};
    end
end
set(handles.mibQuestDlg,'Name', titleStr);

if nargin < 6   % check for buttons
    buttons = {'Right', 'Middle', 'Left'};
else
    if isempty(varargin{3})
        buttons = {'Right', 'Middle', 'Left'};
    else
        buttons = varargin{3};
    end
end

if nargin < 5   % check for the dialog text prompt
    prompt = 'Press one of these buttons';
else
    if isempty(varargin{2})
        prompt = 'Press one of these buttons';
    else
        prompt = varargin{2};
    end
end
handles.textString.String = prompt;

if isempty(varargin{1})
    handles.mibPath = mibPath;
else
    handles.mibPath = cell2mat(varargin{1});
end

% add default values for the options structure
if ~isfield(options, 'Icon'); options.Icon = 'question'; end
if ~isfield(options, 'WindowStyle'); options.WindowStyle = 'normal'; end

% handling Help button
if ~isfield(options, 'HelpUrl')
    handles.HelpUrl = []; 
else
    handles.HelpUrl = options.HelpUrl;
end
if ~isempty(handles.HelpUrl); handles.helpBtn.Visible = 'on'; end
if isfield(options, 'helpBtnText')
    handles.helpBtn.String = options.helpBtnText; 
    handles.helpBtn.TooltipString = options.helpBtnText;
end

if ~isfield(options, 'PromptLines')
    promptLines = 1;
else
    promptLines = options.PromptLines;
end

de = handles.rightBtn.Position(4);    % standard height for the edits/combos/checkboxes

% make the window wider
% handles.mibQuestDlg.Visible = 'on';

% update window height
if isfield(options, 'WindowHeight')
    handles.mibQuestDlg.Position(4) = options.WindowHeight;
    handles.axes1.Position(2) = handles.mibQuestDlg.Position(4) - handles.axes1.Position(4) - de/2;
    handles.textString.Position(4) = handles.axes1.Position(2)+handles.axes1.Position(4)-handles.textString.Position(2);
end

if ~isfield(options, 'ButtonWidth')
    options.ButtonWidth(1) = handles.rightBtn.Position(3);
    options.ButtonWidth(2) = handles.middleBtn.Position(3);
    options.ButtonWidth(3) = handles.leftBtn.Position(3);
end

if numel(buttons) > 0
    handles.rightBtn.String = buttons{1}; 
    handles.rightBtn.TooltipString = buttons{1}; 
    handles.rightBtn.Position(3) = options.ButtonWidth(1); 
end
if numel(buttons) > 1
    handles.middleBtn.String = buttons{2}; 
    handles.middleBtn.TooltipString = buttons{2}; 
    handles.middleBtn.Position(3) = options.ButtonWidth(2); 
end
if numel(buttons) > 2
    handles.leftBtn.String = buttons{3}; 
    handles.leftBtn.TooltipString = buttons{3}; 
    handles.leftBtn.Position(3) = options.ButtonWidth(3); 
end

if isfield(options, 'WindowWidth')
    defaultWidth = handles.mibQuestDlg.Position(3);
    handles.mibQuestDlg.Position(3) = handles.mibQuestDlg.Position(3)*options.WindowWidth;
    %handles.leftBtn.Position(1) = handles.leftBtn.Position(1) + handles.mibQuestDlg.Position(3)-defaultWidth;
    %handles.rightBtn.Position(1) = handles.rightBtn.Position(1) + handles.mibQuestDlg.Position(3)-defaultWidth;
    handles.textString.Position(3) = handles.textString.Position(3)+ handles.mibQuestDlg.Position(3)-defaultWidth;
end

% update position of the buttons
handles.rightBtn.Position(1) = handles.mibQuestDlg.Position(3) - handles.rightBtn.Position(3) - 8;
handles.middleBtn.Position(1) = handles.rightBtn.Position(1) - handles.middleBtn.Position(3) - 8;
handles.leftBtn.Position(1) = handles.middleBtn.Position(1) - handles.leftBtn.Position(3) - 8;
posButton = handles.leftBtn.Position;

% load the icon and
% correct the image axes depending on the image size
switch options.Icon
    case 'question'
        iconFilename = 'mib_question.png';
    case 'celebrate'
        iconFilename = 'mib_celebrate.jpg';
    case 'call4help'
        iconFilename = 'mib_call4help.jpg';
    case 'warning'
        iconFilename = 'mib_warning.png';
end

% load the icon
[~, ~, iconExt] = fileparts(iconFilename);
mibDir = handles.mibPath;
if isempty(handles.mibPath)
    if isdeployed % Stand-alone mode.
        [~, result] = system('path');
        mibDir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    else % MATLAB mode.
        mibDir = fileparts(which('mib'));
    end
end
% old code for GIF
%[IconData, IconCMap] = imread(fullfile(mibDir, 'Resources', 'mib_quest.gif'), 'BackgroundColor', handles.mibQuestDlg.Color);
switch iconExt
    case '.png'
        [IconData, IconCMap] = imread(fullfile(mibDir, 'Resources', iconFilename), 'BackgroundColor', handles.mibQuestDlg.Color);
    case '.jpg'
        [IconData, IconCMap] = imread(fullfile(mibDir, 'Resources', iconFilename));
end

%  resize the icon
if ismember(options.Icon, {'warning', 'question'})
    IconData = imresize(IconData, 0.4, 'lanczos3');
end

% increase the axes size for the image
origAxPositions = handles.axes1.Position;
handles.axes1.Units = 'pixels';
handles.axes1.Position(3) = size(IconData, 2);
handles.axes1.Position(4) = size(IconData, 1);
handles.axes1.Units = 'points';
% correct X1 and Y1 position for the image axes
handles.axes1.Position(1) = de/4;
handles.axes1.Position(2) = posButton(2)+posButton(4)+handles.textString.Position(4)/2; %handles.mibQuestDlg.Position(4) - handles.axes1.Position(4) + handles.axes1.Position(4);
% calculate how much the image axes were increased
axShiftX = handles.axes1.Position(3) - origAxPositions(3);
% decrese the size of the referenced handles.textString
handles.textString.Position(1) = handles.textString.Position(1) + axShiftX;
handles.textString.Position(3) = handles.textString.Position(3) - axShiftX;
% increase window height to keep the image
handles.mibQuestDlg.Position(4) = max([handles.mibQuestDlg.Position(4) handles.axes1.Position(4)+de*2]);
handles.axes1.Position(2) = handles.mibQuestDlg.Position(4) - handles.axes1.Position(4) - de/2;


% Choose default command line output for mibQuestDlg
handles.output = [];

% update font and size
global Font;
if ~isempty(Font)
    if handles.textString.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.textString.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibQuestDlg, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibQuestDlg);

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

pos = handles.mibQuestDlg.Position;
handles.dialogHeight = pos(4);

Img = image(IconData, 'Parent', handles.axes1);
% update colormap for GIF
if ~isempty(IconCMap)
    IconCMap(IconData(1,1)+1,:) = handles.mibQuestDlg.Color;   % replace background color
    handles.mibQuestDlg.Colormap = IconCMap;
end
handles.axes1.Visible = 'off';
handles.axes1.YDir = 'reverse';
handles.axes1.XLim = Img.XData;
handles.axes1.YLim = Img.YData;
handles.axes1.DataAspectRatioMode = 'manual';
handles.axes1.DataAspectRatio = [1, 1, 1];

if numel(buttons) < 3; handles.leftBtn.Visible = 'off'; end
if numel(buttons) < 2; handles.middleBtn.Visible = 'off'; end %#ok<ISCL>
    
% update WindowKeyPressFcn
handles.mibQuestDlg.WindowKeyPressFcn = {@mibQuestDlg_KeyPressFcn, handles};

% Make the GUI modal
if strcmp(options.WindowStyle, 'modal')
    handles.mibQuestDlg.WindowStyle = 'modal';
else
    handles.mibQuestDlg.WindowStyle = 'normal';
end

% Update handles structure
guidata(hObject, handles);
drawnow;

handles.mibQuestDlg.Visible = 'on';

% highlight text in the edit box
uicontrol(handles.rightBtn);

% UIWAIT makes mibQuestDlg wait for user response (see UIRESUME)
uiwait(handles.mibQuestDlg);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibQuestDlg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles = guidata(handles.mibQuestDlg);

% Get default command line output from handles structure
if isempty(handles.output)
    varargout{1} = {};
else
    varargout{1} = handles.output;
end

% The figure can be deleted now
delete(handles.mibQuestDlg);
end

% --- Executes when user attempts to close mibQuestDlg.
function mibQuestDlg_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibQuestDlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    cancelBtn_Callback(hObject, eventdata, handles);
    % The GUI is still in UIWAIT, us UIRESUME
    %uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end
end

% --- Executes on button press in leftBtn.
function buttons_Callback(hObject, eventdata, handles)
% hObject    handle to leftBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
drawnow;     % needed to fix callback after the key press
handles.output = eventdata.Source.String;

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibQuestDlg);
end

% --- Executes on key press over mibQuestDlg with no controls selected.
function mibQuestDlg_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibQuestDlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if nargin < 3;    handles = guidata(hObject); end

%if strcmp(handles.leftBtn.Visible, 'off') 
%    CurrentKey = 'escape'; 
%else
%    CurrentKey = hObject.CurrentKey;
%end

CurrentKey = hObject.CurrentKey;

% Check for "enter" or "escape"
if isequal(CurrentKey, 'escape')
    cancelBtn_Callback(hObject, eventdata, handles);
end    
%if isequal(CurrentKey, 'return')
%    okBtn_Callback(hObject, eventdata, handles);
%end    
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = {};

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibQuestDlg);
end

% --- Executes when mibInputMultiDlg is resized.
function mibQuestDlg_ResizeFcn(hObject, eventdata, handles)
if isfield(handles, 'dialogHeight')     % to skip this part during initialization of the dialog
%     pos = handles.mibInputMultiDlg.Position;
%     pos(4) = handles.dialogHeight;
%     handles.mibInputMultiDlg.Position = pos;
    %handles.hWidget(:).Units = 'normalized';
    %handles.hText.Units = 'normalized';
end

end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(handles.HelpUrl(1:4), 'http')
    % http://mib.helsinki.fi
    web(handles.HelpUrl, '-browser');
else
    eval(handles.HelpUrl);
end
end

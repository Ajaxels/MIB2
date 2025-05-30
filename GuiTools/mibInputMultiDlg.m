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

function varargout = mibInputMultiDlg(varargin)
% function [answer, selectedIndices] = mibInputMultiDlg(mibPath, prompts, defaultAns, dlg_title, options)
% custom input dialog
%
%
% Parameters:
% mibPath:  [optional] a cell string with a path to MIB installation, use
% @code global mibPath; @endcode to get it, or just an empty cell: {[]}
% prompts:  a cell array {n x 1} with the prompts for each edit field of the dialog
% defaultAns: a cell array {n x 1} with the default answers for each edit.
% The following options for each element is available:
% @li '' or 'some text' - initialized as a text box with the provided default text
% @li another cell array - initialized as a combo box with entries taken
% from this cell array; @b Note! the last entry should be the default value
% to be selected!
% @li true/false - initialized as a checkbox
% dlg_title: - a string with the name of the dialog
% options: an @em optional structure with additional options
% .WindowStyle - a string, can be either 'normal' or 'modal' (default).
% .PromptLines - a number or an array of numbers (equal to number of prompts) that define how many lines
% of text should be in the prompt field. Default is 1.
% .Title - a string with a text that will be displayed before the widgets, at the top of the window
% .TitleLines - a number that defines number of text lines reserved for the title
% .WindowWidth - a number scales the standard width of the dialog x times
% .Columns - an integer that defines number of columns
% .LastItemColumns - [optional] force the last entry to be on a single column, 1 or 0
% .Focus - define index of the widget to get focused
% .okBtnText -  text for the OK button
% .helpBtnText -  text for the Help button
% .HelpUrl - URL to the help page, when provided a Help button is displayed, 
% press of the button opens the url in a browser (requires 'http' in the
% beginning of the url link). Alternatively, it can be a command to
% execute.
% .msgBoxOnly - logical, to mimic message box without input fields
% .Icon - string ('question'-default, 'celebrate', 'call4help', 'warning'), an icon to use
%
% Return values:
% answer: a cell array with the entered values, or @em empty, when cancelled
% selectedIndices: a vector with indices of selected options, mostly used
% for comboboxes

%| 
% @b Examples:
% @code
% global mibPath;
% prompts = {'Enter a text'; 'Select the option'; 'Are you sure?'; 'placeholder, remove text to make empty'; 'This is very very very very very very very very very very long prompt'};
% defAns = {'my test string'; {'Option 1', 'Option 2', 'Option 3', 2}; true; NaN; []};
% dlgTitle = 'multi line input diglog';
% options.WindowStyle = 'normal';       // [optional] style of the window
% options.PromptLines = [1, 1, 1, 1, 2];   // [optional] number of lines for widget titles
% options.Title = 'My test Input dialog';   // [optional] additional text at the top of the window
% options.TitleLines = 2;                   // [optional] make it twice tall, number of text lines for the title
% options.WindowWidth = 1.2;    // [optional] make window x1.2 times wider
% options.Columns = 2;    // [optional] define number of columns
% options.Focus = 1;      // [optional] define index of the widget to get focus
% options.HelpUrl = 'http:\\mib.helsinki.fi'; // [optional], an url for the Help button
% options.LastItemColumns = 1; // [optional] force the last entry to be on a single column
% options.msgBoxOnly = false; // [optional] mimic message box without input fields
% options.Icon = 'question'; // [optional] icon to use: "question" (default), "celebrate", "call4help", "warning"
% [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
% if isempty(answer); return; end 
% @endcode

% Updates
% 13.01.2021, added syntax: prompt = 'text'; defAns = NaN to draw an empty placeholder without a widget

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibInputMultiDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @mibInputMultiDlg_OutputFcn, ...
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

% --- Executes just before mibInputMultiDlg is made visible.
function mibInputMultiDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibInputMultiDlg (see VARARGIN)

global mibPath;     % path to mib installation directory

if nargin < 8   % check for missing options structure
    options = struct;
else
    options = varargin{5};
end

if nargin < 7   % check for missing or empty title string
    titleStr = 'MultiEdit dialog';
else
    if isempty(varargin{4})
        titleStr = 'MultiEdit dialog';
    else
        titleStr = varargin{4};
    end
end

if nargin < 6   % check for default answers field
    defAns = {[]};
else
    if isempty(varargin{3})
        defAns = {[]};
    else
        defAns = varargin{3};
    end
end

if nargin < 5   % check for the text prompts field
    prompts = {'Enter a text:'};
else
    if isempty(varargin{2})
        prompts = {'Enter a text:'};
    else
        prompts = varargin{2};
    end
end

if isempty(varargin{1})
    handles.mibPath = mibPath;
else
    handles.mibPath = cell2mat(varargin{1});
end

% add default values for the options structure
if ~isfield(options, 'Icon'); options.Icon = 'question'; end
if ~isfield(options, 'WindowStyle'); options.WindowStyle = 'normal'; end
if ~isfield(options, 'Columns'); options.Columns = 1; end
if ~isfield(options, 'Focus'); options.Focus = 1; end
if ~isfield(options, 'LastItemColumns'); options.LastItemColumns = 0; end
if isfield(options, 'okBtnText')
    handles.okBtn.String = options.okBtnText;
    handles.okBtn.TooltipString = options.okBtnText;
end
if ~isfield(options, 'HelpUrl')
    handles.HelpUrl = []; 
else
    handles.HelpUrl = options.HelpUrl;
end
if ~isempty(handles.HelpUrl); handles.Help.Visible = 'on'; end
if isfield(options, 'helpBtnText')
    handles.Help.String = options.helpBtnText; 
    handles.Help.TooltipString = options.helpBtnText;
end
if ~isfield(options, 'msgBoxOnly'); options.msgBoxOnly = false; end

if ~isfield(options, 'PromptLines')
    PromptLines = ones([numel(prompts) 1]);
else
    if numel(options.PromptLines) == 1
        PromptLines = ones([numel(prompts) 1])*options.PromptLines;
    else
        PromptLines = options.PromptLines;
    end
end

set(handles.mibInputMultiDlg,'Name', titleStr);

% make the window wider
handles.mibInputMultiDlg.Visible = 'on';
% handles.mibInputMultiDlg.Units = 'pixels';
% ch = handles.mibInputMultiDlg.Children;
% for i=1:numel(ch); ch(i).Units = 'pixels'; end

if isfield(options, 'WindowWidth')
    defaultWidth = handles.mibInputMultiDlg.Position(3);
    handles.mibInputMultiDlg.Position(3) = handles.mibInputMultiDlg.Position(3)*options.WindowWidth;
    handles.okBtn.Position(1) = handles.okBtn.Position(1) + handles.mibInputMultiDlg.Position(3)-defaultWidth;
    handles.cancelBtn.Position(1) = handles.cancelBtn.Position(1) + handles.mibInputMultiDlg.Position(3)-defaultWidth;
    handles.textString.Position(3) = handles.textString.Position(3)+ handles.mibInputMultiDlg.Position(3)-defaultWidth;
end

posEdit = handles.textEdit.Position;
posButton = handles.okBtn.Position;
de = posEdit(4);    % standard height for the edits/combos/checkboxes

% load the icon and
% correct the image axes depending on the image size
switch options.Icon
    case 'warning'
        iconFilename = 'mib_warning.png';
    case 'question'
        iconFilename = 'mib_question.png';
    case 'celebrate'
        iconFilename = 'mib_celebrate.jpg';
    case 'call4help'
        iconFilename = 'mib_call4help.jpg';
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
%[IconData, IconCMap] = imread(fullfile(mibDir, 'Resources', 'mib_quest.gif'), 'BackgroundColor', handles.mibInputMultiDlg.Color);
switch iconExt
    case '.png'
        [IconData, IconCMap] = imread(fullfile(mibDir, 'Resources', iconFilename), 'BackgroundColor', handles.mibInputMultiDlg.Color);
    case '.jpg'
        [IconData, IconCMap] = imread(fullfile(mibDir, 'Resources', iconFilename));
end

%  resize the icon
if ismember(options.Icon, {'warning', 'question'})
        IconData = imresize(IconData, 0.32, 'lanczos3');
end
% increase the axes size for the image
origAxPositions = handles.axes1.Position;
handles.axes1.Units = 'pixels';
handles.axes1.Position(3) = size(IconData, 2);
handles.axes1.Position(4) = size(IconData, 1);
handles.axes1.Units = 'points';
% correct X1 and Y1 position for the image axes
handles.axes1.Position(1) = de/4;
handles.axes1.Position(2) = posButton(2)+posButton(4)+handles.textString.Position(4)/2; %handles.mibInputMultiDlg.Position(4) - handles.axes1.Position(4) + handles.axes1.Position(4);
% calculate how much the image axes were increased
axShiftX = handles.axes1.Position(3) - origAxPositions(3);
% decrese the size of the referenced handles.textString
handles.textString.Position(1) = handles.textString.Position(1) + axShiftX;
handles.textString.Position(3) = handles.textString.Position(3) - axShiftX;
% increase window height to keep the image
handles.mibInputMultiDlg.Position(4) = max([handles.mibInputMultiDlg.Position(4) handles.axes1.Position(4)+de*2]);

posText = handles.textString.Position;
x1 = posText(1);    % left point for positioning the widgets
dt = posText(4);    % standard height for the prompts

widthFull = posText(3);     % standard width of the widgets
if options.Columns > 1
    width = widthFull/options.Columns-de/2;
else
    width = widthFull;
end

posVec = nan([numel(prompts)*2, 4]);    % allocate space for position matrix
shiftY = 0; %dt*PromptLines(1);            % shifty
maxShiftY = 0;  % maximal shift of the Y-coordinate
widgetId = 1;
shiftX = 0;

for elementId = 1:numel(prompts)
    if shiftX < floor((elementId-1)/ceil((numel(prompts)-options.LastItemColumns)/options.Columns))*width
        columnId = floor((elementId-1)/ceil((numel(prompts)-options.LastItemColumns)/options.Columns));
        shiftX = columnId*width + de/2*columnId;
        shiftY = 0; %dt*PromptLines(1);
    end

    % fix for the last item to be on a single column
    if options.LastItemColumns == 1 && elementId == numel(prompts)
        shiftX = 0;
        shiftY = maxShiftY;
    end
    
    if ~islogical(defAns{elementId})    % make text string
        posVec(widgetId, 1) = x1+shiftX;
        posVec(widgetId, 2) = shiftY+dt*PromptLines(elementId);
        posVec(widgetId, 3) = width;
        posVec(widgetId, 4) = dt*PromptLines(elementId);
        shiftY = shiftY + dt*PromptLines(elementId);
        if options.LastItemColumns == 1 && elementId == numel(prompts)
            posVec(widgetId, 3) = widthFull;
        end
    end
    widgetId = widgetId + 1;
    
    posVec(widgetId, 1) = x1+shiftX;
    posVec(widgetId, 2) = shiftY+de;
    posVec(widgetId, 3) = width;
    posVec(widgetId, 4) = de;
    shiftY = shiftY + de + de/2;
    if options.LastItemColumns == 1 && elementId == numel(prompts)
        posVec(widgetId, 3) = widthFull;
    end
    widgetId = widgetId + 1;
    maxShiftY = max([maxShiftY shiftY]);
end

if options.msgBoxOnly == false  % add input widgets
    if min(posVec(:,2)) < 0
        posVec(:,2) = posVec(:,2) - min(posVec(:,2));
    end
    maxY = max(posVec(:,2));
    posVec(:,2) = maxY - posVec(:,2)+posButton(2)+posButton(4)+de/2;

    widgetId = 1;
    for elementId = 1:numel(prompts)
        if ~islogical(defAns{elementId})
            handles.hText(elementId) = uicontrol('Parent', handles.mibInputMultiDlg, 'Style', 'text', ...
                'Units', 'points', 'HorizontalAlignment', 'left', ...
                'String', prompts{elementId}, ...
                'Position', posVec(widgetId,:));
        end
        widgetId = widgetId + 1;

        if ~iscell(defAns{elementId}) || isempty(defAns{elementId})
            if islogical(defAns{elementId})     % make a checkbox
                handles.hWidget(elementId) = uicontrol('Parent', handles.mibInputMultiDlg, 'Style', 'checkbox', 'Units', 'points', ...
                    'String', prompts{elementId}, ...
                    'Value', defAns{elementId}, ...
                    'Position', posVec(widgetId,:));
            else                                % make an editbox
                if ~isempty(isnan(defAns{elementId})) && isnan(defAns{elementId}(1))
                    % place holder, no widget
                else
                    if isempty(defAns{elementId}); defAns{elementId} = ''; end

                    handles.hWidget(elementId) = uicontrol('Parent', handles.mibInputMultiDlg, 'Style', 'edit', ...
                        'Units', 'points', 'HorizontalAlignment', 'left', ...
                        'String', defAns{elementId}, ...
                        'Position', posVec(widgetId,:));
                end
            end
        else    % make a combobox
            if isnumeric(defAns{elementId}{end})
                entriesList = defAns{elementId}(1:end-1);
                selectedValue = defAns{elementId}{end};
            else
                entriesList = defAns{elementId};
                selectedValue = 1;
            end
            handles.hWidget(elementId) = uicontrol('Parent', handles.mibInputMultiDlg, 'Style', 'popupmenu', 'Units', 'points', ...
                'String', entriesList, ...
                'Position', posVec(widgetId,:));
            handles.hWidget(elementId).Value = selectedValue;
        end
        widgetId = widgetId + 1;
    end
end

% Adding the widgets to the figure
% add title to the window
if isfield(options, 'Title')
    if ~isfield(options, 'TitleLines'); options.TitleLines = 1; end
    y1 = max(posVec(:,2))+de/2+dt*PromptLines(1);
    posVec = [x1, y1, widthFull, dt*options.TitleLines];
    y1 = y1 + dt*options.TitleLines;
    
    handles.hTitle = uicontrol('Parent', handles.mibInputMultiDlg, 'Style', 'text', ...
        'Units', 'points', 'HorizontalAlignment', 'left', ...
        'String', options.Title, ...
        'Position', posVec(1,:));
else
    options.TitleLines = 1;
    y1 = max(posVec(:,2)) +dt*PromptLines(1);
end

% resize the figure
handles.mibInputMultiDlg.Position(4) = max([y1 + de/2 handles.mibInputMultiDlg.Position(4)]);

% Choose default command line output for mibInputMultiDlg
handles.output = defAns;
handles.selectedIndeces = ones([numel(defAns), 1]);

% update font and size
global Font;
if ~isempty(Font)
    if handles.textString.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.textString.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibInputMultiDlg, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibInputMultiDlg);

% delete dummy widgets
delete(handles.textEdit);
delete(handles.textString);

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

pos = handles.mibInputMultiDlg.Position;
handles.dialogHeight = pos(4);

Img = image(IconData, 'Parent', handles.axes1);
% update colormap for GIF
if ~isempty(IconCMap)
    IconCMap(IconData(1,1)+1,:) = handles.mibInputMultiDlg.Color;   % replace background color
    handles.mibInputMultiDlg.Colormap = IconCMap;
end
handles.axes1.Visible = 'off';
handles.axes1.YDir = 'reverse';
handles.axes1.XLim = Img.XData;
handles.axes1.YLim = Img.YData;
handles.axes1.DataAspectRatioMode = 'manual';
handles.axes1.DataAspectRatio = [1, 1, 1];

% update y-position of the image axes
handles.axes1.Position(2) = handles.mibInputMultiDlg.Position(4)-handles.axes1.Position(4) - dt;

% update WindowKeyPressFcn
handles.mibInputMultiDlg.WindowKeyPressFcn = {@mibInputMultiDlg_KeyPressFcn, handles};

% Make the GUI modal
if strcmp(options.WindowStyle, 'modal')
    handles.mibInputMultiDlg.WindowStyle = 'modal';
else
    handles.mibInputMultiDlg.WindowStyle = 'normal';
end

% % define the tab order and set the widgets to normalized for resizing
ch = handles.mibInputMultiDlg.Children;
for i=1:numel(ch)
    %if ~isa(ch(i), 'matlab.graphics.axis.Axes')
        ch(i).Units = 'normalized';
    %end
end
% for i=1:numel(ch)-3
%    uistack(ch(i), 'top'); 
%    ch(i).Units = 'normalized';
% end
% ch(end-2).Units = 'normalized';
% ch(end-1).Units = 'normalized';
% ch(end).Units = 'normalized';

% Update handles structure
guidata(hObject, handles);
drawnow;

% % make the window wider
% if isfield(options, 'WindowWidth')
%     handles.mibInputMultiDlg.Position(3) = handles.mibInputMultiDlg.Position(3)*options.WindowWidth;
% end
handles.mibInputMultiDlg.Visible = 'on';

% highlight text in the edit box
if ~options.msgBoxOnly
    uicontrol(handles.hWidget(options.Focus));
else
    % for message box disable OK button and rename Cancel to OK
    handles.okBtn.Visible = 'off';
    if isfield(options, 'okBtnText')
        handles.cancelBtn.String = options.okBtnText; 
        handles.cancelBtn.TooltipString = options.okBtnText; 
    else
        handles.cancelBtn.String = 'OK';
    end
end

% UIWAIT makes mibInputMultiDlg wait for user response (see UIRESUME)
uiwait(handles.mibInputMultiDlg);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibInputMultiDlg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles = guidata(handles.mibInputMultiDlg);

% Get default command line output from handles structure
if isempty(handles.output)
    varargout{1} = {};
    varargout{2} = {};
else
    varargout{1} = handles.output;
    varargout{2} = handles.selectedIndeces;
end
%varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.mibInputMultiDlg);
end

% --- Executes when user attempts to close mibInputMultiDlg.
function mibInputMultiDlg_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibInputMultiDlg (see GCBO)
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

% --- Executes on button press in okBtn.
function okBtn_Callback(hObject, eventdata, handles)
% hObject    handle to okBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
drawnow;     % needed to fix callback after the key press
handles.selectedIndeces = ones([numel(handles.hWidget), 1]);    % indices of the selected widgets, mostly used for comboboxes
for id=1:numel(handles.hWidget)
    switch handles.hWidget(id).Style
        case 'edit'
            handles.output{id} = handles.hWidget(id).String;
        case 'checkbox'
            handles.output{id} = logical(handles.hWidget(id).Value);
        case 'popupmenu'
            list = handles.hWidget(id).String;
            handles.output{id} = list{handles.hWidget(id).Value};
            handles.selectedIndeces(id) = handles.hWidget(id).Value;
    end
end

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.mibInputMultiDlg);
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
uiresume(handles.mibInputMultiDlg);
end

% --- Executes on key press over mibInputMultiDlg with no controls selected.
function mibInputMultiDlg_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibInputMultiDlg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if nargin < 3;    handles = guidata(hObject); end

if strcmp(handles.okBtn.Visible, 'off') 
    CurrentKey = 'escape'; 
else
    CurrentKey = hObject.CurrentKey;
end

% Check for "enter" or "escape"
if isequal(CurrentKey, 'escape')
    cancelBtn_Callback(hObject, eventdata, handles);
end    
if isequal(CurrentKey, 'return')
    okBtn_Callback(hObject, eventdata, handles);
end    
end


function textEdit_Callback(hObject, eventdata, handles)
% hObject    handle to textEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textEdit as text
%        str2double(get(hObject,'String')) returns contents of textEdit as a double
end


% --- Executes when mibInputMultiDlg is resized.
function mibInputMultiDlg_ResizeFcn(hObject, eventdata, handles)
if isfield(handles, 'dialogHeight')     % to skip this part during initialization of the dialog
%     pos = handles.mibInputMultiDlg.Position;
%     pos(4) = handles.dialogHeight;
%     handles.mibInputMultiDlg.Position = pos;
    %handles.hWidget(:).Units = 'normalized';
    %handles.hText.Units = 'normalized';
end

end

% --- Executes on button press in Help.
function Help_Callback(hObject, eventdata, handles)
% hObject    handle to Help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(handles.HelpUrl(1:4), 'http') || ~isempty(strfind(handles.HelpUrl, 'html'))
    % http://mib.helsinki.fi
    web(handles.HelpUrl, '-browser');
else
    eval(handles.HelpUrl);
end
end

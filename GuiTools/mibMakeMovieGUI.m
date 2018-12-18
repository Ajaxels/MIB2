function varargout = mibMakeMovieGUI(varargin)
% function varargout = mibMakeMovieGUI(varargin)
% mibMakeMovieGUI function is responsible for saving video files of the datasets.
%
% mibMakeMovieGUI contains MATLAB code for mibMakeMovieGUI.fig

% Copyright (C) 21.08.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 19.01.2016 use of rounded values in the scale bar
% 03.02.2016, updated for 4D datasets

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibMakeMovieGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibMakeMovieGUI_OutputFcn, ...
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


% --- Executes just before mibMakeMovieGUI is made visible.
function mibMakeMovieGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibMakeMovieGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.text25.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text25.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibMakeMovieGUI, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibMakeMovieGUI);

% Choose default command line output for mibSnapshotGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left', 'bottom');

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
% set(handles.mibMakeMovieGUI,'WindowStyle','modal');

% UIWAIT makes mibMakeMovieGUI wait for user response (see UIRESUME)
% uiwait(handles.mibMakeMovieGUI);

end

% --- Outputs from this function are returned to the command line.
function varargout = mibMakeMovieGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibMakeMovieGUI.
function mibMakeMovieGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibMakeMovieGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function crop_Callback(hObject, eventdata, handles)
handles.winController.crop_Callback();
end

% --- Executes on button press in continueBtn.
function continueBtn_Callback(hObject, eventdata, handles)
handles.winController.continueBtn_Callback();
end

% function I = addScaleBar(I, pixSize, scale, orientation)
% % Fuse text into an image I
% % based on original code by by Davide Di Gloria
% % http://www.mathworks.com/matlabcentral/fileexchange/26940-render-rgb-text-over-rgb-or-grayscale-image
% % I=renderText(I, text)
% % text -> cell with text
% 
% base=uint8(1-logical(imread('chars.bmp')));
% table='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890''?!"?$%&/()=?^?+???,.-<\|;:_>????*@#[]{} ';
% 
% if orientation == 4
%     pixelSize = pixSize.x/scale;
% elseif orientation == 1
%     pixelSize = pixSize.x/scale;
% elseif orientation == 2
%     pixelSize = pixSize.y/scale;
% end
% 
% width = size(I,2);
% height = size(I,1);
% 
% %scaleBarText = sprintf('%.3f %s',width*pixelSize/10, pixSize.units);
% %scaleBarLength = round(width/10);
% 
% targetStep = width*pixelSize/10;  % targeted length of the scale bar in units
% mag = floor(log10(targetStep));     % magnitude of the scale bar
% magPow = power(10, mag);
% magDigit = floor(targetStep/magPow + 0.5);
% roundStep = magDigit*magPow;    % rounded step
% if mag < 0
%     strText = ['scaleBarText = sprintf(''%.' num2str(abs(mag)) 'f %s'', roundStep, pixSize.units);'];
%     eval(strText);
% else
%     scaleBarText = sprintf('%d %s', roundStep, pixSize.units);
% end
% scaleBarLength = round(roundStep/pixelSize);
% 
% shiftX = 5;     % shift of the scale bar from the left corner
% text_str = scaleBarText;
% if scaleBarLength+shiftX*2+(numel(text_str)*12) > width
%     scaleBarText = sprintf('%.2f %s',width*pixelSize/10, pixSize.units);
%     scaleBarLength = round(width/10);
%     shiftX = 5;     % shift of the scale bar from the left corner
%     text_str = scaleBarText;
% end
% 
% n = numel(text_str);
% ColorsNumber = size(I, 3);
% 
% coord(2,n)=0;
% for i=1:n
%     coord(:,i)= [0 find(table == text_str(i))-1];
% end
% m = floor(coord(2,:)/26);
% coord(1,:) = m*20+1;
% coord(2,:) = (coord(2,:)-m*26)*13+1;
% 
% model = zeros(22,size(I,2),size(I,3), class(I));
% total_index = 1;
% max_int = double(intmax(class(I)));
% 
% if scaleBarLength+shiftX*2+(numel(text_str)*12) > width
%     %msgbox(sprintf('Image is too small to put the scale bar!\nSaving image without the scale bar...'),'Scale bar','warn');
%     return;
% end
% for index = 1:numel(text_str)
%     model(1:20, scaleBarLength+shiftX*2+(12*index-11):scaleBarLength+shiftX*2+(index*12), :) = repmat(imcrop(base,[coord(2,total_index) coord(1,total_index) 11 19])*max_int, [1, 1, ColorsNumber]);
%     total_index = total_index + 1;
% end
% % add scale
% model(10:12, shiftX:shiftX+scaleBarLength-1,:) = repmat(max_int, [3, scaleBarLength, ColorsNumber]);
% model(8:14, shiftX,:) = repmat(max_int, [7, 1, ColorsNumber]);
% model(8:14, shiftX+scaleBarLength-1,:) = repmat(max_int, [7, 1, ColorsNumber]);
% 
% I = cat(1, I, model);
% end


function outputDir_Callback(hObject, eventdata, handles)
handles.winController.outputDir_Callback();
end

% --- Executes on button press in selectFileBtn.
function selectFileBtn_Callback(hObject, eventdata, handles)
handles.winController.selectFileBtn_Callback();
end

% --- Executes on selection change in codecPopup.
function codecPopup_Callback(hObject, eventdata, handles)
handles.winController.codecPopup_Callback();
end

function widthEdit_Callback(hObject, eventdata, handles)
handles.winController.widthEdit_Callback();
end

function heightEdit_Callback(hObject, eventdata, handles)
handles.winController.heightEdit_Callback();
end

function framerateEdit_Callback(hObject, eventdata, handles)
val = str2double(hObject.String);
if val < 1
    hObject.String = '5';
    msgbox('The frame rate should be a positive number', 'Error!', 'error', 'modal');
end
end

function qualityEdit_Callback(hObject, eventdata, handles)
val = str2double(hObject.String);
if val < 1 || val > 100
    hObject.String = '85';
    msgbox('The frame rate should be a positive from 0 through 100.', 'Error!', 'error', 'modal');
end
end


% --- Executes on button press in helpButton.
function helpButton_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile({mibPath}, 'techdoc/html/ug_gui_menu_file_makevideo.html'), '-helpbrowser');
end



function firstFrameEdit_Callback(hObject, eventdata, handles)
handles.winController.firstFrameEdit_Callback();
end


function lastFrameEdit_Callback(hObject, eventdata, handles)
handles.winController.lastFrameEdit_Callback();
end

% --- Executes on key press with focus on mibMakeMovieGUI and none of its controls.
function mibMakeMovieGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibMakeMovieGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    cancelBtn_Callback(handles.closeBtn, eventdata, handles);
end

if isequal(get(hObject,'CurrentKey'),'return')
    continueBtn_Callback(handles.continueBtn, eventdata, handles)
end
end

% --- Executes on button press in scalebarCheck.
function scalebarCheck_Callback(hObject, eventdata, handles)
handles.winController.scalebarCheck_Callback();
end


% --- Executes on selection change in directionPopup.
function directionPopup_Callback(hObject, eventdata, handles)
handles.winController.directionPopup_Callback();
end

% --- Executes on selection change in roiPopup.
function roiPopup_Callback(hObject, eventdata, handles)
handles.winController.roiPopup_Callback();
end


% --- Executes on button press in splitChannelsCheck.
function splitChannelsCheck_Callback(hObject, eventdata, handles)
handles.winController.splitChannelsCheck_Callback();
end

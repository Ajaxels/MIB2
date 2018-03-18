function status = editbox_Callback(hObject, chtype, default_val, variation, hFocus)
% function status = editbox_Callback(hObject, chtype, default_val, variation, hFocus)
% Check for entered values in an edit box
%
% Parameters:
% hObject: handle to the editbox 
% chtype: - required type of the input
% - ''int'' -> positive and negative integers
% - ''pint'' -> positive integers
% - ''float'' -> positive and negative floats
% - ''pfloat'' -> positive floats and zero
% - ''intrange'' -> range of integers without zero
% - ''posintx2''   -> two integers separated with comma
% default_val: - [@em optional], default value if the input is wrong. @b
% default is @b 1
% variation: [@em optional] a variation of the input, a vector [minValue, maxValue]
% hFocus: [@em optional], a handle of uicontroller (such as button to obtain the focus) 
%
% Return values:
% status: result of the function:
% - @b - fail
% - @b - success

% Note! a similar function is present in mibView class, it should probably
% be moved away from there in the future

% Copyright (C) 10.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 5; hFocus = []; end
if nargin < 4
    variation = [-intmax('int32') intmax('int32')];   % variation of the entered value
elseif isempty(variation)
    variation = [NaN, NaN];
end
if nargin < 3
    default_val = '1';  % default value to enter
elseif isempty(default_val)    
    default_val = '1'; 
end
if isnan(variation(1))
    variation(1) = -intmax('int32');
end
if isnan(variation(2))
    variation(2) = intmax('int32');
end

status = 1;
txt = hObject.String;
err_str = '';
switch chtype
    case 'int'
        template = '[-0-9]';
        err_str = 'This value should be a positive/negative integer but not a zero';
    case 'pint'
        template = '[0-9]';
        err_str = 'This value should be a positive integer';
    case 'float'
        template = '[0-9.-]';
        err_str = 'This value should be a float number';
    case 'pfloat'
        template = '[0-9.]';
        err_str = 'This value should be a positive float number';
    case 'intrange'
        template = '[-0-9]';
        err_str = 'This value should be a positive integer range for example: 1-6';
    case 'posintx2'
        template = '[0-9;]';
        err_str = 'This value should be one or two positive integers separated with a semicolon';        
        
end
if ~strcmp(err_str,'')
    num = regexp(txt,template);
    if length(num) ~= length(txt)
        msgbox(err_str,'Error!','error');
        hObject.String = default_val;
        status = 0;
    end
end
if isempty(txt)
    msgbox('Please enter a value!','Error!','error');
    hObject.String = default_val;
    status = 0;
end
if ~isnan(variation) & status == 1
    entered_val = str2double(txt);
    if entered_val < variation(1) || entered_val > variation(2)
        str2 = ['The value should be in range:' num2str(variation(1)) '-' num2str(variation(2))];
        msgbox(str2,'Error!','error');
        hObject.String = default_val;
        status = 0;
    end
end

if status == 0
    hObject.Selected = 'on';
    hObject.BackgroundColor = [1 0 0];
else
    hObject.Selected = 'off';
    hObject.BackgroundColor = [1 1 1];
    if ~isempty(hFocus)
        uicontrol(hFocus);      
    end
end

end
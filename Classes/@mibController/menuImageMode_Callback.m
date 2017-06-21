function menuImageMode_Callback(obj, hObject)
% function menuImageMode_Callback(obj, hObject)
% callback to the Menu->Image->Mode, convert image to different formats
%
% Parameters:
% hObject: handle to the selected menu entry
% 

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if obj.mibModel.getImageProperty('time') < 2; obj.mibModel.mibDoBackup('image', 1); end;

switch get(hObject,'tag')
    case 'menuImageGrayscale'
        if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'truecolor') && size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 3) > 3
            button = questdlg(sprintf('!!! Attention !!!\n\nDirect conversion of the multichannel image to greyscale is not possible\nHowever it is possible to perform conversion using the LUT colors'),'Multiple color channels','Convert','Cancel','Cancel');
            if strcmp(button, 'Cancel'); return; end;
            if obj.mibModel.useLUT == 0
                errordlg('Please make sure that the LUT checkbox in the View settings panel is checked!','LUT is not selected');
                return;
            end
            obj.mibModel.useLUT = 0;
        end
        obj.mibModel.I{obj.mibModel.Id}.convertImage('grayscale');
    case 'menuImageRGBColor'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('truecolor');
    case 'menuImageHSVColor'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('hsvcolor');
    case 'menuImageIndexed'
        if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'truecolor') && size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 3) > 3
            button = questdlg(sprintf('!!! Attention !!!\n\nDirect conversion of the multichannel image to greyscale is not possible\nHowever it is possible to perform conversion using the LUT colors'),...
                'Multiple color channels', 'Convert', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end;
            if obj.mibModel.useLUT == 0
                errordlg('Please make sure that the LUT checkbox in the View settings panel is checked!','LUT is not selected');
                return;
            end
            obj.mibModel.useLUT = 0;
        end
        obj.mibModel.I{obj.mibModel.Id}.convertImage('indexed');
    case 'menuImage8bit'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('uint8');
    case 'menuImage16bit'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('uint16');
    case 'menuImage32bit'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('uint32');
end
obj.updateGuiWidgets();
obj.plotImage();
end
function img = mibAddText2Img_Legacy(img, textArray, positionList, textTable, options)
% function  img = mibAddText2Img_Legacy(img, textArray, positionList, textTable, options)
% Add text label to the image, an older function that does not use
% insertText and insertMarker functions from the Computer Vision System
% Toolbox
%
% Parameters:
%       img: - > image, 2D
%       textArray: -> a cell array with text, [textArray{1}='label1'; textArray{2}='label2';] 
%       positionList: -> position of a label [pointNo; x, y]
%       textTable: -> a bitmap two color image with a table of letters (@em
%       DejaVuSansMono.png); member of mibModel class
%       options: -> a structure with @em optional additional parameters
%           .color -> [@em optional, default color GREY] a number or a rgb-vector with a color for the text,
%           @em for @em example: [1 0 0] - for red; or 0.5 - for grey
%           .fontSize -> [@em optional, default font size=2] a number with a font size from 1 to 7, that corresponds to pt8, 10 ... 20 of DejaVu Sans Mono font.
%           .markerText -> [@em an @em optional @em string, default
%                           'both'] when @b both show a label next to the position marker,
%                           when @b marker - show only the marker without the label, when
%                           @b text - show only text without marker
%       
%
% Return values:
%   img: -> image 2D

%| @b Examples:
%
% @code 
% textArray{1}='label1'; 
% textArray{2}='label2';
% positionList(1,:) = [50, 75];
% positionList(2,:) = [150, 175];
% options.color = [1 0 0];
% options.fontSize = 3;
% selection(:,:,5) = ib_addText2Img(selection(:,:,5), textArray, positionList, obj.mibModel.dejavufont, options);      // add 2 labels to the selection layer
% @endcode

% Copyright (C) 22.05.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global DejaVuSansMono;

if nargin < 5
    options = struct('color', 0.5, 'fontSize', 2, 'markerText', 'both');
end
if nargin < 4; textTable = []; end
if nargin < 3; error('mibAddText2Img: wrong number of parameters'); end

if isempty(textTable)
    if ~isempty(DejaVuSansMono)
        textTable = DejaVuSansMono;
    else
        textTable = 1-imread('DejaVuSansMono.png');   % table with DejaVu font, Pt = 8, 10, 12, 14, 16, 18, 20
    end
end

if isstruct(options)
    if ~isfield(options, 'color'); options.color = 0.5; end
    if ~isfield(options, 'fontSize'); options.fontSize = 2; end
    if ~isfield(options, 'markerText'); options.markerText = 'both'; end
else
    error('mibAddText2Img: parameter _options_ should be a structure!');    
end

if ischar(textArray); textArray = cellstr(textArray); end

% remove labels when show only marker is enabled
if strcmp(options.markerText, 'marker')
    textArray = cell([numel(textArray), 1]);
end

imgH = size(img, 1);
imgW = size(img, 2);
imgC = size(img, 3);

if size(img, 3) ~= numel(options.color)
    options.color = repmat(options.color (1),[1 imgC]);
end

% if options.fontSize > 7     % means that the font size is stated in pixels
%     heightVec = [13 16 18 20];
%     floorVec = abs(floor(options.fontSize./heightVec)-options.fontSize./heightVec);
%     ceilVec = ceil(options.fontSize./heightVec)-options.fontSize./heightVec;
%     [minVal1, minPos1] = min(floorVec);
%     [minVal2, minPos2] = min(ceilVec);
%     if minVal1 < minVal2
%         resize = floor(options.fontSize/heightVec(minPos1));
%         options.fontSize = minPos1;
%     else
%         resize = ceil(options.fontSize/heightVec(minPos2));
%         options.fontSize = minPos2;
%     end
% else
%     resize = 1;
% end

switch options.fontSize
    case 1  % pt 8
        charW = 5;  % width of a character
        charH = 9;  % height of a character
        rowShift = 1;   % Y-shift to get to the proper text size
    case 2  % pt 10
        charW = 6;  % width of a character
        charH = 10;  % height of a character
        rowShift = 10;   % Y-shift to get to the proper text size
    case 3  % pt 12
        charW = 7;  % width of a character
        charH = 13;  % height of a character
        rowShift = 21;   % Y-shift to get to the proper text size
    case 4  % pt 14
        charW = 8;  % width of a character
        charH = 13;  % height of a character
        rowShift = 35;   % Y-shift to get to the proper text size
    case 5  % pt 16
        charW = 10;  % width of a character
        charH = 16; % height of a character
        rowShift = 48;   % Y-shift to get to the proper text size
    case 6  % pt 18
        charW = 11;  % width of a character
        charH = 18; % height of a character
        rowShift = 64;   % Y-shift to get to the proper text size        
    case 7  % pt 20
        charW = 12;  % width of a character
        charH = 20; % height of a character
        rowShift = 84;   % Y-shift to get to the proper text size        
    otherwise
        error('mibAddText2Img: options.fontSize should be between 1 and 7');
end

table='1234567890.-+ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz(),;:@ _/';   % table of characters included in the textTable

for textStrId = 1:numel(textArray)    
    textStr = textArray{textStrId};
    posX = positionList(textStrId, 1);
    posY = positionList(textStrId, 2);
    
    % do not render labels that do not fit in the image view
    if posX < 1 || posY < 1 || posX > imgW || posY>imgH
        continue;
    end
    
    for i=1:numel(textStr)  % get coordinates of the desired letter in textTable
        pos = (find(table == textStr(i))-1)*charW + 1;
        if ~isempty(pos)
            coord(i) = pos; %#ok<AGROW>
        else
            coord(i) = (find(table == ' ') -1)*charW + 1; %#ok<AGROW>   % add space if character was not found
        end
    end
    
    % preserve space for text image
    textImg = zeros([charH charW*numel(textStr)],'uint8');
    dH = 5;
    if strcmp(options.markerText, 'text'); dH = 0; end
    if size(textImg, 1)+dH > imgH
        textImg = [];
    elseif size(textImg, 2)+5 > imgW
        textImg = [];
    end
    
    if ~isempty(textImg)
        for index = 1:numel(textStr)    % generate letters
            textImg(1:charH, index*charW-charW+1:index*charW) = textTable(rowShift:rowShift+charH-1,coord(index):coord(index)+charW-1);
        end
        
        % crop textImg when it is smaller than the shown image
        if size(textImg, 1) + 3 > imgH
            textImg = textImg(1:imgH-3,:);
        end
        if size(textImg, 2) + 3 > imgW
            textImg = textImg(:,1:imgW-3);
        end
        
        % determine where to put a marker cross (left or right part of the image)
        if posX-2 < 1; posX = 3; end     % x
        if posY-2 < 1; posY = 3; end     % y
        if posX+size(textImg, 2) > imgW;  posX = -2; end   % minus sign indicates that the cross is on the right side of the label
        if posY+size(textImg, 1) > imgH;  posY = -2; end
        
        imgTextComb = zeros([size(textImg,1)+3 size(textImg,2)+3], 'uint8');
        if posX > 0 && posY > 0
            imgTextComb(4:end,4:end) = textImg;
            if strcmp(options.markerText, 'both')
                imgTextComb(1:5,3) = 1;
                imgTextComb(3,1:5) = 1;
            end
        elseif posX > 0 && posY < 0
            imgTextComb(4:end,4:end) = textImg;
            if strcmp(options.markerText, 'both')
                imgTextComb(end-2,1:5) = 1;
                imgTextComb(end-4:end,3) = 1;
            end
            posY = imgH - size(imgTextComb,1) + 1;
        elseif posX < 0 && posY > 0
            imgTextComb(1:end-3,1:end-3) = textImg;
            if strcmp(options.markerText, 'both')
                imgTextComb(3,end-4:end) = 1;
                imgTextComb(1:5,end-2) = 1;
            end
            posX = imgW - size(imgTextComb,2) + 3;
        else
            imgTextComb(1:end-3,1:end-3) = textImg;
            if strcmp(options.markerText, 'both')
                imgTextComb(end-2,end-4:end) = 1;
                imgTextComb(end-4:end,end-2) = 1;
            end
            posY = imgH - size(imgTextComb,1) + 1;
            posX = imgW - size(imgTextComb,2) + 1;
        end
        
%         if resize > 1
%             imgTextComb = imresize(imgTextComb, resize);
%         end
        
        for colCh = 1:imgC
            imgCrop = img(posY-2:posY-3+size(imgTextComb,1), posX-2:posX-3+size(imgTextComb,2), colCh);
            if max(options.color) > 1
                imgCrop(imgTextComb==1) = options.color(colCh);
            else
                imgCrop(imgTextComb==1) = options.color(colCh)*intmax(class(img));
            end
            img(posY-2:posY-3+size(imgTextComb,1), posX-2:posX-3+size(imgTextComb,2),colCh) = imgCrop;
        end
    elseif imgH > 5 && imgW > 5     % draw a cross
        if posX-2 < 1; posX = 3; end     % x
        if posX+2 > imgW; posX = imgW - 3; end     % x
        if posY-2 < 1; posY = 3; end     % y 
        if posY+2 > imgH; posY = imgH - 3; end     % y
        for colCh = 1:imgC
            imgCrop = img(posY-2:posY+2, posX-2:posX+2,colCh);
            if max(options.color) > 1
                imgCrop(1:5,3) = options.color(colCh);
                imgCrop(3,1:5) = options.color(colCh);
            else
                imgCrop(1:5,3) = options.color(colCh)*intmax(class(img));
                imgCrop(3,1:5) = options.color(colCh)*intmax(class(img));
            end
            
            img(posY-2:posY+2, posX-2:posX+2,colCh) = imgCrop;
        end
    end
    %img(posY-2:posY-3+size(imgTextComb,1), posX-2:posX-3+size(imgTextComb,2),:) = imgTextComb | img(posY-2:posY-3+size(imgTextComb,1), posX-2:posX-3+size(imgTextComb,2),:);
end
end
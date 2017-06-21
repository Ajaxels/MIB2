function status = convertImage(obj, format)
% function status = convertImage(obj, format)
% Convert image to specified format: 'grayscale', 'truecolor', 'indexed' and 'uint8', 'uint16', 'uint32' class
%
% Parameters:
% format: description of the new image format
% - ''grayscale'' - grayscale image, 1 color channel
% - ''truecolor'' - truecolor image, 2 or 3 color channels (red, green, blue)
% - ''hsvcolor'' - hsv color image, 3 color channels (hue, saturation, value)
% - ''indexed'' - indexed colors, the color map is stored in @em imageData.img_info. @e Colormap
% - ''uint8'' - 8-bit unsinged integer, [0 - 255] levels
% - ''uint16'' - 16-bit unsinged integer, [0 - 65535] levels;
% - ''uint32'' - 32-bit unsinged integer, [0 - 4294967295] levels; @b Note! Not Really tested...
%
% Return values:
% status: @b 1 -success, @b 0 -fail

%| 
% @b Examples:
% @code status = obj.mibModel.I{obj.mibModel.Id}.convertImage(obj, 'grayscale');   // Call from mibController; convert dataset to the grayscale type @endcode

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

status = 0;
global mibPath;

tic
maxCounter = obj.time*obj.depth;
wb = waitbar(0,['Converting image to ' format ' format'], 'Name', 'Converting image', 'WindowStyle', 'modal');
if strcmp(format, 'grayscale')   % -> grayscale
    switch obj.meta('ColorType')
        case 'grayscale'        % grayscale->
            delete(wb);
            return;
        case 'truecolor'    % truecolor->grayscale
            from = 'truecolor';
            if size(obj.img{1}, 3) > 3
                I = zeros([obj.height, obj.width, 1, obj.depth, obj.time], class(obj.img{1})); %#ok<ZEROLIKE>
                selectedColorsLUT = obj.lutColors(obj.slices{3},:);     % take LUT colors for the selected color channels
                max_int = double(intmax(class(obj.img{1})));
                
                index = 0;
                for t=1:obj.time
                    for sliceId=1:obj.depth
                        sliceImg = obj.img{1}(:, :, obj.slices{3}, sliceId, t);    % get slice
                        R = zeros([size(sliceImg,1), size(sliceImg,2)], class(obj.img{1})); %#ok<ZEROLIKE>
                        G = zeros([size(sliceImg,1), size(sliceImg,2)], class(obj.img{1})); %#ok<ZEROLIKE>
                        B = zeros([size(sliceImg,1), size(sliceImg,2)], class(obj.img{1})); %#ok<ZEROLIKE>
                        for colorId=1:numel(obj.slices{3})
                            adjImg = imadjust(sliceImg(:,:,colorId), ...
                                [obj.viewPort.min(obj.slices{3}(colorId))/max_int obj.viewPort.max(obj.slices{3}(colorId))/max_int], ...
                                [0 1], obj.viewPort.gamma(obj.slices{3}(colorId)));
                            R = R + adjImg*selectedColorsLUT(colorId, 1);
                            G = G + adjImg*selectedColorsLUT(colorId, 2);
                            B = B + adjImg*selectedColorsLUT(colorId, 3);
                        end
                        imgRGB = cat(3,R,G,B);
                        I(:,:,1,sliceId,t) = rgb2gray(imgRGB);
                        index = index + 1;
                        if mod(index, 10)==0; waitbar(index/maxCounter, wb); end; 
                    end
                end
                obj.img{1} = I;
            else
                I = obj.img{1};
                if size(I, 3) == 1  % a single color channel
                    I(:,:,2,:,:) = zeros([size(I,1), size(I,2), size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
                    I(:,:,3,:,:) = zeros([size(I,1), size(I,2), size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
                elseif size(I,3) == 2   % two color channels
                    I(:,:,3,:,:) = zeros([size(I,1), size(I,2), size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
                end
                obj.img{1} = zeros([size(I,1), size(I,2), 1, size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
                index = 0;
                for t=1:obj.time
                    for i=1:obj.depth
                        obj.img{1}(:,:,1,i,t) = rgb2gray(I(:,:,:,i,t));
                        if mod(index, 10)==0; waitbar(index/maxCounter, wb); end; 
                        index = index + 1;
                    end
                end
            end
        case 'hsvcolor'    % hsvcolor->grayscale            
            delete(wb);
            errordlg('Please convert the image to RGB color!','Wrong image format!');
            return;
        case 'indexed'      % indexed->grayscale
            from = 'indexed';
            I = obj.img{1};
            obj.img{1} = zeros([size(I,1), size(I,2), 1, size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
            index = 0;
            for t=1:obj.time
                for i=1:obj.depth
                    obj.img{1}(:,:,1,i,t) = ind2gray(I(:,:,:,i,t), obj.meta('Colormap'));
                    if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                    index = index + 1;
                end
            end
            obj.meta('Colormap') = '';
    end
    obj.meta('ColorType') = 'grayscale';
elseif strcmp(format, 'truecolor')   % ->truecolor
    switch obj.meta('ColorType')
        case 'grayscale'    % grayscale->truecolor
            from = 'grayscale';
            I = obj.img{1};
            obj.img{1} = zeros([size(I,1), size(I,2), 3, size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
            obj.img{1}(:,:,1,:,:) = I;
            obj.img{1}(:,:,2,:,:) = I;
            obj.img{1}(:,:,3,:,:) = I;
            waitbar(.85,wb);
        case 'truecolor'    % truecolor->truecolor
            delete(wb);
            return;
        case 'hsvcolor'    % hsvcolor->truecolor
            from = 'hsvcolor';
            I = obj.img{1};
            obj.img{1} = zeros([size(I,1), size(I,2), 3, size(I,4), size(I,5)], 'uint8');
            index = 0;
            for t=1:obj.time
                for i=1:obj.depth
                    obj.img{1}(:,:,:,i,t) = uint8(hsv2rgb(double(I(:,:,:,i,t))/255)*255);
                	if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                    index = index + 1;
                end
            end
            waitbar(.85,wb);
        case 'indexed'      % indexed->truecolor
            from = 'indexed';
            I = obj.img{1};
            obj.img{1} = zeros([size(I,1), size(I,2), 3, size(I,4), size(I,5)], class(I)); %#ok<ZEROLIKE>
            max_int = double(intmax(class(I)));
            index = 0;
            for t=1:obj.time
                for i=1:obj.depth
                    obj.img{1}(:,:,:,i,t) = ind2rgb(I(:,:,:,i,t), obj.meta('Colormap'))*max_int;
                    if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                    index = index + 1;
                end
            end
            obj.meta('Colormap') = '';
    end
    obj.meta('ColorType') = 'truecolor';
elseif strcmp(format,'hsvcolor')   % ->hsvcolor
    switch obj.meta('ColorType')
        case 'grayscale'    % grayscale->hsvcolor
            delete(wb);
            errordlg('Please convert the image to RGB color!','Wrong image format!');
            return;
        case 'truecolor'    % truecolor->hsvcolor
            from = 'truecolor';
            if size(obj.img{1}, 3) ~= 3
                delete(wb);
                errordlg('Please convert the image to RGB color!','Wrong image format!');
                return;
            end
            I = obj.img{1};
            obj.img{1} = zeros([size(I,1), size(I,2), 3, size(I,4), size(I,5)], 'uint8');
            index = 0;
            for t=1:obj.time
                for i=1:obj.depth
                    obj.img{1}(:,:,:,i,t) = uint8(rgb2hsv(I(:,:,:,i,t))*255);
                    if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                    index = index + 1;
                end
            end
            waitbar(.85,wb);
        case 'hsvcolor'
            delete(wb);
            return;            
        case 'indexed'      % indexed->hsvcolor
            delete(wb);
            errordlg('Please convert the image to RGB color!','Wrong image format!');
            return;
    end
    obj.meta('ColorType') = 'hsvcolor';    
elseif strcmp(format,'indexed')   % ->indexed
    if strcmp(obj.meta('ColorType'), 'indexed') % indexed->indexed
        delete(wb);
        return;
    end
    if strcmp(obj.meta('ColorType'), 'hsvcolor') % hsvcolor->indexed
        delete(wb);
        errordlg('Please convert the image to RGB color!','Wrong image format!');
        return;
    end
    %answer = inputdlg(sprintf('Please enter number of graylevels\n [1-65535]'),'Convert to indexed image',1,{'255'});
    answer = mibInputDlg({mibPath}, sprintf('Please enter number of graylevels\n [1-65535]'), 'Convert to indexed image', '255');
    if isempty(answer);  delete(wb); return; end;
    levels = round(str2double(cell2mat(answer)));
    if levels >= 1 && levels <=255
        class_id = 'uint8';
    elseif levels > 255 && levels <= 65535
        class_id = 'uint16';
    else
        delete(wb);
        msgbox('Wrong number of gray levels','Error','error');
        return;
    end
    switch obj.meta('ColorType')
        case 'grayscale'    % grayscale->indexed
            from = 'grayscale';
            I = obj.img{1};
            obj.img{1} = zeros([size(I,1), size(I,2), 1, size(I,4), size(I,5)], class_id);
            index = 0;
            for t=1:obj.time
                for i=1:obj.depth
                    [obj.img{1}(:,:,1,i,t), obj.meta('Colormap')] =  gray2ind(I(:,:,1,i,t),levels);
                    if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                    index = index + 1;
                end
            end
        case 'truecolor'    % truecolor->indexed
            from = 'truecolor';
            if size(obj.img{1},3) > 3
                I = zeros([size(obj.img,1), size(obj.img,2), 1, size(obj.img,4), size(obj.img,5)], class_id);
                selectedColorsLUT = obj.lutColors(obj.slices{3});     % take LUT colors for the selected color channels
                max_int = double(intmax(class(obj.img{1})));
                index = 0;
                for t=1:obj.time
                    for sliceId=1:obj.depth
                        sliceImg = obj.img{1}(:,:,obj.slices{3},sliceId,t);    % get slice
                        R = zeros([size(sliceImg,1), size(sliceImg,2)], class(obj.img{1})); %#ok<ZEROLIKE>
                        G = zeros([size(sliceImg,1), size(sliceImg,2)], class(obj.img{1})); %#ok<ZEROLIKE>
                        B = zeros([size(sliceImg,1), size(sliceImg,2)], class(obj.img{1})); %#ok<ZEROLIKE>
                        for colorId=1:numel(obj.slices{3})
                            adjImg = imadjust(sliceImg(:,:,colorId),[obj.viewPort.min(obj.slices{3}(colorId))/max_int obj.viewPort.max(obj.slices{3}(colorId))/max_int],[0 1],obj.viewPort.gamma(obj.slices{3}(colorId)));
                            R = R + adjImg*selectedColorsLUT(colorId, 1);
                            G = G + adjImg*selectedColorsLUT(colorId, 2);
                            B = B + adjImg*selectedColorsLUT(colorId, 3);
                        end
                        imgRGB = cat(3,R,G,B);
                        [I(:,:,1,sliceId,t), obj.meta('Colormap')] = rgb2ind(imgRGB, levels);
                        if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                        index = index + 1;
                    end
                end
                obj.img{1} = I;
            else
                I = obj.img{1};
                obj.img{1} = zeros([size(I,1), size(I,2), 1, size(I,4), size(I,5)], class_id);
                index = 0;
                for t=1:obj.time
                    for i=1:obj.depth
                        [obj.img{1}(:,:,1,i,t), obj.meta('Colormap')] =  rgb2ind(I(:,:,:,i,t),levels);
                        if mod(index,10)==0; waitbar(index/maxCounter, wb); end; 
                        index = index + 1;
                    end
                end
            end
    end
    obj.meta('ColorType') = 'indexed';
elseif strcmp(format, 'uint8')   % -> uint8
    if strcmp(obj.meta('ColorType'), 'indexed')
        msgbox('Convert to RGB or Grayscale first','Error','error');
        delete(wb);
        return;
    end
    switch class(obj.img{1})
        case 'uint8'
            delete(wb);
            return;
        case 'uint16'       % uint16->uint8 
            from = class(obj.img{1});
            if max(obj.viewPort.min) > 0 || max(obj.viewPort.max)<65535 || mean(obj.viewPort.gamma) ~= 1
                img = zeros(size(obj.img{1}), 'uint8');
                maxIndex = size(obj.img{1}, 5) * size(obj.img{1}, 3) * size(obj.img{1}, 4);
                index = 1;
                
                for t=1:size(obj.img{1}, 5)
                    for c=1:size(obj.img{1}, 3)
                        for z=1:size(obj.img{1}, 4)
                            img(:,:,c,z,t) = uint8(imadjust(obj.img{1}(:,:,c,z,t), [obj.viewPort.min(c)/65535 obj.viewPort.max(c)/65535],[0 1],obj.viewPort.gamma(c))/255);
                            if mod(index,10)==0; waitbar(index/maxIndex, wb); end
                            index = index + 1;
                        end
                    end
                end
                obj.img{1} = img;
                log_text = ['ContrastGamma: Min:' num2str(obj.viewPort.min') ', Max: ' num2str(obj.viewPort.max') ,...
                    ', Gamma: ' num2str(obj.viewPort.gamma')];
                log_text = regexprep(log_text,' +',' ');
                obj.updateImgInfo(log_text);
            else
                obj.img{1}= uint8(obj.img{1} / (double(intmax('uint16'))/double(intmax('uint8'))));
            end
        case 'uint32'       % uint32->uint8
            from = class(obj.img{1});
            obj.img{1} = uint8(obj.img{1} / (double(intmax('uint32'))/double(intmax('uint8'))));
    end
elseif strcmp(format,'uint16')   % -> uint16
    if strcmp(obj.meta('ColorType'),'indexed')
        msgbox('Convert to RGB or Grayscale first','Error','error');
        delete(wb);
        return;
    end
    switch class(obj.img{1})
        case 'uint16'
            delete(wb);
            return;
        case 'uint8'       % uint8->uint16 
            from = class(obj.img{1});
            obj.img{1} = uint16(obj.img{1})*(double(intmax('uint16'))/double(intmax('uint8')));
        case 'uint32'    % uint32->uint16
            from = class(obj.img{1});
            obj.img{1} = uint32(obj.img{1})*(double(intmax('uint32'))/double(intmax('uint8')));
    end
elseif strcmp(format,'uint32')   % -> uint32
    if strcmp(obj.meta('ColorType'),'indexed')
        msgbox('Convert to RGB or Grayscale first','Error','error');
        delete(wb);
        return;
    end
    switch class(obj.img{1})
        case 'uint32'
            delete(wb);
            return;
        case 'uint8'       % uint8->uint32 
            msgbox('Not implemented','Error','error');
            delete(wb);
            return;
            %from = class(obj.img{1});
            %obj.img{1} = uint32(obj.img{1})*(double(intmax('uint32'))/double(intmax('uint8')));
        case 'uint16'      % uint16->uint32
            msgbox('Not implemented','Error','error');
            delete(wb);
            return;
            %from = class(obj.img{1});
            %obj.img{1} = uint32(obj.img{1})*(double(intmax('uint32'))/double(intmax('uint16')));
    end
end

obj.colors = size(obj.img{1}, 3);
obj.slices{3} = 1:obj.colors;   % color slices to show

% update display parameters
obj.updateDisplayParameters();
log_text = ['Converted to from ' from ' to ' format];
obj.updateImgInfo(log_text);
delete(wb);
status = 1;
toc
end

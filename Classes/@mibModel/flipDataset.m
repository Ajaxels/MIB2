function flipDataset(obj, mode)
% function flipDataset(obj, mode)
% Flip dataset horizontally, vertically or in the Z direction
% 
% Flip dataset and other layers in horizontal or vertical direction  
%
% Parameters:
% mode: -> a string that defines the flipping mode
%     - ''flipH'' -> horizontal flip
%     - ''flipV'' -> vertical flip
%     - ''flipZ'' -> flip Z direction
%     - ''flipT'' -> flip T direction
%
% Return values:
% 

% Copyright (C) 01.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if obj.getImageProperty('depth') == 1 && strcmp(mode, 'flipZ'); return; end;   % no z-flipping for single image
tic

options.blockModeSwitch = 0;    % overwrite blockmode switch
wb = waitbar(0,sprintf('Flipping image\nPlease wait...'), 'Name', 'Flip dataset', 'WindowStyle', 'modal');
time = obj.getImageProperty('time');
if time < 2; obj.mibDoBackup('image', 1); end;

if strcmp(mode, 'flipT')
    img = cell2mat(obj.getData4D('image', 4, 0, options));   % get dataset (image)
    index = 1;
    for t=time:-1:1
        obj.setData3D('image', img(:,:,:,:,t), index, 4, 0, options);   % get dataset (image)
        waitbar(index/time, wb);
        index = index + 1;
    end
    
    % flip other layers
    if obj.getImageProperty('modelType') == 63 && obj.preferences.disableSelection == 0
        waitbar(0.5, wb, sprintf('Flipping other layers\nPlease wait...'));
        img = cell2mat(obj.getData4D('everything', 4, 0, options));   % get dataset (image)
        index = 1;
        for t=time:-1:1
            obj.setData3D('everything', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
            index = index + 1;
            waitbar(index/time, wb);
        end
    elseif obj.preferences.disableSelection == 0
        % flip selection layer
        waitbar(0.25, wb, sprintf('Flipping the selection layer\nPlease wait...'));
        img = cell2mat(obj.getData4D('selection', 4, 0, options));   % get dataset (image)
        index = 1;
        for t=time:-1:1
            obj.setData3D('selection', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
            index = index + 1;
            waitbar(index/time, wb);
        end
        
        % flip mask
        if obj.getImageProperty('maskExist')
            waitbar(0.5, wb, sprintf('Flipping the mask layer\nPlease wait...'));
            img = cell2mat(obj.getData4D('mask', 4, 0, options));   % get dataset (image)
            index = 1;
            for t=time:-1:1
                obj.setData3D('mask', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
                index = index + 1;
                waitbar(index/time, wb);
            end
        end
        
        % flip model
        if obj.getImageProperty('modelExist')
            waitbar(0.75, wb, sprintf('Flipping the model layer\nPlease wait...'));
            img = cell2mat(obj.getData4D('model', 4, 0, options));   % get dataset (image)
            index = 1;
            for t=time:-1:1
                obj.setData3D('model', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
                index = index + 1;
                waitbar(index/time, wb);
            end
        end
    end
    waitbar(1, wb, sprintf('Finishing...'));

    log_text = ['Flip: mode=' mode];
    obj.getImageMethod('updateImgInfo', NaN, log_text);
    delete(wb);
    toc;
    
    notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
    eventdata = ToggleEventData(1);
    notify(obj, 'plotImage', eventdata);
    return;
end

% flip image
for t=1:time
    img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get dataset (image)
    %if handles.matlabVersion < 8.2
    %    img = flipme(img, mode);
    %else
        img = flipmeR2013b(img, mode);
    %end
    obj.setData3D('image', img, t, 4, 0, options);   % set dataset (image) back
    waitbar(t/time, wb);
end
clear img;

% flip other layers
if obj.getImageProperty('modelType') == 63 && obj.preferences.disableSelection == 0
    waitbar(0.5, wb, sprintf('Flipping other layers\nPlease wait...'));
    if time < 2
        obj.mibDoBackup('everything', 1);  % backup other layers
    end
    for t=1:time
        img = cell2mat(obj.getData3D('everything', t, 4, NaN, options));   % get dataset (image)
        %if handles.matlabVersion < 8.2
        %    img = flipme(img, mode);
        %else
            img = flipmeR2013b(img, mode);
        %end
        obj.setData3D('everything', img, t, 4, NaN, options);   % set dataset (image) back
        waitbar(t/time, wb);
    end
elseif obj.preferences.disableSelection == 0
    % flip selection layer
    waitbar(0.25, wb, sprintf('Flipping the selection layer\nPlease wait...'));
    for t=1:time
        img = cell2mat(obj.getData3D('selection', t, 4, NaN, options));   % get dataset (image)
        %if handles.matlabVersion < 8.2
        %    img = flipme(img, mode);
        %else
            img = flipmeR2013b(img, mode);
        %end
        obj.setData3D('selection', img, t, 4, NaN, options);   % set dataset (image) back
        waitbar(t/time, wb);
    end
    
    % flip mask
    if obj.getImageProperty('maskExist')
        waitbar(0.5, wb, sprintf('Flipping the mask layer\nPlease wait...'));
        for t=1:time
            img = cell2mat(obj.getData3D('mask', t, 4, NaN, options));   % get dataset (image)
            %if handles.matlabVersion < 8.2
            %    img = flipme(img, mode);
            %else
                img = flipmeR2013b(img, mode);
            %end
            obj.setData3D('mask', img, t, 4, NaN, options);   % set dataset (image) back
            waitbar(t/time, wb);
        end
    end
    
    % flip model
    if obj.getImageProperty('modelExist')
        waitbar(0.75, wb, sprintf('Flipping the model layer\nPlease wait...'));
        for t=1:time
            img = cell2mat(obj.getData3D('model', t, 4, NaN, options));   % get dataset (image)
            %if handles.matlabVersion < 8.2
            %    img = flipme(img, mode);
            %else
                img = flipmeR2013b(img, mode);
            %end
            obj.setData3D('model', img, t, 4, NaN, options);   % set dataset (image) back
            waitbar(t/time, wb);
        end
    end
end
waitbar(1, wb, sprintf('Finishing...'));

log_text = ['Flip: mode=' mode];
obj.getImageMethod('updateImgInfo', NaN, log_text);
delete(wb);

notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);

toc
end

% function img = flipme(img, mode)
% % flip function
% if strcmp(mode, 'flipZ')
%     img = flipdim(img, ndims(img));
% elseif strcmp(mode, 'flipH')
%     img = flipdim(img, 2);
% elseif strcmp(mode, 'flipV')
%     img = flipdim(img, 1);
% end
% end

function img = flipmeR2013b(img, mode)
% flip function, for newer releases
if strcmp(mode, 'flipZ')
    img = flip(img, ndims(img));
elseif strcmp(mode, 'flipH')
    img = flip(img, 2);
elseif strcmp(mode, 'flipV')
    img = flip(img, 1);
end
end
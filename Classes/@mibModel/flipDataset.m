function flipDataset(obj, mode, showWaitbar)
% function flipDataset(obj, mode, showWaitbar)
% Flip dataset horizontally, vertically or in the Z direction
% 
% Flip dataset and other layers in horizontal or vertical direction  
%
% Parameters:
% mode: -> a string that defines the flipping mode
%     - ''Flip horizontally'' -> horizontal flip
%     - ''Flip vertically'' -> vertical flip
%     - ''Flip Z'' -> flip Z direction
%     - ''Flip T'' -> flip T direction
% showWaitbar: logical, show or not the waitbar
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

if nargin < 3; showWaitbar = true; end

if obj.getImageProperty('depth') == 1 && strcmp(mode, 'Flip Z'); return; end   % no z-flipping for single image
tic

options.blockModeSwitch = 0;    % overwrite blockmode switch
if showWaitbar; wb = waitbar(0,sprintf('Flipping image\nPlease wait...'), 'Name', 'Flip dataset', 'WindowStyle', 'modal'); end
time = obj.getImageProperty('time');
if time < 2; obj.mibDoBackup('image', 1); end

if strcmp(mode, 'Flip T')
    img = cell2mat(obj.getData4D('image', 4, 0, options));   % get dataset (image)
    index = 1;
    for t=time:-1:1
        obj.setData3D('image', img(:,:,:,:,t), index, 4, 0, options);   % get dataset (image)
        if showWaitbar; waitbar(index/time, wb); end
        index = index + 1;
    end
    
    % flip other layers
    if obj.getImageProperty('modelType') == 63 && obj.I{obj.Id}.disableSelection == 0
        if showWaitbar; waitbar(0.5, wb, sprintf('Flipping other layers\nPlease wait...')); end
        img = cell2mat(obj.getData4D('everything', 4, 0, options));   % get dataset (image)
        index = 1;
        for t=time:-1:1
            obj.setData3D('everything', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
            index = index + 1;
            if showWaitbar; waitbar(index/time, wb); end
        end
    elseif obj.I{obj.Id}.disableSelection == 0
        % flip selection layer
        if showWaitbar; waitbar(0.25, wb, sprintf('Flipping the selection layer\nPlease wait...')); end
        img = cell2mat(obj.getData4D('selection', 4, 0, options));   % get dataset (image)
        index = 1;
        for t=time:-1:1
            obj.setData3D('selection', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
            index = index + 1;
            if showWaitbar; waitbar(index/time, wb); end
        end
        
        % flip mask
        if obj.getImageProperty('maskExist')
            if showWaitbar; waitbar(0.5, wb, sprintf('Flipping the mask layer\nPlease wait...')); end
            img = cell2mat(obj.getData4D('mask', 4, 0, options));   % get dataset (image)
            index = 1;
            for t=time:-1:1
                obj.setData3D('mask', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
                index = index + 1;
                if showWaitbar; waitbar(index/time, wb); end
            end
        end
        
        % flip model
        if obj.getImageProperty('modelExist')
            if showWaitbar; waitbar(0.75, wb, sprintf('Flipping the model layer\nPlease wait...')); end
            img = cell2mat(obj.getData4D('model', 4, 0, options));   % get dataset (image)
            index = 1;
            for t=time:-1:1
                obj.setData3D('model', img(:,:,:,t), index, 4, 0, options);   % get dataset (image)
                index = index + 1;
                if showWaitbar; waitbar(index/time, wb); end
            end
        end
    end
    if showWaitbar; waitbar(1, wb, sprintf('Finishing...')); end

    log_text = ['Flip: mode=' mode];
    obj.getImageMethod('updateImgInfo', NaN, log_text);
    if showWaitbar; delete(wb); end
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
    if showWaitbar; waitbar(t/time, wb); end
end
clear img;

% flip other layers
if obj.getImageProperty('modelType') == 63 && obj.I{obj.Id}.disableSelection == 0
    if showWaitbar; waitbar(0.5, wb, sprintf('Flipping other layers\nPlease wait...')); end
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
        if showWaitbar; waitbar(t/time, wb); end
    end
elseif obj.I{obj.Id}.disableSelection == 0
    % flip selection layer
    if showWaitbar; waitbar(0.25, wb, sprintf('Flipping the selection layer\nPlease wait...')); end
    for t=1:time
        img = cell2mat(obj.getData3D('selection', t, 4, NaN, options));   % get dataset (image)
        %if handles.matlabVersion < 8.2
        %    img = flipme(img, mode);
        %else
            img = flipmeR2013b(img, mode);
        %end
        obj.setData3D('selection', img, t, 4, NaN, options);   % set dataset (image) back
        if showWaitbar; waitbar(t/time, wb); end
    end
    
    % flip mask
    if obj.getImageProperty('maskExist')
        if showWaitbar; waitbar(0.5, wb, sprintf('Flipping the mask layer\nPlease wait...')); end
        for t=1:time
            img = cell2mat(obj.getData3D('mask', t, 4, NaN, options));   % get dataset (image)
            %if handles.matlabVersion < 8.2
            %    img = flipme(img, mode);
            %else
                img = flipmeR2013b(img, mode);
            %end
            obj.setData3D('mask', img, t, 4, NaN, options);   % set dataset (image) back
            if showWaitbar; waitbar(t/time, wb); end
        end
    end
    
    % flip model
    if obj.getImageProperty('modelExist')
        if showWaitbar; waitbar(0.75, wb, sprintf('Flipping the model layer\nPlease wait...')); end
        for t=1:time
            img = cell2mat(obj.getData3D('model', t, 4, NaN, options));   % get dataset (image)
            %if handles.matlabVersion < 8.2
            %    img = flipme(img, mode);
            %else
                img = flipmeR2013b(img, mode);
            %end
            obj.setData3D('model', img, t, 4, NaN, options);   % set dataset (image) back
            if showWaitbar; waitbar(t/time, wb); end
        end
    end
end
if showWaitbar; waitbar(1, wb, sprintf('Finishing...')); end

log_text = ['Flip: mode=' mode];
obj.getImageMethod('updateImgInfo', NaN, log_text);
if showWaitbar; delete(wb); end

notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);

toc
end

% function img = flipme(img, mode)
% % flip function
% if strcmp(mode, 'flip Z')
%     img = flipdim(img, ndims(img));
% elseif strcmp(mode, 'Flip horizontally')
%     img = flipdim(img, 2);
% elseif strcmp(mode, 'Flip vertically')
%     img = flipdim(img, 1);
% end
% end

function img = flipmeR2013b(img, mode)
% flip function, for newer releases
if strcmp(mode, 'Flip Z')
    img = flip(img, ndims(img));
elseif strcmp(mode, 'Flip horizontally')
    img = flip(img, 2);
elseif strcmp(mode, 'Flip vertically')
    img = flip(img, 1);
end
end
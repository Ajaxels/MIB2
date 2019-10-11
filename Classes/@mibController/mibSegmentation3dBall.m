function mibSegmentation3dBall(obj, y, x, z, modifier, BatchOptIn)
% function mibSegmentation3dBall(obj, y, x, z, modifier, BatchOptIn)
% Do segmentation using the 3D ball tool
%
% Parameters:
% y: y-coordinate of the 3D ball center
% x: x-coordinate of the 3D ball center
% z: z-coordinate of the 3D ball center
% modifier: a string, to specify what to do with the generated selection
% - @em empty - add to 3D ball to the selection layer
% - @em ''control'' - remove 3D ball from the selection layer
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Radius - Spot radius in pixels
% @li .X - Vector or a single X coordinate of the spot center
% @li .Y - Vector or a single X coordinate of the spot center
% @li .Z - Vector or a single Z coordinate of the spot center, keep empty to use the currently shown
% @li .Mode - Add or subtract spot at the provided coordinate(s)
% @li .FixSelectionToMask - Apply thresholding only to the masked area
% @li .FixSelectionToMaterial - Apply thresholding only to the area of the selected material; use Modify checkboxes to update the selected material
% @li .Target - Destination layer for spot
% @li .showWaitbar - Show or not the progress bar during execution
%
% Return values:
% 

%| @b Examples:
% @code obj.mibSegmentation3dBall(50, 75, 10, '');  // call from mibController; add a 3D ball to position [y,x,z]=50,75,10 @endcode

% Copyright (C) 16.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String);

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.id = obj.mibModel.Id;   % optional, id
BatchOpt.Radius = num2str(radius);
if ~isempty(x)
    BatchOpt.X = num2str(x);
else
    BatchOpt.X = '';    
end
if ~isempty(y)
    BatchOpt.Y = num2str(y);
else
    BatchOpt.Y = '';
end
BatchOpt.Z = '';
if isempty(modifier)
    BatchOpt.Mode = {'add'};
else
    if strcmp(modifier, 'shift')
        BatchOpt.Mode = {'add'};
    else
        BatchOpt.Mode = {'erase'};
    end
end
BatchOpt.Mode{2} = {'add', 'erase'};
BatchOpt.FixSelectionToMask = logical(obj.mibModel.I{BatchOpt.id}.fixSelectionToMask); 
BatchOpt.FixSelectionToMaterial = logical(obj.mibModel.I{BatchOpt.id}.fixSelectionToMaterial);  
BatchOpt.Target = {'selection'};
BatchOpt.Target{2} = {'selection', 'mask'};
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = '3D ball';

BatchOpt.mibBatchTooltip.Radius = 'Ball radius in pixels';
BatchOpt.mibBatchTooltip.X = 'Vector or a single X coordinate of the 3D ball center';
BatchOpt.mibBatchTooltip.Y = 'Vector or a single X coordinate of the 3D ball center';
BatchOpt.mibBatchTooltip.Z = 'Vector or a single Z coordinate of the 3D ball center, keep empty to use the currently shown';
BatchOpt.mibBatchTooltip.Mode = 'Add or subtract a 3D ball at the provided coordinate(s)';
BatchOpt.mibBatchTooltip.FixSelectionToMask = 'Apply 3D ball only to the masked area';
BatchOpt.mibBatchTooltip.FixSelectionToMaterial = 'Apply 3D ball only to the area of the selected material; use Modify checkboxes to update the selected material';
BatchOpt.mibBatchTooltip.Target = 'Destination layer for spot';
BatchOpt.mibBatchTooltip.showWaitbar = 'Show or not the progress bar during execution';

%%
if nargin == 6  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 5th parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

%%
pixSize = obj.mibModel.I{BatchOpt.id}.pixSize;
minVox = min([pixSize.x pixSize.y pixSize.z]);
ratioX = pixSize.x/minVox;
ratioY = pixSize.y/minVox;
ratioZ = pixSize.z/minVox;
radius = str2double(BatchOpt.Radius) - 1;
radius = [radius/ratioX radius/ratioX;radius/ratioY radius/ratioY;radius/ratioZ radius/ratioZ];
radius = round(radius);
rad_vec = radius; % vector of radii [-dy +dy;-dx +dx; -dz +dz] for detection out of image border cases
y_max = obj.mibModel.I{BatchOpt.id}.height; 
x_max = obj.mibModel.I{BatchOpt.id}.width;
z_max = obj.mibModel.I{BatchOpt.id}.depth; 

xVec = str2num(BatchOpt.X); %#ok<ST2NM>
yVec = str2num(BatchOpt.Y); %#ok<ST2NM>
if isempty(BatchOpt.Z)
    zVec = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
else
    zVec = str2num(BatchOpt.Z);     %#ok<ST2NM>
end
if numel(xVec) ~= numel(yVec)
    errordlg(sprintf('!!! Error !!!\n\nNumber of X and Y coordinate mismatch!'), '3D ball segmentation');
    notify(obj.mibModel, 'stopProtocol');
    return;
end
if numel(zVec) < numel(xVec)    % make the zVec equal to xVec and yVec
    zVec = repmat(zVec(1), [1, numel(xVec)]);
end

showWaitbarLocal = 0;
if BatchOpt.showWaitbar && numel(xVec) > 1
    showWaitbarLocal = 1;
end
if showWaitbarLocal; wb = waitbar(0, 'Please wait...', 'Name', '3D ball segmentation'); end

max_rad = max(max(radius));
[x1,y1,z1] = meshgrid(-max_rad:max_rad,-max_rad:max_rad,-max_rad:max_rad);
ball = sqrt((x1/radius(1,1)).^2+(y1/radius(2,1)).^2+(z1/radius(3,1)).^2);
for index = 1:numel(xVec)
    y = yVec(index);
    x = xVec(index);
    z = zVec(index);
    rad_vec2 = rad_vec;
    
    if y-radius(1,1)<=0; rad_vec2(1,1) = y-1; end
    if y+radius(1,2)>y_max; rad_vec2(1,2) = y_max-y; end
    if x-radius(2,1)<=0; rad_vec2(2,1) = x-1; end
    if x+radius(2,2)>x_max; rad_vec2(2,2) = x_max-x; end
    if z-radius(3,1)<=0; rad_vec2(3,1) = z-1; end
    if z+radius(3,2)>z_max; rad_vec2(3,2) = z_max-z; end
    
    selarea = zeros(max_rad*2+1,max_rad*2+1,max_rad*2+1, 'uint8');    % do strel ball type in volume
    selarea(ball<=1) = 1;
    selarea = selarea(max_rad-rad_vec2(1,1)+1:max_rad+rad_vec2(1,2)+1,max_rad-rad_vec2(2,1)+1:max_rad+rad_vec2(2,2)+1,max_rad-rad_vec2(3,1)+1:max_rad+rad_vec2(3,2)+1);
    options.y = [y-rad_vec2(1,1) y+rad_vec2(1,2)];
    options.x = [x-rad_vec2(2,1) x+rad_vec2(2,2)];
    options.z = [z-rad_vec2(3,1) z+rad_vec2(3,2)];
    options.id = BatchOpt.id;

    % do backup
    if index == 1
        if numel(xVec) == 1
            obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 1, options); 
        else
            backupOpt.id = options.id;
            obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 1, backupOpt); 
        end
    end

    % limit selection to material of the model
    if BatchOpt.FixSelectionToMaterial
        selcontour = obj.mibModel.I{BatchOpt.id}.getSelectedMaterialIndex();
        model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, selcontour, options));
        selarea = selarea & model;
    end

    % limit selection to the masked area
    if BatchOpt.FixSelectionToMask && obj.mibModel.I{BatchOpt.id}.maskExist   % do selection only in the masked areas
        model = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, options));
        selarea = selarea & model;
    end

    if strcmp(BatchOpt.Mode{1}, 'add')    % combines selections
        selarea = cell2mat(obj.mibModel.getData3D(BatchOpt.Target{1}, NaN, 4, NaN, options)) | selarea;
        obj.mibModel.setData3D(BatchOpt.Target{1}, {selarea}, NaN, 4, NaN, options);
    else  % subtracts selections
        sel = cell2mat(obj.mibModel.getData3D(BatchOpt.Target{1}, NaN, 4, NaN, options));
        sel(selarea==1) = 0;
        obj.mibModel.setData3D(BatchOpt.Target{1}, {sel}, NaN, 4, NaN, options);
    end
    if showWaitbarLocal; wb = waitbar(index/numel(xVec), wb); end
end
if showWaitbarLocal; delete(wb); end
obj.plotImage();


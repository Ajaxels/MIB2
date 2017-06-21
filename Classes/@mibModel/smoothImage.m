function smoothImage(obj, type)
% function smoothImage(obj, type)
% smooth 'Mask', 'Selection' or 'Model' layer
%
% Parameters:
% type: a string with type of the layer for the smoothing
% - ''selection'' - smooth the 'Selection' layer
% - ''model'' - smooth the 'Model' layer
% - ''mask'' - smooth the 'Mask' layer
% 
% Return values:
% 

% Copyright (C) 10.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

title = [type 'Smoothing...'];
def = {'2D', '5', '5', '5'};
prompt = {'Mode (''3D'' for smoothing in 3D or ''2D'' for smoothing in 2D):',...
    'XY Kernel size:', ...
    sprintf('Z Kernel size for 3D; Y-dim for 2D\nleave empty for automatic calculation based on voxel size:'),...
    'Sigma'};
answer = inputdlg(prompt, title, [1 30], def, 'on');    
if size(answer) == 0; return; end; 

if isnan(str2double(answer{3}))
    kernel = str2double(answer{2});
else
    kernel = [str2double(answer{2}) str2double(answer{3})];
end

if strcmp(answer{1},'2D')
    options.fitType = 'Gaussian';
else
    options.fitType = 'Gaussian 3D';
end
options.hSize = kernel;
if isempty(answer{4})
    options.sigma = 1;
else
    options.sigma = str2double(answer{4});    
end

options.pixSize = obj.I{obj.Id}.pixSize;
options.orientation = obj.I{obj.Id}.orientation;
options.showWaitbar = 0;    % do not show the waitbar in the ib_doImageFiltering function
type = lower(type);
t1 = 1;
t2 = obj.I{obj.Id}.time;

wb = waitbar(0, sprintf('Smoothing the %s layer\nPlease wait...', type), ...
    'Name', 'Smoothing', 'WindowStyle', 'modal');

switch type
    case {'mask', 'selection'}
        if t1==t2
            obj.mibDoBackup(type, 1);
        end
        options.dataType = '3D';
        for t=t1:t2
            mask = cell2mat(obj.getData3D(type, t, 4));
            mask = mibDoImageFiltering(mask, options);
            obj.setData3D(type, mask, t, 4);
            waitbar(t/t2,wb);
        end
    case 'model'
        options.dataType = '3D';
        sel_model = obj.I{obj.Id}.selectedMaterial - 2;
        if sel_model < 1; return; end;
        if t1==t2
            obj.mibDoBackup('model', 1);
        end
        start_no=sel_model;
        end_no=sel_model;
        
        for t=t1:t2
            for object = start_no:end_no
                model = cell2mat(obj.getData3D('model', t, 4, object));
                model = mibDoImageFiltering(model, options);
                obj.setData3D('model', model, t, 4, object);
            end
            waitbar(t/t2,wb);
        end
end
delete(wb);
end
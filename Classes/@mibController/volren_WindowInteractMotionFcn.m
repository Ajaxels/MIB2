function volren_WindowInteractMotionFcn(obj, seltype)
% function volren_WindowInteractMotionFcn(obj, seltype)
% callback for translation/rotation of dataset during the volume rendering mode
%
% Parameters:
% seltype: a string with parameter
% @li 'normal' - rotation mode
% @li 'alt' - pan/translation mode

% Copyright (C) 24.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

xy = obj.mibView.handles.mibImageAxes.CurrentPoint;
if (~isempty(xy))
    axes_size(1) = obj.mibModel.I{obj.mibModel.Id}.axesX(2)-obj.mibModel.I{obj.mibModel.Id}.axesX(1);
    axes_size(2) = obj.mibModel.I{obj.mibModel.Id}.axesY(2)-obj.mibModel.I{obj.mibModel.Id}.axesY(1);
    brush_curr_xy = [xy(1, 1) xy(1, 2)]./axes_size(1:2);  % as fraction of the viewing axes
end

if strcmp(seltype, 'normal')    % rotation
    dx = obj.mibView.brushPrevXY(1) - brush_curr_xy(1);
    dy = obj.mibView.brushPrevXY(2) - brush_curr_xy(2);
    r1 = -360*dx;   % r1 = radtodeg(atan2(R(3,2), R(3,3)));
    r2 = 360*dy;    % r2 = radtodeg(atan2(-R(3,1), sqrt( R(3,2)^2+R(3,3)^2 )));
    R = RotationMatrix([r1, r2, 0]);

    %r3 = radtodeg(atan2(R(2,1), R(1,1)));
    
    %obj.mibModel.I{obj.mibModel.Id}.volren.Rx = mod(obj.mibModel.I{obj.mibModel.Id}.volren.Rx + r1, 360);
    %obj.mibModel.I{obj.mibModel.Id}.volren.Ry = mod(obj.mibModel.I{obj.mibModel.Id}.volren.Ry + r2, 360);
    %obj.mibModel.I{obj.mibModel.Id}.volren.Rz = mod(obj.mibModel.I{obj.mibModel.Id}.volren.Rz + r3, 360);
    %sprintf('Rx=%f, Ry=%f, Rz=%f\n', obj.mibModel.I{obj.mibModel.Id}.volren.Rx, obj.mibModel.I{obj.mibModel.Id}.volren.Ry, obj.mibModel.I{obj.mibModel.Id}.volren.Rz)
    
    obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = R*obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix;
elseif strcmp(seltype, 'alt')   % pan
    t2=550*(obj.mibView.brushPrevXY(1) - brush_curr_xy(1));
    t1=550*(obj.mibView.brushPrevXY(2) - brush_curr_xy(2));
    
    obj.mibModel.I{obj.mibModel.Id}.volren.T = TranslateMatrix([t1 t2 0]);
    T = TranslateMatrix([t1 t2 0]);
    obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = T*obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix;
end
obj.mibView.brushPrevXY = brush_curr_xy;
obj.plotImage();
end

function R = RotationMatrix(r)
% Determine the rotation matrix (View matrix) for rotation angles xyz ...
Rx=[1 0 0 0;                     0 cosd(r(1)) -sind(r(1)) 0;     0 sind(r(1)) cosd(r(1)) 0;    0 0 0 1];
Ry=[cosd(r(2)) 0 sind(r(2)) 0;   0 1 0 0;                        -sind(r(2)) 0 cosd(r(2)) 0;   0 0 0 1];
Rz=[cosd(r(3)) -sind(r(3)) 0 0;  sind(r(3)) cosd(r(3)) 0 0;      0 0 1 0;                      0 0 0 1];
R=Rx*Ry*Rz;
end

function M = TranslateMatrix(t)
M=[1 0 0 -t(1);
    0 1 0 -t(2);
    0 0 1 -t(3);
    0 0 0 1];
%M = makehgtform('translate',-t(1),-t(2),-t(3)) ;
end


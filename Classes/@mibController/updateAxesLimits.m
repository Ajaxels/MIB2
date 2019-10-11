function updateAxesLimits(obj, mode, index, newMagFactor)
% function updateAxesLimits(obj, index, mode, newMagFactor)
% Updates the obj.mibImage.axesX and obj.mibImage.axesY during fit screen, resize, or new dataset drawing
%
% Parameters:
% mode: update mode
% @li 'resize' -> [@em default] scale to width/height
% @li 'zoom' -> scale during the zoom
% index: [@b optional] index of the mibImage to update, when @em [] updates the currently selected dataset
% newMagFactor: a value of the new magnification factor, only for the 'zoom' mode
% Return values:
% 

%| 
% @b Examples:
% @code obj.updateAxesLimits('zoom', newMagFactor);     // call from mibController; update the axes using new magnification value @endcode
% @code obj.updateAxesLimits('resize'); // call from mibController; to fit the screen @endcode

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin <  4; newMagFactor = 1; end
if nargin <  3; index = []; end
if nargin <  2; mode = []; end

if isempty(index); index = obj.mibModel.Id; end
if isempty(mode); mode = 'resize'; end

% get the scaling coefficient
if obj.mibModel.I{index}.orientation == 4     % xy
    coef_z = obj.mibModel.I{index}.pixSize.x/obj.mibModel.I{index}.pixSize.y;
    Height = obj.mibModel.I{index}.height;
    Width = obj.mibModel.I{index}.width;
elseif obj.mibModel.I{index}.orientation == 1     % xz
    coef_z = obj.mibModel.I{index}.pixSize.z/obj.mibModel.I{index}.pixSize.x;
    Height = obj.mibModel.I{index}.width;
    Width = obj.mibModel.I{index}.depth;
elseif obj.mibModel.I{index}.orientation == 2     % yz
    coef_z = obj.mibModel.I{index}.pixSize.z/obj.mibModel.I{index}.pixSize.y;
    Height = obj.mibModel.I{index}.height;
    Width = obj.mibModel.I{index}.depth;
end

obj.mibView.handles.mibImageAxes.Units = 'pixels';
axSize = obj.mibView.handles.mibImageAxes.Position;
[axesX, axesY] = obj.mibModel.getAxesLimits(index);
magFactor = obj.mibModel.getMagFactor(index);
if isnan(axesX(1)) || strcmp(mode, 'resize') == 1
    if obj.mibModel.I{index}.volren.show == 0
        if Height < axSize(4) && Width*coef_z >= axSize(3)     % scale to width
            magFactor = Width*coef_z/axSize(3);
            axesX(1) = 1;
            axesX(2) = Width;
            axesY(1) = Height/2 - axSize(4)/2*magFactor;
            axesY(2) = Height/2 + axSize(4)/2*magFactor;
        elseif Height >= axSize(4) && Width*coef_z < axSize(3)     % scale to height
            magFactor = Height/axSize(4);
            axesX(1) = Width/2 - axSize(3)/2/coef_z*magFactor;
            axesX(2) = Width/2 + axSize(3)/2/coef_z*magFactor;
            axesY(1) = 1;
            axesY(2) = Height;
        else        % scale to the width/height
            if axSize(4)/Height < axSize(3)/(Width*coef_z)   % scale to height
                magFactor = Height/axSize(4);
                axesX(1) = Width/2 - axSize(3)/coef_z/2*magFactor;
                axesX(2) = Width/2 + axSize(3)/2/coef_z*magFactor;
                axesY(1) = 1;
                axesY(2) = Height;
            else % scale to width
                magFactor = Width*coef_z/axSize(3);
                axesX(1) = 1;
                axesX(2) = Width;
                axesY(1) = Height/2 - axSize(4)/2*magFactor;
                axesY(2) = Height/2 + axSize(4)/2*magFactor;
            end
        end
        obj.mibModel.setAxesLimits(axesX, axesY, index);
        obj.mibModel.setMagFactor(magFactor, index);
    else
        if Height < axSize(4) && Width*coef_z >= axSize(3)     % scale to width   
            newMagFactor = Width*coef_z/axSize(3);
        elseif Height >= axSize(4) && Width*coef_z < axSize(3)     % scale to height
            newMagFactor = Height/axSize(4);
        else
            if axSize(4)/Height < axSize(3)/(Width*coef_z)   % scale to height
                newMagFactor = Height/axSize(4);
            else % scale to width
                newMagFactor = Width*coef_z/axSize(3);
            end
        end
        scaleRatio = newMagFactor/magFactor;
        obj.mibModel.setMagFactor(newMagFactor, index);
        S = makehgtform('scale', 1/scaleRatio);
        obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = S * obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix;
        obj.mibView.handles.mibZoomEdit.String = [num2str(str2double(sprintf('%.3f', 1/newMagFactor))*100) ' %'];
    end
elseif strcmp(mode, 'zoom')
    if obj.mibModel.I{obj.mibModel.Id}.volren.show == 0
        dxHalf = diff(axesX)/2;
        dyHalf = diff(axesY)/2;
        xCenter = axesX(1) + dxHalf;
        yCenter = axesY(1) + dyHalf;
        xLim(1) = xCenter - dxHalf*newMagFactor/magFactor;
        xLim(2) = xCenter + dxHalf*newMagFactor/magFactor;
        yLim(1) = yCenter - dyHalf*newMagFactor/magFactor;
        yLim(2) = yCenter + dyHalf*newMagFactor/magFactor;
        % check for out of image boundaries cases
        if xLim(2) < 1 || xLim(1) > Width
            xLim = xLim - xLim(1);
        end;
        if yLim(2) < 1 || yLim(1) > Height
            yLim = yLim - yLim(1);
        end;
        
        obj.mibModel.setAxesLimits(xLim, yLim, index)
    else
        scaleRatio = newMagFactor/magFactor;
        S = makehgtform('scale', 1/scaleRatio);
        obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = S * obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix;
    end
    obj.mibModel.setMagFactor(newMagFactor, index);
end
end
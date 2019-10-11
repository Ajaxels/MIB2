function mibGUI_WindowDragAndDropMotionFcn(obj, brushSelection, varargin)
% function mibGUI_WindowBrushMotionFcn(obj, brushSelection)
% This function draws the displaced materials during use of the drag and
% drop materials tool
%
% Parameters:
% brushSelection: an image of the selected layer

% Copyright (C) 05.08.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

pos = obj.mibView.handles.mibImageAxes.CurrentPoint;
XLim = size(obj.mibView.Ishown,2);
YLim = size(obj.mibView.Ishown,1);
pos = round(pos);

if pos(1,1)<=0; pos(1,1)=1; end
if pos(1,1)>XLim; pos(1,1)=XLim; end
if pos(1,2)<=0; pos(1,2)=1; end
if pos(1,2)>YLim; pos(1,2)=YLim; end

if isnan(obj.mibView.brushPrevXY(1,1))
    obj.mibView.brushPrevXY = [pos(1,1) pos(1,2)];
    return;
end

% calculate shift for the selection layer
diffX = pos(1,1) - obj.mibView.brushPrevXY(1);
diffY = pos(1,2) - obj.mibView.brushPrevXY(2);

selAreaOut = zeros(size(brushSelection), 'uint8');
w2 = XLim-abs(diffX);
h2 = YLim-abs(diffY);
if diffY>0 && diffX>0
    selAreaOut(diffY+1:end, diffX+1:end) = brushSelection(1:h2, 1:w2);
elseif diffY>0 && diffX<=0
    selAreaOut(diffY+1:end, 1:w2) = brushSelection(1:h2, abs(diffX)+1:end);
elseif diffY<=0 && diffX>0
    selAreaOut(1:h2, diffX+1:end) = brushSelection(abs(diffY)+1:end, 1:w2);
elseif diffY<=0 && diffX<=0
    selAreaOut(1:h2, 1:w2) = brushSelection(abs(diffY)+1:end, abs(diffX)+1:end);
end
img = obj.mibView.Ishown;
img(selAreaOut==1) = img(selAreaOut==1) + intmax(class(obj.mibView.Ishown))*.4;

obj.mibView.imh.CData = img;
end

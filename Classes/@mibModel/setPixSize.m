function setPixSize(obj, pixSize, id)
% function setPixSize(obj, pixSize, id)
% set pixSize structure for the currently shown or id dataset
%
% Parameters:
% pixSize: a structure with diminsions of voxels, @code .x .y .z .t .tunits .units @endcode
% the fields are
% @li .x - physical width of a pixel
% @li .y - physical height of a pixel
% @li .z - physical thickness of a pixel
% @li .t - time between the frames for 2D movies
% @li .tunits - time units
% @li .units - physical units for x, y, z. Possible values: [m, cm, mm, um, nm]
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.setPixSize(pixSize);     // call from mibController: set pixSize for the currently shown dataset @endcode
% @code obj.mibModel.setPixSize(pixSize, 4);     // call from mibController: set pixSize for dataset 4 @endcode

% Copyright (C) 25.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
if nargin < 3; id = obj.Id; end 
if nargin < 2
    errordlg(sprintf('!!! Error !!!\n\nthe pixSize parameter is missing'),'mibModel.setPixSize');
    return;
end;
obj.I{id}.pixSize = pixSize;
end



function updateShownId(obj, Id)
% function updateShownId(Id)
% update index of the displayed dataset, after, for example press of the
% handles.mibBufferToggle buttons in mibGUI
%
% Parameters:
% Id: index of the dataset
%

%| 
% @b Examples:
% @code obj.updateShownId(str2double(Id));     // a call from obj.mibBufferToggle_Callback  @endcode

% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

obj.mibModel.mibPrevId = num2str(obj.mibModel.Id);   % update previously shown id
obj.mibModel.Id = Id;               % update Id
notify(obj.mibModel, 'updateId');   % notify the controller about updated Id
obj.plotImage(0);                   % plot image
end
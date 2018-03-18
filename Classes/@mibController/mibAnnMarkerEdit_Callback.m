function mibAnnMarkerEdit_Callback(obj)
% function mibAnnMarkerEdit_Callback(obj)
% callback for selection of annotation marker type, updates
% mibAnnMarkerEdit field of the mibModel
%
% Parameters: 
%
% Return values
%

% Copyright (C) 28.02.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.mibModel.mibAnnMarkerEdit = lower(obj.mibView.handles.mibAnnMarkerEdit.String{obj.mibView.handles.mibAnnMarkerEdit.Value});
obj.plotImage();
end

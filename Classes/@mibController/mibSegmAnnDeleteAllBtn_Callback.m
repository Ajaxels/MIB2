function mibSegmAnnDeleteAllBtn_Callback(obj)
% function mibSegmAnnDeleteAllBtn_Callback(obj)
% callback to Menu->Models->Annotations...->Delete all annotations,
% delete all annotations of the model
%
% Parameters:
% 

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

obj.mibModel.mibDoBackup('labels', 0);
obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels();
obj.plotImage();
notify(obj.mibModel, 'updatedAnnotations');

end
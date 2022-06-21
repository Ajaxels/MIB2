function mibDragAndDropFiles(obj, DragNDrop, event)
% function mibDragAndDropFiles(obj, DragNDrop, event)
% callback for dropping model files into the segmentation table:
% loading the files

% Copyright (C) 13.06.2022, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 

switch event.DropType
    case 'file'
        [path, fn, ext] = fileparts(event.Data{1});
        BatchOpt.DirectoryName = {path};
        BatchOpt.FilenameFilter = [fn, ext];
        obj.mibModel.loadModel([], BatchOpt);
    case 'string'
        % nothing here yet
end

end
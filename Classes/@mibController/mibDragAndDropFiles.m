function mibDragAndDropFiles(obj, DragNDrop, event)
% function mibDragAndDropFiles(obj, DragNDrop, event)
% callback for dropping the files into the image view panel:
% loading the files

% Copyright (C) 07.11.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 

switch event.DropType
    case 'file'
        BatchOpt.Mode = {'Combine datasets'};
        BatchOpt.DirectoryName = {fileparts(event.Data{1})};
        BatchOpt.Filenames = {event.Data};
        
        obj.mibModel.myPath = BatchOpt.DirectoryName{1};
        obj.mibFilesListbox_cm_Callback([], BatchOpt);
    case 'string'
        % nothing here yet
end

end
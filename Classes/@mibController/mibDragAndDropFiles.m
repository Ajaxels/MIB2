% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function mibDragAndDropFiles(obj, DragNDrop, event)
% function mibDragAndDropFiles(obj, DragNDrop, event)
% callback for dropping the files into the image view panel:
% loading the files

switch event.DropType
    case 'file'
        [path, fn, ext] = fileparts(event.Data{1});
        switch ext
            case '.model'   % drag and drop model files to load
                BatchOpt.DirectoryName = {path};
                BatchOpt.FilenameFilter = [fn, ext];
                obj.mibModel.loadModel([], BatchOpt);
            case '.mask'   % drag and drop mask files to load
                BatchOpt.DirectoryName = {path};
                BatchOpt.FilenameFilter = [fn, ext];
                obj.mibModel.loadMask([], BatchOpt);
            case '.ann'
                res = load(event.Data{1}, '-mat');
                if size(res.labelPosition,2) == 3  % missing the t
                    res.labelPosition(:, 4) = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                end
                obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(res.labelText, res.labelPosition, res.labelValue);
                
                % alternative way to call plot image, via notify listener
                eventdata = ToggleEventData(0);
                notify(obj.mibModel, 'plotImage', eventdata);
            otherwise   % drag and drop image files to open
                BatchOpt.Mode = {'Combine datasets'};
                BatchOpt.DirectoryName = {fileparts(event.Data{1})};
                BatchOpt.Filenames = {sort(event.Data)};    % sort filenames, otherwise the first file may be the one that was under the focus when drag-n-drop started

                obj.mibModel.myPath = BatchOpt.DirectoryName{1};
                obj.mibFilesListbox_cm_Callback([], BatchOpt);        
        end
    case 'string'
        % nothing here yet
end

end
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

function mibDragAndDropModelFiles(obj, DragNDrop, event)
% function mibDragAndDropModelFiles(obj, DragNDrop, event)
% callback for dropping model files into the segmentation table:
% loading the files

switch event.DropType
    case 'file'
        [path, fn, ext] = fileparts(sort(event.Data));   % sort filenames, otherwise the first file may be the one that was under the focus when drag-n-drop started
        switch ext{1}
            case '.ann'
                res = load(event.Data{1}, '-mat');
                if size(res.labelPosition,2) == 3  % missing the t
                    res.labelPosition(:, 4) = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                end
                obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(res.labelText, res.labelPosition, res.labelValue);
                
                % alternative way to call plot image, via notify listener
                eventdata = ToggleEventData(0);
                notify(obj.mibModel, 'plotImage', eventdata);
            otherwise
                BatchOpt.DirectoryName = path(1);
                BatchOpt.FilenameFilter = [fn{1}, ext{1}];
                BatchOpt.FilenameFilter = cellfun(@(a, b) [a, b], fn, ext, 'UniformOutput', false);
                obj.mibModel.loadModel([], BatchOpt);
        end
    case 'string'
        % nothing here yet
end

end
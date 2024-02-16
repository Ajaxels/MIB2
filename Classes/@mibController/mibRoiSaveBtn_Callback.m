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

function mibRoiSaveBtn_Callback(obj)
% function mibRoiSaveBtn_Callback(obj)
% a callback to the obj.mibView.handles.mibRoiSaveBtn, saves roi to a file in the matlab format
%
% Parameters:
% 
% Return values:
% 

% Updates
% 

if obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0) < 1
    msg = {'Create a Region of interest first!'};
    msgbox(msg,'Warning!','warn');
    return;
end

fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
if isempty(fn_out)
    fn_out = obj.mibModel.myPath;
end
dots = strfind(fn_out,'.');
fn_out = fn_out(1:dots(end)-1);
[filename, path] = uiputfile(...
    {'*.roi',  'Area shape, Matlab format (*.roi)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Save roi data...',fn_out);
if isequal(filename,0); return; end % check for cancel

fn_out = fullfile(path, filename);
Data = obj.mibModel.I{obj.mibModel.Id}.hROI.Data; %#ok<NASGU>

save(fn_out, 'Data', '-mat', '-v7.3');
fprintf('MIB: saving ROI to %s -> done!\n', fn_out);

end

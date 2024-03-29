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

function mibBioformatsCheck_Callback(obj)
% function mibBioformatsCheck_Callback()
% Bioformats that can be read with loci BioFormats toolbox
% this function updates the list of file filters in obj.mibView.handles.mibFileFilterPopup
%

% %| 
% @b Examples:
% @code mibController.mibBioformatsCheck_Callback();  //  @endcode

% Updates
% 

position = obj.mibView.handles.mibFileFilterPopup.UserData;     % get previous position in the list
obj.mibView.handles.mibFileFilterPopup.UserData = obj.mibView.handles.mibFileFilterPopup.Value; % update position in the list

if obj.mibView.handles.mibBioformatsCheck.Value == 1     % use bioformats reader
    % check for temp directory for the Memoizer
    if ~isfield(obj.mibModel.preferences.ExternalDirs, 'BioFormatsMemoizerMemoDir')
        obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir = 'c:\temp\mibVirtual';
    end
    
    if isdir(obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir) == 0 %#ok<ISDIR>
        try
            mkdir(obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir);
        catch err
            warndlg(sprintf('!!! Warning !!!\n\nUse of the BioFormats reader requires a directory to keep Memoizer class temporary files!\n\nPlease specify it in\nMenu->File->Preferences->External dirs...'), 'Missing required directory');
            return;
        end
    end
    
    if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1     % add amiramesh for the virtual mode
        extentions = ['all known', obj.mibModel.preferences.System.Files.BioFormatsVirtExt];
    else
        extentions = ['all known', obj.mibModel.preferences.System.Files.BioFormatsExt];
    end
    obj.mibView.handles.mibFileFilterPopup.String = extentions;
    obj.mibView.handles.mibFileFilterPopup.Value = position;
else
    if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1     % add amiramesh for the virtual mode
        extentions = ['all known', obj.mibModel.preferences.System.Files.StdVirtExt];
    else
        extentions = ['all known', obj.mibModel.preferences.System.Files.StdExt];
    end

    obj.mibView.handles.mibFileFilterPopup.String = extentions;
    if position > numel(extentions); position = 1; end
    obj.mibView.handles.mibFileFilterPopup.Value = position;
end
[~, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
obj.updateFilelist([fn, ext]);
end
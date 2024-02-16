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

function status = mibSegmentationSAM_requirements(obj)
% function status = mibSegmentationSAM_requirements(obj, BatchOptIn)
% Check for files required to run segmentation using segment-anything model https://segment-anything.com
%
% Parameters:
% 
% Return values:
% status: [logical], switch indicating success of the function

% Updates
% 

status = false;
if obj.matlabVersion < 9.12
    msgbox(sprintf('Error!!!\n\nSegment anything model requires MATLAB R2022a or newer!'),...
        'MATLAB version is too old', 'error');
    return;
end

if isempty(obj.mibModel.preferences.ExternalDirs.PythonInstallationPath) || ~isfile(obj.mibModel.preferences.ExternalDirs.PythonInstallationPath)
    errordlg(sprintf(['!!! Error !!!\n\nLocation of python interpreter (python.exe) is not specified or python.exe is missing!\n\n' ...
        'Specify Python location using\nMenu->File->Preferences->External dirs...']), ...
        'Missing Python location');
    return;
end

if isempty(obj.mibModel.preferences.SegmTools.SAM.sam_installation_path) || ...
        ~isfolder(obj.mibModel.preferences.SegmTools.SAM.sam_installation_path)
    errordlg(sprintf('!!! Error !!!\n\nLocation of segment-anything is not specified!\nSpecify its location using SAM settings dialog'), ...
        'Missing SAM location');
    return;
end

% get settings file with links to SAM backbones
linksFile = fullfile(obj.mibPath, obj.mibModel.preferences.SegmTools.SAM.linksFile);
if exist(linksFile, 'file') == 0
    errordlg(sprintf('!!! Error !!!\n\nLocation of "sam_links.json" with links to SAM backbones is not specified!\n\nSpecify its location using SAM settings dialog, the default location in Resources directory under MIB installation'), ...
        'Missing sam_links.json location');
    return;
end
% read links with backbones
linksJSON = fileread(linksFile);
linksStruct = jsondecode(linksJSON);

% get index of the selected backbone
selectedBackboneIndex = find(ismember({linksStruct.name}, obj.mibModel.preferences.SegmTools.SAM.backbone));
checkpointFilename = linksStruct(selectedBackboneIndex).checkpointFilename; % 'sam_vit_h_4b8939.pth', 'sam_vit_l_0b3195.pth', 'sam_vit_b_01ec64.pth'
onnxFilename = linksStruct(selectedBackboneIndex).onnxFilename;             % sam_onnx_vit_h_quantized.onnx, sam_onnx_vit_l_quantized.onnx, sam_onnx_vit_b_quantized.onnx
checkpointLink = linksStruct(selectedBackboneIndex).checkpointLink_url_1;   % https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
checkpointLink2 = linksStruct(selectedBackboneIndex).checkpointLink_url_2;  % http://mib.helsinki.fi/web-update/sam/sam_vit_h_4b8939.pth
onnxLink = linksStruct(selectedBackboneIndex).onnxLink;     % vit_h.zip     % http://mib.helsinki.fi/web-update/sam/vit_h.zip

checkpointIsMissing = true;
while checkpointIsMissing
    checkpointExists = isfile(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, checkpointFilename));
    onnxExists = isfile(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, onnxFilename));

    if checkpointExists == 0 || onnxExists == 0
        answer = questdlg( ...
            sprintf(['!!! Warning !!!\n\n' ...
            'The following files were not found and will be downloaded\n' ...
            '  - checkpoint: %s\n' ...
            '  - onnx:          %s\n\n' ...
            'The destination directory is\n' ...
            '%s\n\n' ...
            'Before download, you can update the destination directory\n\n' ...
            'Please note that the progress bar won''t be updated during the process and it may take a while...'], ...
            checkpointFilename, onnxFilename, obj.mibModel.preferences.ExternalDirs.DeepMIBDir), ...
            'Download checkpoint', ...
            'Continue with download', 'Update directory', 'Cancel', 'Cancel');
        
        switch answer
            case 'Update directory'
                [file, path] = uiputfile({'*.onnx', 'ONNX Files (*.onnx)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Select output directory', fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, checkpointFilename));
                if file == 0; return; end
                obj.mibModel.preferences.ExternalDirs.DeepMIBDir = path;
                checkpointIsMissing = false;
            case 'Cancel'
                return;
            case 'Continue with download'
                checkpointIsMissing = false;
        end
    else
        checkpointIsMissing = false;
    end
end

% download checkpoint file
if checkpointExists == 0
    wb = waitbar(0, sprintf(''), 'Name', 'Downloading checkpoint file');
    wb.Children.Title.Interpreter = 'none';
    waitbar(0, wb, sprintf('Downloading checkpoint %s...\nNote that the progress bar won''t be updated', obj.mibModel.preferences.SegmTools.SAM.backbone));
    drawnow;
    try
        websave(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, checkpointFilename), checkpointLink);
    catch err
        websave(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, checkpointFilename), checkpointLink2);
    end
    waitbar(1, wb);
    fprintf('The checkpoint file %s was downloaded to %s\n', checkpointFilename, obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    delete(wb);
end

if onnxExists == 0
    wb = waitbar(0, sprintf(''), 'Name', 'Downloading onnx file');
    wb.Children.Title.Interpreter = 'none';
    waitbar(0, wb, sprintf('Downloading onnx %s...\nNote that the progress bar won''t be updated', obj.mibModel.preferences.SegmTools.SAM.backbone));

    drawnow;
    unzip(onnxLink, obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    waitbar(1, wb);
    fprintf('The onnx file %s was downloaded to %s\n', onnxFilename, obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    delete(wb);
end

% update sessionSettings with the selected backbone
obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename = checkpointFilename;
obj.mibModel.sessionSettings.SAMsegmenter.Links.onnxFilename = onnxFilename;
obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone = linksStruct(selectedBackboneIndex).backbone;
status = true;
end

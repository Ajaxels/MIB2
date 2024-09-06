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

function status = mibSegmentationSAM_requirements(obj, samVersion)
% function status = mibSegmentationSAM_requirements(obj, samVersion)
% Check for files required to run segmentation using segment-anything model https://segment-anything.com
%
% Parameters:
% samVersion: integer with version of SAM
%   @li 1 -> default, the first version SAM (https://segment-anything.com)
%   @li 2 -> the second version SAM-2 (https://github.com/facebookresearch/segment-anything-2)
% Return values:
% status: [logical], switch indicating success of the function

% Updates
% 12.08.2024, added segment-anything-2

if nargin < 2; samVersion = 1; end

% define proper field name in obj.mibModel.preferences.SegmTools structure
samVersionName = 'SAM';
if samVersion==2; samVersionName = 'SAM2'; end

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

if isempty(obj.mibModel.preferences.SegmTools.(samVersionName).sam_installation_path) || ...
        ~isfolder(obj.mibModel.preferences.SegmTools.(samVersionName).sam_installation_path)
    errordlg(sprintf('!!! Error !!!\n\nLocation of segment-anything is not specified!\nSpecify its location using SAM settings dialog'), ...
        'Missing SAM location');
    return;
end

% get settings file with links to SAM backbones
linksFile = fullfile(obj.mibPath, obj.mibModel.preferences.SegmTools.(samVersionName).linksFile);
if exist(linksFile, 'file') == 0
    errordlg(sprintf(['!!! Error !!!\n\nLocation of "sam_links.json" (or "sam2_links.json" for SAM2) with links to SAM backbones is not specified!\n\n' ...
        'Specify its location using SAM settings dialog, ' ...
        'the default location in Resources directory under MIB installation']), ...
        'Missing sam_links.json location');
    return;
end
% read links with backbones
linksJSON = fileread(linksFile);
linksStruct = jsondecode(linksJSON);

% get index of the selected backbone
selectedBackboneIndex = find(ismember({linksStruct.name}, obj.mibModel.preferences.SegmTools.(samVersionName).backbone));
checkpointFilename = linksStruct(selectedBackboneIndex).checkpointFilename; % 'sam_vit_h_4b8939.pth', 'sam_vit_l_0b3195.pth', 'sam_vit_b_01ec64.pth'
checkpointLink = linksStruct(selectedBackboneIndex).checkpointLink_url_1;   % https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
checkpointLink2 = linksStruct(selectedBackboneIndex).checkpointLink_url_2;  % http://mib.helsinki.fi/web-update/sam/sam_vit_h_4b8939.pth
onnxFilename = '*** not used ***';
modelCfgFilename = '*** not used ***';
switch samVersion
    case 1
        onnxFilename = linksStruct(selectedBackboneIndex).onnxFilename;             % sam_onnx_vit_h_quantized.onnx, sam_onnx_vit_l_quantized.onnx, sam_onnx_vit_b_quantized.onnx
        onnxLink = linksStruct(selectedBackboneIndex).onnxLink;     % vit_h.zip     % http://mib.helsinki.fi/web-update/sam/vit_h.zip
    case 2
        % for SAM2 links to model configs are needed
        modelCfgLink = linksStruct(selectedBackboneIndex).modelCfgLink_url_1;
        modelCfgLink2 = linksStruct(selectedBackboneIndex).modelCfgLink_url_2;
        [~, modelCfgFilename] = fileparts(modelCfgLink);
        modelCfgFilename = [modelCfgFilename '.yaml'];
end

checkpointIsMissing = true;
while checkpointIsMissing
    checkpointExists = isfile(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, checkpointFilename));
    switch samVersion
        case 1
            modelCfgExists = true; % yaml is not used in SAM1
            onnxExists = isfile(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, onnxFilename));
        case 2
            modelCfgExists = isfile(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, modelCfgFilename));
            onnxExists = true; % onnx is not used in SAM2
    end
    
    if checkpointExists == 0 || onnxExists == 0 || modelCfgExists == 0
        answer = questdlg( ...
            sprintf(['!!! Warning !!!\n\n' ...
                'The following files were not found and will be downloaded\n' ...
                '  - checkpoint:    %s\n' ...
                '  - onnx (SAM1):   %s\n' ...
                '  - yaml (SAM2):   %s\n\n' ...
                'The destination directory is\n' ...
                '%s\n\n' ...
                'Before download, you can update the destination directory\n\n' ...
                'Please note that the progress bar won''t be updated during the process and it may take a while...'], ...
                checkpointFilename, onnxFilename, modelCfgFilename, obj.mibModel.preferences.ExternalDirs.DeepMIBDir), ...
            'Download checkpoint', ...
            'Continue with download', 'Update directory', 'Cancel', 'Cancel');
        
        switch answer
            case 'Update directory'
                selpath = uigetdir(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, 'Directory for trainined models');
                if selpath == 0; return; end
                
                obj.mibModel.preferences.ExternalDirs.DeepMIBDir = selpath;
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
    waitbar(0, wb, sprintf('Downloading checkpoint %s...\nNote that the progress bar won''t be updated', obj.mibModel.preferences.SegmTools.(samVersionName).backbone));
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
    waitbar(0, wb, sprintf('Downloading onnx %s...\nNote that the progress bar won''t be updated', obj.mibModel.preferences.SegmTools.(samVersionName).backbone));

    drawnow;
    unzip(onnxLink, obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    waitbar(1, wb);
    fprintf('The onnx file %s was downloaded to %s\n', onnxFilename, obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    delete(wb);
end

if modelCfgExists == 0
    wb = waitbar(0, sprintf(''), 'Name', 'Downloading yaml file');
    wb.Children.Title.Interpreter = 'none';
    waitbar(0, wb, sprintf('Downloading model config for "%s"\nNote that the progress bar won''t be updated', obj.mibModel.preferences.SegmTools.(samVersionName).backbone));

    drawnow;
    try
        websave(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, modelCfgFilename), modelCfgLink);
    catch err
        websave(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, modelCfgFilename), modelCfgLink2);
    end

    waitbar(1, wb);
    fprintf('The model config file %s was downloaded to %s\n', modelCfgFilename, obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    delete(wb);
end

% update sessionSettings with the selected backbone
obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename = checkpointFilename;
obj.mibModel.sessionSettings.SAMsegmenter.Links.onnxFilename = onnxFilename;
obj.mibModel.sessionSettings.SAMsegmenter.Links.modelCfgFilename = modelCfgFilename;
obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone = linksStruct(selectedBackboneIndex).backbone;

% if samVersion == 2
%     % tiny, 155 Mb
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename = 'sam2_hiera_tiny.pt';
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone = 'sam2_hiera_t';
%     % small, 184 Mb
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename = 'sam2_hiera_small.pt';
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone = 'sam2_hiera_s';
%     % base plus, 323 Mb
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename = 'sam2_hiera_base_plus.pt';
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone = 'sam2_hiera_b+';
%     % large 898 Mb
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename = 'sam2_hiera_large.pt';
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone = 'sam2_hiera_l';
% 
%     obj.mibModel.sessionSettings.SAMsegmenter.Links.onnxFilename = '';
% end

status = true;
end

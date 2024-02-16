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

function menuFileExamples_Callback(obj, BatchOptIn)
% function menuFileExamples_Callback(obj, BatchOptIn)
% a callback to Menu->File->Example datasets, import an example dataset
% into MIB
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%             a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%             variables are preferred over the BatchOptIn variables
% .Dataset -> [cell], dataset name as listed in MIB->Menu->File->Example datasets
% .DirectoryName -> [cell], output directory only for DeepMIB projects

% Updates
%

% specify default BatchOptIn
BatchOpt = struct();
BatchOpt.Dataset = {'Huh7 and model'};
BatchOpt.Dataset{2} = {'Syntetic 2D Large spots', 'Syntetic 2D small spots', 'Synthetic 2.5D large spots', 'Syntetic 2D patch-wise',...
    '2D EM membranes','2D LM nuclei','3D EM mitochondria','3D LM hair cells',...
    'LM 3D SIM ER','LM 3D STED','LM WF ER photobleaching',...
    'Huh7 and model','Trypanosoma and model', ...
    'MATLAB Brain and model'};
BatchOpt.DirectoryName = {'Current MIB path'};   % specify the target directory
BatchOpt.DirectoryName{2} = {'Current MIB path', 'Inherit from Directory/File loop', obj.mibModel.myPath};  % this option forces the directories to be provided from the Dir/File loops
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Menu -> File';
BatchOpt.mibBatchActionName = 'Example datasets';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Dataset = sprintf('Select dataset or a DeepMIB project to import');
BatchOpt.mibBatchTooltip.DirectoryName = sprintf('Output directory for importing of DeepMIB projects');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the waitbar');

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
        if strcmp(BatchOpt.DirectoryName{1}, 'Current MIB path')
            BatchOpt.DirectoryName{1} = obj.mibModel.myPath; 
        end
    end
else
    if strcmp(BatchOpt.DirectoryName{1}, 'Current MIB path'); BatchOpt.DirectoryName{1} = obj.mibModel.myPath; end
end

if ismember(BatchOpt.Dataset{1}, {'Synthetic 2D Large spots','Synthetic 2D small spots','Synthetic 2.5D large spots','Synthetic 2D patch-wise',...
             '2D EM membranes','2D LM nuclei','3D EM mitochondria','3D LM hair cells'})
    BatchOpt.DirectoryName{1} = uigetdir(BatchOpt.DirectoryName{1}, 'Select directory to unzip the project');
    if BatchOpt.DirectoryName{1} == 0; return; end
end

if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Importing %s dataset\nPlease wait...', BatchOpt.Dataset{1}), 'Name', 'Example dataset'); end

switch BatchOpt.Dataset{1}
    case {'Synthetic 2D Large spots','Synthetic 2D small spots','Synthetic 2.5D large spots','Synthetic 2D patch-wise',...
             '2D EM membranes','2D LM nuclei','3D EM mitochondria','3D LM hair cells'}
        switch BatchOpt.Dataset{1}
            case 'Synthetic 2D small spots'
                url = 'http://mib.helsinki.fi/tutorials/datasets/2D_SmallSpots_3cl_Unet.zip';
            case 'Synthetic 2D Large spots'
                url = 'http://mib.helsinki.fi/tutorials/datasets/2D_LargeSpots_2cl_DeepLabV3.zip';
            case 'Synthetic 2.5D large spots'
                url = 'http://mib.helsinki.fi/tutorials/datasets/25D_LargeSpots.zip';
            case 'Synthetic 2D patch-wise'
                url = 'http://mib.helsinki.fi/tutorials/datasets/2D_LargeSpots_Patchwise_DeepLabV3.zip';
            case '2D EM membranes'
                url = 'http://mib.helsinki.fi/tutorials/deepmib/1_2DEM_Files.zip';
            case '2D LM nuclei'
                url = 'http://mib.helsinki.fi/tutorials/deepmib/2_2DLM_Files.zip';
            case '3D EM mitochondria'
                url = 'http://mib.helsinki.fi/tutorials/deepmib/3_3DEM_Files.zip';
            case '3D LM hair cells'
                url = 'http://mib.helsinki.fi/tutorials/deepmib/4_3DLM_Files.zip';
        end
        if BatchOpt.showWaitbar; waitbar(0.1, wb); end
        unzip(url, BatchOpt.DirectoryName{1});
        if BatchOpt.showWaitbar; waitbar(0.9, wb); end
        obj.updateMyPath(BatchOpt.DirectoryName{1});
    case 'LM 3D SIM ER'
        % % make raw file
%         fid=fopen('LM_SIM_ER.raw','w+');
%         cnt=fwrite(fid, I, 'uint8');
%         fclose(fid);

        % read data file
        options = weboptions("ContentType", "raw");
        vol = webread('http://mib.helsinki.fi/tutorials/datasets/LM_SIM_ER.raw', options);
        vol = reshape(vol, [1024 1024 1 20]);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        obj.mibModel.I{obj.mibModel.Id} = mibImage(vol);
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = fullfile(obj.mibModel.myPath, 'LM_SIM_ER.tif');
        obj.mibModel.I{obj.mibModel.Id}.pixSize.x = 0.04;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.y = 0.04;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.z = 0.125;
        % update Bounding Box
        obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [0 0 0]);
        % add XResolution/YResolution fields
        [obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize] = mibUpdatePixSizeAndResolution(obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize);
        obj.mibModel.I{obj.mibModel.Id}.updateImgInfo('MIB demo dataset, LM SIM, ER', 'insert', 2);
        notify(obj.mibModel, 'newDataset');
        notify(obj.mibModel, 'plotImage');
    case 'LM 3D STED'
        % % make raw file
%         fid=fopen('LM_STED.raw','w+');
%         cnt=fwrite(fid, I, 'uint8');
%         fclose(fid);

        % read data file
        options = weboptions("ContentType", "raw");
        vol = webread('http://mib.helsinki.fi/tutorials/datasets/LM_STED.raw', options);
        vol = reshape(vol, [1024 1024 2 13]);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        obj.mibModel.I{obj.mibModel.Id} = mibImage(vol);
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = fullfile(obj.mibModel.myPath, 'LM_STED.tif');
        obj.mibModel.I{obj.mibModel.Id}.pixSize.x = 0.0329059;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.y = 0.0329059;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.z = 0.335694;
        % update Bounding Box
        obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [0 0 0]);
        % add XResolution/YResolution fields
        [obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize] = mibUpdatePixSizeAndResolution(obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize);
        obj.mibModel.I{obj.mibModel.Id}.updateImgInfo('MIB demo dataset, LM STED', 'insert', 2);
        notify(obj.mibModel, 'newDataset');
        notify(obj.mibModel, 'plotImage');
    case 'LM WF ER photobleaching'
        % % make raw file
%         fid=fopen('LM_WF_timelapse_Photobleaching.raw','w+');
%         cnt=fwrite(fid, I, 'uint16');
%         fclose(fid);

        % read data file
        options = weboptions("ContentType", "raw");
        vol = webread('http://mib.helsinki.fi/tutorials/datasets/LM_WF_timelapse_ER_Photobleaching.raw', options);
        vol = typecast(vol, 'uint16');  % convert to unit16
        vol = reshape(vol, [301 383 1 250]);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end

        obj.mibModel.I{obj.mibModel.Id} = mibImage(vol);
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = fullfile(obj.mibModel.myPath, 'LM_WF_timelapse_ER_Photobleaching.tif');
        obj.mibModel.I{obj.mibModel.Id}.pixSize.x = 0.157142;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.y = 0.157142;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.z = 1;
        % update Bounding Box
        obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [0 0 0]);
        % add XResolution/YResolution fields
        [obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize] = mibUpdatePixSizeAndResolution(obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize);
        obj.mibModel.I{obj.mibModel.Id}.updateImgInfo('MIB demo dataset, LM wide-field time-laspe, ER', 'insert', 2);
        obj.mibModel.I{obj.mibModel.Id}.viewPort.min = 96;
        obj.mibModel.I{obj.mibModel.Id}.viewPort.max = 423;
        notify(obj.mibModel, 'newDataset');
        notify(obj.mibModel, 'plotImage');
    case 'Huh7 and model'
        % % make raw file
        % fid=fopen('SBEM_Huh7.raw','w+');
        % cnt=fwrite(fid, I, 'uint8');
        % fclose(fid);
        % 
        % fid=fopen('Labels_SBEM_Huh7.raw','w+');
        % cnt=fwrite(fid, O.model, 'uint8');
        % fclose(fid);

        % read data file
        modelMaterialColors = [ 0.6510    0.2627    0.1294;
                                0.3098    0.4196    0.6706;
                                1.0000    0.8000    0.4000;
                                0.2784    0.6980    0.4941;
                                0.1020    0.2000    0.4353;
                                0.5882    0.6627    0.8353];
        
        options = weboptions("ContentType", "raw");
        vol = webread('http://mib.helsinki.fi/tutorials/datasets/SBEM_Huh7.raw', options);
        vol = reshape(vol, [372 521 1 75]);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        label = webread('http://mib.helsinki.fi/tutorials/datasets/Labels_SBEM_Huh7.raw', options);
        label = reshape(label, [372 521 75]);
        if BatchOpt.showWaitbar; waitbar(0.8, wb); end
        obj.mibModel.I{obj.mibModel.Id} = mibImage(vol);
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = fullfile(obj.mibModel.myPath, 'SBEM_Huh7.tif');
        obj.mibModel.I{obj.mibModel.Id}.pixSize.x = 0.013;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.y = 0.013;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.z = 0.030;
        % update Bounding Box
        obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [0 0 0]);
        % add XResolution/YResolution fields
        [obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize] = mibUpdatePixSizeAndResolution(obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize);
        obj.mibModel.I{obj.mibModel.Id}.updateImgInfo('MIB demo dataset, Huh7 SBEM', 'insert', 2);
        
        obj.mibModel.setData3D('model', label);
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = [{'LD'}; {'NE'}; {'ER'}; {'Mito'}];
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = modelMaterialColors;
        notify(obj.mibModel, 'newDataset');
        notify(obj.mibModel, 'showModel');
    case 'Trypanosoma and model'
        % % make raw file
        % fid=fopen('SBEM_Trypanosoma.raw','w+');
        % cnt=fwrite(fid, I, 'uint8');
        % fclose(fid);
        % 
        % fid=fopen('Labels_SBEM_Trypanosoma.raw','w+');
        % cnt=fwrite(fid, O.model, 'uint8');
        % fclose(fid);

        % read data file
        modelMaterialColors = [ 0.3098    0.4196    0.6706;
                                0.2784    0.6980    0.4941;
                                0.6510    0.2627    0.1294;
                                0.4902    0.1804    0.5608;
                                1.0000    0.8000    0.4000;
                                0.9686    0.9176    0.7961];
        
        options = weboptions("ContentType", "raw");
        vol = webread('http://mib.helsinki.fi/tutorials/datasets/SBEM_Trypanosoma.raw', options);
        vol = reshape(vol, [887 813 1 171]);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        label = webread('http://mib.helsinki.fi/tutorials/datasets/Labels_SBEM_Trypanosoma.raw', options);
        label = reshape(label, [887 813 171]);
        if BatchOpt.showWaitbar; waitbar(0.8, wb); end
        obj.mibModel.I{obj.mibModel.Id} = mibImage(vol);
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = fullfile(obj.mibModel.myPath, 'SBEM_Trypanosoma.tif');
        obj.mibModel.I{obj.mibModel.Id}.pixSize.x = 0.0140193;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.y = 0.0140193;
        obj.mibModel.I{obj.mibModel.Id}.pixSize.z = 0.03;
        % update Bounding Box
        obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [0 0 0]);
        % add XResolution/YResolution fields
        [obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize] = mibUpdatePixSizeAndResolution(obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize);
        obj.mibModel.I{obj.mibModel.Id}.updateImgInfo('MIB demo dataset, Trypanosoma, SBEM', 'insert', 2);
        
        obj.mibModel.setData3D('model', label);
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = [{'Nuclei'}; {'Mito'}; {'Vesicles'}; {'LD'}; {'ER'}; {'Cytoplasm'}];
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = modelMaterialColors;
        notify(obj.mibModel, 'newDataset');
        notify(obj.mibModel, 'showModel');
    case 'MATLAB Brain and model'
        if isdeployed
            errordlg(sprintf('!!! Error !!!\n\nMATLAB brain dataset and its model is only available in MIB for MATLAB!'), 'Not available');
            return;
        end

        dataDir = fullfile(toolboxdir("images"),"imdata","BrainMRILabeled");
        load(fullfile(dataDir,"images","vol_003.mat"));
        load(fullfile(dataDir,"labels","label_003.mat"));
        vol = permute(vol, [1,2,4,3]);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end

        % convert to 8bit
        vol = uint8(vol*0.1469);
        obj.mibModel.I{obj.mibModel.Id} = mibImage(vol);
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = fullfile(obj.mibModel.myPath, 'brainMRI_MATLAB_Example.tif');
        
        % update Bounding Box
        obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [0 0 0]);
        % add XResolution/YResolution fields
        [obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize] = mibUpdatePixSizeAndResolution(obj.mibModel.I{obj.mibModel.Id}.meta, obj.mibModel.I{obj.mibModel.Id}.pixSize);
        obj.mibModel.I{obj.mibModel.Id}.updateImgInfo('MATLAB Brain MRI demo dataset', 'insert', 2);
        
        obj.mibModel.setData3D('model', label);
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = [{'Mat1'}; {'Mat2'}; {'Mat3'}];
        notify(obj.mibModel, 'newDataset');
        notify(obj.mibModel, 'showModel');
end
if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end

eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);
end
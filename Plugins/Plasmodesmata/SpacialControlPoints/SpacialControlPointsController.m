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

classdef SpacialControlPointsController < handle
    properties
        mibModel
        % handles to the model
        noGui = 1
        % a variable indicating a plugin without GUI
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when plugin is closed
    end
    
    methods
        function obj = SpacialControlPointsController(mibModel)
            obj.mibModel = mibModel;    % assign model
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                return;
            end
            
            obj.calculate();  % start the main function
        end
        
        function status = thinMaterial(obj, materialIndex, wb)
            % preprocess material of the model to thin it and remove small profiles 
            % 
            % Parameters:
            % materialIndex: index of the material to be thinned
            
            status = 0;
            if nargin < 2
                errordlg('The index of material to be thinnied is required!');
                return;
            end
            
            % check for existance of mask
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 1
                answer = questdlg(sprintf('!!! Warning !!!\n\nThe existing mask will be removed\nContinue?'), ...
                    'Current mask will be removed', ...
                    'Continue','Cancel','Cancel');
                if strcmp(answer, 'Cancel'); return; end
            end
            
            if nargin < 3
                wb = waitbar(0, sprintf('Thinning the material and removing short profiles\nThe results will be moved to the mask layer...'));
            else
                waitbar(0, wb, sprintf('Thinning the material and removing short profiles\nThe results will be moved to the mask layer...'));
            end
            
            sliceCounter = 1;   % counter for slices
            maxSlice = obj.mibModel.I{obj.mibModel.Id}.time*obj.mibModel.I{obj.mibModel.Id}.depth;
            getDataOptions.blockModeSwitch = 0;
            obj.mibModel.I{obj.mibModel.Id}.clearMask();
            
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                getDataOptions.t = [t, t];
                for z=1:obj.mibModel.I{obj.mibModel.Id}.depth
                    Mask = cell2mat(obj.mibModel.getData2D('model', z, 4, materialIndex, getDataOptions));    % get the mask
                    
                    % thin the objects
                    Mask = bwmorph(Mask, 'thin', Inf);
                    
                    Mask = mibRemoveBranches(Mask);

                    obj.mibModel.setData2D('mask', Mask, z, 4, NaN, getDataOptions);    % set the mask
                    sliceCounter = sliceCounter + 1;
                    waitbar(sliceCounter/maxSlice, wb);
                end
            end
            if nargin < 3; delete(wb); end
            notify(obj.mibModel, 'showMask');
            status = 1;
        end
        
        % ------------------------------------------------------------------
        % Main function for calculations
        % Add your code here
        function calculate(obj)
            % start main calculation of the plugin
            global mibPath
            
            % ------ SETUP parameters -------
            try
                % generate path to config file
                cfgFilename = fullfile(mibPath, 'Plugins', 'Arabidopsis', 'SpacialControlPoints', 'config.cfg');
                fn = fopen(cfgFilename);
                tline = fgetl(fn);
                while tline ~= -1
                    eqSign = strfind(tline, '=');
                    procSign = strfind(tline, '%');
                    if isempty(eqSign); continue; end
                    
                    if strfind(tline(1:eqSign), 'noInterations') %#ok<STRIFCND>
                        noIterations = str2double(tline(eqSign+1:procSign-1));
                    elseif strfind(tline(1:eqSign), 'excelTemplate') %#ok<STRIFCND>
                        excelTemplate = strtrim(tline(eqSign+1:procSign-1));
                        excelTemplate = excelTemplate(2:end-1);     % remove ' ' signs
                    end
                    tline = fgetl(fn);
                end
                
                fclose(fn);
            catch err
                excelTemplate = '_random_points';       % excel filename will be generated from the model filename + this text
                noIterations = 10;                      % number of interations to perform
                fprintf('Can''t load config file at %s, using default values. NoIterations=10 and output template ending "_random_points"\n', cfgFilename);
            end
            
            prompts = {'Define number of interations',  'Filename suffix:', 'Index of material for thinning (unless the thinned mask is already present)', 'Random seed generator (number or keep empty for random initialization)'};
            defAns = {num2str(noIterations), excelTemplate, '', ''};
            dlgTitle = 'Define number of interations';
            options.PromptLines = [1 1 2 1];
            options.Title = sprintf('This plugin generates N-sets of random points (number of points in each set is equal to the number of present annotation points) and places them over the random position over the centerline of the object.\nSee more:\nhttps://andreapaterlini.github.io/Plasmodesmata_dist_wall/distributions.html\nThe plugin requires:\n1. centerline of the material in the mask layer (may be calculated in this script)\n2. set of annotations indicating the objects of interest\n\nPlease enter number of sets to obtain:');
            options.Title = {'This plugin generates N-sets of random points (number of points in each set is equal to the number of present annotation points) and places them over the random position over the centerline of the object.',...
                             'Press the Help button for details!', ...
                             '',...'
                             'The plugin requires:',...'
                             '1. centerline of the material in the mask layer (may be calculated in this script)',...
                             '2. set of annotations indicating the objects of interest'};
            options.TitleLines = 9;                  
            options.WindowWidth = 1.4; 
            options.HelpUrl = 'https://andreapaterlini.github.io/Plasmodesmata_dist_wall/distributions.html';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            noIterations = str2double(answer{1});
            excelTemplate = answer{2};
            thinMaterial = answer{3};
            randomSeed = answer{4};
            
            % add a waitbar to follow the progress
            wb = waitbar(0, 'Please wait...');

            % ---- START OF THE SCRIPT -------
            %%%%%%%% NEED TO KEEP THIS BIT TO HAVE THE SKELETON TO PLACE THE RANDOM
            %%%%%%%% POINTS ON IT
            
            % get dataset dimensions
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
            %  get the pixel size
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();  % obtain bounding box [Xmin, Width, Ymin, Height, Zmin, Depth]
            
            if ~isempty(thinMaterial)
                status = obj.thinMaterial(str2double(thinMaterial), wb);
                if status == 0; delete(wb); return; end
            else
                if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                    errordlg(sprintf('!!! Error !!!\n\nThe mask layer with a centerline of the model is required to proceed further\nPlease use select a material and use Menu->Selection->Morphological 2D/3D operations->Thin with Infinite and remove branch parameters to make it'));
                    delete(wb);
                    return;
                end
            end
            
            skel = cell2mat(obj.mibModel.getData3D('mask'));
            % get labels for the pores
            [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels;
            if numel(labelsList) == 0
                errordlg(sprintf('!!! Error !!!\n\nThis plugin requires a set of annotations present in the model.\nPlease use Segmentation panel->Annotations tool to highlights points'));
                delete(wb);
                return;
            end
            
            % space allocation
            output = zeros([noIterations, numel(labelsList), 3]);  % coordinate x, y, z
            
            % initialize the random number generator
            if isempty(randomSeed)
                rng('shuffle');     % reshuffle the random number generator
            else
                rng(str2double(randomSeed), 'twister');
            end
            indices = find(skel >= 1);    % get indices of the skeleton
            
            for iterNo=1:noIterations
                notOk = 1;
                while notOk
                    randomIndices = randi(numel(indices), [numel(labelsList), 1]); % pick a random point from the skeleton, Uniformly distributed pseudorandom integers
                    randomIndices = unique(randomIndices);
                    if numel(randomIndices) == numel(labelsList)
                        notOk = 0;
                    end
                end
                
                for ind = 1:numel(randomIndices)
                    [y, x, z] = ind2sub([height, width, depth], indices(randomIndices(ind)));     % convert from linear indices to x,y,z coordinates
                    output(iterNo, ind, :) = [x*pixSize.x+bb(1), y*pixSize.y+bb(3), z*pixSize.z+bb(5)];   % convert to the physical units and shift relative to the  bounding box
                end
                
                waitbar(iterNo/noIterations, wb);   % update the waitbar
            end
            
            % filename
            outputFilename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            [path, filename] = fileparts(outputFilename);
            outputFilename = fullfile(path, [filename, excelTemplate, '.mat']);
            
            save(outputFilename, 'output');     % saving results in matlab format
            
            % export to comma separated values for R
            [~, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            DatasetFilename = [fn, ext];
            
            %varNames = {'IterationNumber','X_units','Y_units','Z_units', 'DatasetFilename'};
            %varTypes = {'double','double','double','double','string'};
            %FinalTable = table('Size',[0 numel(varNames)], 'VariableTypes', varTypes, 'VariableNames', varNames);

            % allocate space
            noRows = size(output,1)*size(output,2);
            noPoints = size(output,2);
            
            IterationNumber = zeros([noRows, 1]);
            X_units = zeros([noRows, 1]);
            Y_units = zeros([noRows, 1]);
            Z_units = zeros([noRows, 1]);
            DatasetFilename = repmat(DatasetFilename, [noRows, 1]);
            
            for iterNo=1:noIterations
                IterationNumber((iterNo-1)*noPoints+1:iterNo*noPoints) = repmat(iterNo, [noPoints, 1]);
                X_units((iterNo-1)*noPoints+1:iterNo*noPoints) = output(iterNo, :, 1)';
                Y_units((iterNo-1)*noPoints+1:iterNo*noPoints) = output(iterNo, :, 2)';
                Z_units((iterNo-1)*noPoints+1:iterNo*noPoints) = output(iterNo, :, 3)';
            end
            T = table(IterationNumber, X_units, Y_units, Z_units, DatasetFilename);
            
            outPutFilename1 = fullfile(path, [filename, excelTemplate, '.csv']);
            
            % save results as CSV
            writetable(T, outPutFilename1);
            
            delete(wb);         % delete the waitbar
        end
        
        
    end
end
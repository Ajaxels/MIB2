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

function menuFileRender_Callback(obj, parameter)
% function menuFileRender_Callback(obj, parameter)
% a callback to MIB->Menu->File->Render volume...
%
% Parameters:
% parameter: a char that specify where to render the volume
% @li 'fiji' - using Fiji 3D viewer
% @li 'volviewer' - using Matlab VolumeViewer application
%
% % @note VolumeViewer is available only for the Matlab version of MIB,
% requires Matlab R2017a or newer!

% Updates
% 25.03.2018, updated to use also Matlab volume viewer app, previously
% named as menuFileRenderFiji_Callback
global mibPath;

switch parameter
    case 'mib'  % hardware rendering in MIB, from R2018b
        if verLessThan('Matlab', '9.13'); obj.mibModel.preferences.System.RenderingEngine = 'Volshow, R2018b'; end
        if strcmp(obj.mibModel.preferences.System.RenderingEngine, 'Viewer3d, R2022b')
            obj.startController('mibVolRenAppController');
        elseif strcmp(obj.mibModel.preferences.System.RenderingEngine, 'Volshow, R2018b')
            if verLessThan('matlab', '9.5') % obj.matlabVersion < 9.5
                errordlg(sprintf('!!! Error !!!\n\nHardware accelerated rendering is only available in Matlab R2018b or newer!'),'Matlab version is too old');
                return;
            end
            colorsNo = obj.mibModel.getImageProperty('colors');
            if colorsNo > 1
                colCh = cell([colorsNo, 1]);
                for i=1:colorsNo
                    colCh{i} = sprintf('Color channel %d', i);
                end
                colCh{end+1} = max([1, obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel]);
                prompts = {'Select color channel'};
                defAns = {colCh};
                dlgTitle = 'Select color channel';
                options.Title = sprintf('The volume rendering is only available for a single color channel!\nPlease select the color channel to render');
                options.TitleLines = 3;
                [answer, colCh] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer); return; end
            else
                colCh = 1;
            end
            options.mode = 'VolumeRendering'; % 'VolumeRendering', 'MaximumIntensityProjection','Isosurface'
            options.dataType = 'image';
            options.colorChannel = colCh;
            if isfield(obj.mibModel.sessionSettings, 'VolumeRendering')
                options.Settings = obj.mibModel.sessionSettings.VolumeRendering;
            end
            obj.startController('mibVolRenController', options);
        end
    case 'fiji'
        img = cell2mat(obj.mibModel.getData3D('image', NaN, 4));
        mibRenderVolumeWithFiji(img, obj.mibModel.I{obj.mibModel.Id}.pixSize);
    case 'volviewer'
        img = cell2mat(obj.mibModel.getData3D('image', NaN, 4));
        if size(img, 3) > 1
            errordlg(sprintf('!!! Error !!!\n\nVolume viewer is not compatible with multicolor images;\nplease keep only a single color channel displayed and try again!'), 'Not implemented');
            return;
        end
        if ~verLessThan('matlab', '9.6') % obj.matlabVersion >= 9.6
            answer = 'Only volume';
            if obj.mibModel.I{obj.mibModel.Id}.modelExist
                answer = questdlg(sprintf('Would you like to have the model exported together with the volume?'), ...
                    'Include model', 'Volume with model', 'Only volume', 'Cancel', 'Only volume');
                if strcmp(answer, 'Cancel'); return; end
            end
            if strcmp(answer, 'Only volume')
                volumeViewer(squeeze(img), 'VolumeType', 'Volume', 'ScaleFactors', [obj.mibModel.I{obj.mibModel.Id}.pixSize.x obj.mibModel.I{obj.mibModel.Id}.pixSize.y obj.mibModel.I{obj.mibModel.Id}.pixSize.z]);
            else
                Model = cell2mat(obj.mibModel.getData3D('model'));
                volumeViewer(squeeze(img), Model, 'ScaleFactors', [obj.mibModel.I{obj.mibModel.Id}.pixSize.x obj.mibModel.I{obj.mibModel.Id}.pixSize.y obj.mibModel.I{obj.mibModel.Id}.pixSize.z]);
            end
        elseif ~verLessThan('matlab', '9.4') % obj.matlabVersion >= 9.4
            tform = zeros(4);
            tform(1,1) = obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
            tform(2,2) = obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
            tform(3,3) = obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
            tform(4,4) = 1;
            volumeViewer(squeeze(img), tform);
        else
            volumeViewer(squeeze(img));
        end
end
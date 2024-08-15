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
% Date: 28.08.2023

function setDefaultSegmentationColorPalette(obj, paletteName, colorsNo)
% function setDefaultSegmentationColorPalette(obj, paletteName, colorsNo)
% set default color palette for materials of the model
%
% Parameters:
% paletteName: string with the name of the palette to use, see below for
% the options
% colorsNo: [@b optional], numeric, number of required color channels
%
% Return values:
%

%|
% @b Examples:
% @code obj.mibModel.setDefaultSegmentationColorPalette('Default, 6 colors');     // call from mibController: selects the default color scheme with 6 colors @endcode
% @code obj.mibModel.setDefaultSegmentationColorPalette('Qualitative (Monte Carlo->Half Baked), 3-12 colors', 6);     // call from mibController: set "Qualitative (Monte Carlo->Half Baked)" palette with 6 colors @endcode

% Updates
% 240605: updated for models with 65535+ material

global mibPath;

if nargin < 3; colorsNo = []; end
if nargin < 2; paletteName = 'Default, 6 colors'; colorsNo = 6; end

% if obj.I{obj.Id}.modelType > 255
%     errordlg(sprintf('!!! Error !!!\n\nThe color palette is only available for models with up to 255 materials'), 'Too many materials');
%     return;
% end

% update number of colors
if isempty(colorsNo)
    if obj.I{obj.Id}.modelType < 256
        colorsNo = numel(obj.I{obj.Id}.modelMaterialNames);
    else
        colorsNo = 65535;
    end

    if ismember(paletteName, {'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot'})
        answer = mibInputDlg({mibPath}, ...
            sprintf('Please enter number of colors\n(max. value is %d)', obj.I{obj.Id}.modelType), ...
            'Define number of colors', num2str(colorsNo));
        if isempty(answer); return; end

        colorsNo = str2double(answer{1});
        % if colorsNo > 255
        %     errordlg(sprintf('!!! Error !!!\n\nNumber of colors should be below 256'), 'Too many colors');
        %     return;
        % end
    end
end

switch paletteName
    case 'current2default'
        obj.preferences.Colors.ModelMaterialColors = obj.I{obj.Id}.modelMaterialColors;
        return;
    case 'default2current'
        palette = obj.preferences.Colors.ModelMaterialColors;
    otherwise
        palette = mibGenerateDefaultSegmentationPalette(paletteName, colorsNo);
        if isempty(palette)
            errordlg(sprintf('!!! Error !!!\n\nMost likely number of materials in the model larger that the number of colors in the selected color scheme!'), 'Wrong color palette');
            return;
        end
end

if size(palette, 1) < colorsNo
    rng('shuffle');     % randomize generator
    palette2 =  colormap(rand([colorsNo-size(palette, 1), 3]));
    palette = [palette; palette2];
end

% update colors for the current model
obj.I{obj.Id}.modelMaterialColors = palette;

motifyEvent.Name = 'updateSegmentationTable';
eventdata = ToggleEventData(motifyEvent);
notify(obj, 'modelNotify', eventdata);
notify(obj, 'plotImage');

end



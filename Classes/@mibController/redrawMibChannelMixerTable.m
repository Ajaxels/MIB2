% --- Executes on button press in maskShowCheck.
function redrawMibChannelMixerTable(obj)
% function redrawMibChannelMixerTable(obj)
% Update obj.mibView.handles.mibChannelMixerTable table and obj.mibView.handles.mibColChannelCombo color combo box
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 07.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% update color combo box and channel mixer table
pause(0.1);

maxColors = obj.mibModel.getImageProperty('colors');
slices = obj.mibModel.getImageProperty('slices');
lutColors = obj.mibModel.getImageProperty('lutColors');
data = logical(zeros(size(maxColors,1))); %#ok<LOGL>

col_channels(1) = cellstr('All'); %#ok<AGROW>
for col_ch=1:maxColors
    col_channels(col_ch+1) = cellstr(['Ch ' num2str(col_ch)]); %#ok<AGROW>
    if isempty(find(slices{3}==col_ch, 1))
        data(col_ch) = false;
    else
        data(col_ch) = true;
    end
end
obj.mibView.handles.mibColChannelCombo.String = col_channels;
obj.mibView.handles.mibColChannelCombo.Value = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel+1;

% update mibChannelMixerTable
colorGen = @(color,text) ['<html><table border=0 width=40 bgcolor=''',color,'''><TR><TD>',text,'</TD></TR> </table></html>'];
tableData = cell([numel(data) 3]);
displayedLutColors = zeros([numel(data) 3]);
useLut = obj.mibView.handles.mibLutCheckbox.Value;
colorIndex = 0;
for colorId = 1:numel(data)
    tableData{colorId, 1} = colorId;
    tableData{colorId, 2} = data(colorId);
    if useLut
        tableData{colorId, 3} = colorGen(sprintf('rgb(%d, %d, %d)', round(lutColors(colorId, 1)*255), round(lutColors(colorId, 2)*255), round(lutColors(colorId, 3)*255)),'&nbsp;');  % rgb(0,255,0)
        displayedLutColors(colorId, :) = lutColors(colorId, :);
    else
        if sum(data) == 1
            if data(colorId) == 1
                tableData{colorId, 3} = colorGen('rgb(0, 0, 0)', '&nbsp;');
                displayedLutColors(colorId, :) = [0, 0, 0];
            else
                tableData{colorId, 3} = 'X';
                displayedLutColors(colorId, :) = [NaN, NaN, NaN];
            end
         elseif sum(data) == 2
            if numel(data) < 4 || find(data==1, 1, 'last') < 4    % when 3 or less color channels present, preserve the color channels
                if data(colorId) == 1
                    switch colorId
                        case 1
                            tableData{colorId, 3} = colorGen('rgb(255, 0, 0)', '&nbsp;');
                            displayedLutColors(colorId, :) = [1, 0, 0];
                        case 2
                            tableData{colorId, 3} = colorGen('rgb(0, 255, 0)', '&nbsp;');
                            displayedLutColors(colorId, :) = [0, 1, 0];
                        case 3
                            tableData{colorId, 3} = colorGen('rgb(0, 0, 255)', '&nbsp;');
                            displayedLutColors(colorId, :) = [0, 0, 1];
                    end
                else
                    tableData{colorId, 3} = 'X';
                    displayedLutColors(colorId, :) = [NaN, NaN, NaN];
                end
            else    % when 4 or more color channels present, show channel in blue
                if data(colorId) == 1
                    colorIndex = colorIndex + 1;
                    switch colorIndex
                        case 1
                            tableData{colorId, 3} = colorGen('rgb(255, 0, 0)', '&nbsp;');
                            displayedLutColors(colorId, :) = [1, 0, 0];
                        case 2
                            tableData{colorId, 3} = colorGen('rgb(0, 255, 0)', '&nbsp;');
                            displayedLutColors(colorId, :) = [0, 1, 0];
                    end
                else
                    tableData{colorId, 3} = 'X';
                    displayedLutColors(colorId, :) = [NaN, NaN, NaN];
                end
            end
            
        else    % 3 or more selected color channels, show only the 3 first in the list
            if data(colorId) == 1
                colorIndex = colorIndex + 1;
                switch colorIndex
                    case 1
                        tableData{colorId, 3} = colorGen('rgb(255, 0, 0)', '&nbsp;');
                        displayedLutColors(colorId, :) = [1, 0, 0];
                    case 2
                        tableData{colorId, 3} = colorGen('rgb(0, 255, 0)', '&nbsp;');
                        displayedLutColors(colorId, :) = [0, 1, 0];
                    case 3
                        tableData{colorId, 3} = colorGen('rgb(0, 0, 255)', '&nbsp;');
                        displayedLutColors(colorId, :) = [0, 0, 1];
                    otherwise
                        tableData{colorId, 3} = 'X';
                end
            else
                tableData{colorId, 3} = 'X';
                displayedLutColors(colorId, :) = [NaN, NaN, NaN];
            end
        end
    end
end
obj.mibView.handles.mibChannelMixerTable.Data = tableData;
obj.mibView.handles.mibChannelMixerTable.ColumnWidth = {19 25 15};
obj.mibModel.displayedLutColors = displayedLutColors;
end
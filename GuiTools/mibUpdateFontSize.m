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

function mibUpdateFontSize(hFig, Font)
% function mibUpdateFontSize(hFig, fontSize)
% Update font size for text widgets
%
% Parameters:
% hFig: handle to the figure
% Font: - structure with font settings, possible fields
%   .FontName -> 'Arial'
%   .FontWeight -> 'normal'
%   .FontAngle -> 'normal'
%   .FontUnits -> 'points'
%   .FontSize -> 10
%
% Return values:
% 

% Updates
% 

if ~isprop(hFig, 'RunningAppInstance')  % guide type of figure
    tempList = findall(hFig, 'Style', 'text');   % set font to text
    for i=1:numel(tempList)
        set(tempList(i), Font);
        % combine text and tooltip
        textStr = tempList(i).String;
        TooltipStr = tempList(i).TooltipString;
        if iscell(textStr)
            if isempty(TooltipStr) || numel(textStr{1}) > numel(TooltipStr) || strcmp(TooltipStr(1:numel(textStr{1})), textStr{1}) == 0
                tempList(i).TooltipString = sprintf('%s; %s', textStr{1}, TooltipStr);
            end
        else
            if isempty(TooltipStr) || numel(textStr) > numel(TooltipStr) || strcmp(TooltipStr(1:numel(textStr)), textStr) == 0
                if size(textStr,1) > 1  % reformat the char to lines
                    for ind = 2:size(textStr,1)
                        if ind==2
                            textOut = [strtrim(textStr(1,:)), '\n' strtrim(textStr(ind,:))];
                        else
                            textOut = [textOut, '\n' strtrim(textStr(ind,:))]; %#ok<AGROW>
                        end
                    end
                    textStr = textOut;
                end
                tempList(i).TooltipString = sprintf('%s; %s', textStr, TooltipStr);
                tempList(i).TooltipString = sprintf([textStr '; ' TooltipStr]);
            end
        end
    end

    tempList = findall(hFig,'Style','checkbox');    % set color to checkboxes
    for i=1:numel(tempList)
        set(tempList(i), Font);

        % combine text and tooltip
        textStr = tempList(i).String;
        TooltipStr = tempList(i).TooltipString;
        tempList(i).TooltipString = sprintf('%s; %s', textStr, TooltipStr);
    end

    tempList = findall(hFig, 'Type', 'uipanel');    % set font to panels
    set(tempList, Font);

    tempList = findall(hFig, 'Style', 'radiobutton');    % set font to radiobuttons
    set(tempList, Font);

    tempList = findall(hFig, 'Type', 'uibuttongroup');    % set font to uibuttongroup
    set(tempList, Font);

    tempList = findall(hFig, 'Type', 'uicontrol');    % set font to buttons
    set(tempList, Font);

    tempList = findall(hFig, 'Type', 'uitable');    % set font to tables
    set(tempList, Font);
else    % app designer
    processChildren(hFig, Font);
end
end

function processChildren(h, Font)
% function processChildren(h, Font)
% iterate children of h and update their font name and size
%
% Parameters:
% h: handle to a child
% Font: - structure with font settings, possible fields
%   .FontName -> 'Arial'
%   .FontWeight -> 'normal'
%   .FontAngle -> 'normal'
%   .FontUnits -> 'points'
%   .FontSize -> 10

children = h.Children;
for i=1:numel(children)
    if isprop(children(i), 'FontName')
        children(i).FontName = Font.FontName;
        if isprop(children(i), 'FontSize')  % 'matlab.ui.container.Tab' does not have find size
            children(i).FontSize = Font.FontSize+4;     % it looks that appdesigner font size is 4 units smaller than corresponding guide app
        end
    end
    if isprop(children(i), 'Children')
        processChildren(children(i), Font); 
    end
end
end

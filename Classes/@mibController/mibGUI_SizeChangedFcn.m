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

function mibGUI_SizeChangedFcn(obj, resizeParameters)
% function mibGUI_SizeChangedFcn(obj, resizeParameters)
% resizing for panels of MIB
%
% Parameters:
% resizeParameters: an optional structure used when move vertical
% (mibView.handles.mibSeparatingPanel) and horizontal
% (mibView.handles.mibSeparatingPanel2) resize panel sliders
% .name - a string with name of the panel
% .panelShift - a number with shift of the panel or true/false state to show or hide the top and bottom panels

% Updates
% 09.03.2023 added hiding/showing of the top and bottom panels

if isempty(obj.mibView); return; end

if nargin < 2
    resizeParameters = struct();
    %separatingPanelPos = obj.mibView.handles.mibSeparatingPanel.Position;
    %verticalPanelShift =  separatingPanelPos(1); %-(separatingPanelPos(3))/2;
end

mibSegmSelectedOnlyCheckPos = obj.mibView.handles.mibSegmSelectedOnlyCheck.Position;
checkH = mibSegmSelectedOnlyCheckPos(4);    % height of a checkbox to use for internal shifts

separatingPanelPos = obj.mibView.handles.mibSeparatingPanel.Position;
verticalPanelShift = separatingPanelPos(1);

separatingPanelPos2 = obj.mibView.handles.mibSeparatingPanel2.Position;
horizontalPanelShift = separatingPanelPos2(2);

if isfield(resizeParameters, 'name')
    switch resizeParameters.name
        case 'mibSeparatingPanel'
            %separatingPanelPos = obj.mibView.handles.mibSeparatingPanel.Position;
            separatingPanelPos(1) = resizeParameters.panelShift;
            obj.mibView.handles.mibSeparatingPanel.Position = separatingPanelPos;
            verticalPanelShift = resizeParameters.panelShift;
        case 'mibSeparatingPanel2'
            %separatingPanelPos = obj.mibView.handles.mibSeparatingPanel2.Position;
            separatingPanelPos2(2) = resizeParameters.panelShift;
            obj.mibView.handles.mibSeparatingPanel2.Position = separatingPanelPos2;
            horizontalPanelShift = resizeParameters.panelShift;
        case 'mibPathPanel'
            if resizeParameters.panelShift == true  % show panel
                % restore default height
                obj.mibView.handles.mibPathPanel.Position(4) = obj.mibView.guiPositions.mibPathPanel(4);  
            else    % hide panel
                obj.mibView.handles.mibPathPanel.Position(4) = 0;   
            end
        case 'mibToolsPanel'
            if resizeParameters.panelShift == true  % show panel
                % restore default height
                obj.mibView.handles.mibToolsPanel.Position(4) = obj.mibView.guiPositions.mibToolsPanel(4);   
            else    % hide panel
                obj.mibView.handles.mibToolsPanel.Position(4) = 0;   
            end
    end
end

obj.mibView.handles.mibGUI.Units = 'points';
obj.mibView.handles.mibImageAxes.Units = 'normalized';
figPos = obj.mibView.handles.mibGUI.Position;

% resize bottom panels
toolsPanPos = obj.mibView.handles.mibToolsPanel.Position;
toolsPanPos(1) = verticalPanelShift;
toolsPanPos(3) = figPos(3)-verticalPanelShift;
obj.mibView.handles.mibToolsPanel.Position = toolsPanPos;

% resize the path panel
obj.mibView.handles.mibPathPanel.Position(1) = checkH/5;
obj.mibView.handles.mibPathPanel.Position(2) = figPos(4)-obj.mibView.handles.mibPathPanel.Position(4);
obj.mibView.handles.mibPathPanel.Position(3) = figPos(3)-checkH/2.5;
obj.mibView.handles.mibPathPanel.Position(4) = obj.mibView.handles.mibPathPanel.Position(4);

obj.mibView.handles.mibPathSubPanel.Position(1) = obj.mibView.handles.mibPathPanel.Position(3)-obj.mibView.handles.mibPathSubPanel.Position(3)-checkH/3;
obj.mibView.handles.mibPathEdit.Position(3) = obj.mibView.handles.mibPathSubPanel.Position(1) - obj.mibView.handles.mibPathEdit.Position(1)-checkH/2;

obj.mibView.handles.mibPathSubPanel.Position(2) = checkH/6.5;
obj.mibView.handles.mibPathSubPanel.Position(4) = max([0 obj.mibView.handles.mibPathPanel.Position(4)-checkH/2]);

% resize the directory contents panel
obj.mibView.handles.mibDirectoryPanel.Position(1) = checkH/5;
obj.mibView.handles.mibDirectoryPanel.Position(2) = horizontalPanelShift+checkH/5;
obj.mibView.handles.mibDirectoryPanel.Position(3) = verticalPanelShift-checkH/5;
obj.mibView.handles.mibDirectoryPanel.Position(4) = obj.mibView.handles.mibPathPanel.Position(2)-horizontalPanelShift-checkH/5;

% resize subpanels inside directory contents panel
obj.mibView.handles.mibBufferTogglesButtonGroup.Position(2) = obj.mibView.handles.mibDirectoryPanel.Position(4) - obj.mibView.handles.mibBufferTogglesButtonGroup.Position(4) - checkH/1.5;

obj.mibView.handles.mibFilesListbox.Position(2) = obj.mibView.handles.mibDirSubpanel.Position(2) + obj.mibView.handles.mibDirSubpanel.Position(4)+checkH/5;
obj.mibView.handles.mibFilesListbox.Position(3) = verticalPanelShift-checkH;
panelHeight = obj.mibView.handles.mibDirectoryPanel.Position(4)-obj.mibView.handles.mibDirSubpanel.Position(4)-obj.mibView.handles.mibBufferTogglesButtonGroup.Position(4)-checkH*1.5;
if panelHeight < 1
    warndlg(sprintf('!!! Warning !!!\n\nThe height of the Directory contents is too small!\nPlease increase its height\nor do not decrease the height of MIB any further'),...
        'Height limitation', 'modal');
end
obj.mibView.handles.mibFilesListbox.Position(4) = panelHeight;

% resize the width of mibSeparatingPanel2
separatingPanelPos2(3) = verticalPanelShift - checkH/3;
obj.mibView.handles.mibSeparatingPanel2.Position = separatingPanelPos2;

% resize the segmentation panel
obj.mibView.handles.mibSegmentationPanel.Position(1) = checkH/5;
obj.mibView.handles.mibSegmentationPanel.Position(3) = obj.mibView.handles.mibDirectoryPanel.Position(3);
obj.mibView.handles.mibSegmentationPanel.Position(4) = horizontalPanelShift - checkH/5;

obj.mibView.handles.mibSegmentationTopSubPanel.Position(2) = obj.mibView.handles.mibSegmentationPanel.Position(4)-obj.mibView.handles.mibSegmentationTopSubPanel.Position(4)-checkH/1.4;

% resize the segmentation table
obj.mibView.handles.mibSegmentationTable.Position(3) = obj.mibView.handles.mibSegmentationPanel.Position(3) - checkH/1.4;
obj.mibView.handles.mibSegmentationTable.Position(4) = obj.mibView.handles.mibSegmentationPanel.Position(4) - ...
                                                       obj.mibView.handles.mibSegmentationTopSubPanel.Position(4) -...
                                                       mibSegmSelectedOnlyCheckPos(2) - checkH*2;
 
% resize ROI panel
obj.mibView.handles.mibRoiPanel.Position = obj.mibView.handles.mibSegmentationPanel.Position; 

% resize image view panel
obj.mibView.handles.mibViewPanel.Position(1) = obj.mibView.handles.mibToolsPanel.Position(1)+checkH/5;
obj.mibView.handles.mibViewPanel.Position(2) = obj.mibView.handles.mibToolsPanel.Position(2)+obj.mibView.handles.mibToolsPanel.Position(4);
obj.mibView.handles.mibViewPanel.Position(3) = figPos(3)-verticalPanelShift-checkH/2;
obj.mibView.handles.mibViewPanel.Position(4) = figPos(4)-obj.mibView.handles.mibToolsPanel.Position(4)-obj.mibView.handles.mibPathPanel.Position(4);

obj.mibView.handles.mibImageAxes.Units = 'points';
axPos = ceil(obj.mibView.handles.mibImageAxes.Position);
sliceSliderPos = obj.mibView.handles.mibSlider3Dpanel.Position;
obj.mibView.handles.mibSlider3Dpanel.Position = [sliceSliderPos(1) sliceSliderPos(2), sliceSliderPos(3),axPos(4)];

timeSliderPos = obj.mibView.handles.mibSliderTimePanel.Position;
obj.mibView.handles.mibSliderTimePanel.Position = [axPos(1) timeSliderPos(2), axPos(3), timeSliderPos(4)];

% update image
for i=1:obj.mibModel.maxId
    obj.updateAxesLimits('resize', i);
end
obj.plotImage();

%im_browser_winMouseMotionFcn(obj.mibView.handles.im_browser, NaN, handles);

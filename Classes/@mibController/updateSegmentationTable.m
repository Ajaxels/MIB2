function updateSegmentationTable(obj, position)
% function updateSegmentationTable(obj, position)
% Update obj.mibView.handles.mibSegmentationTable in the main window of mibGIU.m
%
% Parameters:
% position: [@em optional] a string with scroll value for the segmentation table:
% @li 'current' - [@em default] keep current position
% @li 'first' - scroll to the first row
% @li 'end' - scroll to the last row
%
% Copyright (C) 14.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 2; position = 'current'; end

% check Fix selection to material checkbox
userData = obj.mibView.handles.mibSegmentationTable.UserData;
if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1     % selected only
    fontColor = [200, 200, 200];
else
    fontColor = [0, 0, 0];
end

if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = {}; 
end

if obj.mibModel.I{obj.mibModel.Id}.modelType < 256  % for 63 and 255 type models
    max_color = numel(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames);
    %obj.mibView.handles.mibSegmentationTable.ColumnEditable = logical([0 0 0]);
else                                                % for other models
    max_color = 2;
    %obj.mibView.handles.mibSegmentationTable.ColumnEditable = logical([0 1 0]);
end

% generate additional colors for materials if needed
if max_color > size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1) 
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1)+1:max_color, :) = ...
        rand([max_color-size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1), 3]);
end

tableData = cell([max_color+2, 3]);
colergen = @(color,text) ['<html><table border=0 width=25 bgcolor=',color,'><TR><TD>',text,'</TD></TR></table></html>'];

if obj.mibModel.I{obj.mibModel.Id}.modelType < 256 
    %colergen2 = @(color,text) ['<html><table border=0 width=300 bgcolor=',color,'><TR><TD>',text,'</TD></TR></table></html>'];
    colergen2 = @(color,text) ['<html><table border=0 width=300 color=',color,'><TR><TD>',text,'</TD></TR></table></html>'];
    for i=1:max_color+2
        if i==1         % Mask
            tableData{i, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', round(obj.mibModel.preferences.maskcolor(1)*255), ...
                round(obj.mibModel.preferences.maskcolor(2)*255), round(obj.mibModel.preferences.maskcolor(3)*255)),'&nbsp;');  % rgb(0,255,0)
            tableData{i, 2} = colergen2(sprintf('''rgb(%d, %d, %d)''', fontColor(1), fontColor(2), fontColor(3)), 'Mask');  
            %tableData{i, 2} = 'Mask';  
            tableData{i, 3} = false;
        elseif i == 2   % Ext
            tableData{i, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', 255, 255, 255),'&nbsp;');  % rgb(0,255,0)
            tableData{i, 2} = colergen2(sprintf('''rgb(%d, %d, %d)''', fontColor(1), fontColor(2), fontColor(3)), 'Exterior');  
            %tableData{i, 2} = 'Exterior';
            tableData{i, 3} = false;
        else
            if obj.mibModel.showAllMaterials || i == obj.mibModel.I{obj.mibModel.Id}.selectedMaterial
                tableData{i, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', ...
                    round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(i-2, 1)*255), ...
                    round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(i-2, 2)*255), ...
                    round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(i-2, 3)*255)),'&nbsp;');  % rgb(0,255,0)
            else
                tableData{i, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', 255, 255, 255),'&nbsp;');  % rgb(0,255,0)
            end
            tableData{i, 2} = colergen2(sprintf('''rgb(%d, %d, %d)''', fontColor(1), fontColor(2), fontColor(3)), obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{i-2});  
            %tableData{i, 2} = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{i-2};  
            tableData{i, 3} = false;        
        end
    end
else
    tableData{1, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', round(obj.mibModel.preferences.maskcolor(1)*255), ...
        round(obj.mibModel.preferences.maskcolor(2)*255), round(obj.mibModel.preferences.maskcolor(3)*255)),'&nbsp;');  % rgb(0,255,0)
    tableData{1, 2} = 'Mask';
    tableData{1, 3} = false;
    tableData{2, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', 255, 255, 255),'&nbsp;');  % rgb(0,255,0)
    tableData{2, 2} = 'Exterior';
    tableData{2, 3} = false;
    
    colorId = mod(str2double(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{1})-1, 65535)+1;
    tableData{3, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', ...
            round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colorId, 1)*255), ...
            round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colorId, 2)*255), ...
            round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colorId, 3)*255)),'&nbsp;');  % rgb(0,255,0)
    tableData{3, 2} = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{1};  
    tableData{3, 3} = false; 
    
    colorId = mod(str2double(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{2})-1, 65535)+1;
    tableData{4, 1} = colergen(sprintf('''rgb(%d, %d, %d)''', ...
            round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colorId, 1)*255), ...
            round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colorId, 2)*255), ...
            round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colorId, 3)*255)),'&nbsp;');  % rgb(0,255,0)
    tableData{4, 2} = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{2};    
    tableData{4, 3} = false; 

end

if ~isfield(userData, 'jTable')  % stop here during starting up of MIB
     return;                                     
end

%%
jScrollPosition = userData.jScroll.getViewport.getViewPosition(); % store the view position of the table
w1 = userData.jTable.getColumnModel.getColumn(0).getWidth;
w2 = userData.jTable.getColumnModel.getColumn(1).getWidth;
w3 = userData.jTable.getColumnModel.getColumn(2).getWidth;
obj.mibView.handles.mibSegmentationTable.Data = tableData;
obj.mibView.handles.mibSegmentationTable.ColumnWidth = {w1, w2, w3};

if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial > max_color+2;     obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = 1;   end
if obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial > max_color+2;     obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = 1;   end
obj.mibView.handles.mibSegmentationTable.UserData = userData;
drawnow;
eventdata.Indices = [obj.mibModel.I{obj.mibModel.Id}.selectedMaterial, 2];

obj.mibSegmentationTable_CellSelectionCallback(eventdata);     % update Materials column
eventdata.Indices = [obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial, 3];
obj.mibSegmentationTable_CellSelectionCallback(eventdata);     % update Materials column

% restore the view position of the table
drawnow;
% scroll the table
switch position
    case 'current'
        userData.jScroll.getViewport.setViewPosition(jScrollPosition);
    case 'end'
        VerticalScrollBar = userData.jScroll.getVerticalScrollBar();
        VerticalScrollBar.setValue(VerticalScrollBar.getMaximum());
    case 'first'
        VerticalScrollBar = userData.jScroll.getVerticalScrollBar();
        VerticalScrollBar.setValue(0);
end
userData.jScroll.repaint;
% update callback for key press
obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(hObject, eventdata)); % turn ON callback for the keys
end
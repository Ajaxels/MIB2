function mibSegmentationTable_CellSelectionCallback(obj, eventdata)
% mibSegmentationTable_CellSelectionCallback(obj, eventdata)
% Callback for cell selection in the handles.mibSegmentationTable table of mibGIU.m
%
% Parameters:
% 

% Copyright (C) 14.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 21.04.2017, IB updated for 65635 type of models
% 04.08.2017, IB updated to 'e' shortcut use

if isempty(eventdata.Indices); return; end
if size(eventdata.Indices,1) > 1 && eventdata.Indices(1,1) == 1 % check for Ctrl+A press
    obj.updateSegmentationTable();
    return; 
end

Indices = eventdata.Indices(1,:);

userData = obj.mibView.handles.mibSegmentationTable.UserData;
prevMaterial = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial;   % index of the previously selected material
prevAddTo =obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial;         % index of the previously selected add to material
jTable = userData.jTable;   % jTable is initializaed in the beginning of mibGUI.m
unlink = userData.unlink;   % unlink selection of material from Add to (does not apply for the Fix selection to material mode)
% fix selection to material checkbox
if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
    unlink = 1;
    fontColor = [200, 200, 200];
else
    fontColor = [0, 0, 0];
end

if Indices(2) == 2        % selection of Material
    selectedMaterial = Indices(1);
    obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = selectedMaterial;
    
    if ~ismember(selectedMaterial, obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection)
        obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(1) = obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(2);
        obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(2) = selectedMaterial;
    end
    
    if unlink == 0
        obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = selectedMaterial;
        jTable.setValueAt(java.lang.Boolean(0), prevMaterial-1, 2);
        
        %drawnow limitrate nocallbacks;     % this syntax does not work with R2014b
        refreshdata(obj.mibView.handles.mibSegmentationTable);  % instead of drawnow, seems to be faster
        
        jTable.setValueAt(java.lang.Boolean(1), selectedMaterial-1, 2);
    end
    obj.mibView.handles.mibSegmentationTable.UserData = userData;
elseif Indices(2) == 3    % click on the Add to checkbox
    if isempty(prevMaterial)
        selectedMaterial = Indices(1);
        obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = selectedMaterial;
    else
        if unlink == 1
            selectedMaterial = prevMaterial;
            prevMaterial = [];
        else
            selectedMaterial = Indices(1);
        end
    end
    
    if isempty(prevAddTo)
        obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = Indices(1);
        jTable.setValueAt(java.lang.Boolean(1),Indices(1)-1, 2);
    elseif prevAddTo ~= Indices(1)
        jTable.setValueAt(java.lang.Boolean(0),prevAddTo-1, 2);
        obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = Indices(1);
        jTable.setValueAt(java.lang.Boolean(1),Indices(1)-1, 2);
    elseif prevAddTo == Indices(1)
        jTable.setValueAt(java.lang.Boolean(1),prevAddTo-1, 2);
    end
    
    if unlink == 0
        obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = selectedMaterial;
        if ~ismember(selectedMaterial, obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection)
            obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(1) = obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(2);
            obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(2) = selectedMaterial;
        end
    end
    obj.mibView.handles.mibSegmentationTable.UserData = userData;
else                        % define color
    if Indices(1) == 1    % mask
        c = uisetcolor(obj.mibModel.preferences.maskcolor, 'Set color for Mask');
        if length(c) == 1
            return; 
        end
        obj.mibModel.preferences.maskcolor = c;
    elseif Indices(1) > 2
        figTitle = ['Set color for ' obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{Indices(1)-2}];
        c = uisetcolor(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(Indices(1)-2,:), figTitle);
        if length(c) == 1
            return; 
        end
        if obj.mibModel.I{obj.mibModel.Id}.modelType < 256
            colIndex = Indices(1)-2;
        else
            colIndex = str2double(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{Indices(1)-2});
            colIndex = mod(colIndex-1, 65535)+1;
        end
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(colIndex,:) = c;
    else
        return;
    end
    obj.updateSegmentationTable();
    obj.plotImage(0);
    return;
end

colergen = @(color,text) ['<html><table border=0 width=300 bgcolor="rgb(255, 255, 255)" color=',color,'><TR><TD>',text,'</TD></TR></table></html>'];
% remove background for the previously selected item
if ~isempty(prevMaterial)
    if prevMaterial ~= selectedMaterial
        if prevMaterial == 1
                jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', fontColor(1), fontColor(2), fontColor(3)), 'Mask')), prevMaterial-1, 1);
        elseif prevMaterial == 2
                jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', fontColor(1), fontColor(2), fontColor(3)), 'Exterior')), prevMaterial-1, 1);
        else
                jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d,%d,%d)''', fontColor(1), fontColor(2), fontColor(3)), ...
                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{prevMaterial-2})), prevMaterial-1,1); % clear background
                
                %drawnow limitrate nocallbacks;     % this syntax does not work with R2014b
                refreshdata(obj.mibView.handles.mibSegmentationTable);  % instead of drawnow, seems to be faster
                
                if obj.mibModel.showAllMaterials == 0
                    jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', 255, 255, 255),'&nbsp;')),prevMaterial-1,0); % clear color field
                end
        end
    end
end

colergen = @(color,text) ['<html><table border=0 width=300 color=0 bgcolor=',color,'><TR><TD>',text,'</TD></TR></table></html>'];
if selectedMaterial == 1
    jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', 51, 153, 255), 'Mask')), selectedMaterial-1,1);
elseif selectedMaterial == 2
    jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', 51, 153, 255), 'Exterior')), selectedMaterial-1,1);
else
    if obj.mibModel.I{obj.mibModel.Id}.modelType < 256 
        jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', 51, 153, 255), ...
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{selectedMaterial-2})),selectedMaterial-1, 1);
        if obj.mibModel.showAllMaterials == 0
            jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', ...
                round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(selectedMaterial-2, 1)*255), ...
                round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(selectedMaterial-2, 2)*255), ...
                round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(selectedMaterial-2, 3)*255)), ...
                '&nbsp;')),selectedMaterial-1,0); % update color for the field
        end
    else
        jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', 51, 153, 255), ...
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{selectedMaterial-2})), selectedMaterial-1, 1);
        materialIndex = mod(str2double(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{selectedMaterial-2})-1, 65535)+1;
        jTable.setValueAt(java.lang.String(colergen(sprintf('''rgb(%d, %d, %d)''', ...
                round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(materialIndex, 1)*255), ...
                round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(materialIndex, 2)*255), ...
                round(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(materialIndex, 3)*255)), ...
                '&nbsp;')),selectedMaterial-1,0); % update color for the field
    end
end

if obj.mibModel.showAllMaterials == 0 && selectedMaterial > 2
    obj.plotImage();
end
end
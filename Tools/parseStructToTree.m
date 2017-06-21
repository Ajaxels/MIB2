function docNode = parseStructToTree(s,treeModel, docNode)
% function docNode = parseStructToTree(s,docNode,curNode)
% function to parse structure (XML) to uitree object
% based on struct2xml.m file by W. Falkena, ASTI, TUDelft, 27-08-2010
%
% Parameters:
% s: structure to be parsed
% docNode: node 1
%
% Return values:
% docNode: uitree object

% Copyright (C) 21.04.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

fnames = fieldnames(s);
for i = 1:length(fnames)
    curfield = fnames{i};
    
    %substitute special characters
    curfield_sc = curfield;
    
    curfield_sc = strrep(curfield_sc,'_dash_','-');
    curfield_sc = strrep(curfield_sc,'_colon_',':');
    curfield_sc = strrep(curfield_sc,'_dot_','.');
    
    if (strcmp(curfield,'AttributesText'))
        %Attribute data
        continue;
    elseif (strcmp(curfield,'Text'))
        %Text data
        if ~isempty(s.Text)
            curfield_sc = s.Text;
            curElement = uitreenode('v0',curfield_sc, curfield_sc, [], true);
            treeModel.insertNodeInto(curElement, docNode, docNode.getChildCount());
        end
    else
        %Sub-element
        if (isstruct(s.(curfield)))
            %single element
            if ~strcmp(curfield_sc, 'Attributes')
                curElement = uitreenode('v0',curfield_sc, curfield_sc, [], false);
                treeModel.insertNodeInto(curElement, docNode, docNode.getChildCount());
                parseStructToTree(s.(curfield), treeModel, curElement);
            else
                parseStructToTree(s.(curfield), treeModel, docNode);
            end
            
        elseif (iscell(s.(curfield)))
            %multiple elements
            for c = 1:length(s.(curfield))
                curElement = uitreenode('v0',curfield_sc, curfield_sc, [], false);
                treeModel.insertNodeInto(curElement, docNode, docNode.getChildCount());
                if (isstruct(s.(curfield){c}))
                    parseStructToTree(s.(curfield){c}, treeModel, curElement);
                else
                    disp('Warning. The cell could not be processed, since it contains no structure.');
                end
            end
        else
            %eventhough the fieldname is not text, the field could
            %contain text. Create a new element and use this text
            
            curElement = uitreenode('v0',[curfield_sc ': ' s.(curfield)], [curfield_sc ': ' s.(curfield)], [], true);
            treeModel.insertNodeInto(curElement, docNode, docNode.getChildCount());
        end
    end
end
end

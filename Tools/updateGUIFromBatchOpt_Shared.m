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

function View = updateGUIFromBatchOpt_Shared(View, BatchOpt)
% function obj = updateGUIFromBatchOpt_Shared(obj, BatchOpt)
% a common function used by all tools compatible with the Batch mode to
% setup widgets of GUI from the BatchOpt structure
% 
% Parameters:
% View: View class of the controller
% BatchOpt: controlling BatchOpt structure

fieldNames = fieldnames(BatchOpt);
for fieldId = 1:numel(fieldNames)
    % if fieldId==45
    %     0
    % end
    if ~isempty(View.Figure)        % for GUIs made with AppDesigner
        if isprop(View.Figure, fieldNames{fieldId})
            switch View.Figure.(fieldNames{fieldId}).Type
                case 'uieditfield'
                    View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId});
                case {'uinumericeditfield', 'uispinner'}
                    if numel(BatchOpt.(fieldNames{fieldId})) >= 2
                        if BatchOpt.(fieldNames{fieldId}){2}(1) == BatchOpt.(fieldNames{fieldId}){2}(2)     % limits can't be the same value
                            BatchOpt.(fieldNames{fieldId}){2}(2) = BatchOpt.(fieldNames{fieldId}){2}(2) + .0001;
                        end
                        View.Figure.(fieldNames{fieldId}).Limits = BatchOpt.(fieldNames{fieldId}){2};
                    end
                    if numel(BatchOpt.(fieldNames{fieldId})) >= 3
                        View.Figure.(fieldNames{fieldId}).RoundFractionalValues = BatchOpt.(fieldNames{fieldId}){3};
                    end
                    try
                        View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId}){1};
                    catch err
                        fprintf('Field id: %s\n', fieldNames{fieldId});
                        err
                    end
                case 'uicheckbox'
                    View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId});
                case 'uibuttongroup'
                    radioChildren = View.Figure.(fieldNames{fieldId}).Children;
                    for i=1:numel(radioChildren)
                        if strcmp(radioChildren(i).Tag, BatchOpt.(fieldNames{fieldId}){1})
                            radioChildren(i).Value = 1;
                        end
                    end
                case {'uidropdown', 'uilistbox'}
                    if numel(BatchOpt.(fieldNames{fieldId})) == 2   % populate the contents of the dropdown
                        % check whether the item exist in the list
                        View.Figure.(fieldNames{fieldId}).Items = BatchOpt.(fieldNames{fieldId}){2};
                    end
                    try
                        View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId}){1};
                    catch err
                        fprintf('Field id: %s\n', fieldNames{fieldId});
                        err
                    end
            end
            if isfield(BatchOpt, 'mibBatchTooltip')
                if isfield(BatchOpt.mibBatchTooltip, fieldNames{fieldId})
                    View.Figure.(fieldNames{fieldId}).Tooltip = BatchOpt.mibBatchTooltip.(fieldNames{fieldId});
                end
            end
        end
    else    % for GUIs made with GUIDE
        if isfield(View.handles, fieldNames{fieldId})
            if strcmp(View.handles.(fieldNames{fieldId}).Type, 'uibuttongroup')     % radio buttons
                radioChildren = View.handles.(fieldNames{fieldId}).Children;
                for i=1:numel(radioChildren)
                    if strcmp(radioChildren(i).Tag, BatchOpt.(fieldNames{fieldId}){1})
                        radioChildren(i).Value = 1;
                    end
                end
            else
                switch View.handles.(fieldNames{fieldId}).Style
                    case 'popupmenu'
                        if numel(BatchOpt.(fieldNames{fieldId})) == 2   % populate the contents of the dropdown
                            View.handles.(fieldNames{fieldId}).String = BatchOpt.(fieldNames{fieldId}){2};
                        end
                        View.handles.(fieldNames{fieldId}).Value = find(ismember(BatchOpt.(fieldNames{fieldId}){2}, BatchOpt.(fieldNames{fieldId}){1}));
                    case 'edit'
                        View.handles.(fieldNames{fieldId}).String = BatchOpt.(fieldNames{fieldId});
                    case 'checkbox'
                        View.handles.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId});

                end
            end
        end
    end
    
end

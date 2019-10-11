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
    if ~isempty(View.Figure)        % for GUIs made with AppDesigner
        if isprop(View.Figure, fieldNames{fieldId})
            switch View.Figure.(fieldNames{fieldId}).Type
                case 'uieditfield'
                    View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId});
                case 'uinumericeditfield'
                    View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId}){1};
                    if numel(BatchOpt.(fieldNames{fieldId})) >= 2
                        View.Figure.(fieldNames{fieldId}).Limits = BatchOpt.(fieldNames{fieldId}){2};
                    end
                    if numel(BatchOpt.(fieldNames{fieldId})) >= 3
                        View.Figure.(fieldNames{fieldId}).RoundFractionalValues = BatchOpt.(fieldNames{fieldId}){3};
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
                case 'uidropdown'
                    if numel(BatchOpt.(fieldNames{fieldId})) == 2   % populate the contents of the dropdown
                        View.Figure.(fieldNames{fieldId}).Items = BatchOpt.(fieldNames{fieldId}){2};
                    end
                    View.Figure.(fieldNames{fieldId}).Value = BatchOpt.(fieldNames{fieldId}){1};
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

function BatchOpt = updateBatchOptFromGUI_Shared(BatchOpt, hObject)
% function BatchOpt = updateBatchOptFromGUI_Shared(BatchOpt, hObject)
% a common function used by all tools compatible with the Batch mode to
% update BatchOpt structure fields from GUI widgets
%
% Parameters
% BatchOpt: current structure with BatchOpt settings
% hObject: handle to particular GUI object that should update corresponding
% field in the BatchOpt structure

switch hObject.Type
    case 'uibuttongroup'
        hChildren = hObject.Children;
        for i=1:numel(hChildren)
            if isprop(hChildren(i), 'Style')    % GUIDE GUI
                if strcmp(hChildren(i).Style, 'radiobutton')
                    if hChildren(i).Value == 1
                        BatchOpt.(hObject.Tag)(1) = {(hChildren(i).Tag)};
                    end
                end
            else        % AppDesigner GUI
                if strcmp(hChildren(i).Type, 'uiradiobutton')
                    if hChildren(i).Value == 1
                        BatchOpt.(hObject.Tag)(1) = {(hChildren(i).Tag)};
                    end
                end
            end
        end
    case {'uieditfield', 'uicheckbox'}  % app designer GUI
        BatchOpt.(hObject.Tag) = hObject.Value;
    case 'uinumericeditfield'   % app designer GUI
        BatchOpt.(hObject.Tag){1} = hObject.Value;
        BatchOpt.(hObject.Tag){2} = hObject.Limits;
        BatchOpt.(hObject.Tag){3} = hObject.RoundFractionalValues;
    case 'uidropdown'
        BatchOpt.(hObject.Tag)(1) = {hObject.Value};
    case 'uicontrol'        % GUIDE GUI
        switch hObject.Style
            case 'popupmenu'
                currString = hObject.String;
                if ~ischar(currString)
                    BatchOpt.(hObject.Tag)(1) = currString(hObject.Value);
                else    % when only a single entry in the popup menu
                    BatchOpt.(hObject.Tag)(1) = {currString};
                end
            case 'checkbox'
                BatchOpt.(hObject.Tag) = logical(hObject.Value);
            case 'edit'
                BatchOpt.(hObject.Tag) = hObject.String;
            case 'radiobutton'
                % find parent for the radio button
                radioParent = hObject.Parent;
                hRadios = findobj(radioParent, 'Style', 'radiobutton');
                for i=1:numel(hRadios)
                    BatchOpt.(hRadios(i).Tag) = false;
                end
                BatchOpt.(hObject.Tag) = logical(hObject.Value);
        end
        
end
end
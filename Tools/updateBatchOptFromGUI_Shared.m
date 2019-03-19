function BatchOpt = updateBatchOptFromGUI_Shared(BatchOpt, hObject)
% function BatchOpt = updateBatchOptFromGUI_Shared(BatchOpt, hObject)
% a common function used by all tools compatible with the Batch mode to
% setup BatchOpt structure fields

switch hObject.Style
    case 'popupmenu'
        currString = hObject.String;
        if ~ischar(currString)
            BatchOpt.(hObject.Tag) = currString(hObject.Value);
        else    % when only a single entry in the popup menu
            BatchOpt.(hObject.Tag) = {currString};
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
function BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput)
% function BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput)
% a common function used by all tools compatible with the Batch mode to
% combine fields of the input structure BatchOptIn with fields of the
% default structure BatchOpt

BatchOptInputFields = fieldnames(BatchOptInput);
for i=1:numel(BatchOptInputFields)
    % check for popup menu, update only the first element, because the second element provides the list of options
    if iscell(BatchOptInput.(BatchOptInputFields{i}))   
        if isempty(BatchOptInput.(BatchOptInputFields{i}))
            BatchOpt.(BatchOptInputFields{i})(1) = {''};
        else
            BatchOpt.(BatchOptInputFields{i})(1) = BatchOptInput.(BatchOptInputFields{i})(1);
        end
    else
        BatchOpt.(BatchOptInputFields{i}) = BatchOptInput.(BatchOptInputFields{i});
    end
end
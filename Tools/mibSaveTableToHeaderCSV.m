% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 13.09.2024
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function mibSaveTableToHeaderCSV(fn, T)
% function mibSaveTableToCSV(fn, T)
% Save MATLAB Table (T) to CSV file (fn) with a header
% standard MATLAB writetable function does not support generation of
% headers, this function allows to produce CSV file with header generated
% from table Properties
%
% Parameters:
% fn: full path to the destination filename
% T: MATLAB table, the the following examples for details of usage
%
% 

%| 
% @b Examples:
% @code
% generate data for the table
% conditionNames = {'WT', 'Treatment'}; % define conditions for data
% dataMatrix = {};
% dataMatrix{1} = [1:10; rand([1, 10])]'; % populate table with WT data
% dataMatrix{2} = [1:5; rand([1, 5])]'; % populate table with Treatment data
% % for table number of rows should be the same for all conditions
% maxLength = max(cellfun(@length, dataMatrix)); % determine the maximum length of the vectors in the cell array
% dataMatrix = cellfun(@(v) [v; NaN(maxLength-length(v), size(v,2))], dataMatrix, 'UniformOutput', false); % pad each vector with NaNs to make them the same length
% resultsTable = table(dataMatrix{:}, 'VariableNames', conditionNames); % init the table
% resultsTable = addprop(resultsTable,{'XLabel','YLabel'}, {'variable','variable'}); % [optional] add properties for X and Y labels
% resultsTable.Properties.Description = 'Desctiption of the table'; % [optional] add description
% resultsTable.Properties.RowNames = cellfun(@num2str,num2cell(1:10),'UniformOutput',false); % [optional] add row names
% for condId=1:numel(conditionNames) % [optional] add additional info
%     resultsTable.Properties.VariableDescriptions{condId} = sprintf('Condition %d description', condId);
%     resultsTable.Properties.VariableUnits{condId} = 'um'; % units
%     resultsTable.Properties.CustomProperties.XLabel{condId} = 'x label'; % x label for data
%     resultsTable.Properties.CustomProperties.YLabel{condId} = 'y label'; % y label for data
% end
% mibSaveTableToHeaderCSV('d:\myfiles\output.csv', resultsTable); % save table to CSV
% @endcode
% see more examples in MCcalc2 plugin
% Updates
%

% Open a file for writing
fid = fopen(fn, 'w');

% Write the table description as a comment in the file
if isprop(T.Properties, 'Description')
    fprintf(fid, '# Description: %s\n', T.Properties.Description);
end

% Write description of variables if available
if isprop(T.Properties, 'VariableDescriptions') && ~isempty(T.Properties.VariableDescriptions)
    fprintf(fid, '# VariableDescriptions:\n');
    for i = 1:numel(T.Properties.VariableDescriptions)
        fprintf(fid, '#   %s:  %s\n', T.Properties.VariableNames{i}, strrep(T.Properties.VariableDescriptions{i}, newline, ' '));
    end
end

% Write units value if available
if isprop(T.Properties, 'VariableUnits') && ~isempty(T.Properties.VariableUnits)
    fprintf(fid, '# VariableUnits: %s\n', T.Properties.VariableUnits{1});
end

% Write custom properties if available
if isprop(T.Properties, 'CustomProperties') && ~isempty(fieldnames(T.Properties.CustomProperties))
    customFields = fieldnames(T.Properties.CustomProperties);
    for i = 1:length(customFields)
        if isempty(T.Properties.CustomProperties.(customFields{i})); continue; end
        fprintf(fid, '# %s: %s\n', customFields{i}, T.Properties.CustomProperties.(customFields{i}){1});
    end
end
fprintf(fid, '\n');

% Write column titles, as the append mode does not write column titles

% add row names, if available
if isprop(T.Properties, 'RowNames') && ~isempty(T.Properties.RowNames)
    fprintf(fid, 'Row names, ');
end
% append variable names
for i=1:numel(T.Properties.VariableNames)
    if size(T.(T.Properties.VariableNames{i}) ,2) == 1
        fprintf(fid, '%s,', T.Properties.VariableNames{i});
    else
        for j=1:size(T.(T.Properties.VariableNames{i}) ,2)
            fprintf(fid, '%s_%d, %s_Y,', T.Properties.VariableNames{i}, j);
        end
    end
end

% Close the file
fclose(fid);

% append the main table
if isprop(T.Properties, 'RowNames') && ~isempty(T.Properties.RowNames)
    writetable(T, fn, 'WriteMode', 'append', 'WriteRowNames', true);
else
    writetable(T, fn, 'WriteMode', 'append');
end

end
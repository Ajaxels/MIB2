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

function BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput)
% function BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput)
% a common function used by all tools compatible with the Batch mode to
% combine fields of the input structure BatchOptIn with fields of the
% default structure BatchOpt

BatchOptInputFields = fieldnames(BatchOptInput);
for i=1:numel(BatchOptInputFields)
    % check for popup menu, update only the first element, because the second element provides the list of options
    
%     if strcmp(BatchOptInputFields{i}, 'Architecture')
%         0;
%     end

    if iscell(BatchOptInput.(BatchOptInputFields{i}))
        if isempty(BatchOptInput.(BatchOptInputFields{i}))
            BatchOpt.(BatchOptInputFields{i})(1) = {''};
        else
            if isfield(BatchOpt, BatchOptInputFields{i})
                % take only the first element
                %try
                BatchOpt.(BatchOptInputFields{i})(1) = BatchOptInput.(BatchOptInputFields{i})(1);
                %catch err
                %    0
                %end
            else    % take all elements
                for indexId = 1:numel(BatchOptInput.(BatchOptInputFields{i}))
                    BatchOpt.(BatchOptInputFields{i})(indexId) = BatchOptInput.(BatchOptInputFields{i})(indexId);
                end
            end
            % BatchOpt.(BatchOptInputFields{i})(1) = BatchOptInput.(BatchOptInputFields{i})(1);
        end
    else
        BatchOpt.(BatchOptInputFields{i}) = BatchOptInput.(BatchOptInputFields{i});
    end
end
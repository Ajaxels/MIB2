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

function primaryStruct = mibConcatenateStructures(primaryStruct, secondaryStruct)
% function primaryStruct = mibConcatenateStructures(primaryStruct, secondaryStruct)
% update fields of  primaryStruct using the fields of secondaryStruct
%
% Parameters:
% primaryStruct: primary structure that should be updates
% secondaryStruct: secondary structure that should be concatenated into the primary structure
%
% Return value:
% primaryStruct: updated primary structure

%| 
% @b Examples:
% @code obj.mibModel.preferences = mibConcatenateStructures(obj.mibModel.preferences, mib_pars.preferences); //updates fields of obj.mibModel.preferences with fields from mib_pars.preferences @endcode

% Updates
% 

secFieldsList = fieldnames(secondaryStruct);

for fieldId = 1:length(secFieldsList)
    % try
        if isstruct(secondaryStruct.(secFieldsList{fieldId})) || ...
            ( isfield(primaryStruct, secFieldsList{fieldId}) && isstruct(primaryStruct.(secFieldsList{fieldId})) )
            if isempty(secondaryStruct.(secFieldsList{fieldId}))
                continue;
            elseif isfield(primaryStruct, secFieldsList{fieldId})
                if isstruct(secondaryStruct.(secFieldsList{fieldId}))
                    primaryStruct.(secFieldsList{fieldId}) = ...
                        mibConcatenateStructures(primaryStruct.(secFieldsList{fieldId}), secondaryStruct.(secFieldsList{fieldId}));
                end
            else
                primaryStruct.(secFieldsList{fieldId}) = secondaryStruct.(secFieldsList{fieldId});
            end
        else
            primaryStruct.(secFieldsList{fieldId}) = secondaryStruct.(secFieldsList{fieldId});
        end
    % catch err
    %     err
    % end
end
end
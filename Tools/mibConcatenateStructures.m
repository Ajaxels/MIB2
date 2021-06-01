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
%
% Copyright (C) 03.11.2020, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

secFieldsList = fieldnames(secondaryStruct);

for fieldId = 1:length(secFieldsList)
    if isstruct(secondaryStruct.(secFieldsList{fieldId}))
        if isfield(primaryStruct, secFieldsList{fieldId})
            primaryStruct.(secFieldsList{fieldId}) = ...
                mibConcatenateStructures(primaryStruct.(secFieldsList{fieldId}), secondaryStruct.(secFieldsList{fieldId}));
        else
            primaryStruct.(secFieldsList{fieldId}) = secondaryStruct.(secFieldsList{fieldId});
        end
    else
        primaryStruct.(secFieldsList{fieldId}) = secondaryStruct.(secFieldsList{fieldId});
    end
end
end
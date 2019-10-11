function index = getSelectedMaterialIndex(obj, target)
% function index = getSelectedMaterialIndex(obj)
% return the index of the currently selected material in the mibView.handles.mibSegmentationTable
% 
% Parameters:
% target: a string with optional target column of the table
% @li ''Material'' - (@em default) the selected row in the material column
% @li ''AddTo'' - the selected row in the AddTo column
%
% Return values:
% index: an index of the currently selected material;
% @li ''-1'' - Mask
% @li ''0'' - Exterior
% @li ''1'' - 1st material of the model
% @li ''2'' - 2nd material of the model
%

%| 
% @b Examples:
% @code selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex(); // call from mibController class; return the index of the currently selected material @endcode
% @code selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'); // call from mibController class; return the index of the currently selected material in the AddTo column @endcode

if nargin < 2; target = 'Material'; end

switch target
    case 'Material'
        index = obj.selectedMaterial;
    case 'AddTo'
        index = obj.selectedAddToMaterial;
end

if obj.modelType < 256
    index = index - 2;
else
    index = index - 2;
    if index > 0
        index = str2double(obj.modelMaterialNames{index});
    end
end
end
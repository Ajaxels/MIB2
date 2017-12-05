function index = getSelectedMaterialIndex(obj)
% function index = getSelectedMaterialIndex(obj)
% return the index of the currently selected material
% 
% Parameters:
% 
% Return values:
% index: an index of the currently selected material
%

%| 
% @b Examples:
% @code selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex(); // call from mibController class; return the index of the currently selected material @endcode

if obj.modelType < 256
    index = obj.selectedMaterial - 2;
else
    index = str2double(obj.modelMaterialNames{obj.selectedMaterial - 2});
end

end
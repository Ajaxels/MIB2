function updateWidgets(obj)
% function updateWidgets(obj)
% update widgets of mibBatchController class

% update obj.View.handles.actionPopup

obj.View.handles.sectionPopup.String = {obj.Sections.Name}';
obj.View.handles.sectionPopup.Value = obj.selectedSection;

obj.View.handles.actionPopup.String = {obj.Sections(obj.selectedSection).Actions.Name}';
obj.View.handles.actionPopup.Value = obj.selectedAction;

end



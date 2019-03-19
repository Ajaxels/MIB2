classdef (ConstructOnLoad) ToggleEventData < event.EventData
    % a class to path event data with notify function
    
    properties
        Parameter
    end
    
    methods
        function data = ToggleEventData(newParameter)
            data.Parameter = newParameter;
        end
    end
end
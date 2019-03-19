classdef (ConstructOnLoad) ToggleEventData < event.EventData
    % a class to pass data together with a notification event
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.

    
    properties
        Parameter
    end
    
    methods
        function data = ToggleEventData(newParameter)
            % function data = ToggleEventData(newParameter)
            % 
            % Parameters:
            % newParameter: a data that has to be passed to the destination
            % function with the event
            %
            % Return values:
            % data: a structure with the provided parameter
            
            data.Parameter = newParameter;
        end
    end
end
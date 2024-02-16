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

classdef mibPluginWithoutGUIController < handle
    properties
        mibModel
        % handles to the model
        noGui = 1
        % a variable indicating a plugin without GUI
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when plugin is closed
    end
    
    methods
        function obj = mibPluginWithoutGUIController(mibModel)
            obj.mibModel = mibModel;    % assign model
            
			% check for the virtual stacking mode and close it
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                return;
            end
			
            % start the main function
			obj.calculateBtn_Callback(); 
        end
        
        % ------------------------------------------------------------------
        % Main function for calculations
        % Add your code here
        function calculateBtn_Callback(obj)
            % start main calculation of the plugin
            
            % below a small test, replace it with your own code
            
            % add a waitbar to follow the progress
            wb = waitbar(0, 'Please wait');
            
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');  % get dataset dimensions
            img = cell2mat(obj.mibModel.getData2D('image'));    % get the currently displayed image

            waitbar(0.5, wb);   % update the waitbar
            imtool(img);        % display the current image using imtool
            waitbar(1, wb);     % update the waitbar
            delete(wb);         % delete the waitbar
        end
        
        
    end
end
classdef mibChildView < handle
    % @type mibChildView class is a template of the View type classes for
    % each controller
    
	% Copyright (C) 16.12.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	%
    
    properties
        gui
        % handle to the main gui Figure
        mibModel
        % handles to the model
        Controller
        % handles to the controller
        handles
        % a list of handles for the gui
        Figure
        % handle to the for GUI made with AppDesigner
    end
    
    methods
        function obj = mibChildView(controller, guiName)
            obj.Controller = controller;
            obj.mibModel = controller.mibModel;
            fh = str2func(guiName);     % string to function
            obj.gui = fh(obj.Controller);   % init the gui
            
            if isprop(obj.gui, 'Figure')  % appDesigner app
                % copy property names to Tag field, to have it similar to GUIDE usage
                propList = properties(obj.gui);
                for propId = 1:numel(propList)
                    if isprop(obj.gui.(propList{propId}), 'Tag')
                        obj.gui.(propList{propId}).Tag = propList{propId};
                    end
                end
                guiHandle = obj.gui.Figure;
                obj.getChildren(guiHandle);
                
                obj.Figure = obj.gui;
                obj.gui = obj.gui.Figure;
            else   % guide app
                % extract handles to widgets of the main GUI
                figHandles = findobj(obj.gui);
                for i=1:numel(figHandles)
                    if ~isempty(figHandles(i).Tag)  % some context menu comes without Tags
                        obj.handles.(figHandles(i).Tag) = figHandles(i);
                    end
                end
            end
            % add listner to obj.mibModel and call controller function as a callback
            %obj.Controller.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.Controller.ViewListner_Callback(obj.Controller, src, evnt));     % for static
            %obj.Controller.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.Controller.ViewListner_Callback(obj.Controller, src, evnt));     % for static
        end
        
        function getChildren(obj, guiHandle)
            % get handles to children of GUI elements and assign them to
            % obj.handles structure
            %
            % Parameters:
            % guiHandle: handle of the element to get children
            childrenList = guiHandle.Children;
            for i=1:numel(childrenList)     % generate handles structure similar to guide
                obj.handles.(childrenList(i).Tag) = childrenList(i);
                switch childrenList(i).Type
                    case {'uigridlayout', 'uipanel'}
                        obj.getChildren(obj.handles.(childrenList(i).Tag));
                    otherwise
                        
                end
            end
        end
    end
end
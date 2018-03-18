classdef mibAboutController < handle
    % classdef mibAboutController < handle
    % a controller class for the About window
    
    % Copyright (C) 28.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibAboutController(mibModel, versionText)
            global Font mibPath;
            obj.mibModel = mibModel;    % assign model
            
            guiName = 'mibAboutGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            if obj.View.handles.descriptionText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.descriptionText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % load splash screen
            img = imread(fullfile(mibPath, 'Resources', 'mib_about.jpg'));
            
            addTextOptions.color = [1 1 0];
            addTextOptions.fontSize = 3;
            addTextOptions.markerText = 'text';
            addTextOptions.AnchorPoint = 'LeftBottom';
            dateTag = versionText(26:end);  % trim to remove 'Microscopy Image Browser ' text
            img = mibAddText2Img(img, dateTag, [1,402], addTextOptions);
            
            imh = image(img, 'parent', obj.View.handles.axes1);
            obj.View.handles.axes1.XTick = [];
            obj.View.handles.axes1.YTick = [];
            obj.View.handles.axes1.Box = 'off';
            obj.View.handles.axes1.Visible = 'off';
            
            greet_txt1 = [
                {versionText}
                ];
            
            greet_txt2 = [
                {'image segmentation and beyond'}
                {'Matlab for dummies series'}
                {'http://mib.helsinki.fi'}
                {''}
                {'Core developer:'}
                {'     Ilya Belevich'}
                {'     ilya.belevich@helsinki.fi'}
                {''}
                {'Developers:'}
                {'     Merja Joensuu'}
                {'     Darshan Kumar'}
                {'     Helena Vihinen'}
                {'     Eija Jokitalo'}
                {''}
                {'Electron Microscopy Unit'}
                {'Institute of Biotechnology'}
                {'University of Helsinki'}
                {'Finland'}
                ];
            obj.View.handles.titleText.String = greet_txt1;
            obj.View.handles.descriptionText.String = greet_txt2;
            
        end
        
        function closeWindow(obj)
            % closing mibAboutController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
    end
end
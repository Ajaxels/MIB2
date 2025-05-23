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

classdef mibMeasure < matlab.mixin.Copyable
    % @type mibMeasure class is responsible for keeping Measurements
    
    % Updates
    %
    
    % heavily based on Image Measurement Utility written by Jan Neggers,
    % Eindhoven Univeristy of Technology.
    % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
    
    properties
        Data
        % a structure with measurements
        %      .Data.n  - index, double
        %      .Data.type   - type, string: 'LinDistance',
        %      .Data.value  - value, double
        %      .Data.info   - info, free text
        %      .Data.X      - X-coordinates of points
        %      .Data.Y      - Y-coordinates of points
        %      .Data.Z      - Z-coordinates of points
        %      .Data.T      - T-coordinates of points
        %      .Data.orientation      - orientation of the measurement: 4-yx; 1-zx; 2-zy
        %      .Data.spline
        %      .Data.circ
        %      .Data.intensity  - average intensity of the profile
        %      .Data.profile    - intensity profile
        %      .Data.integrateWidth - only for Distance (linear) width of the integrated intensity profile, otherwise empty
        hImg
        % handle to mibImage class
        Options
        % a structure with show options
        %      .Options.marker1 = 'o'; - style 1 for markers
        %      .Options.marker2 = '.';  - style 2 for markers
        %      .Options.markersize = '10'; - size of markers
        %      .Options.linestyle1 = '-'; - style 1 for lines
        %      .Options.linestyle2 = '--'; - style 2 for lines
        %      .Options.linewidth = '1' ; - width for lines
        %      .Options.color1 = 'y';   - color style 1
        %      .Options.color2 = 'k';   - color style 2
        %      .Options.textcolorfg = 'y';  - text color
        %      .Options.textcolorbg = 'none';  - color for text background
        %      .Options.fontsize = '14';  - size of the font
        %      .Options.splinemethod = 'spline';  - method for splines
        %      .Options.showMarkers = 1;
        %      .Options.showLines = 1;
        %      .Options.showText = 1;
        roi
        % a structure with ROI data:
        % - roi.pos - coordinates of ROIs
        % - roi.type - ROIs type: 'imline'
        % - roi.imroi - handle to imroi Matlab class
        % - roi.cb - array of callbacks to 'addNewPositionCallback' function
        typeToShow
        % a string that defines type of measurements to show:
        % - 'All' - show all
        % - 'Angle'
        % - 'Caliper'
        % - 'Circle (R)'
        % - 'Distance (linear)'
        % - 'Distance (polyline)'
        % - 'Point'
        fixZ
        % a switch that fixes Z and T values when the measurements are recalculated
    end
    
    events
        addMeasurement
        % add a new measurement, when the Measure Tool is displayed
        % note: use this syntax instead to send event
        % motifyEvent.Name = 'addMeasurement';
        % eventdata = ToggleEventData(motifyEvent);
        % notify(obj.mibModel, 'modelNotify', eventdata);
        updatePosition
        % update coordinates of measurements
    end
    
    methods
        function obj = mibMeasure(hImg)
            % function obj = mibMeasure(hImg)
            % Constructor for the @type mibMeasure class.
            %
            % Constructor for the mibMeasure class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % hImg: - handle to mibImage class
            %
            % Return values:
            % obj - instance of the @type mibMeasure class.
            
            obj.hImg = hImg;
            obj.clearContents();
        end
        
        function addMeasurements(obj, newData, n)
            % function addMeasurements(obj, newData, n)
            % add or insert measurement into the obj.Data structure
            %
            % Parameters:
            % newData: structure of a new measurement to insert. Fields should match those of obj.Data
            % n: [@em optional] position where to add the measurement, @em default - number of measurements in obj.Data + 1
            %
            % Return values:
            %
            
            %|
            % @b Examples:
            % @code mibMeasure.addMeasurements(newData, 5); insert measurement to position 5 @endcode
            
            if nargin < 3; n = obj.getNumberOfMeasurements() + 1; end
            
            noMeasurements = obj.getNumberOfMeasurements();
            if n <= noMeasurements  % insert measurement
                obj.Data(n+1:numel(obj.Data)+1)  = obj.Data(n:numel(obj.Data));
                obj.Data(n) = newData;
                newNs = num2cell(1:numel(obj.Data));
                [obj.Data(1:numel(obj.Data)).n] = newNs{:};
            else                    % add measurement
                obj.Data(n) = newData;
            end
        end
        
        
        function addMeasurementsToPlot(obj, mibModel, mode, axes)
            % function addMeasurementsToPlot(obj, mibModel, mode, axes)
            % plot measurement marks above images
            %
            % Parameters:
            % mibModel: mibModel class of MIB
            % mode: a string that defines a mode of the shown image: 'shown' (in most cases), or 'full' (for panning)
            % axes: define a handles to axes that should be
            % used for drawing, used in mibSnapshotGUI.m; @em default mibView.handles.mibImageAxes
            %
            % Return values:
            %
            
            %|
            % @b Examples:
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.addMeasurementsToPlot(obj.mibModel, 'shown', obj.mibView.handles.mibImageAxes); // call from mibController; to show the measurements above the image in the mibController.plotImage function @endcode
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.addMeasurementsToPlot(obj.mibModel, 'full', obj.mibView.handles.mibImageAxes); // call from mibController; to show the measurements above the image in the mibGUI_WindowButtonDownFcn function @endcode
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            
            if nargin < 4
                %axes = mibController.mibView.handles.mibImageAxes;
                axes = gca;
            end
            
            sliceNo = obj.hImg.getCurrentSliceNumber();
            timePnt = obj.hImg.getCurrentTimePoint();
            ZT_vec = [[obj.Data.Z]', [obj.Data.T]'];
            if isempty(ZT_vec); return; end
            indices = find(ismember(ZT_vec, [sliceNo timePnt],'rows') == 1);    %#ok<EFIND> % get indices of measurements that should be shown
            
            if mibModel.mibShowAnnotationsCheck == 0 || isempty(indices)     % nothing to show
                return;
            end
            
            O = obj.Options;
            % Evaluate options
            % ==============================
            marker = {O.marker1 ; O.marker2};
            markersize = str2double(O.markersize);
            if length(O.color1) == 1 || strcmpi(O.color1,'none')
                color{1,1} = O.color1;
            else
                color{1,1} = str2num(O.color1);
            end
            if length(O.color2) == 1 || strcmpi(O.color2,'none')
                color{2,1} = O.color2;
            else
                color{2,1} = str2num(O.color2);
            end
            linestyle = {O.linestyle1 ; O.linestyle2};
            linewidth = str2double(O.linewidth);
            if length(O.textcolorfg) == 1 || strcmpi(O.textcolorfg,'none')
                textcolorfg = O.textcolorfg;
            else
                textcolorfg = str2num(O.textcolorfg); %#ok<*ST2NM>
            end
            if length(O.textcolorbg) == 1  || strcmpi(O.textcolorbg,'none')
                textcolorbg = O.textcolorbg;
            else
                textcolorbg = str2num(O.textcolorbg);
            end
            fontsize = str2double(O.fontsize);
            
            set(axes, 'NextPlot', 'add');
            %indices = find([obj.Data.Z]' == sliceNo);
            
            if ~strcmp(obj.typeToShow, 'All')
                indices2 = find(ismember([obj.Data.type], obj.typeToShow));
                indices = intersect(indices, indices2);
            end
            for i = 1:numel(indices)
                % convert the value to string
                value = sprintf('%.2f', obj.Data(indices(i)).value);
                X = obj.Data(indices(i)).X;
                Y = obj.Data(indices(i)).Y;
                circ  = obj.Data(indices(i)).circ;
                spl   = obj.Data(indices(i)).spline;
                if strcmp(get(get(axes,'parent'),'tag'), 'mibViewPanel')  % recalculate coordinates for the imageAxes
                    [X,Y] = mibModel.convertDataToMouseCoordinates(X, Y, mode);
                else
                    [X,Y] = mibModel.convertDataToMouseCoordinates(X, Y, mode, 1);
                end
                
                % plot the measurement, and set the plot options
                switch cell2mat(obj.Data(indices(i)).type)
                    case 'Distance (linear)'
                        h1 = plot(axes, X, Y, '-xw', X, Y, ':+k');
                        ht = text(X(2),Y(2),['  ' value], 'Parent', axes);
                        h  = h1;
                    case 'Point'
                        h1 = plot(axes, X, Y, 'o');
                        ht = text(X, Y, ['  ' obj.Data(indices(i)).value], 'Parent', axes);
                        h  = h1;
                        %marker = marker(1);
                        %color = color(1);
                        %linestyle = linestyle(1);
                    case 'Caliper'
                        h1 = plot(axes, X(1:2), Y(1:2), '-xw', X(1:2), Y(1:2), ':+k');
                        h2 = plot(axes, X(3:4), Y(3:4), '-xw', X(3:4), Y(3:4), ':+k');
                        h  = [h1; h2];
                        ht = text(X(3), Y(3), ['  ' value], 'Parent', axes);
                        
                        set(h2, {'Marker'}, marker)
                        set(h2, 'MarkerSize', markersize)
                        set(h2, {'MarkerEdgeColor'}, color)
                        
                        set(h2, {'LineStyle'}, linestyle)
                        set(h2, {'Color'}, color)
                        set(h2, 'LineWidth', linewidth)
                    case 'Circle (R)'
                        if strcmp(get(get(axes, 'parent'), 'tag'), 'mibViewPanel')  % recalculate coordinates for the imageAxes
                            [circ.xc, circ.yc] = mibModel.convertDataToMouseCoordinates(circ.xc, circ.yc, mode);
                        else
                            [circ.xc,circ.yc] = mibModel.convertDataToMouseCoordinates(circ.xc, circ.yc, mode, 1);
                        end
                        h1 = plot(axes, circ.xc, circ.yc, 'xw', circ.xc, circ.yc, '+k');
                        h2 = plot(axes, X, Y, '-w', X, Y, ':k');
                        h  = [h1; h2];
                        ht = text(circ.xc, circ.yc, ['  ' value], 'Parent', axes);
                        
                        set(h2, 'Marker', 'none')
                        set(h2, {'LineStyle'}, linestyle)
                        set(h2, {'Color'}, color)
                        set(h2, 'LineWidth', linewidth)
                    case 'Angle'
                        h1 = plot(axes, X, Y, '-xw', X, Y, ':+k');
                        ht = text(X(2), Y(2), ['   ' value], 'Parent', axes);
                        h = h1;
                    case 'Distance (polyline)'
                        if strcmp(get(get(axes, 'parent'), 'tag'), 'mibViewPanel')  % recalculate coordinates for the imageAxes
                            [spl.x, spl.y] = mibModel.convertDataToMouseCoordinates(spl.x, spl.y, mode);
                        else
                            [spl.x, spl.y] = mibModel.convertDataToMouseCoordinates(spl.x, spl.y, mode, 1);
                        end
                        h1 = plot(axes, spl.x, spl.y, 'xw', spl.x, spl.y, '+k');
                        h2 = plot(axes, X, Y, '-w', X, Y, ':k');
                        h  = [h1; h2];
                        ht = text(spl.x(end), spl.y(end), [' ' value], 'Parent', axes);
                        
                        set(h2, 'Marker', 'none');
                        set(h2, {'LineStyle'}, linestyle);
                        set(h2, {'Color'}, color);
                        set(h2, 'LineWidth', linewidth);
                end
                
                if strcmp(cell2mat(obj.Data(indices(i)).type), 'Point')
                    set(h1, {'MarkerEdgeColor'}, color(1));
                    set(h1, {'Color'}, color(1));
                    set(h1, {'Marker'}, marker(1));
                    set(h1, {'LineStyle'}, linestyle(1));
                else
                    set(h1, {'MarkerEdgeColor'}, color);
                    set(h1, {'Color'}, color);
                    set(h1, {'Marker'}, marker);
                    set(h1, {'LineStyle'}, linestyle);
                end

                set(h1, 'MarkerSize', markersize);
                                set(h1, 'LineWidth', linewidth);
                
                if strcmp(cell2mat(obj.Data(indices(i)).type), 'Distance (polyline)')
                    set(h1, 'LineStyle', 'none');
                end
                
                set(ht, 'Color', textcolorfg);
                set(ht, 'BackgroundColor', textcolorbg);
                set(ht, 'FontSize', fontsize);
                
                if O.showMarkers == 0; set(h, 'marker', 'none'); end
                if O.showLines == 0; set(h, 'LineStyle', 'none'); end
                if O.showText == 0; set(ht, 'Visible', 'off'); end
                
                set(ht, 'tag', 'measurements');
                set(h, 'tag', 'measurements');
            end
            axes.NextPlot = 'replace';
        end
        
        
        function clearContents(obj)
            % function clearContents(obj)
            % Set all elements of the class to default values
            %
            % Parameters:
            %
            % Return values:
            
            %|
            % @b Examples:
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.clearContents(); // call from mibController; @endcode
            
            obj.setDefaultOptions();   %  set Options to default state
            obj.clearData();  % clear Data structure
            obj.fixZ = false; % allow change of Z and T when editing measurements, it should be true when the measurements are recalculated
        end
        
        function clearData(obj)
            % function clearData(obj)
            % Removes all values of the Data structure
            %
            % Parameters:
            %
            % Return values:
            
            %|
            % @b Examples:
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.clearData(); // call from mibController; @endcode
            
            obj.Data = [];
            
            obj.Data.n = [];
            obj.Data.type = [];
            obj.Data.value  = [];
            obj.Data.X = [];
            obj.Data.Y = [];
            obj.Data.Z = [];
            obj.Data.T = [];
            obj.Data.spline = [];
            obj.Data.circ = [];
            obj.Data.intensity = [];
            obj.Data.profile = [];
            obj.Data.integrateWidth = [];
            obj.Data.info = [];
            
            obj.roi.pos = [];
            obj.roi.type = [];
            obj.roi.imroi = [];
            obj.roi.cb = [];
            
            if isempty(obj.typeToShow); obj.typeToShow = 'All'; end
        end
        
        function generateKymograph(obj, mibController, index, colCh, options)
            % function generateKymograph(mibController, index, colCh, widthProfile, options)
            % generate kymograph and save it as an image
            %
            % Parameters:
            % mibController: handle to mibController class
            % index: an index of the measurement to update
            % colCh: number of a color channel for intensity profile, or 0 for all color channels
            % options: structure with additional options
            % .widthProfile -  width of profile for measurements of intensity profiles, could be empty
            % .outputFilename - full path to the output file
            % .outputFormat - output format, 'tif', 'csv, mat'
            % .calcKymograph - true/false, calculate kymograph
            
            if nargin < 5; options = struct(); end
            if nargin < 4; colCh = obj.Data(index).colCh; end
            if ~isfield(options, 'widthProfile'); options.widthProfile = []; end
            if ~isfield(options, 'outputDir'); options.outputDir = 'c:\temp'; end
            if ~isfield(options, 'fnTemplate'); options.fnTemplate = 'kymograph'; end
            if ~isfield(options, 'outputFormat'); options.outputFormat = 'tif'; end
            if ~isfield(options, 'calcKymograph'); options.calcKymograph = true; end
            
            finetuneCheck = 0;
            calcIntensity = 1;
            
            type = obj.Data(index).type;
            switch cell2mat(type)
                case 'Distance (linear)'
                    obj.DistanceFun(mibController, index, colCh, finetuneCheck, options.widthProfile, calcIntensity, options);
                case 'Circle (R)'
                    % not available
                case 'Angle'
                    % not available
                case 'Caliper'
                    % not available
                case 'Distance (polyline)'
                    obj.DistancePolyFun(mibController, index, colCh, [], finetuneCheck, calcIntensity, options);
                case 'Point'
                    % not available
            end
            
        end
        
        function editMeasurements(obj, mibController, index, colCh, widthProfile, finetuneCheck, calcIntensity)
            % function editMeasurements(obj, mibController, colCh, widthProfile, finetuneCheck, calcIntensity)
            % update measurements
            %
            % Parameters:
            % mibController: handle to mibController class
            % index: an index of the measurement to update
            % colCh: number of a color channel for intensity profile, or 0
            % for all color channels
            % widthProfile: [@em optional] width of profile for measurements of intensity profiles, could be empty
            % finetuneCheck: [@em optional] a number 0 - do not fine tune the measurement; 1-do the finetuning manually
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate
            % intensity profile, 0 - do not calculate
            
            if nargin < 7; calcIntensity = 1; end
            if nargin < 6; finetuneCheck = 1; end
            if nargin < 5; widthProfile = []; end
            if nargin < 4; colCh = obj.Data(index).colCh; end
            
            %disableSegmentation = mibController.mibModel.disableSegmentation;
            mibController.mibModel.disableSegmentation = 1;
            
            type = obj.Data(index).type;
            switch cell2mat(type)
                case 'Distance (linear)'
                    obj.DistanceFun(mibController, index, colCh, finetuneCheck, widthProfile, calcIntensity);
                case 'Circle (R)'
                    obj.CircleFun(mibController, index, colCh, finetuneCheck, calcIntensity);
                case 'Angle'
                    obj.AngleFun(mibController, index, colCh, finetuneCheck, calcIntensity);
                case 'Caliper'
                    obj.CaliperFun(mibController, index, colCh, finetuneCheck, calcIntensity);
                case 'Distance (polyline)'
                    obj.DistancePolyFun(mibController, index, colCh, [], finetuneCheck, calcIntensity);
                case 'Point'
                    obj.PointFun(mibController, index, colCh, finetuneCheck, calcIntensity);
            end
            mibController.mibModel.disableSegmentation = 0;
        end
        
        function removeMeasurements(obj, index)
            % removeMeasurements(obj, index)
            % Remove measurement(s) from the class
            %
            % Parameters:
            % index: [optional], an index of the measurement point to remove, when empty or zero - removes all points
            %
            % Return values:
            %
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.removeMeasurements(); // call from mibController;remove all measurements @endcode
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.removeMeasurements(5); // call from mibController; remove 5th measurement @endcode
            
            if nargin < 2; index = 0; end;
            if isempty(index); index = 0; end;
            
            if index == 0   % remove all measurements
                button = questdlg(sprintf('Warning!\nYou are going to delete all measurements\nAre you sure?'),'Delete measurements!','Delete','Cancel','Cancel');
                if strcmp(button, 'Cancel'); return; end;
                obj.clearData();
            else            % remove a single measurement
                if numel(index) == obj.getNumberOfMeasurements()
                    obj.clearData();    % situation that is equal to delete all
                else
                    obj.Data(index) = [];
                    newNs = num2cell(1:numel(obj.Data));
                    [obj.Data(1:numel(obj.Data)).n] = newNs{:};
                end;
                
            end
        end
        
        function setOptions(obj)
            % function setOptions(obj)
            % Update all values of the Options structure of the class
            %
            % Parameters:
            %
            % Return values:
            
            %|
            % @b Examples:
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.setOptions(); call from mibController; @endcode
            
            prompt={...
                sprintf('Marker Style 1\n( + o * . x s d ^ v > < p h )'),...
                'Marker Style 2',...
                'Marker Size',...
                sprintf('Line Style 1\n(-   --   :   -. )'),...
                'Line Style 2',...
                'Line Width',...
                sprintf('Color 1\n( r  g  b  c  m  y  k  w none)'),...
                'Color 2',...
                'Text Foreground Color',...
                'Text Background Color',...
                'Text Fontsize'};
            
            O = obj.Options;
            O = rmfield(O, 'showMarkers');
            O = rmfield(O, 'showLines');
            O = rmfield(O, 'showText');
            O = rmfield(O, 'splinemethod');
            fields = fieldnames(O);
            
            defAns={...
                {'+', 'o', '*', '.', 'x', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};...
                {'+', 'o', '*', '.', 'x', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};...
                O.markersize;...
                {'-','--',':','-.'};...
                {'-','--',':','-.'};...
                O.linewidth;...
                {'r','g','b','c','m','y','k','w','none'};...
                {'r','g','b','c','m','y','k','w','none'};...
                {'r','g','b','c','m','y','k','w','none'};...
                {'r','g','b','c','m','y','k','w','none'};...
                O.fontsize};
            
            % build the default answer from the options structure
            for k = [1 2 4 5 7 8 9 10]
                idx2 = find(ismember(defAns{k}, O.(fields{k}))==1);
                defAns{k}{end+1} = idx2;
                %                 defaultanswer{k} = O.(fields{k});
                %                 if ~ischar(defaultanswer{k})
                %                     defaultanswer{k} = num2str(defaultanswer{k});
                %                 end
            end
            
            A = mibInputMultiDlg([], prompt, defAns, 'Plot Options');
            if isempty(A); return; end
            
            obj.Options.marker1 = A{1};
            obj.Options.marker2 = A{2};
            obj.Options.markersize = A{3};
            obj.Options.linestyle1 = A{4};
            obj.Options.linestyle2 = A{5};
            obj.Options.linewidth = A{6};
            obj.Options.color1 = A{7};
            obj.Options.color2 = A{8};
            obj.Options.textcolorfg = A{9};
            obj.Options.textcolorbg = A{10};
            obj.Options.fontsize = A{11};
            
        end
        
        function setDefaultOptions(obj)
            % function setDefaultOptions(obj)
            % Set all values of the Options structure of the class to default values
            %
            % Parameters:
            %
            % Return values:
            
            %|
            % @b Examples:
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.setDefaultOptions(); // call from mibController; @endcode
            
            obj.Options.marker1 = 'o';
            obj.Options.marker2 = '.';
            obj.Options.markersize = '10';
            obj.Options.linestyle1 = '-';
            obj.Options.linestyle2 = '--';
            obj.Options.linewidth = '1' ;
            obj.Options.color1 = 'y';
            obj.Options.color2 = 'k';
            obj.Options.textcolorfg = 'y';
            obj.Options.textcolorbg = 'none';
            obj.Options.fontsize = '14';
            obj.Options.splinemethod = 'spline';
            obj.Options.showMarkers = 1;
            obj.Options.showLines = 1;
            obj.Options.showText = 1;
        end
        
        function position = drawROI(obj, mibController, type, pos, instant)
            % function drawROI(obj, mibController, type, pos, instant)
            % show a ROI object in the mibController.mibView.handles.mibImageAxes for selection of
            % the area to measure
            %
            % Creates an instanse of Matlab 'imroi' class and store it in  @em mibMeasure.roi.imroi
            %
            % Parameters:
            % mibController: a handle of mibController class
            % type: a type of ROI: ''imline'', ''imellipse''
            % pos: coordinates of the ROI
            % @li [x1, y1; x2, y2] -> '@b imline'
            % @li [x1, y1, Rwidth, Rheight] -> '@b imellipse'
            % instant: [@em optional], used only for imellipse to automatically get position of vertices. 1 or 0 (default).
            %
            % Return values:
            % position:  coordinates of the selected area
            
            %|
            % @b Examples:
            % @code position = obj.mibModel.I{obj.mibModel.I}.hMeasure.drawROI(obj, 'imline', [10, 10; 50, 50]); // call from mibController; draw a line @endcode
            
            if nargin < 5; instant = 0; end
            
            switch type
                case 'imline'
                    % recalculate coordinates from data to image axes
                    [pos2(:,1), pos2(:,2)] = mibController.mibModel.convertDataToMouseCoordinates(pos(:,1),  pos(:,2), 'shown');
                    
                    obj.roi.imroi = imline(mibController.mibView.handles.mibImageAxes, pos2); %pos = [X-vector Y-vector]
                    obj.roi.pos = pos;
                    obj.roi.type = type;
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition2(p));
                    position = wait(obj.roi.imroi);
                    if ~isempty(position)
                        [position(:,1), position(:,2)] = mibController.mibModel.convertMouseToDataCoordinates(position(:,1), position(:,2), 'shown');
                    end
                    %position = obj.roi.pos;
                case 'imellipse'
                    [pos2(1), pos2(2)] = mibController.mibModel.convertDataToMouseCoordinates(pos(1),  pos(2), 'shown');
                    pos2(3) = pos(3)/obj.hImg.magFactor;
                    pos2(4) = pos(4)/obj.hImg.magFactor;
                    obj.roi.imroi = imellipse(mibController.mibView.handles.mibImageAxes, pos2); %pos = [x y width height]
                    % fix the aspect ratio (so no ellipses are allowed)
                    setFixedAspectRatioMode(obj.roi.imroi,true);
                    obj.roi.pos = pos;
                    obj.roi.type = type;
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition1(p));
                    if instant
                        position = obj.roi.imroi.getVertices;
                    else
                        position = wait(obj.roi.imroi);
                    end
                    if ~isempty(position)
                        [position(:,1), position(:,2)] = mibController.mibModel.convertMouseToDataCoordinates(position(:,1), position(:,2), 'shown');
                    end
                    %position = obj.roi.pos;
                case 'impoly'
                    [pos2(:,1), pos2(:,2)] = mibController.mibModel.convertDataToMouseCoordinates( pos(:,1),  pos(:,2), 'shown');
                    obj.roi.imroi = impoly(mibController.mibView.handles.mibImageAxes, pos2, 'Closed', false); %pos = [X-vector Y-vector]
                    obj.roi.pos = pos;
                    obj.roi.type = type;
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition2(p));
                    position = wait(obj.roi.imroi);
                    if ~isempty(position)
                        [position(:,1), position(:,2)] = mibController.mibModel.convertMouseToDataCoordinates(position(:,1), position(:,2), 'shown');
                    end
                case 'impoint'
                    [pos2(:,1), pos2(:,2)] = mibController.mibModel.convertDataToMouseCoordinates(pos(:,1),  pos(:,2), 'shown');
                    obj.roi.imroi = impoint(mibController.mibView.handles.mibImageAxes, pos2);
                    obj.roi.pos = pos;
                    obj.roi.type = type;
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition2(p));
                    position = wait(obj.roi.imroi);
                    if ~isempty(position)
                        [position(1), position(2)] = mibController.mibModel.convertMouseToDataCoordinates(position(1), position(2), 'shown');
                    end
                case 'imfreehand'
                    obj.roi.imroi = imfreehand(mibController.mibView.handles.mibImageAxes, 'Closed', false);
                    obj.roi.pos = [];
                    obj.roi.type = type;
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition2(p));
                    position = obj.roi.imroi.getPosition();
                    %position = wait(obj.roi.imroi);
                    if ~isempty(position)
                        [position(:,1), position(:,2)] = mibController.mibModel.convertMouseToDataCoordinates(position(:,1), position(:,2), 'shown');
                    end
            end
            
            if isvalid(obj.roi.imroi)
                % detect color, if it is red -> set position to [] for to cancel
                color = obj.roi.imroi.getColor();
                delete(obj.roi.imroi);
                if sum(color == [1 0 0])==3;  position=[];   end
            end
            obj.roi.pos = [];
            obj.roi.type = [];
            obj.roi.imroi = [];
            obj.roi.cb = [];
        end
        
        function updateROIposition1(obj, new_position)
            % function updateROIposition1(obj, new_position, roi_index)
            % Update ROI position during movement of @em imrect and @em imellipse
            %
            % one of two functions resposible for update of @em mibMeasure.roi. @e pos.
            % The other one is @em mibMeasure.updateROIposition2()
            %
            % Parameters:
            % new_position: a vector with coordinates of a new position [xmin, ymin, width, height]
            pos2(1) = new_position(1)*obj.hImg.magFactor+max([0 floor(obj.hImg.axesX(1))]);
            pos2(2) = new_position(2)*obj.hImg.magFactor+max([0 floor(obj.hImg.axesY(1))]);
            pos2(3) = new_position(3)*obj.hImg.magFactor;
            pos2(4) = new_position(4)*obj.hImg.magFactor;
            obj.roi.pos=pos2;
        end
        
        function updateROIposition2(obj, new_position)
            % function updateROIposition2(obj, new_position)
            % Update position during movement of @em impoly, @em imline
            %
            % one of two functions resposible for update of @em mibMeasure.roi. @em pos. The other one is
            % @em mibMeasure.updateROIposition1()
            %
            % Parameters:
            % new_position: a vector with coordinates of a new position [point_number][x, y]
            
            pos2(:,1) = new_position(:,1)*obj.hImg.magFactor+max([0 floor(obj.hImg.axesX(1))]);
            pos2(:,2) = new_position(:,2)*obj.hImg.magFactor+max([0 floor(obj.hImg.axesY(1))]);
            obj.roi.pos = pos2;
            notify(obj, 'updatePosition');
        end
        
        function updateROIScreenPosition(obj, mode)
            % function updateROIScreenPosition(obj, mode)
            % Updates position of ROI when plotting in handles.imageAxes
            %
            % Parameters:
            % mode: identifier of the updating mode:
            % - ''@b crop'' during zooming
            % - ''@b full'' during panning of the axes
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.updateROIScreenPosition('crop'); // call from mibController; update positions of all ROIs during zoom in/out @endcode
            % @code obj.mibModel.I{obj.mibModel.I}.hMeasure.updateROIScreenPosition('full'); // call from mibController; update positions of all ROIs during panning @endcode
            pos = obj.roi.pos;
            if strcmp(obj.roi.type,'impoly') || strcmp(obj.roi.type,'imline') || strcmp(obj.roi.type,'impoint')
                if strcmp(mode, 'crop')
                    pos2(:,1) = (pos(:,1) -  max([0 floor(obj.hImg.axesX(1))]))/obj.hImg.magFactor;
                    pos2(:,2) = (pos(:,2) -  max([0 floor(obj.hImg.axesY(1))]))/obj.hImg.magFactor;
                    obj.roi.imroi.setPosition(pos2);
                else
                    pos2 = pos/max([1 obj.hImg.magFactor]);
                    obj.roi.imroi.removeNewPositionCallback(obj.roi.cb);
                    obj.roi.imroi.setPosition(pos2);
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition2(p));
                end
            elseif strcmp(obj.roi.type,'imellipse') || strcmp(obj.roi.type,'imrect')
                if strcmp(mode, 'crop')
                    pos2(1) = (pos(1) -  max([0 floor(obj.hImg.axesX(1))]))/obj.hImg.magFactor;
                    pos2(2) = (pos(2) -  max([0 floor(obj.hImg.axesY(1))]))/obj.hImg.magFactor;
                    pos2(3) = pos(3)/obj.hImg.magFactor;
                    pos2(4) = pos(4)/obj.hImg.magFactor;
                    obj.roi.imroi.setPosition(pos2);
                else
                    pos2 = pos/max([1 obj.hImg.magFactor]);
                    obj.roi.imroi.removeNewPositionCallback(obj.roi.cb);
                    obj.roi.imroi.setPosition(pos2);
                    obj.roi.cb = addNewPositionCallback(obj.roi.imroi, @(p) obj.updateROIposition1(p));
                end
            end
        end
        
        function number = getNumberOfMeasurements(obj)
            % number = getNumberOfMeasurements(obj)
            % Get number of stored measurements
            %
            % Parameters:
            %
            % Return values:
            % number:  number of stored measurements
            
            %|
            % @b Examples
            % @code number = obj.mibModel.I{obj.mibModel.I}.hMeasure.getNumberOfMeasurements(); // call from mibController; get the total number @endcode
            
            if isempty(obj.Data(1).n)
                number = 0;
            else
                number = numel(obj.Data);
            end
        end
        
        function circ = circlefit(obj, x,y)
            % function circ = circlefit(obj, x,y)
            % least squares circle fitting (see matlab help/demo (pendulum))
            %
            % Parameters:
            % x:
            % y:
            %
            % Return values:
            % circ:
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            
            n = length(x);
            M   = [x(:), y(:) ones(n,1)];
            abc = M \ -( x(:).^2 + y(:).^2);
            xc  = -abc(1)/2;
            yc  = -abc(2)/2;
            R   = sqrt((xc^2 + yc^2) - abc(3));
            
            circ.xc = xc;
            circ.yc = yc;
            circ.R  = R;
        end
        
        function [result, info] = AngleFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % function [result, info] = AngleFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % This function allows the measurement of an angle between 3 points
            %
            % Parameters:
            % mibController: handle of mibController
            % index: [@em Optional] an index of measurement to update; when
            % empty (@b [] ) - adds a new measurement
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate
            % intensity profile, 0 - do not calculate
            % infoDlgText:  [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown, 
            % overwise use text provided in this variable
            %
            % Return values:
            % result: - 1-success, 0-cancel
            % info: information text that was provided
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.AngleFun(obj, [], 1); // call from mibMeasureToolController; get points and measure the angle between them. Calculate intensity profile for color channel 1 @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.AngleFun(obj, 2, 1); // call from mibMeasureToolController; edit second measurement. @endcode
            
            global mibPath;
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            if nargin < 7; infoDlgText = NaN; end
            if nargin < 6; calcIntensity = 1; end
            if nargin < 5; finetuneCheck = 1; end
            if nargin < 4; colCh = 1; end
            if nargin < 3; index = []; end
            result = 0;
            
            if isempty(index)   % add new measurement
                % Select the intersection
                mibController.mibView.handles.mibImageAxes.NextPlot = 'add';
                [x, y, z, u, v] = mibController.mibView.getClickPoint();
                if isempty(x)
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                h = plot(mibController.mibView.handles.mibImageAxes,...
                    u, v, 'r+', u, v, 'bo', 'markersize', 10);
                % Select a point on the first line
                [x1, y1, z1, u1, v1] = mibController.mibView.getClickPoint();
                if isempty(x1)
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    delete(h);
                    return;
                end
                x(2) = x1; y(2) = y1;
                z(2) = z1;
                u(2) = u1; v(2) = v1;

                h(3:4) = plot(mibController.mibView.handles.mibImageAxes,...
                    u, v, 'r+', u, v, 'bo', 'markersize', 10);
                % Select a point on the second line
                [x1, y1] = mibController.mibView.getClickPoint();
                delete(h);
                mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                
                if isempty(x1)
                    return;
                end
                x(3) = x1; y(3) = y1;
                
                if finetuneCheck
                    position = obj.drawROI(mibController, 'impoly', [x(2), y(2); x(1), y(1); x(3), y(3)]);
                else
                    position = [x(2), y(2); x(1), y(1); x(3), y(3)];
                end
                % get Z-value
                z = obj.hImg.getCurrentSliceNumber();
                timePoint = obj.hImg.getCurrentTimePoint();
                if ischar(infoDlgText)
                    prompts = {'Add text for the info field'};
                    defAns = {infoDlgText};
                    dlgTitle = 'Angle info';
                    options.WindowStyle = 'modal';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer) 
                        info = ''; 
                    else
                        info = answer{1}; 
                    end
                else
                    info = ''; % info text
                end
                
            else                % edit existing measurement
                tempData = obj.Data(index);     % store the current state
                obj.removeMeasurements(index);  % remove measurement
                
                if finetuneCheck
                    x = tempData.X;
                    y = tempData.Y;
                    mibController.plotImage();
                    position = obj.drawROI(mibController, 'impoly', [x(1), y(1); x(2), y(2); x(3), y(3)]);
                else
                    position(:,1) = tempData.X;
                    position(:,2) = tempData.Y;
                end
                % update Z-value
                if obj.fixZ
                    z = tempData.Z;
                else
                    z = mibController.mibModel.I{mibController.mibModel.Id}.getCurrentSliceNumber();
                end
                tempData.Z = z;
                timePoint = tempData.T;
                info = tempData.info;
            end
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var')
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            
            orientation = obj.hImg.orientation;
            pixSize = obj.hImg.pixSize;
            if orientation == 1   % zx orientation
                aspectRatio = pixSize.z/pixSize.x;
            elseif orientation == 2   % zy orientation
                aspectRatio = pixSize.z/pixSize.y;
            else        % xy orientation
                aspectRatio = pixSize.x/pixSize.y;
            end
            
            v1 = [(position(1,1)-position(2,1))*aspectRatio, position(1,2)-position(2,2)];
            v2 = [(position(3,1)-position(2,1))*aspectRatio, position(3,2)-position(2,2)];
            
            phi = acos(dot(v1,v2)/(norm(v1)*norm(v2)));
            Angle = (phi * (180/pi)); % radtodeg(phi)
            
            X = position(:,1);
            Y = position(:,2);
            
            % create image space (for intensity)
            if calcIntensity
                if orientation == 1   % zx orientation
                    [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.width);
                elseif orientation == 2   % zy orientation
                    [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.height);
                else        % xy orientation
                    [x, y] = meshgrid(1:obj.hImg.width, 1:obj.hImg.height);
                end
                
                % calculate a length vector
                t = [ 0 ; hypot(diff(X),diff(Y)) ];
                t = cumsum(t);
                
                % discretize the measurement line
                Ni = max(t);
                ti = linspace(0,max(t),Ni);
                xi = interp1(t,X,ti);
                yi = interp1(t,Y,ti);
                
                getDataOptions.blockModeSwitch = 0;
                im = cell2mat(mibController.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
                
                % interpolate the intensity profile along the measurement line
                for ch=1:size(im, 3)
                    profile(ch,:) = interp2(x, y, double(im(:,:,ch)), xi, yi); %#ok<AGROW>
                end
                
                % calculate the average intensity
                intensity = mean(profile, 2);
            else
                intensity = NaN;
                ti = NaN;
                profile = NaN;
            end
            
            % store the measurement
            if isempty(index)
                n = obj.getNumberOfMeasurements + 1;
            else
                n = index;
            end
            newData.n = n;
            newData.type      = cellstr('Angle');
            newData.value     = Angle;
            newData.X         = X;
            newData.Y         = Y;
            newData.Z         = z(1,1);
            newData.T         = timePoint;
            newData.spline    = [];
            newData.circ      = [];
            newData.intensity = intensity;
            newData.info = info;
            newData.profile   = [ti ; profile];
            newData.integrateWidth = [];
            
            obj.addMeasurements(newData, n);
            mibController.plotImage();
            result = 1;
        end
        
        function [result, info] = CaliperFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % function [result, info] = CaliperFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % measuring a distance between two opposite sides of an object
            %
            % Parameters:
            % mibController: handle of mibController
            % index: [@em Optional] an index of measurement to update; when
            % empty (@b [] ) - adds a new measurement
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate
            % intensity profile, 0 - do not calculate
            % infoDlgText:  [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown,
            % overwise use text provided in this variable
            %
            % Return values:
            % result: 1-success, 0-cancel
            % info: information text that was provided
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.CaliperFun(obj, [], 1); // call from mibMeasureToolController; get points and measure the distance between them. Calculate intensity profile for color channel 1 @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.CaliperFun(obj, 2, 1); // call from mibMeasureToolController; edit second measurement. @endcode
            
            global mibPath;
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            if nargin < 7; infoDlgText = NaN; end
            if nargin < 6; calcIntensity = 1; end
            if nargin < 5; finetuneCheck = 1; end
            if nargin < 4; colCh = 1; end
            if nargin < 3; index = []; end
            result = 0;
            
            if isempty(index)   % add new measurement
                mibController.mibView.handles.mibImageAxes.NextPlot = 'add';
                
                % select two preliminary points
                [x, y, z, u, v] = mibController.mibView.getClickPoint();
                if isempty(x)
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                h = plot(mibController.mibView.handles.mibImageAxes,...
                    u, v, 'r+', u, v, 'bo', 'markersize', 10);
                [x1, y1] = mibController.mibView.getClickPoint();
                if isempty(x1)
                    delete(h);
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                x(2) = x1; 
                y(2) = y1;
                delete(h);
                pos(:,1) = x;
                pos(:,2) = y;
                if finetuneCheck
                    L = obj.drawROI(mibController, 'imline', pos);
                else
                    L(:,1) = x;
                    L(:,2) = y;
                end
                if isempty(L) % cancel
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                
                [U, V] = mibController.mibModel.convertDataToMouseCoordinates(L(:,1), L(:,2), 'shown');
                h = plot(mibController.mibView.handles.mibImageAxes, ...
                    U, V, '-+r', U, V, '--ob', 'markersize', 10);
                
                X = L(:,1);
                Y = L(:,2);
                mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                
                % Adjust the Point, double click the line when ready
                [x1, y1] = mibController.mibView.getClickPoint();
                if isempty(x1)
                    delete(h);
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                x(3) = x1; y(3) = y1;

                if finetuneCheck
                    P = obj.drawROI(mibController, 'impoint',[x(3), y(3)]);
                else
                    P = [x(3), y(3)];
                end
                delete(h);
                if isempty(P);  return; end % cancel
                
                clear position;
                position(1:3,1) = [X ; P(1)];
                position(1:3,2) = [Y ; P(2)];
                % get Z-value
                z = obj.hImg.getCurrentSliceNumber();
                timePoint = obj.hImg.getCurrentTimePoint();
                if ischar(infoDlgText)
                    prompts = {'Add text for the info field'};
                    defAns = {infoDlgText};
                    dlgTitle = 'Caliper info';
                    options.WindowStyle = 'modal';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer)
                        info = '';
                    else
                        info = answer{1};
                    end
                else
                    info = ''; % info text
                end
                
            else                % edit existing measurement
                tempData = obj.Data(index);     % store the current state
                obj.removeMeasurements(index);  % remove measurement
                clear pos;
                
                if finetuneCheck
                    pos(1:2,1) = tempData.X(1:2);
                    pos(1:2,2) = tempData.Y(1:2);
                    mibController.plotImage();
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'add';
                    L = obj.drawROI(mibController, 'imline', pos);
                    if ~isempty(L) % not cancel
                        [U, V] = mibController.mibModel.convertDataToMouseCoordinates(L(:,1), L(:,2), 'shown');
                        h = plot(mibController.mibView.handles.mibImageAxes,...
                            U, V, '-+r', U, V, '--ob', 'markersize', 10);
                        X = L(:,1);
                        Y = L(:,2);
                        P = obj.drawROI(mibController, 'impoint', [tempData.X(3), tempData.Y(3)]);
                        delete(h);
                        if isempty(P) % cancel
                            position = [];
                        else
                            position(:,1) = [X ; P(1)];
                            position(:,2) = [Y ; P(2)];
                        end
                    else    % cancel
                        position = [];
                    end
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                else
                    position(:,1) = tempData.X;
                    position(:,2) = tempData.Y;
                end
                % update Z-value
                if obj.fixZ
                    z = tempData.Z;
                else
                    z = mibController.mibModel.I{mibController.mibModel.Id}.getCurrentSliceNumber();
                end
                tempData.Z = z;
                timePoint = tempData.T;
                info = tempData.info;
            end
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var')
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            
            % calculate the perpendicular distance
            x1 = position(1,1);
            x2 = position(2,1);
            x3 = position(3,1);
            y1 = position(1,2);
            y2 = position(2,2);
            y3 = position(3,2);
            
            % calculate the distance (hypot = pythagoras)
            orientation = obj.hImg.orientation;
            pixSize = obj.hImg.pixSize;
            if orientation == 1   % zx orientation
                pixX = pixSize.z;
                pixY = pixSize.x;
                if calcIntensity
                    % create image space (for intensity)
                    [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.width);
                end
            elseif orientation == 2   % zy orientation
                pixX = pixSize.z;
                pixY = pixSize.y;
                if calcIntensity
                    % create image space (for intensity)
                    [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.height);
                end
            else        % xy orientation
                pixX = pixSize.x;
                pixY = pixSize.y;
                if calcIntensity
                    % create image space (for intensity)
                    [x, y] = meshgrid(1:obj.hImg.width, 1:obj.hImg.height);
                end
            end
            
            % The perpendicular distance (http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html)
            D = ( (x2-x1)*pixX * (y1-y3)*pixY - (x1-x3)*pixX*(y2-y1)*pixY ) / hypot((x2-x1)*pixX,(y2-y1)*pixY);
            Caliper = abs(D);
            D = ( (x2-x1) * (y1-y3) - (x1-x3)*(y2-y1) ) / hypot((x2-x1),(y2-y1));
            
            % now determine the location of the fourth point for plotting
            dx = (x1-x2);
            dy = y1-y2;
            dist = sqrt(dx*dx + dy*dy);
            dx = dx / dist;
            dy = dy / dist;
            x4 = x3 + D*dy;
            y4 = y3 - D*dx;
            
            % Storing the four points
            X = [x1 ; x2 ; x3 ; x4];
            Y = [y1 ; y2 ; y3 ; y4];
            
            if calcIntensity
                % calculate a length vector
                t = [ 0 ; hypot(diff(X(3:4)),diff(Y(3:4))) ];
                t = cumsum(t);
                
                % discretize the measurement line
                Ni = ceil(max(t));
                ti = linspace(0,max(t),Ni);
                xi = interp1(t,X(3:4),ti);
                yi = interp1(t,Y(3:4),ti);
                
                getDataOptions.blockModeSwitch = 0;
                im = cell2mat(mibController.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
                
                % interpolate the intensity profile along the measurement line
                for ch=1:size(im, 3)
                    profile(ch, :) = interp2(x, y, double(im(:,:,ch)), xi, yi);
                end
                
                % calculate the average intensity
                intensity = mean(profile, 2);
            else
                intensity = NaN;
                profile = NaN;
            end
            % store the measurement
            if isempty(index)
                n = obj.getNumberOfMeasurements + 1;
            else
                n = index;
            end
            newData.n = n;
            newData.type      = cellstr('Caliper');
            newData.value     = Caliper;
            newData.X         = X;
            newData.Y         = Y;
            newData.Z         = z(1,1);
            newData.T         = timePoint;
            newData.spline    = [];
            newData.circ      = [];
            newData.intensity = intensity;
            newData.info = info;
            ti = linspace(0, Caliper, size(profile, 2));
            newData.profile   = [ti ; profile];
            newData.integrateWidth = [];
            
            obj.addMeasurements(newData, n);
            mibController.plotImage();
            result = 1;
        end
        
        function [result, info] = CircleFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % function [result, info] = CircleFun(obj, mibController, index, colCh, finetuneCheck, infoDlgText)
            % This function allows the measurement of a radius
            %
            % Parameters:
            % mibController: handle of mibController
            % index: [@em Optional] an index of measurement to update; when
            % empty (@b [] ) - adds a new measurement
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate
            % intensity profile, 0 - do not calculate
            % infoDlgText:  [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown,
            %               overwise use text provided in this variable
            %
            % Return values:
            % result: 1-success, 0-cancel
            % info: information text that was provided
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.CircleFun(obj, [], 1); // call from mibMeasureToolController; get points and measure the radius. Calculate intensity profile for color channel 1 @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.CircleFun(obj, 2, 1); // call from mibMeasureToolController; edit second measurement. @endcode
            
            global mibPath;
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            if nargin < 7; infoDlgText = NaN; end
            if nargin < 6; calcIntensity = 1; end
            if nargin < 5; finetuneCheck = 1; end
            if nargin < 4; colCh = 1; end
            if nargin < 3; index = []; end
            result = 0;
            
            if isempty(index)   % add new measurement
                mibController.mibView.handles.mibImageAxes.NextPlot = 'add';
                [x, y, z, u, v] = mibController.mibView.getClickPoint();
                if isempty(x)
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                h = plot(mibController.mibView.handles.mibImageAxes,...
                    u, v, 'r+', u, v, 'bo', 'markersize', 10);
                % select edge of the circle
                [x1, y1] = mibController.mibView.getClickPoint();
                delete(h);
                mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                if isempty(x1)
                    return;
                end
                x(2) = x1; y(2) = y1;
                
                % calculate the box around the circle
                A = diff(x);
                B = diff(y);
                R = hypot(A,B);
                P = [x(1)-R y(1)-R 2*R 2*R];
                if finetuneCheck
                    position = obj.drawROI(mibController, 'imellipse', P);
                else
                    position = obj.drawROI(mibController, 'imellipse', P, 1);
                end
                
                % get Z-value
                z = obj.hImg.getCurrentSliceNumber();
                timePoint = obj.hImg.getCurrentTimePoint();
                if ischar(infoDlgText)
                    prompts = {'Add text for the info field'};
                    defAns = {infoDlgText};
                    dlgTitle = 'Circle info';
                    options.WindowStyle = 'modal';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer)
                        info = '';
                    else
                        info = answer{1};
                    end
                else
                    info = ''; % info text
                end
            else                % edit existing measurement
                tempData = obj.Data(index);     % store the current state
                obj.removeMeasurements(index);  % remove measurement
                
                u = tempData.circ.xc;
                v = tempData.circ.yc;
                u(2) = u + tempData.circ.R;
                v(2) = v;
                A = diff(u);
                B = diff(v);
                R = hypot(A,B);
                P = [u(1)-R v(1)-R 2*R 2*R];
                if finetuneCheck
                    mibController.plotImage();
                    position = obj.drawROI(mibController, 'imellipse', P);
                else
                    position = obj.drawROI(mibController, 'imellipse', P, 1);
                end
                % update Z-value
                if obj.fixZ
                    z = tempData.Z;
                else
                    z = mibController.mibModel.I{mibController.mibModel.Id}.getCurrentSliceNumber();
                end
                tempData.Z = z;
                timePoint = tempData.T;
                info = tempData.info;
            end
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var')
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            
            % use circlefit to obtain the radius
            circ = obj.circlefit(position(:,1), position(:,2));
            xc = circ.xc;
            yc = circ.yc;
            % recalculate radius in image units
            Radius = circ.R*obj.hImg.pixSize.x;
            
            % store points on the circle for later plotting
            phi = linspace(0,2*pi,60);
            X = circ.R*sin(phi) + circ.xc;
            Y = circ.R*cos(phi) + circ.yc;
            if calcIntensity
                % create image space (for intensity)
                [x, y] = meshgrid(1:obj.hImg.width, 1:obj.hImg.height);
                
                % find all pixels inside the circle
                incircle = inpolygon(x, y, X, Y);
                
                getDataOptions.blockModeSwitch = 0;
                im = cell2mat(mibController.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
                
                for ch=1:size(im, 3)
                    % profile
                    im_temp = im(:,:,ch);
                    profile(ch,:) = im_temp(incircle).'; %#ok<AGROW>
                    % calculate the average intensity
                    intensity(ch) = mean(im_temp(incircle)); %#ok<AGROW>
                end
                
                % distance from center
                ti = hypot(x(incircle)-xc,y(incircle)-yc).';
            else
                intensity = NaN;
                profile = NaN;
                ti = NaN;
            end
            % store the measurement
            if isempty(index)
                n = obj.getNumberOfMeasurements + 1;
            else
                n = index;
            end
            newData.n = n;
            newData.type      = cellstr('Circle (R)');
            newData.value     = Radius;
            newData.X         = X;
            newData.Y         = Y;
            newData.Z         = z(1,1);
            newData.T         = timePoint;
            newData.spline    = [];
            newData.circ      = circ;
            newData.intensity = intensity;
            newData.info = info;
            newData.profile   = [ti ; profile];
            newData.integrateWidth = [];
            
            obj.addMeasurements(newData, n);
            mibController.plotImage();
            result = 1;
        end
        
        function [result, info] = DistanceFreeFun(obj, mibController, colCh, finetuneCheck, calcIntensity, freehandOptions)
            % function [result, info] = DistanceFreeFun(obj, mibController, colCh, finetuneCheck, calcIntensity, freehandOptions)
            % measuring of distance along the free-hand path. The path is
            % converted to the impoly line
            %
            % Parameters:
            % mibController: handle of mibController
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate
            % intensity profile, 0 - do not calculate
            % freehandOptions: structure with additional parameters
            % .fixNumberPoints - logical, when checked do not ask for number of points
            % .noPointsEdit - string with selected number of points to use
            % .infoDlgText - [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown,
            %      overwise use text provided in this variable

            %
            % Return values:
            % result: 1-success, 0-cancel
            % info: information text that was provided
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFreeFun(obj, 1); // call from mibMeasureToolController; draw a path and measure the distance between points. Calculate intensity profile for color channel 1 @endcode
            
            global mibPath;
            if nargin < 6
                freehandOptions.fixNumberPoints = false;
                freehandOptions.noPointsEdit  = '5';
            end
            if nargin < 5; calcIntensity = 1; end
            if nargin < 4; finetuneCheck = 1; end
            if nargin < 3; colCh = 1; end
            result = 0;
            
            if ~isfield(freehandOptions, 'fixNumberPoints'); freehandOptions.fixNumberPoints = false; end
            if ~isfield(freehandOptions, 'noPointsEdit'); freehandOptions.noPointsEdit = '5'; end
            if ~isfield(freehandOptions, 'infoDlgText'); freehandOptions.infoDlgText = NaN; end
            
            info = ''; % default info text
            position = obj.drawROI(mibController, 'imfreehand');
            
            % get Z-value
            z = obj.hImg.getCurrentSliceNumber();
            timePoint = obj.hImg.getCurrentTimePoint();
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var')
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            
            dlgTitle = 'Convert to polyline';
            options.WindowStyle = 'modal';
            if ~freehandOptions.fixNumberPoints  % freehand mode
                if isfield(mibController.mibModel.sessionSettings.measureTool, 'noPointsEdit')
                    noPointsEdit = mibController.mibModel.sessionSettings.measureTool.noPointsEdit;
                else
                    noPointsEdit = '5';
                end
                
                if ischar(freehandOptions.infoDlgText)
                    prompts = {sprintf('There are %d vertices in the line. \n\nIf needed type a new number of vertices in range 1-%d to reduce this value', ...
                        size(position,1), size(position,1)); ...
                        'Add text for the info field'};
                    defAns = {noPointsEdit; freehandOptions.infoDlgText;};
                    options.PromptLines = [5, 1];
                    options.Focus = 2;
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end 
                    info = answer{2}; % update info text
                else
                    prompts = {sprintf('There are %d vertices in the line. \n\nIf needed type a new number of vertices in range 1-%d to reduce this value', ...
                        size(position,1), size(position,1))};
                    defAns = {noPointsEdit};
                    options.PromptLines = 5;
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end 
                    info = ''; % update info text
                end
                
                noPointsInt = str2double(answer{1});
                coef = round( size(position,1) / (noPointsInt-1) - 1);
                mibController.mibModel.sessionSettings.measureTool.noPointsEdit = answer{1};
            else
                if ischar(freehandOptions.Info)
                    prompts = {'Add text for the info field'};
                    defAns = {freehandOptions.Info;};
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end 
                    info = answer{1}; % update info text
                else
                    info = ''; % info text
                end
                
                noPointsInt = str2double(freehandOptions.noPointsEdit);
                coef = round( size(position,1) / (noPointsInt-1) - 1);
            end
            positionEnd = position(end,:);
            position = position(1:coef:end,:);
            position(end,:) = positionEnd;
            
            spl.x = position(:,1);
            spl.y = position(:,2);
            
            n = obj.getNumberOfMeasurements + 1;
            newData.n = n;
            newData.type = cellstr('Distance (polyline)');
            newData.value = [];
            newData.X = [];
            newData.Y = [];
            newData.Z = z(1,1);
            newData.T = timePoint;
            newData.spline = spl;
            newData.circ = [];
            newData.intensity = [];
            newData.info = info;
            newData.profile = [];
            newData.integrateWidth = [];
            
            obj.addMeasurements(newData, n);
            
            % call DistancePolyFun to do calculations
            obj.DistancePolyFun(mibController, n, colCh, size(position,1), finetuneCheck, calcIntensity);
            result = 1;
        end
        
        function [result, info] = DistancePolyFun(obj, mibController, index, colCh, noPoints, finetuneCheck, calcIntensity, options)
            % function [result, info] = DistancePolyFun(obj, mibController, index, colCh, noPoints, modeString, finetuneCheck, calcIntensity, options)
            % measuring of distance along the path
            %
            % Parameters:
            % mibController: handle of mibController
            % index: [@em Optional] an index of measurement to update; when
            % empty (@b [] ) - adds a new measurement
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % noPoints: [@em optional] define number of points in the path; @em default = 5
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate intensity profile, 0 - do not calculate
            % options: structure with additional options
            %   .widthProfile -  width of profile for measurements of intensity profiles, could be empty
            %   .outputFilename - full path to the output file
            %   .outputFormat - output format, 'tif', csv, mat, preview', when preview show it as a plot
            %   .calcKymograph - true/false, calculate kymograph
            %   .addScale - add scale to kymograph
            %  .infoDlgText - [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown,
            %      overwise use text provided in this variable
            %
            % Return values:
            % result: 1-success, 0-cancel
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistancePolyFun(obj, [], 1, 10); // call from mibMeasureToolController; get 10 points and measure the distance between them. Calculate intensity profile for color channel 1 @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistancePolyFun(obj, 2, 1); // call from mibMeasureToolController; edit second measurement. @endcode
            
            global mibPath;
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            if nargin < 8; options.calcKymograph = false; end
            if nargin < 7; calcIntensity = 1; end
            if nargin < 6; finetuneCheck = 1; end
            if nargin < 5; noPoints = 5; end
            if nargin < 4; colCh = 1; end
            if nargin < 3; index = []; end
            result = 0;
            
            if ~isfield(options, 'addScale'); options.addScale = false; end
            if ~isfield(options, 'infoDlgText'); options.infoDlgText = NaN; end
            
            % update number of points
            if noPoints < 2; noPoints = 2; end
            
            if isempty(index)   % add new measurement
                x = zeros(1, noPoints);
                y = zeros(1, noPoints);
                h = zeros(2, noPoints);
                u = zeros(1, noPoints);
                v = zeros(1, noPoints);
                mibController.mibView.handles.mibImageAxes.NextPlot = 'add';
                mibController.mibView.gui.WindowScrollWheelFcn = []; % disable scroll callback
                for k = 1:noPoints
                    [x1, y1, ~, u1, v1] = mibController.mibView.getClickPoint();
                    if isempty(x1)
                        delete(h);
                        mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                        mibController.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) mibController.mibGUI_ScrollWheelFcn(eventdata));   % restore scroll callback
                        return;
                    end
                    x(k) = x1;
                    y(k) = y1;
                    u(k) = u1;
                    v(k) = v1;
                    h(:,k) = plot(mibController.mibView.handles.mibImageAxes,...
                        u(k), v(k), 'r+', u(k), v(k), 'bo');
                end
                delete(h);
                mibController.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) mibController.mibGUI_ScrollWheelFcn(eventdata));   % restore scroll callback
                mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                if finetuneCheck
                    pos = [x ; y ].';
                    position = obj.drawROI(mibController, 'impoly', pos);
                else
                    position(:,1) = x;
                    position(:,2) = y;
                end
                % get Z-value
                z = obj.hImg.getCurrentSliceNumber();
                timePoint = obj.hImg.getCurrentTimePoint();
                if ischar(options.infoDlgText)
                    prompts = {'Add text for the info field'};
                    defAns = {options.infoDlgText};
                    dlgTitle = 'Distance Polyline info';
                    dlgOptions.WindowStyle = 'modal';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, dlgOptions);
                    if isempty(answer)
                        info = '';
                    else
                        info = answer{1};
                    end
                else
                    info = ''; % info text
                end
            elseif options.calcKymograph
                xVec = round(obj.Data(index).X);
                yVec = round(obj.Data(index).Y);
                timePoint = obj.Data(index).T;
                % generate indices of the points
                pntIndices = sub2ind([mibController.mibModel.I{mibController.mibModel.Id}.height, mibController.mibModel.I{mibController.mibModel.Id}.width], ...
                    yVec, xVec);
                
                resXvectorStep = obj.Data(index).value/(numel(pntIndices)-1);   % step between the points in the resulting image in units
                
                getDataOptions.blockModeSwitch = 0;
                getDataOptions.t = timePoint;
                if mibController.mibModel.I{mibController.mibModel.Id}.orientation == 4
                    for z=1:mibController.mibModel.I{mibController.mibModel.Id}.depth
                        im = cell2mat(mibController.mibModel.getData2D('image', z, NaN, colCh, getDataOptions));
                        
                        if z == 1
                            imgOut = zeros([mibController.mibModel.I{mibController.mibModel.Id}.depth, numel(pntIndices), size(im,3)], class(im));
                            noPix = size(im,1)*size(im,2); % number of pixels in a single slice
                        end
                        for ch=1:size(im, 3)
                            imgOut(z, :, ch) = im(pntIndices+(ch-1)*noPix);
                        end
                    end
                end
                
                imageDesciption = sprintf('Kymograph, X - polyline profile length, Y-depth/time projection. X step: %f %s, Y step: %f %s or %f %s', ...
                    resXvectorStep, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units, ...
                    mibController.mibModel.I{mibController.mibModel.Id}.pixSize.z, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units,...
                    mibController.mibModel.I{mibController.mibModel.Id}.pixSize.t, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.tunits);
                
                % add scale bar
                if strcmp(options.outputFormat, 'preview') || options.addScale
                    pixSize.x = resXvectorStep;
                    pixSize.y = resXvectorStep;
                    pixSize.units = mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units;
                    try
                        addTextOpt.textSuffix = sprintf(' dY=%.2f%s (%.1f%s)', ...
                            mibController.mibModel.I{mibController.mibModel.Id}.pixSize.z, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units,...
                            mibController.mibModel.I{mibController.mibModel.Id}.pixSize.t, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.tunits);
                        addTextOpt.markerText = 'text';
                        %imgOut2 = mibAddScaleBar(repmat(imgOut, [1,1,3]), pixSize, 1, addTextOpt);
                        imgOut = mibAddScaleBar(repmat(imgOut, [1, 1, 3]), pixSize, 1, addTextOpt);
                        imgOut = mibAddText2Img(imgOut, addTextOpt.textSuffix, [110, size(imgOut,1)-20], addTextOpt);
                    catch err
                        %imgOut;
                    end
                end
                
                switch options.outputFormat
                    case 'preview'
                        figure(124);
                        imshow(imgOut);
                    case 'tif'
                        if options.addScale
                            imwrite(imgOut, options.outputFilename, options.outputFormat);    
                            % save info
                            fileID = fopen([options.outputFilename(1:end-3) 'txt'], 'w');
                            fprintf(fileID, '%s', imageDesciption);
                            fclose(fileID);
                        else
                            % convert to mibImage and calibrate
                            I2 = mibImage(imgOut);
                            pixSize.x = resXvectorStep;
                            pixSize.y = mibController.mibModel.I{mibController.mibModel.Id}.pixSize.z;
                            I2.updatePixSizeResolution(pixSize);
                            I2.updateImgInfo(imageDesciption);

                            SavingOpt.FilenamePolicy = {'Use new provided name'};
                            SavingOpt.OutputDirectoryPolicy = {'Full path'};
                            SavingOpt.silent = 1;
                            SavingOpt.showWaitbar = false;
                            SavingOpt.Format = 'TIF format uncompressed (*.tif)';
                            I2.saveImageAsDialog(options.outputFilename, SavingOpt);
                            % save info
                            fileID = fopen([options.outputFilename(1:end-3) 'txt'], 'w');
                            fprintf(fileID, '%s', imageDesciption);
                            fclose(fileID);
                        end
                    case 'mat'
                        dataOut.x = 0:numel(pntIndices)-1;
                        dataOut.x = dataOut.x * resXvectorStep;
                        dataOut.y = imgOut;
                        dataOut.imageDesciption = imageDesciption;
                        save(options.outputFilename, 'dataOut');
                    case 'csv'
                        dataOut.x = 0:numel(pntIndices)-1;
                        dataOut.x = dataOut.x * resXvectorStep;
                        dataOut.y = imgOut;
                        T = table(dataOut.x', dataOut.y');
                        T.Properties.VariableNames{1} = sprintf('X vector, %s', mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units);
                        T.Properties.VariableNames{2} = 'Slice';
                        writetable(T, options.outputFilename)
                        
                end
                result = 1;
                return
            else% edit existing measurement
                tempData = obj.Data(index);     % store the current state
                obj.removeMeasurements(index);  % remove measurement
                
                if finetuneCheck
                    mibController.plotImage();
                    pos(:,1) = tempData.spline.x;
                    pos(:,2) = tempData.spline.y;
                    position = obj.drawROI(mibController, 'impoly', pos);
                else
                    position(:,1) = tempData.spline.x;
                    position(:,2) = tempData.spline.y;
                end
                % update Z-value
                if obj.fixZ
                    z = tempData.Z;
                else
                    z = mibController.mibModel.I{mibController.mibModel.Id}.getCurrentSliceNumber();
                end
                tempData.Z = z;
                timePoint = tempData.T;
                info = tempData.info;
            end
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var') && ~isempty(tempData.X)
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            
            % calculate the distance (hypot = pythagoras)
            orientation = obj.hImg.orientation;
            pixSize = obj.hImg.pixSize;
            if orientation == 1   % zx orientation
                pixX = pixSize.z;
                pixY = pixSize.x;
                % create image space (for intensity)
                [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.width);
            elseif orientation == 2   % zy orientation
                pixX = pixSize.z;
                pixY = pixSize.y;
                % create image space (for intensity)
                [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.height);
            else        % xy orientation
                pixX = pixSize.x;
                pixY = pixSize.y;
                % create image space (for intensity)
                [x, y] = meshgrid(1:obj.hImg.width, 1:obj.hImg.height);
            end
            
            X = position(:,1);
            Y = position(:,2);
            
            % save for later plotting
            spl.x = X;
            spl.y = Y;
            
            % calculate a length vector
            t = [ 0 ; hypot(diff(X),diff(Y)) ];
            tCum = cumsum(t);
            
            % testing for uniqueness
            I = unique(tCum);
            if length(I) ~= length(tCum)
                errordlg(sprintf('!!! Error !!!\n\nPoints must be distict'), 'Error', 'modal');
                return
            end
            % interpolation method
            method = obj.Options.splinemethod;
            % number of interpolation points
            %N = 50*length(X);
            N = ceil(max(tCum));
            % intepolate along the length vector
            ti = linspace(0, max(tCum), N) ;
            xi = interp1(tCum, X, ti, method);
            yi = interp1(tCum, Y, ti, method);
            
            % calculate the spline length
            L = sum( hypot( diff(xi)*pixX, diff(yi)*pixY ) );
            
            if calcIntensity
                getDataOptions.blockModeSwitch = 0;
                im = cell2mat(mibController.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
                
                for ch=1:size(im, 3)
                    % interpolate the intensity profile along the measurement line
                    profile(ch, :) = interp2(x, y, double(im(:,:,ch)), xi, yi);
                end
                
                % calculate the average intensity
                intensity = mean(profile, 2);
            else
                intensity = NaN;
                profile = NaN;
            end
            if isempty(index)
                n = obj.getNumberOfMeasurements + 1;
            else
                n = index;
            end
            newData.n = n;
            newData.type = cellstr('Distance (polyline)');
            newData.value = L;
            newData.X = xi;
            newData.Y = yi;
            newData.Z = z(1,1);
            newData.T = timePoint;
            newData.spline = spl;
            newData.circ = [];
            newData.intensity = intensity;
            newData.info = info;
            ti = linspace(0, L, size(profile, 2));
            newData.profile = [ti ; profile];
            newData.integrateWidth = [];
            
            obj.addMeasurements(newData, n);
            mibController.plotImage();
            result = 1;
        end
        
        function [result, info] = PointFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % function [result, info] = PointFun(obj, mibController, index, colCh, finetuneCheck, calcIntensity, infoDlgText)
            % add a point as a marker
            %
            % Parameters:
            % mibController: handle of mibController
            % index: [@em Optional] an index of measurement to update; when
            % empty (@b [] ) - adds a new measurement
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate
            % intensity profile, 0 - do not calculate
            % infoDlgText:  [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown,
            %      overwise use text provided in this variable
            %
            % Return values:
            % result: 1-success, 0-cancel
            % info: information text that was provided
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.PointFun(obj, [], 1); // call from mibMeasureToolController; place points and assign a label. @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.PointFun(obj, 2, 1); // call from mibMeasureToolController; edit second measurement. @endcode
            
            global mibPath;
            if nargin < 7; infoDlgText = NaN; end
            if nargin < 6; calcIntensity = 1; end
            if nargin < 5; finetuneCheck = 1; end
            if nargin < 4; colCh = 1; end
            if nargin < 3; index = []; end
            result = 0;
            
            if isempty(index)   % add new measurement
                [x, y] = mibController.mibView.getClickPoint();
                if finetuneCheck
                    position = obj.drawROI(mibController, 'impoint', [x, y]);
                else
                    position = [x, y];
                end
                if isempty(position);  return; end % cancel
                % get Z-value
                z = obj.hImg.getCurrentSliceNumber();
                timePoint = obj.hImg.getCurrentTimePoint();
            else                % edit existing measurement
                tempData = obj.Data(index);     % store the current state
                obj.removeMeasurements(index);  % remove measurement
                
                if finetuneCheck
                    mibController.plotImage();
                    pos(:,1) = tempData.X;
                    pos(:,2) = tempData.Y;
                    position = obj.drawROI(mibController, 'impoint', pos);
                else
                    position(:, 1) = tempData.X;
                    position(:, 2) = tempData.Y;
                end
                % update Z-value
                if obj.fixZ
                    z = tempData.Z;
                else
                    z = mibController.mibModel.I{mibController.mibModel.Id}.getCurrentSliceNumber();
                end
                tempData.Z = z;
                timePoint = tempData.T;
                info = tempData.info;
            end
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var')
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            if isempty(index)   % add new measurement
                n = obj.getNumberOfMeasurements + 1;
                dlgTitle = 'Point info';
                options.WindowStyle = 'modal';
                if ischar(infoDlgText)
                    prompts = {'Enter a label'; 'Add text for the info field'};
                    defAns = {sprintf('Feature %d', n); infoDlgText};
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer)
                        info = '';
                    else
                        info = answer{2};
                    end
                else
                    prompts = {'Enter a label'};
                    defAns = {sprintf('Feature %d', n)};
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    info = ''; % info text
                end
            else                % update existing
                n = index;
                if finetuneCheck
                    answer = mibInputDlg({mibPath}, 'Enter a label', 'Add point', tempData.value);
                else
                    answer{1} = tempData.value;
                end
            end
            if isempty(answer); answer = {''}; end
            
            if calcIntensity
                if colCh == 0
                    intensity = obj.hImg.img{1}(ceil(position(2)),ceil(position(1)), :, z, timePoint); %#ok<AGROW>
                    profile = squeeze(intensity);
                else
                    intensity(ch) = obj.hImg.img{1}(ceil(position(2)),ceil(position(1)), colCh, z, timePoint); %#ok<AGROW>
                    profile = squeeze(intensity);
                end
            else
                intensity = NaN;
                profile = NaN;
            end
            
            newData.n = n;
            newData.type = cellstr('Point');
            newData.value = answer{1};
            newData.X = position(1);
            newData.Y = position(2);
            newData.Z = z(1,1);
            newData.T = timePoint;
            newData.spline = [];
            newData.circ = [];
            newData.intensity = intensity;
            newData.info = info;
            newData.profile = [repmat(1, [1, size(profile,1)]); profile'];
            newData.integrateWidth = [];
            
            obj.addMeasurements(newData, n);
            mibController.plotImage();
            result = 1;
        end
        
        function [result, info] = DistanceFun(obj, mibController, index, colCh, finetuneCheck, integrateWidth, calcIntensity, options)
            % function [result, info] = DistanceFun(obj, mibController, index, colCh, finetuneCheck, integrateWidth, calcIntensity, options)
            % measuring distance between two points
            %
            % Parameters:
            % mibController: handle of mibController
            % index: [@em Optional] an index of measurement to update; when
            % empty (@b [] ) - adds a new measurement
            % colCh: [@em optional] color channel to use for profile; @em default = 1
            % finetuneCheck: [@em optional] @b 1 (@em default) - allow fine-tuning during the placing of measurements; @b 0 - instant placing
            % integrateWidth: [@em optional] a number of pixels for integration of image intensity profile
            % calcIntensity: [@em optional] @b 1 (@em default) - calculate intensity profile, 0 - do not calculate
            % options: structure with additional options
            %   .widthProfile -  width of profile for measurements of intensity profiles, could be empty
            %   .outputFilename - full path to the output file
            %   .outputFormat - output format, 'tif', csv, mat, preview', when preview show it as a plot
            %   .calcKymograph - true/false, calculate kymograph
            %   .addScale - add scale to kymograph
            %   .infoDlgText:  [string or NaN] show dialog to provide information about the measurement, when NaN no dialog is shown,
            %      overwise use text provided in this variable
            %
            % Return values:
            % result: 1-success, 0-cancel
            % info: information text that was provided
            
            %|
            % @b Examples
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFun(obj, [], 1); // call from mibMeasureToolController; get points and measure the distance between them. Calculate intensity profile for color channel 1 @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFun(obj, 2, 1); // call from mibMeasureToolController; edit second measurement. @endcode
            
            global mibPath;
            
            % Credit: adapted from Image Measurement Utility by Jan Neggers
            % http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility
            if nargin < 8
                options.calcKymograph = false;
            end
            if nargin < 7; calcIntensity = 1; end
            if nargin < 6; integrateWidth = []; end
            if nargin < 5; finetuneCheck = 1; end
            if nargin < 4; colCh = 1; end
            if nargin < 3; index = []; end
            result = 0;
            
            if ~isfield(options, 'addScale'); options.addScale = false; end
            if ~isfield(options, 'infoDlgText'); options.infoDlgText = NaN; end
            
            if isempty(index)   % add new measurement
                % select two preliminary points
                mibController.mibView.handles.mibImageAxes.NextPlot = 'add';
                [x, y, z, u, v] = mibController.mibView.getClickPoint();
                if isempty(x)
                    mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                    return;
                end
                h = plot(mibController.mibView.handles.mibImageAxes,...
                    u, v, 'r+', u, v, 'bo', 'markersize', 10);
                [x1, y1] = mibController.mibView.getClickPoint();
                delete(h);
                mibController.mibView.handles.mibImageAxes.NextPlot = 'replace';
                if isempty(x1)
                    return;
                end
                x(2) = x1; y(2) = y1;
                if finetuneCheck
                    pos(:,1) = x;
                    pos(:,2) = y;
                    position = obj.drawROI(mibController, 'imline', pos);
                else
                    position(:,1) = x;
                    position(:,2) = y;
                end
                % get Z-value
                z = obj.hImg.getCurrentSliceNumber();
                timePoint = obj.hImg.getCurrentTimePoint();
                if ischar(options.infoDlgText)
                    prompts = {'Add text for the info field'};
                    defAns = {options.infoDlgText};
                    dlgTitle = 'Distance Linear info';
                    options.WindowStyle = 'modal';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer)
                        info = '';
                    else
                        info = answer{1};
                    end
                else
                    info = ''; % info text
                end
            elseif options.calcKymograph
                xVec = round(obj.Data(index).X);
                yVec = round(obj.Data(index).Y);
                timePoint = obj.Data(index).T;
                pixSize = obj.hImg.pixSize;
                
                A = diff(xVec); %*pixSize.x;
                B = diff(yVec); %*pixSize.y;
                Distance = hypot(A, B); % in pixels;
                
                getDataOptions.blockModeSwitch = 0;
                getDataOptions.t = timePoint;
                if isempty(integrateWidth)
                    % discretize the measurement line
                    xi = linspace(xVec(1), xVec(2), round(Distance));
                    yi = linspace(yVec(1), yVec(2), round(Distance));
                    
                    pntIndices = round(sub2ind([mibController.mibModel.I{mibController.mibModel.Id}.height, mibController.mibModel.I{mibController.mibModel.Id}.width], ...
                        yi, xi));
                    resXvectorStep = obj.Data(index).value/(numel(pntIndices)-1);   % step between the points in the resulting image in units
                else
                    errordlg(sprintf('Error!\n\nKymographs can only be generated when the Integrate checkbox is disabled!'), 'Not implemented');
                    return;
                    im = cell2mat(mibController.mibModel.getData2D('image', 1, NaN, colCh, getDataOptions));
                    [~, ~, samplePntsX, samplePntsY] = mibImageProfileIntegrate(im, xVec(1), yVec(1), xVec(2), yVec(2), integrateWidth);
                end
                
                if mibController.mibModel.I{mibController.mibModel.Id}.orientation == 4
                    for z=1:mibController.mibModel.I{mibController.mibModel.Id}.depth
                        im = cell2mat(mibController.mibModel.getData2D('image', z, NaN, colCh, getDataOptions));
                        
                        if z == 1
                            imgOut = zeros([mibController.mibModel.I{mibController.mibModel.Id}.depth, numel(pntIndices), size(im,3)], class(im));
                            noPix = size(im,1)*size(im,2); % number of pixels in a single slice
                        end
                        for ch=1:size(im, 3)
                            imgOut(z, :, ch) = im(pntIndices+(ch-1)*noPix);
                        end
                    end
                end
                
                imageDesciption = sprintf('Kymograph, X - polyline profile length, Y-depth/time projection. X step: %f %s, Y step: %f %s or %f %s', ...
                    resXvectorStep, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units, ...
                    mibController.mibModel.I{mibController.mibModel.Id}.pixSize.z, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units,...
                    mibController.mibModel.I{mibController.mibModel.Id}.pixSize.t, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.tunits);
                
                % add scale bar
                if strcmp(options.outputFormat, 'preview') || options.addScale
                    pixSize.x = resXvectorStep;
                    pixSize.y = resXvectorStep;
                    pixSize.units = mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units;
                    try
                        addTextOpt.textSuffix = sprintf(' dY=%.2f%s (%.1f%s)', ...
                            mibController.mibModel.I{mibController.mibModel.Id}.pixSize.z, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units,...
                            mibController.mibModel.I{mibController.mibModel.Id}.pixSize.t, mibController.mibModel.I{mibController.mibModel.Id}.pixSize.tunits);
                        addTextOpt.markerText = 'text';
                        %imgOut2 = mibAddScaleBar(repmat(imgOut, [1,1,3]), pixSize, 1, addTextOpt);
                        imgOut = mibAddScaleBar(repmat(imgOut, [1, 1, 3]), pixSize, 1, addTextOpt);
                        imgOut = mibAddText2Img(imgOut, addTextOpt.textSuffix, [110, size(imgOut,1)-20], addTextOpt);
                    catch err
                        %imgOut;
                    end
                end
                
                switch options.outputFormat
                    case 'preview'
                        figure(124);
                        imshow(imgOut);
                    case 'tif'
                        if options.addScale
                            imwrite(imgOut, options.outputFilename, options.outputFormat);
                            % save info
                            fileID = fopen([options.outputFilename(1:end-3) 'txt'], 'w');
                            fprintf(fileID, '%s', imageDesciption);
                            fclose(fileID);
                        else
                            % convert to mibImage and calibrate
                            I2 = mibImage(imgOut);
                            pixSize.x = resXvectorStep;
                            pixSize.y = mibController.mibModel.I{mibController.mibModel.Id}.pixSize.z;
                            I2.updatePixSizeResolution(pixSize);
                            I2.updateImgInfo(imageDesciption);

                            SavingOpt.FilenamePolicy = {'Use new provided name'};
                            SavingOpt.OutputDirectoryPolicy = {'Full path'};
                            SavingOpt.silent = 1;
                            SavingOpt.showWaitbar = false;
                            SavingOpt.Format = 'TIF format uncompressed (*.tif)';
                            I2.saveImageAsDialog(options.outputFilename, SavingOpt);
                            
                            % save info
                            fileID = fopen([options.outputFilename(1:end-3) 'txt'], 'w');
                            fprintf(fileID, '%s', imageDesciption);
                            fclose(fileID); 
                        end
                    case 'mat'
                        dataOut.x = 0:numel(pntIndices)-1;
                        dataOut.x = dataOut.x * resXvectorStep;
                        dataOut.y = imgOut;
                        dataOut.imageDesciption = imageDesciption;
                        save(options.outputFilename, 'dataOut');
                    case 'csv'
                        dataOut.x = 0:numel(pntIndices)-1;
                        dataOut.x = dataOut.x * resXvectorStep;
                        dataOut.y = imgOut;
                        T = table(dataOut.x', dataOut.y');
                        T.Properties.VariableNames{1} = sprintf('X vector, %s', mibController.mibModel.I{mibController.mibModel.Id}.pixSize.units);
                        T.Properties.VariableNames{2} = 'Slice';
                        writetable(T, options.outputFilename)
                end
                result = 1;
                return
                
%                 getDataOptions.blockModeSwitch = 0;
%                 im = cell2mat(mibController.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
%                 % interpolate the intensity profile along the measurement line
%                 if isempty(integrateWidth)
%                     for ch=1:size(im, 3)
%                         profile(ch, :) = interp2(x, y, double(im(:,:,ch)), xi, yi); %#ok<AGROW>
%                     end
%                 else
%                     profile = mibImageProfileIntegrate(im, position(1,1), position(1,2), position(2,1), position(2,2), integrateWidth);
%                     %ti2 = linspace(0, Distance, size(profile,2));
%                     %Distance = profileLength*pixSize.x;
%                 end
            else                % edit existing measurement
                tempData = obj.Data(index);     % store the current state
                obj.removeMeasurements(index);  % remove measurement
                if finetuneCheck
                    mibController.plotImage();
                    pos(:,1) = tempData.X;
                    pos(:,2) = tempData.Y;
                    position = obj.drawROI(mibController, 'imline', pos);
                else
                    position(:,1) = tempData.X;
                    position(:,2) = tempData.Y;
                end
                % update Z-value
                if obj.fixZ
                    z = tempData.Z;
                else
                    z = mibController.mibModel.I{mibController.mibModel.Id}.getCurrentSliceNumber();
                end

                timePoint = tempData.T;
                info = tempData.info;
            end
            
            % detect Cancel due to press of the Escape button
            if isempty(position)
                if exist('tempData','var')
                    obj.addMeasurements(tempData, tempData.n);  % restore the old state
                    mibController.plotImage();
                end
                return;
            end
            
            % calculate the distance (hypot = pythagoras)
            orientation = obj.hImg.orientation;
            pixSize = obj.hImg.pixSize;
            if orientation == 1   % zx orientation
                A = diff(position(:,1))*pixSize.z;
                B = diff(position(:,2))*pixSize.x;
                if calcIntensity
                    if isempty(integrateWidth)
                        % create image space (for intensity)
                        [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.width);
                    end
                end
            elseif orientation == 2   % zy orientation
                A = diff(position(:,1))*pixSize.z;
                B = diff(position(:,2))*pixSize.y;
                if calcIntensity
                    if isempty(integrateWidth)
                        % create image space (for intensity)
                        [x, y] = meshgrid(1:obj.hImg.depth, 1:obj.hImg.height);
                    end
                end
            else        % xy orientation
                A = diff(position(:,1))*pixSize.x;
                B = diff(position(:,2))*pixSize.y;
                if calcIntensity
                    if isempty(integrateWidth)
                        % create image space (for intensity)
                        [x, y] = meshgrid(1:obj.hImg.width, 1:obj.hImg.height);
                    end
                end
            end
            Distance = hypot(A,B);
            
            % store position for later plotting
            X = position(:,1);
            Y = position(:,2);
            
            if calcIntensity
                if isempty(integrateWidth)
                    % calculate a length vector
                    t = [ 0 ; hypot(diff(X),diff(Y)) ];
                    t = cumsum(t);
                    
                    % discretize the measurement line
                    %Ni = 200;
                    Ni = max(t);
                    ti = linspace(0, max(t), Ni);
                    xi = interp1(t, X, ti);
                    yi = interp1(t, Y, ti);
                end
                
                getDataOptions.blockModeSwitch = 0;
                im = cell2mat(mibController.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
                % interpolate the intensity profile along the measurement line
                if isempty(integrateWidth)
                    for ch=1:size(im, 3)
                        profile(ch, :) = interp2(x, y, double(im(:,:,ch)), xi, yi); %#ok<AGROW>
                    end
                else
                    profile = mibImageProfileIntegrate(im, position(1,1), position(1,2), position(2,1), position(2,2), integrateWidth);
                    %ti2 = linspace(0, Distance, size(profile,2));
                    %Distance = profileLength*pixSize.x;
                end
            else
                profile = NaN;
            end
            
            %             % interpolate the intensity profile along the measurement line
            %             for ch=1:size(im, 3)
            %                 if isempty(integrateWidth)
            %                     profile(ch,:) = interp2(x, y, double(im(:,:,ch)), xi, yi); %#ok<AGROW>
            %                 else
            %                     [profile(ch,:), profileLength] = mibImageProfileIntegrate(im(:,:,ch), X(1), Y(1), X(2), Y(2), integrateWidth);
            %                     %ti2 = linspace(0, Distance, size(profile,2));
            %                     %Distance = profileLength*pixSize.x;
            %                 end
            %             end
            
            %profile = ones([size(ti), 1]);
            % calculate the average intensity
            intensity = mean(profile, 2);
            
            % store the measurement
            if isempty(index)
                n = obj.getNumberOfMeasurements + 1;
            else
                n = index;
            end
            newData.n = n;
            newData.type = cellstr('Distance (linear)');
            newData.value = Distance;
            newData.X = X;
            newData.Y = Y;
            newData.Z = z(1,1);
            newData.T = timePoint;
            newData.spline = [];
            newData.circ = [];
            newData.intensity = intensity;
            newData.info = info;
            if calcIntensity
                if isempty(integrateWidth)
                    ti = linspace(0, Distance, Ni);
                else
                    ti = linspace(0, Distance, size(profile, 2));
                end
            else
                ti = NaN;
            end
            newData.profile = [ti ; profile];
            newData.integrateWidth = integrateWidth;
            
            obj.addMeasurements(newData, n);
            
            mibController.plotImage();
            result = 1;
        end
    end
end
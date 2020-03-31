classdef (CaseInsensitiveProperties) mibDragNDropControl < handle
%   mibDragNDropControl Class for Drag & Drop functionality.
%   obj = mibDragNDropControl(javaobj) creates a mibDragNDropControl object for the specified
%   Java object, such as 'javax.swing.JTextArea' or 'javax.swing.JList'. Two
%   callback functions are available: obj.DropFileFcn and obj.DropStringFcn, 
%   that listen to drop actions of respectively system files or plain text.
%
%   The Drag & Drop control class relies on a Java class that need to be
%   visible on the Java classpath. To initialize, call the static method
%   mibDragNDropControl.mibDragNDropInitJava(). The Java class can be adjusted and recompiled if
%   desired.
%
%   mibDragNDropControl Properties:
%       Parent            - The associated Java object.
%       DropFileFcn       - Callback function for system files.
%       DropStringFcn     - Callback function for plain text.
%
%   mibDragNDropControl Methods:
%       mibDragNDropControl        - Constructs the mibDragNDropControl object.
%
%   mibDragNDropControl Static Methods:
%       defaultDropFcn    - Default callback function for drop events.
%       demo              - Runs the demonstration script.
%       mibDragNDropInitJava          - Initializes the Java class.
%       isInitialized     - Checks if the Java class is visible.
%
%   A demonstration is available from the static method mibDragNDropControl.demo().
%
%   Example:
%       mibDragNDropControl.mibDragNDropInitJava();
%       mibDragNDropControl.demo();
%
%   See also:
%       uicontrol, javaObjectEDT.    
%
%   Written by: Maarten van der Seijs, 2015.
%   Version: 1.0, 13 October 2015.
%
%   Modified for MIB by Ilya Belevich
        
    properties (Hidden)
        dropTarget;                
    end
    
    properties (Dependent)
        %PARENT The associated Java object.
        Parent;
    end
    
    properties
        %DROPFILEFCN Callback function executed upon dropping of system files.
        DropFileFcn;        
        %DROPSTRINGFCN Callback function executed upon dropping of plain text.
        DropStringFcn;
        % init status, logical
        initStatus
    end
       
    methods (Static)
        function mibDragNDropInitJava()
        %INITJAVA Initializes the required Java class.
            %Add java folder to javaclasspath if necessary
            if ~mibDragNDropControl.isInitialized()
                classpath = fileparts(mfilename('fullpath'));   
                javaaddpath(fullfile(classpath, 'MLDropTarget'), '-end');
            end 
        end
        
        function TF = isInitialized()            
        %ISINITIALIZED Returns true if the Java class is initialized.
            TF = (exist('MLDropTarget','class') == 8);
        end                           
    end
    
    methods
        function obj = mibDragNDropControl(Parent, DropFileFcn, DropStringFcn)
        %   mibDragNDropControl Drag & Drop control constructor.
        %   obj = mibDragNDropControl(javaobj) contstructs a mibDragNDropControl object for 
        %   the given parent control javaobj. The parent control should be a 
        %   subclass of java.awt.Component, such as most Java Swing widgets.
        %
        %   obj = mibDragNDropControl(javaobj,DropFileFcn,DropStringFcn) sets the
        %   callback functions for dropping of files and text.
            
            obj.initStatus = false;
            
            % Check for Java class
            if mibDragNDropControl.isInitialized() == 0
                %warning('Javaclass MLDropTarget not found. Call mibDragNDropControl.mibDragNDropInitJava() for initialization');
                return;
            end
             
            % Co nstruct DropTarget            
            obj.dropTarget = handle(javaObjectEDT('MLDropTarget'), 'CallbackProperties');
            set(obj.dropTarget,'DropCallback', {@mibDragNDropControl.DndCallback, obj});
            set(obj.dropTarget,'DragEnterCallback', {@mibDragNDropControl.DndCallback, obj});
            
            % Set DropTarget to Parent
            if nargin >=1, Parent.setDropTarget(obj.dropTarget); end
            
            % Set callback functions
            if nargin >=2, obj.DropFileFcn = DropFileFcn; end 
            if nargin >=3, obj.DropStringFcn = DropStringFcn; end
            
            obj.initStatus = true;  % initialized
        end
        
        function set.Parent(obj, Parent)
            if isempty(Parent)
                obj.dropTarget.setComponent([]);
                return
            end
            if isa(Parent,'handle') && ismethod(Parent,'java')
                Parent = Parent.java;
            end
            assert(isa(Parent,'java.awt.Component'),'Parent is not a subclass of java.awt.Component.')
            assert(ismethod(Parent,'setDropTarget'),'DropTarget cannot be set on this object.')
            
            obj.dropTarget.setComponent(Parent);
        end
        
        function Parent = get.Parent(obj)
            Parent = obj.dropTarget.getComponent();
        end
    end
    
    methods (Static, Hidden = true)
        %% Callback functions
        function DndCallback(jSource, jEvent, obj)
            
            if jEvent.isa('java.awt.dnd.DropTargetDropEvent')
                % Drop event     
                try
                    switch jSource.getDropType()
                        case 0
                            % No success.
                        case 1
                            % String dropped.
                            string = char(jSource.getTransferData());
                            if ~isempty(obj.DropStringFcn)
                                evt = struct();
                                evt.DropType = 'string';
                                evt.Data = string;                                
                                feval(obj.DropStringFcn,obj,evt);
                            end
                        case 2
                            % File dropped.
                            files = cell(jSource.getTransferData());                            
                            if ~isempty(obj.DropFileFcn)
                                evt = struct();
                                evt.DropType = 'file';
                                evt.Data = files;                                
                                feval(obj.DropFileFcn,obj,evt);
                            end
                    end
                    
                    % Set dropComplete
                    jEvent.dropComplete(true);  
                catch ME
                    % Set dropComplete
                    jEvent.dropComplete(true);  
                    rethrow(ME)
                end                              
                
            elseif jEvent.isa('java.awt.dnd.DropTargetDragEvent')
                 % Drag event                               
                 action = java.awt.dnd.DnDConstants.ACTION_COPY;
                 jEvent.acceptDrag(action);
            end            
        end
    end
    
    methods (Static)
        function defaultDropFcn(src,evt)
        %   DEFAULTDROPFCN Default drop callback.
        %   DEFAULTDROPFCN(src,evt) accepts the following arguments:
        %       src   - The mibDragNDropControl object.
        %       evt   - A structure with fields 'DropType' and 'Data'.
        
            fprintf('Drop event from %s component:\n',char(src.Parent.class()));
            switch evt.DropType
                case 'file'
                    fprintf('Dropped files:\n');
                    for n = 1:numel(evt.Data)
                        fprintf('%d %s\n',n,evt.Data{n});
                    end
                case 'string'
                    fprintf('Dropped text:\n%s\n',evt.Data);
            end
        end            
        
        function [dndobj,hFig] = demo()
        %DEMO Demonstration of the mibDragNDropControl class functionality.
        %   mibDragNDropControl.demo() runs the demonstration. Make sure that the
        %   Java class is visible in the Java classpath.
            
            % Initialize Java class
            mibDragNDropControl.mibDragNDropInitJava();
        
            % Create figure
            hFig = figure();
            
            % Create Java Swing JTextArea
            jTextArea = javaObjectEDT('javax.swing.JTextArea', ...
                sprintf('Drop some files or text content here.\n\n'));
            
            % Create Java Swing JScrollPane
            jScrollPane = javaObjectEDT('javax.swing.JScrollPane', jTextArea);
            jScrollPane.setVerticalScrollBarPolicy(jScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
                        
            % Add Scrollpane to figure
            [~,hContainer] = javacomponent(jScrollPane,[],hFig);
            set(hContainer,'Units','normalized','Position',[0 0 1 1]);
            
            % Create mibDragNDropControl for the JTextArea object
            dndobj = mibDragNDropControl(jTextArea);
            
            % Set Drop callback functions
            dndobj.DropFileFcn = @demoDropFcn;
            dndobj.DropStringFcn = @demoDropFcn;
            
            % Callback function
            function demoDropFcn(~,evt)
                switch evt.DropType
                    case 'file'
                        jTextArea.append(sprintf('Dropped files:\n'));
                        for n = 1:numel(evt.Data)
                            jTextArea.append(sprintf('%d %s\n',n,evt.Data{n}));
                        end
                    case 'string'
                        jTextArea.append(sprintf('Dropped text:\n%s\n',evt.Data));
                end
                jTextArea.append(sprintf('\n'));
            end
        end
    end    
end
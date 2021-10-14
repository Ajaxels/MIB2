classdef PoolWaitbar < handle
    % classdef PoolWaitbar < handle
    % waitbar for parallel loops
    % based on answer by Edric Ellis from 
    % https://se.mathworks.com/matlabcentral/answers/465911-parfor-waitbar-how-to-do-this-more-cleanly
    %
    % Examples of use
    % pwb = PoolWaitbar(100, 'Example');
    % parfor ii = 1:20  % parfor (ii=1:20, obj.mibModel.cpuParallelLimit)
    %     pwb.increment();
    % end
    % spmd
    %     for ii = 21:40
    %         if labindex == 1
    %             pwb.increment();
    %         end
    %     end
    % end
    % for ii = 41:100
    %     parfeval(@() increment(pwb), 0);
    % end
    %
    % % reuse exiting waitbar
    % wb = waitbar(0.5, 'my waitbar');  % create a standard waitbar
    % n = 200;
    % A = 500;
    % a = zeros(n);
    % pwb = PoolWaitbar(n, sprintf('Please wait...'), wb);   % create PoolWaitbar using existing waitbar window
    % parfor i = 1:n    % parfor (i=1:n, obj.mibModel.cpuParallelLimit)
    %     a(i) = max(abs(eig(rand(A))));
    %     pwb.increment();
    % end
    % keepWaitbar = 1;
    % pwb.deletePoolWaitbar(keepWaitbar);  % delete pw, while keeping wb
    %
    % % Add with a title for the figure
    % pwb = PoolWaitbar(n, sprintf('Please wait...'), wb, 'My waitbar');
    % pwb.setIncrement(10);  % set increment step to 10, whenever needed
    % pwb.updateText('New text');   % update text
    % % pwb.updateMaxNumberOfIterations(100);   % increase number of iterations to 100
    % parfor i = 1:n    % parfor (i=1:n, obj.mibModel.cpuParallelLimit)
    %       pwb.increment();  
    % end
    
    % Copyright (C) 15.01.2020, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
    % Updates
    %

    properties (SetAccess = immutable, GetAccess = private)
        Queue
    end
    
    properties (Access = private, Transient)
        N   % number of iterations
        ClientHandle = []
        Count = 0   % current iteration
        Increment = 1
    end
    
    properties (SetAccess = immutable, GetAccess = private, Transient)
        Listener = []
    end
    
    methods (Access = private)
        function localIncrement(obj)
            obj.Count = obj.Increment + obj.Count;
            waitbar(obj.Count / obj.N, obj.ClientHandle);
        end
    end
    
    methods
        function obj = PoolWaitbar(N, message, existingHandle, WindowName)
            % Constructor
            % Parameters:
            % N: number of iterations of the waitbar
            % message: message to display
            % existingHandle: a handle to existing standard waitbar figure
            % WindowName: title of the figure window
            
            if nargin < 4; WindowName = []; end
            if nargin < 3; existingHandle = []; end
            if nargin < 2; message = []; end
            
            obj.N = N;
            if isempty(existingHandle) && isempty(message)
                obj.ClientHandle = waitbar(0, message);
            elseif isempty(existingHandle)
                obj.ClientHandle = waitbar(0, message);
            elseif isempty(message)
                obj.ClientHandle = existingHandle;
                waitbar(0, obj.ClientHandle);
            else
                obj.ClientHandle = existingHandle;
                waitbar(0, obj.ClientHandle, message);
            end
            
            if ~isempty(WindowName)
                obj.ClientHandle.Name = WindowName;
            end
            obj.Queue = parallel.pool.DataQueue;
            obj.Listener = afterEach(obj.Queue, @(~) localIncrement(obj));
            
            obj.ClientHandle.Children.Title.Interpreter = 'none';
        end
        
        function updateMaxNumberOfIterations(obj, N)
            % function updateMaxNumberOfIterations(obj, N)
            % update the max value of the waitbar slider
            obj.N = N;
        end
        
        function increaseMaxNumberOfIterations(obj, N)
            % function increaseMaxNumberOfIterations(obj, N)
            % increase maximal number of iterations by N
            obj.N = obj.N + N;
        end
        
        function result = getMaxNumberOfIterations(obj)
            % function result = getMaxNumberOfIterations(obj)
            % get number of iterations
            result = obj.N;
        end
        
        function updateText(obj, newText)
            % function updateText(obj, newText)
            % update text of the waitbar
            childrenList = obj.ClientHandle.Children();
            childrenList(1).Title.String = newText;
        end
        
        function setCurrentIteration(obj, count)
            % function setCurrentIteration(obj, N)
            % set the current iteration of the poolwait bar to value N
            obj.Count = count;
        end
            
        
        function setIncrement(obj, increment)
            % function setIncrement(obj, increment)
            % set a new increment value
            obj.Increment = increment;
        end
        
        function increment(obj)
            send(obj.Queue, true);
        end
        
        function delete(obj)
            delete(obj.ClientHandle);
            delete(obj.Queue);
        end
        
        function deletePoolWaitbar(obj, keepWaitbar)
            % function deletePoolWaitbar(obj, keepWaitbar)
            % alternative way to delete PoolWaitbar
            %
            % Parameters:
            % keepWaitbar: logical switch, when 1 - keeps instance of the
            % waitbar obj.ClientHandle, otherwise deletes it
            
            if nargin < 2; keepWaitbar = 0; end
            
            if keepWaitbar==0
                delete(obj);
            else % remove only obj.Queue
                delete(obj.Queue);
            end
        end
        
        function wb = getWaitbarHandle(obj)
            % function wb = getWaitbarHandle(obj)
            % return handle of the waitbar window, to be used before
            % deleting PoolWaitbar to keep the waitbar window open
            
            wb = obj.ClientHandle;
        end
    end
end
classdef Lines3D < matlab.mixin.Copyable
    % @type Lines3D class is resposnible for keeping 3d lines and skeletons
    
    % Copyright (C) 16.04.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    %
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
    % REQUIREMENTS: Matlab 8.6, R2015b!
    %
    % Updates
    % @code
    % // example how to make a simple graph object, where each node is
    % // encoded in pixels (the graph object requires points to be in the physical units)
    %
    % points = [303 81 72;...
    %           294 90 67;...
    %           294 172 56;...
    %           290 207 20;...
    %           252 268 1;...
    %           294 172 40;...
    %           387 198 42;...
    %           400 252 25;
    %           314 270 19];    // coordinates of nodes in pixels, [x, y, z]
    %
    % s = [1 2 3 4 4 6 7];      // input node indices
    % t = [2 3 4 5 6 7 8];      // output node indices
    %
    % NodeName = repmat({'Node'}, [size(points,1), 1]);    // optional names of nodes
    % TreeName = repmat({'TreeName'}, [size(points,1), 1]);    // optional names for the trees (tree identity of each point is defined by this tag)
    % Radius = ones([size(points,1), 1]);    // add node radius to nodes
    % NumberExtra = ones([size(points,1), 1])+1;   // optional, add Extra parameter to nodes
    % StringExtra = repmat({'Comment'}, [size(points,1), 1]);    // optional, add Extra parameter to nodes
    %
    % Weight = ones([numel(s), 1]);    //optional, add weight to edges
    %
    % NodeTable = table(points, NodeName, Radius, TreeName, NumberExtra, StringExtra, 'VariableNames',{'PointsXYZ','NodeName','Radius',TreeName, 'NumberExtra','StringExtra'});
    % EdgeTable = table([s', t'], Weight, 'VariableNames', {'EndNodes', 'Weight'});
    %
    % G = graph(EdgeTable, NodeTable);  // generate the graph
    % G.Nodes.Properties.VariableUnits = {'pixel','string','um','um','string'}; // it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels
    %
    % Graph.Nodes.Properties.UserData.pixSize = struct();   // required when points are pixels, add pixSize structure
    % Graph.Nodes.Properties.UserData.pixSize.x = .013;
    % Graph.Nodes.Properties.UserData.pixSize.y = .013;
    % Graph.Nodes.Properties.UserData.pixSize.z = .03;
    % Graph.Nodes.Properties.UserData.pixSize.units = 'um';
    % Graph.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); // required when points are pixels; add bounding box information
    % @endcode
    %
    % @code
    % // minimalistic example with two trees and points in pixels
    % points = [303 81 72;...
    %           294 90 67;...
    %           294 172 56;...
    %           290 207 20;...
    %           252 268 1;...
    %           294 172 40;...
    %           387 198 42;...
    %           400 252 25;
    %           314 270 19];    // coordinates of nodes in pixels, [x, y, z]
    %
    % s = [1 2 3 5 6 7];      // input node indices
    % t = [2 3 4 6 7 8];      // output node indices
    % TreeName = repmat({'TreeName1'}, [4, 1]);    // nodes 1:4 belong to TreeName1, optional names for the trees (tree identity of each point is defined by this tag)
    % TreeName(5:8) = repmat({'TreeName2'}, [4, 1]);    // nodes 5:8 belong to TreeName2, optional names for the trees (tree identity of each point is defined by this tag)
    % NodeTable = table(points, TreeName, 'VariableNames',{'PointsXYZ','TreeName'}); // make nodes table
    % EdgeTable = table([s', t'], 'VariableNames', {'EndNodes'}); // make edges table
    % G = graph(EdgeTable, NodeTable);  // generate the graph
    % G.Nodes.Properties.VariableUnits = {'pixel','string'}; // it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels
    % G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); // a vector with the bounding box information [xmin, width, ymin, height, zmin, depth]
    % G.Nodes.Properties.UserData.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;  % add pixel size
    % obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(G);  //  replace the current Lines3D with a new graph
    %
                
    properties
        G
        % a graph with lines
        % .Edges - a table containing information about edges of the graph
        %   .EndNodes - connectivity table [edgeId][Node1 Node2], each row defines an edge
        %               with indices of nodes that form the edge
        %   .Edges - matrix with coordinates of the edges, [edgeId][x1 y1 z1 x2 y2 z2], IN PHYSICAL UNITS
        %   .Weight - weights of edges
        %   .Length - length of nodes, IN PHYSICAL UNITS
        % .Nodes - a table containing information about nodes of the graph
        %   .PointsXYZ - coordinates of nodes [NodeId][x, y, z] IN PHYSICAL UNITS
        %       to recalculate from pixels to the imaging units use mibImage.convertPixelsToUnits:
        %   .TreeName - a cell array where each nodes has name of
        %               tree to which the node belong, [NodeId]{'TreeName'}
        %   .NodeName - a cell array with names for the nodes, [NodeId]{'NodeName'}
        %   .Radius - a vector with radii of nodes
        %   .Properties.VariableUnits - a cell array with units for each
        %               variable, when coordinate are 'pixels', MIB suggest recompute
        %               them to image units
        %   .Properties.UserData.pixSize - a structure with pixSize of the underlying dataset
        %               .x - x resoulution, um/px
        %               .y - x resoulution, um/px
        %               .z - x resoulution, um/px
        %   .Properties.UserData.BoundingBox - a vector with the bounding box information [xmin, width, ymin, height, zmin, depth]
        %
        activeNodeId = [];
        % index of the active node
        clipExtraThickness = 1;
        % a number, extend clipping of the edges with additional thickness
        % +/- this number sections
        defaultNodeName = 'Node'
        % default name for nodes
        defaultTreeName = 'Tree'
        % default name for trees
        edgeActiveColor = [0.984, 0.549, 0.000];
        % color of edges for the active tree [R, G, B], from 0 to 1
        edgeColor = [1.000, 0.800, 0.502];
        % color of edges [R, G, B], from 0 to 1
        edgeThickness = 2;
        % thickness of edges
        extraEdgeFields = [];
        % a cell array with names of additional fields in the Edges table of the graph object
        extraEdgeFieldsNumeric = [];
        % a vector with indicator whether the field in extraEdgeFields is numeric (1) or not (0)
        extraNodeFields = [];
        % a cell array with names of additional fields in the Nodes table of the graph object
        extraNodeFieldsNumeric = [];
        % a vector with indicator whether the field in extraNodeFields is numeric (1) or not (0)
        filename = [];
        % filename of the Lines3D file
        matlabVersion
        % version of matlab, required for definition of the strel element
        nodeActiveColor = [1.0000    0.0000         0];
        % color of the active node [R, G, B], from 0 to 1
        nodeColor = [1.0000    1.0000         0];
        % color of nodes [R, G, B], from 0 to 1
        nodeRadius = 5;
        % radius of nodes
        nodeStrel;
        % strel element for making nodes
        noTrees = 0;
        % number of trees of the graph
    end
    
    methods
        function obj = Lines3D(Gin, activeNodeId, options)
            % function obj = Lines3D()
            % Constructor for the @type Lines3D class.
            %
            % Constructor for the Lines3D class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % Gin: [@em optional] graph with 3d lines
            %    .Edges - a table containing information about edges of the graph
            %       .EndNodes - connectivity table [edgeId][Node1 Node2], each row defines an edge
            %                   with indices of nodes that form the edge
            %       .Edges - matrix with coordinates of the edges, [edgeId][x1 y1 z1 x2 y2 z2]
            %    .Nodes - a table containing information about nodes of the graph
            %       .PointsXYZ - coordinates of nodes [NodeId][x, y, z]
            %       to recalculate from pixels to the imaging units use mibImage.convertPixelsToUnits
            %       .Properties.UserData.pixSize - pixSize structure
            %       .Properties.UserData.BoundingBox - bounding box [xmin, width, ymin, height, zmin, depth]
            %       .Properties.VariableUnits - a cell array with units for each
            %               variable, when coordinate are 'pixels', MIB suggest recompute
            %               them to image units
            % activeNodeId: [@em optional] index of the active node, can be @em empty
            % options: [@em optional] a structure with additional settings
            %  .edgeColor - color of edges [R, G, B], from 0 to 1
            %  .edgeThickness - thickness of edges
            %  .nodeColor - color of nodes [R, G, B], from 0 to 1
            %  .nodeActiveColor - color of the active node [R, G, B], from 0 to 1
            %  .nodeRadius - radius of nodes
            %
            % Return values:
            % obj - instance of the @type Labels class.
            
            if nargin < 3; options = struct(); end
            if ~isfield(options, 'edgeColor'); options.edgeColor = obj.edgeColor; end
            if ~isfield(options, 'edgeThickness'); options.edgeThickness = obj.edgeThickness; end
            if ~isfield(options, 'nodeColor'); options.nodeColor = obj.nodeColor; end
            if ~isfield(options, 'nodeActiveColor'); options.nodeActiveColor = obj.nodeActiveColor; end
            if ~isfield(options, 'nodeRadius'); options.nodeRadius = obj.nodeRadius; end
            
            if nargin < 2; activeNodeId = []; end
            if nargin < 1; Gin = []; end
            
            v = ver('Matlab');
            obj.matlabVersion = str2double(v.Version);
            
            obj.setOptions(options);
            
            obj.clearContents();
            if ~isempty(Gin)
                obj.replaceGraph(Gin);
            end
            if ~isempty(activeNodeId); obj.activeNodeId = activeNodeId; end
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
            % @code obj.mibModel.I{obj.mibModel.Id}.Lines3D.clearContents(); @endcode
            
            obj.G = [];   %  a cell array with labels
            obj.noTrees = 0;    % number of trees
            obj.activeNodeId = [];    % active node
            obj.extraEdgeFields = [];
            obj.extraEdgeFieldsNumeric = [];
            obj.extraNodeFields = [];
            obj.extraNodeFieldsNumeric = [];
            obj.defaultNodeName = 'Node';
            obj.defaultTreeName = 'Tree';
            obj.filename = [];
            
            obj.updateNodeStrel(obj.nodeRadius);     % update strel element
            
            if obj.matlabVersion >= 8.6
                %obj.makeDummyGraph();   % generate test graph
            end
            
            %             figure(1);
            %             h = plot(obj.G);
            %             h.XData = obj.G.Nodes.PointsXYZ(:,1);
            %             h.YData = obj.G.Nodes.PointsXYZ(:,2);
            %             h.ZData = obj.G.Nodes.PointsXYZ(:,3);
            
        end
        
        function replaceGraph(obj, Graph)
            % function replaceGraph(obj, Graph)
            % replace the current graph object with a new graph
            %
            % Parameters:
            % Graph: graph object with a new graph, required fields (may have more)
            %   .Nodes - a table containing information about nodes of the graph
            %       .PointsXYZ - matrix with coordinates of nodes [nodeId](x, y, z) (in physical units)
            %           to recalculate from pixels to the imaging units use mibImage.convertPixelsToUnits
            %       .TreeName - [@em optional] a cell array where each entry contains name of the node's parant tree
            %       .NodeName - [@em optional] a cell array where each entry has name of the corresponding node
            %       .Radius - [@em optional] a vector with radius parameter for each node
            %   	.[name_of_field] - [@em optional] optional fields as either array of vectors or cells
            %       .Properties.UserData.pixSize - a structure with pixSize of the underlying dataset
            %               .x - x resoulution, um/px
            %               .y - x resoulution, um/px
            %               .z - x resoulution, um/px
            %       .Properties.UserData.BoundingBox - a vector with the bounding box information [xmin, width, ymin, height, zmin, depth]
            %       .Properties.VariableUnits - a cell array with units for each
            %               variable, when coordinate are 'pixels', MIB suggest recompute
            %               them to image units
            %
            %   .Edges - a table containing information about edges of the graph
            %       .EndNodes - connectivity table [edgeId][Node1 Node2], each row defines an edge
            %                   with indices of nodes that form the edge
            %       .Edges - [@em optional] a matrix with coordinates of the edges, [edgeId][x1 y1 z1 x2 y2 z2], (in physical units)
            %       .Weight - [@em optional] a vector of weights for each edge
            %       .Length - [@em optional] a vector of length for each edge (in physical units)
            
            if nargin < 2; obj.clearContents(); return; end
            
            % get provided fields
            edgeFields = Graph.Edges.Properties.VariableNames;
            nodeFields = Graph.Nodes.Properties.VariableNames;
            
            % update number of trees
            nodeByTree = conncomp(Graph);
            obj.noTrees = max(nodeByTree);
            % define the active node
            obj.activeNodeId = size(Graph.Nodes.PointsXYZ, 1);
            
            % % --------- process Nodes -----------
            % add TreeName
            if ~ismember('TreeName', nodeFields)
                Graph.Nodes.TreeName = cell([size(Graph.Nodes.PointsXYZ, 1), 1]);    % add tree names to nodes
                for treeId = 1:obj.noTrees
                    %Graph.Nodes.TreeName(nodeByTree==1) = repmat({'Tree 001'}, [size(Graph.Nodes.PointsXYZ,1), 1]);    % add tree names to nodes
                    ids = find(nodeByTree == treeId);
                    Graph.Nodes.TreeName(ids) = repmat({sprintf('Tree %.5d', treeId)}, [numel(ids), 1]);    % add tree names to nodes
                end
            end
            % Add node names
            if ~ismember('NodeName', nodeFields)
                Graph.Nodes.NodeName = repmat({'Node'}, [size(Graph.Nodes.PointsXYZ, 1), 1]);    % add tree names to nodes
            end
            % Add Radius
            if ~ismember('Radius', nodeFields)
                Graph.Nodes.Radius = ones([size(Graph.Nodes.PointsXYZ,1), 1]);    % add tree names to nodes
            end
            % adding additional fields
            obj.extraNodeFields = nodeFields(~ismember(nodeFields, {'PointsXYZ', 'TreeName', 'NodeName','Radius'}))';
            obj.extraNodeFieldsNumeric = zeros([numel(obj.extraNodeFields), 1]);
            if ~isempty(obj.extraNodeFields)    % update extraNodeFieldsNumeric variable
                for fieldId = 1:numel(obj.extraNodeFields)
                    obj.extraNodeFieldsNumeric(fieldId) = isnumeric(Graph.Nodes.(obj.extraNodeFields{fieldId})(1));
                end
            end
            % add pixSize structure
            if ~isfield(Graph.Nodes.Properties.UserData, 'pixSize')
                Graph.Nodes.Properties.UserData.pixSize = struct();
                Graph.Nodes.Properties.UserData.pixSize.x = 1;
                Graph.Nodes.Properties.UserData.pixSize.y = 1;
                Graph.Nodes.Properties.UserData.pixSize.z = 1;
                Graph.Nodes.Properties.UserData.pixSize.units = 'um';
                Graph.Nodes.Properties.UserData.pixSize.tunits = 's';
            end
            
            % add variable units if they are missing
            if isempty(Graph.Nodes.Properties.VariableUnits)
                Graph.Nodes.Properties.VariableUnits = repmat(cellstr(''), [numel(Graph.Nodes.Properties.VariableNames), 1]);
            end
            for varNameId = 1:numel(Graph.Nodes.Properties.VariableNames)
                if isempty(Graph.Nodes.Properties.VariableUnits{varNameId})
                    switch Graph.Nodes.Properties.VariableNames{varNameId}
                        case {'PointsXYZ', 'Radius'}
                            Graph.Nodes.Properties.VariableUnits{varNameId} = Graph.Nodes.Properties.UserData.pixSize.units;
                        case {'TreeName', 'NodeName'}
                            Graph.Nodes.Properties.VariableUnits{varNameId} = 'string';
                        otherwise
                            Graph.Nodes.Properties.VariableUnits{varNameId} = '';
                    end
                end
            end
            
            % recalculate pixels to image units
            pointsXYZindex = find(ismember(Graph.Nodes.Properties.VariableNames, 'PointsXYZ'));
            if strcmp(Graph.Nodes.Properties.VariableUnits{pointsXYZindex}, 'pixel')
                orientation = 4;    % assuming xy orientation
                [Graph.Nodes.PointsXYZ(:,1), Graph.Nodes.PointsXYZ(:,2), Graph.Nodes.PointsXYZ(:,3)] = ...
                    convertPixelsToUnits(Graph.Nodes.PointsXYZ(:,1), Graph.Nodes.PointsXYZ(:,2), Graph.Nodes.PointsXYZ(:,3),...
                    Graph.Nodes.Properties.UserData.BoundingBox, Graph.Nodes.Properties.UserData.pixSize, orientation);
                
                Graph.Nodes.Properties.VariableUnits{1} =  Graph.Nodes.Properties.UserData.pixSize.units;
                if ismember('Edges', Graph.Edges.Properties.VariableNames)
                    Graph.Edges.Edges = [];   % remove edges, they will be recalculated in the Lines3D.replaceGraph function
                end
            end
            
            % % --------- process Edges -----------
            % generate edges matrix
            if ~ismember('Edges', edgeFields)
                Graph.Edges.Edges = ...
                    [Graph.Nodes.PointsXYZ(Graph.Edges.EndNodes(:,1),:) Graph.Nodes.PointsXYZ(Graph.Edges.EndNodes(:,2),:)];
            end
            if ~ismember('Weight', edgeFields)
                Graph.Edges.Weight = ones([size(Graph.Edges.EndNodes, 1), 1]);
            end
            if ~ismember('Length', edgeFields)
                Graph = obj.calculateLengthOfNodes(Graph);
                edgeFields = [edgeFields, 'Length'];
            end
            
            % adding additional fields
            obj.extraEdgeFields = edgeFields(~ismember(edgeFields, {'EndNodes', 'Edges', 'Weight', 'Length'}))';
            obj.extraEdgeFieldsNumeric = zeros([numel(obj.extraEdgeFields), 1]);
            if ~isempty(obj.extraEdgeFields)
                for fieldId = 1:numel(obj.extraEdgeFields)
                    obj.extraEdgeFieldsNumeric(fieldId) = isnumeric(Graph.Edges.(obj.extraEdgeFields{fieldId})(1));
                end
            end
            
            obj.G = Graph;
            clear Graph;
        end
        
        function Graph = calculateLengthOfNodes(obj, Graph, options)
            % function Length = calculateLengthOfNodes(obj, Graph, options)
            % calculate length of nodes
            %
            % Parameters:
            % Graph: a graph object
            % options: [@em optional] - an optional structure with
            % additional parameters
            %   .nodeId - id if nodes that include edges that should be
            %   recalculated
            %
            % Return values:
            % Graph: the graph object with added/modified Length field
            
            if obj.noTrees == 0; return; end
            
            if nargin < 3; options = struct(); end
            
            if isfield(options, 'nodeId')   % calculate length only for specified nodes
                edge1 = find(ismember(Graph.Edges.EndNodes(:,1), options.nodeId));
                edge2 = find(ismember(Graph.Edges.EndNodes(:,2), options.nodeId));
                edgeIds = unique([edge1; edge2]);
                for edgeId = edgeIds'   % should be horizontal vector
                    Graph.Edges.Length(edgeId) = sqrt(...
                        (Graph.Edges.Edges(edgeId,1)-Graph.Edges.Edges(edgeId,4))^2 + ...
                        (Graph.Edges.Edges(edgeId,2)-Graph.Edges.Edges(edgeId,5))^2 + ...
                        (Graph.Edges.Edges(edgeId,3)-Graph.Edges.Edges(edgeId,6))^2);
                end
            elseif isfield(options, 'edgeId') % calculate length only for specified edges
                % transpose to horizontal vector
                if size(options.edgeId,1) > size(options.edgeId,2); options.edgeId = options.edgeId'; end
                for edgeId = options.edgeId     % options.edgeId should be horizontal vector
                    Graph.Edges.Length(edgeId) = sqrt(...
                        (Graph.Edges.Edges(edgeId,1)-Graph.Edges.Edges(edgeId,4))^2 + ...
                        (Graph.Edges.Edges(edgeId,2)-Graph.Edges.Edges(edgeId,5))^2 + ...
                        (Graph.Edges.Edges(edgeId,3)-Graph.Edges.Edges(edgeId,6))^2);
                end
            else    % calculate length for all edges
                Length = zeros([size(Graph.Edges.Edges, 1) 1]);
                for edgeId = 1:size(Graph.Edges.Edges, 1)
                    Length(edgeId) = sqrt(...
                        (Graph.Edges.Edges(edgeId,1)-Graph.Edges.Edges(edgeId,4))^2 + ...
                        (Graph.Edges.Edges(edgeId,2)-Graph.Edges.Edges(edgeId,5))^2 + ...
                        (Graph.Edges.Edges(edgeId,3)-Graph.Edges.Edges(edgeId,6))^2);
                end
                Graph.Edges.Length = Length;
            end
        end
        
        function options = getOptions(obj)
            % function options = getOptions(obj)
            % get options of the class
            options = struct();
            options.clipExtraThickness = obj.clipExtraThickness; % a number, extend clipping of the edges with additional thickness +/- this number sections
            options.edgeActiveColor = obj.edgeActiveColor; % color of active tree edges [R, G, B], from 0 to 1
            options.edgeColor = obj.edgeColor; % color of edges [R, G, B], from 0 to 1
            options.edgeThickness = obj.edgeThickness; % thickness of edges
            options.nodeActiveColor = obj.nodeActiveColor; % color of the active node [R, G, B], from 0 to 1
            options.nodeColor = obj.nodeColor; % color of nodes [R, G, B], from 0 to 1
            options.nodeRadius = obj.nodeRadius; % radius of nodes
        end
        
        function setOptions(obj, options)
            % function setOptions(obj, options)
            % update options of the class
            if nargin < 2; return; end
            
            fieldNames = fieldnames(options);
            for fieldId = 1:numel(fieldNames)
                obj.(fieldNames{fieldId}) = options.(fieldNames{fieldId});
            end
            obj.updateNodeStrel(obj.nodeRadius);     % update strel element
        end
        
        function [Graph, nodeIds, EdgesTable, NodesTable] = getTree(obj, treeId)
            % [Graph, nodeIds, EdgesTable, NodesTable] = function getTree(obj, treeId)
            % return graph with the tree specified in treeId
            %
            % Parameters:
            % treeId: index of tree to get
            %
            % Return values:
            % Graph: graph object containing tree specified in treeId
            % nodeIds: indices of nodes belonging to this tree
            % EdgesTable: a table with edges that belong to treeId
            % NodesTable: a table with nodes that belong to treeId
            
            if nargin < 2; return; end
            
            nodeByTree = conncomp(obj.G);
            nodeIds = find(ismember(nodeByTree, treeId));
            Graph = subgraph(obj.G, nodeIds);
            if nargout > 2
                NodesTable = obj.G.Nodes(nodeIds,:);
                edge1 =  find(ismember(obj.G.Edges.EndNodes(:,1), nodeIds));
                edge2 =  find(ismember(obj.G.Edges.EndNodes(:,2), nodeIds));
                edgeIds = unique([edge1, edge2]);
                EdgesTable = obj.G.Edges(edgeIds,:);
            end
        end
        
        function treeNames = getTreeNames(obj, index)
            % function treeNames = getTreeNames(obj, index)
            % return name of trees
            %
            % Parameters:
            % index: [@em optional] indices of the trees
            %
            % Return values:
            % treeNames: a cell array with names of trees
            %
            if nargin < 2; index = []; end
            if isempty(obj.G.Nodes); treeNames =[]; return; end
            
            treeNames = unique(obj.G.Nodes.TreeName, 'stable');     % 'stable' - do not sort the results
            if ~isempty(index)
                treeNames = treeNames(index);
            end
        end
        
        function [noTrees, nodeByTree] = updateNumberOfTrees(obj)
            % function [noTrees, nodeByTree] = updateNumberOfTrees(obj)
            % update number of trees in the graph and get array of nodes by
            % tree index
            %
            % Parameters:
            %
            % Return values:
            % noTrees: total number of isolated trees of the graph
            % nodeByTree: vector of nodes, where values indicate corresponding tree of the node
            noTrees = 0;
            nodeByTree = [];
            if isempty(obj.G); return; end
            if isempty(obj.G.Nodes); return; end
            
            nodeByTree = conncomp(obj.G);
            noTrees = max(nodeByTree);
            obj.noTrees = noTrees;
        end
        
        function deleteTree(obj, treeId)
            % function deleteTree(obj, treeId)
            % delete tree from the graph
            %
            % Parameters:
            % treeId: index of the tree to delete, or string with name of
            % the tree
            
            if nargin < 2; error('treeId is missing!'); end
            
            nodeByTree = conncomp(obj.G); % get tree ids for each node
            
            % find indices of trees to remove
            if ~isnumeric(treeId)
                treeNames = obj.getTreeNames();
                if ischar(treeId); treeId = cellstr(treeId); end   % convert char to cell
                treeId = find(ismember(treeNames, treeId));
            end
            nodeIDs =  find(ismember(nodeByTree, treeId));
            
            % make sure that the active node preserved
            if ~isempty(obj.activeNodeId)
                if ismember(obj.activeNodeId, nodeIDs) % active node belongs to a tree to delete
                    obj.activeNodeId = [];
                    activeTreeName = [];
                else
                    activeTreeName = obj.G.Nodes.TreeName(obj.activeNodeId);
                end
            end
            
            obj.G = rmnode(obj.G, nodeIDs);
            
            % find index of a new active tree
            if ~isempty(activeTreeName)
                obj.activeNodeId = find(ismember(obj.G.Nodes.TreeName, activeTreeName), 1, 'last');
            else
                obj.activeNodeId = size(obj.G.Nodes,1);
            end
            
        end
        
        function insertNode(obj, nodeId, x, y, z)
            % function insertNode(obj, nodeId, x, y, z)
            % insert node to a tree after nodeId, the inserted node becomes
            % an active node
            %
            % Parameters:
            % nodeId: index of the node after which a new node should be inserted
            % x: new x coordinate
            % y: new y coordinate
            % z: new z coordinate
            if nargin < 5; error('not enough parameters!'); end
            if isempty(obj.G); return; end
            
            % modify nodes
            NodesTable = obj.G.Nodes;
            NodesTable = [NodesTable(1:nodeId,:); NodesTable(nodeId,:); NodesTable(nodeId+1:end,:)];
            NodesTable.PointsXYZ(nodeId+1,:) = [x, y, z];
            
            % modify edges
            EdgesTable = obj.G.Edges;
            EdgesTable.EndNodes(EdgesTable.EndNodes(:,1)>nodeId,1) = EdgesTable.EndNodes(EdgesTable.EndNodes(:,1)>nodeId,1) + 1;
            EdgesTable.EndNodes(EdgesTable.EndNodes(:,2)>nodeId,2) = EdgesTable.EndNodes(EdgesTable.EndNodes(:,2)>nodeId,2) + 1;
            
            % find index of the edge where to insert the node
            edgeIndex = find(EdgesTable.EndNodes(:,1)==nodeId);
            if isempty(edgeIndex)   % the active node is the last one in the tree
                errordlg(sprintf('!!! Error !!!\n\nThis active point is the last point of the tree, use the add node function instead or select a previous node'),'End of tree node');
                return;
            end
            if numel(edgeIndex) > 1     % the active node is a branch node of multiple edges
                errordlg(sprintf('!!! Error !!!\n\nThe active node is a branch node for multiple edges!\nPlease select another node'),'Too many input nodes');
                return;
            end
            
            % modify the edges table
            EdgesTable(end+1,:) = EdgesTable(edgeIndex,:);
            EdgesTable.EndNodes(end,1) = nodeId+1;
            EdgesTable.Edges(end, 1:3) = NodesTable.PointsXYZ(nodeId+1,:);
            
            EdgesTable.EndNodes(edgeIndex,2) = nodeId+1;
            EdgesTable.Edges(edgeIndex, 4:6) = NodesTable.PointsXYZ(nodeId+1,:);
            
            % recalculate the graph
            obj.G = graph(EdgesTable, NodesTable);
            obj.activeNodeId = nodeId + 1;
            % recalculate length of edges
            options.nodeId = [nodeId, nodeId+1];
            obj.G = obj.calculateLengthOfNodes(obj.G, options);
        end
        
        function updateNodeCoordinate(obj, nodeId, x, y, z)
            % function updateNodeCoordinate(obj, nodeId, x, y, z)
            % update coordinate of the node
            %
            % Parameters:
            % nodeId: index of the node to update
            % x: new x coordinate
            % y: new y coordinate
            % z: new z coordinate
            
            if nargin < 5; error('not enough paramters!'); end
            % update coordinate of the node
            obj.G.Nodes.PointsXYZ(nodeId,:) = [x, y, z];
            % recalculate edges
            inputIndex = find(obj.G.Edges.EndNodes(:,1) == nodeId);
            outputIndex = find(obj.G.Edges.EndNodes(:,2) == nodeId);
            obj.G.Edges.Edges(inputIndex,1:3) = repmat([x,y,z], [numel(inputIndex), 1]); %#ok<FNDSB>
            obj.G.Edges.Edges(outputIndex,4:6) = repmat([x,y,z], [numel(outputIndex), 1]); %#ok<FNDSB>
            
            % recalculate length of edges
            options.nodeId = nodeId;
            obj.G = obj.calculateLengthOfNodes(obj.G, options);
        end
        
        function addNode(obj, x, y, z, newTreeSwitch, options)
            % function addNode(obj, x, y, z, newTreeSwitch, options)
            % add a new node(s) to the graph; when x,y,z are columns of
            % coordinates they are considered to be connected with edges
            %
            % Parameters:
            % x: a column of x coordinates of nodes (in physical units)
            % y: a column of y coordinates of nodes (in physical units)
            % z: a column of z coordinates of nodes (in physical units)
            % newTreeSwitch: an optional switch to start a new tree
            % options: a structure with optional parameters
            %  .pixSize - structure with pixel sizes of the dataset
            %  .BoundingBox - a vector with the bounding box information [xmin, width, ymin, height, zmin, depth]
            
            if nargin < 6; options = struct(); end
            if nargin < 5; newTreeSwitch = 0; end
            if isempty(obj.activeNodeId); newTreeSwitch = 1; end
            
            if isempty(obj.G)
                newTreeSwitch = 1;
                numNodes = 0;
                %NodeTable = table({[]},{[]},{[]},{[]}, 'VariableNames',{'PointsXYZ','TreeName','NodeName','Radius'});
                %EdgeTable = table({[]},{[]},{[]}, 'VariableNames',{'EndNodes', 'Edges', 'Weight'});
                %obj.G = graph(EdgeTable, NodeTable);
                obj.G = graph();
            else
                numNodes = size(obj.G.Nodes, 1);     % number of nodes in the existing graph
            end
            
            numBranchNodes = numel(x);    % number of nodes in the branch
            nodeFields = obj.G.Nodes.Properties.VariableNames;
            
            if newTreeSwitch == 0   % add node to existing tree
                s = [obj.activeNodeId, numNodes+1:numNodes+numBranchNodes-1];     % input nodes
                t = numNodes+1:numNodes+numBranchNodes;                         % output nodes
                
                % add the coordinates of the active node to x, y, z
                x = [obj.G.Nodes.PointsXYZ(obj.activeNodeId, 1); x];
                y = [obj.G.Nodes.PointsXYZ(obj.activeNodeId, 2); y];
                z = [obj.G.Nodes.PointsXYZ(obj.activeNodeId, 3); z];
                
                NewTreeName = repmat(obj.G.Nodes.TreeName(obj.activeNodeId), [numBranchNodes, 1]);
                NodeName = repmat(obj.G.Nodes.NodeName(obj.activeNodeId), [numBranchNodes, 1]);
                Radius = zeros([numBranchNodes, 1]) + obj.G.Nodes.Radius(obj.activeNodeId);
                Weights = zeros([numel(s), 1])+1;
                
                % add node(s)
                %obj.G.Nodes.PointsXYZ(numNodes+1:numNodes+numBranchNodes-1,:) = [x(2:end) y(2:end) z(2:end)];
                NodeProps = table([x(2:end) y(2:end) z(2:end)], NewTreeName, NodeName, Radius, ...
                    'VariableNames', {'PointsXYZ', 'TreeName', 'NodeName', 'Radius'});
            else  % add node to a new tree
                obj.noTrees = obj.noTrees + 1;  % increase counter of trees
                s = numNodes+1:numNodes+numBranchNodes-1;     % input nodes
                t = numNodes+2:numNodes+numBranchNodes;       % output nodes
                Weights = zeros([numel(s), 1])+1;
                
                % find name for a new tree
                treeNameFound = 0;
                treeCounter = 1;
                treeNames = obj.getTreeNames();
                while treeNameFound == 0
                    NewTreeName = sprintf('%s_%.5d', obj.defaultTreeName, treeCounter);
                    if ~ismember(NewTreeName, treeNames)
                        treeNameFound = 1;
                    else
                        treeCounter = treeCounter + 1;
                    end
                end
                NewTreeName = repmat({NewTreeName}, [numBranchNodes, 1]);
                NodeName = repmat({obj.defaultNodeName}, [numBranchNodes, 1]);
                Radius = ones([numBranchNodes, 1]);
                
                % add node(s)
                %obj.G.Nodes.PointsXYZ(numNodes+1:numNodes+numBranchNodes-1,:) = [x(2:end) y(2:end) z(2:end)];
                NodeProps = table([x y z], NewTreeName, NodeName, Radius, ...
                    'VariableNames', {'PointsXYZ', 'TreeName', 'NodeName', 'Radius'});
            end
            
            % add additional fields to Nodes
            for fieldId=1:numel(obj.extraNodeFields)
                if obj.extraNodeFieldsNumeric(fieldId)
                    valVec = zeros([numel(NewTreeName), 1]);
                else
                    valVec = repmat({''}, [numel(NewTreeName), 1]);
                end
                NodeProps.(obj.extraNodeFields{fieldId}) = valVec;
            end
            
            obj.G = addnode(obj.G, NodeProps);
            
            % add/update pixSize structure
            if isfield(options, 'pixSize')
                obj.G.Nodes.Properties.UserData.pixSize = options.pixSize;
            end
            % add/update pixSize structure
            if isfield(options, 'BoundingBox')
                obj.G.Nodes.Properties.UserData.BoundingBox = options.BoundingBox;
            end
            
            % add edge(s) field that describe each edge
            if numel(s) > 0
                EdgesVec = zeros([numel(s), 6]);
                LengthVec = zeros([numel(s), 1]);
                for edge = 1:numel(s)
                    EdgesVec(edge,:) = [x(edge), y(edge), z(edge), x(edge+1), y(edge+1), z(edge+1)];
                end
                
                % make table with edges
                Table = table([s', t'], EdgesVec, Weights, LengthVec, 'VariableNames', {'EndNodes', 'Edges', 'Weight', 'Length'});
                
                % add additional fields to Edges
                for fieldId=1:numel(obj.extraEdgeFields)
                    if obj.extraEdgeFieldsNumeric(fieldId)
                        valVec = zeros([numel(Weights), 1]);
                    else
                        valVec = repmat({''}, [numel(Weights), 1]);
                    end
                    Table.(obj.extraEdgeFields{fieldId}) = valVec;
                end
                
                % rearrange the table so that the variable names match those in the obj.G.Edges table
                % do not resort when adding the first edge
                if numel(obj.G.Edges.Properties.VariableNames) > 1
                    Table = Table(:, obj.G.Edges.Properties.VariableNames);
                end
                
                obj.G = addedge(obj.G, Table);
                obj.activeNodeId = t(end);   % define the active node
                
                % recalculate length of edges
                options.nodeId = Table.EndNodes;
                obj.G = obj.calculateLengthOfNodes(obj.G, options);
            else
                obj.activeNodeId = size(obj.G.Nodes, 1);
            end
        end
        
        function connectNodes(obj, s, t)
            % function connectNodes(obj, nodeId1, nodeId2)
            % make an edge between two nodes
            %
            % Parameters:
            % s: index of the first node
            % t: index of the second node
            if nargin < 3; error('not enough parameters!'); end
            
            noNodes = size(obj.G.Nodes,1);
            if max([s, t]) > noNodes
                error('graph does not have that many nodes!');
            end
            
            GidxOut = findedge(obj.G, s, t);
            if GidxOut > 0
                return; % nodes are already connected
            end
            
            EdgesVec = zeros([numel(s), 6]);
            LengthVec = zeros([numel(s), 1]);
            Weights = zeros([numel(s), 1])+1;
            for edge = 1:numel(s)
                EdgesVec(edge,:) = [obj.G.Nodes.PointsXYZ(s,:), obj.G.Nodes.PointsXYZ(t,:)];
            end
            
            % make table with edges
            Table = table([s', t'], EdgesVec, Weights, LengthVec, 'VariableNames', {'EndNodes', 'Edges', 'Weight', 'Length'});
            
            % add additional fields to Edges
            for fieldId=1:numel(obj.extraEdgeFields)
                if obj.extraEdgeFieldsNumeric(fieldId)
                    valVec = zeros([numel(Weights), 1]);
                else
                    valVec = repmat({''}, [numel(Weights), 1]);
                end
                Table.(obj.extraEdgeFields{fieldId}) = valVec;
            end
            
            % rearrange the table so that the variable names match those in the obj.G.Edges table
            % do not resort when adding the first edge
            if numel(obj.G.Edges.Properties.VariableNames) > 1
                Table = Table(:, obj.G.Edges.Properties.VariableNames);
            end
            
            obj.G = addedge(obj.G, Table);
            obj.activeNodeId = t(end);   % define the active node
            
            % recalculate length of edges
            options.nodeId = Table.EndNodes;
            obj.G = obj.calculateLengthOfNodes(obj.G, options);
            
            currentNumberOfTrees = obj.noTrees;
            [numTrees, nodeByTree] = obj.updateNumberOfTrees();
            if currentNumberOfTrees ~= numTrees
                % update number of trees and TreeNames
                obj.noTrees = numTrees;
                treeNameS = obj.G.Nodes.TreeName(s(1));
                treeNameT = obj.G.Nodes.TreeName(t(1));
                % rename tree names of the target to source
                obj.G.Nodes.TreeName(ismember(obj.G.Nodes.TreeName, treeNameT)) = treeNameS;
            end
        end
        
        
        function nodeId = findClosestNode(obj, x, y, z, orientation)
            % function nodeId = findClosestNode(obj, x, y, z, orientation)
            % find the closest node to a point with coordinates x, y, z
            %
            % Parameters:
            % x: x coordinate of a point next to the node
            % y: y coordinate of a point next to the node
            % z: z coordinate of a point next to the node
            % orientation: [@em optional] a number with orientation of the dataset, 4-yx, 1-xz, 2-yz, default 4
            
            if nargin < 5; orientation = 4; end
            
            % transpose points from xy to
            if orientation == 1         % zx
                x1 = x; y1 = y; z1 = z;
                x = z1; y = x1; z = y1;
            elseif orientation == 2     % zy
                x1 = x; y1 = y; z1 = z;
                x = z1; y = y1; z = x1;
            end
            
            % find all points of the existing graph that are shown on the slice of the first point of the branch
            [nodes, nodeIds] = obj.findSliceNodes(z, orientation);
            if orientation == 1         % zx
                nodes = nodes(:,[3 1]);
            elseif orientation == 2     % zy
                nodes = nodes(:,[3 2]);
            end
            dist = distancePoints([x, y], nodes(:,1:2));    % matGeom function
            
            % find the closest point
            [minDist, nodeId] = min(dist);
            % find index of the closest node to the specified point to delete
            nodeId = nodeIds(nodeId);
        end
        
        function setActiveNode(obj, x, y, z, orientation)
            % function setActiveNode(obj, x, y, z, orientation)
            % set active the node which is closest to a point with
            % coordinates x, y, z as the active node
            %
            % Parameters:
            % x: x coordinate of a point next to the node
            % y: y coordinate of a point next to the node
            % z: z coordinate of a point next to the node
            % orientation: [@em optional] a number with orientation of the dataset, 4-yx, 1-xz, 2-yz, default 4
            
            if nargin < 5; orientation = 4; end
            
            nodeId = obj.findClosestNode(x, y, z, orientation);
            if isempty(nodeId); return; end     % no node
            obj.activeNodeId = nodeId(1);
        end
        
        
        function splitAtNode(obj, x, y, z, orientation)
            % function splitAtNode(obj, x, y, z, orientation)
            % split tree at the node that is closest to the point with coordinates x, y, z
            % the node and its edges will be removed
            %
            % Parameters:
            % x: x coordinate of a point next to the node
            % y: y coordinate of a point next to the node
            % z: z coordinate of a point next to the node
            % orientation: [@em optional] a number with orientation of the dataset, 4-yx, 1-xz, 2-yz, default 4
            if nargin < 5; orientation = 4; end
            
            nodeId = obj.findClosestNode(x, y, z, orientation);
            if isempty(nodeId); return; end     % no node
            
            N = neighbors(obj.G, nodeId);   % find neighboring nodes
            obj.G = rmnode(obj.G, nodeId);  % remove node and split the graph
            obj.noTrees = obj.noTrees + numel(N)-1;  % increase tree counter
            
            %             if nodeId == obj.activeNodeId
            %                 %obj.activeNodeId = [];
            %                 obj.activeNodeId = obj.activeNodeId - 1;    % decrease by 1 due to remove of the node
            %             else
            %                 obj.activeNodeId = obj.activeNodeId - 1;    % decrease by 1 due to remove of the node
            %             end
            %             if obj.activeNodeId == 0; obj.activeNodeId = []; end
            if ~isempty(N)
                obj.activeNodeId = min(N);
            else
                if obj.noTrees > 0
                    obj.activeNodeId = 1;
                else
                    obj.activeNodeId = [];
                end
            end
            
            % rename tree name for the second part of the splitted graph,
            % add 's' to the end
            if numel(N) > 1   % real split, i.e the deleted node was not on the end of the graph
                N = sort(N);
                bins = conncomp(obj.G);
                for i=2:numel(N)
                    newFirstNode = N(i)-1;      % new index of the new node, decreased by one due to remove of the node earlier
                    nodesToRenameIds = find(bins == bins(newFirstNode));    % find indices to rename
                    treeNameTemplate = obj.G.Nodes.TreeName{nodesToRenameIds(1)};
                    underLineIndex = strfind(treeNameTemplate, '_');
                    if ~isempty(underLineIndex)
                        treeNameTemplate = treeNameTemplate(1:underLineIndex(end)-1);
                    end
                    
                    % generate a new tree name
                    notOk = 1;
                    while notOk > 0
                        newTreeName = sprintf('%s_%.5d', treeNameTemplate, randi(65535));
                        if ~ismember({newTreeName}, obj.G.Nodes.TreeName)
                            notOk = 0;
                        end
                    end
                    
                    %obj.G.Nodes.TreeName(nodesToRenameIds) = arrayfun(@(x, y) {sprintf('%ss%d', cell2mat(x), y-1)}, obj.G.Nodes.TreeName(nodesToRenameIds), repmat(i, [numel(nodesToRenameIds), 1]));
                    %obj.G.Nodes.TreeName(nodesToRenameIds) = repmat({sprintf('%s_%.3d', treeNameTemplate, obj.noTrees-i+2)}, [numel(nodesToRenameIds), 1]);
                    obj.G.Nodes.TreeName(nodesToRenameIds) = repmat({newTreeName}, [numel(nodesToRenameIds), 1]);
                end
            end
            
            % recalculate length of edges
            obj.G = obj.calculateLengthOfNodes(obj.G);
        end
        
        function result = deleteNode(obj, x, y, z, orientation)
            % function result = deleteNode(obj, x, y, z)
            % delete node that is closest to the point with coordinates x, y, z
            % the previous and following nodes get connected after remove of
            % the node
            %
            % Parameters:
            % x: x coordinate of a point next to the node, or index of the
            % node (in this case, y and z should be empty)
            % y: y coordinate of a point next to the node
            % z: z coordinate of a point next to the node
            % orientation: [@em optional] a number with orientation of the dataset, 4-yx, 1-xz, 2-yz, default 4
            %
            % Return value:
            % results: type of the node that was deleted
            %  'removed tree' - the last node of a tree was removed, so the tree
            %  'middle node'  - the removed node was in a middle of a tree
            %  'multiple split' - the node had more than 2 connections and as result multiple new trees were formed
            if nargin < 5; orientation = 4; end
            if nargin < 3; y = []; z = []; end
            result = '';
            
            if isempty(y)
                nodeId = x;
            else
                nodeId = [];
            end
            
            if isempty(nodeId)
                nodeId = obj.findClosestNode(x, y, z, orientation);
                if isempty(nodeId); return; end     % no node
            end
            
            % find edges that connected to this node
            edgeIds = unique([find(obj.G.Edges.EndNodes(:,1) == nodeId); find(obj.G.Edges.EndNodes(:,2) == nodeId)]);
            if isempty(edgeIds)     % a single not connected node
                obj.G = rmnode(obj.G, nodeId);
                obj.noTrees = obj.noTrees - 1;
                N = nodeId-1;   % N is used at the end of the function to reassign the active node
                result = 'removed tree';
            elseif numel(edgeIds) == 2  % node is between other nodes
                affectedEdges = obj.G.Edges(edgeIds,:);
                N = neighbors(obj.G, nodeId);   % find neighboring nodes
                obj.G = rmnode(obj.G, nodeId);
                
                N(N>nodeId) = N(N>nodeId) - 1;  % decrease N by 1 because the node was removed
                
                if findedge(obj.G, N(1), N(2)) == 0   % if edge already exist skip formation of a new one
                    node1 = N(1);
                    node2 = N(2);
                    EndNodesClip = affectedEdges(1,:);
                    EndNodesClip.EndNodes(1:2) = [node1, node2];
                    EndNodesClip.Edges(1:3) = obj.G.Nodes(node1,:).PointsXYZ;
                    EndNodesClip.Edges(4:6) = obj.G.Nodes(node2,:).PointsXYZ;
                    obj.G = addedge(obj.G, EndNodesClip);
                    
                    % recalculate length of edges
                    options.nodeId = EndNodesClip.EndNodes;
                    obj.G = obj.calculateLengthOfNodes(obj.G, options);
                end
                result = 'middle node';
            else    % node is at the end of the graph or between 3 or more nodes
                N = neighbors(obj.G, nodeId);   % find neighboring nodes
                obj.G = rmnode(obj.G, nodeId);
                
                obj.noTrees = obj.noTrees + numel(N)-1;  % increase tree counter
                % rename tree name for the second part of the splitted graph,
                % add 's' to the end
                if numel(N) > 1   % real split
                    bins = conncomp(obj.G);
                    for i=2:numel(N)
                        newFirstNode = N(i)-1;      % new index of the new node, decreased by one due to remove of the node earlier
                        nodesToRenameIds = find(bins == bins(newFirstNode));    % find indices to rename
                        
                        obj.G.Nodes.TreeName(nodesToRenameIds) = arrayfun(@(x, y) {sprintf('%ss%d', cell2mat(x), y-1)}, obj.G.Nodes.TreeName(nodesToRenameIds), repmat(i, [numel(nodesToRenameIds), 1]));
                    end
                end
                N(N>nodeId) = N(N>nodeId) - 1;  % decrease N by 1 because the node was removed
                result = 'multiple split';
            end
            
            % correct the active node
            if ~isempty(obj.activeNodeId)
                if obj.activeNodeId == nodeId   % reassign the active node
                    obj.activeNodeId = N(1);
                else
                    obj.activeNodeId(obj.activeNodeId>nodeId) = obj.activeNodeId(obj.activeNodeId>nodeId) - 1;
                end
                if obj.activeNodeId == 0; obj.activeNodeId = []; end
            end
        end
        
        function makeDummyGraph(obj)
            % function makeDummyGraph(obj)
            % generate a dummy graph for developmental purposes
            points = [303 81 72;...
                294 90 67;...
                294 172 56;...
                290 207 20;...
                252 268 1;...
                294 172 40;...
                387 198 42;...
                400 252 25;
                314 270 19];
            
            s = [1 2 3 4 4 6 8];
            t = [2 3 4 5 6 7 9];
            
            Graph = graph(s, t);
            Graph.Nodes.PointsXYZ = points;
            
            %             figure(1);
            %             h = plot(Graph);
            %             h.XData = Graph.Nodes.PointsXYZ(:,1);
            %             h.YData = Graph.Nodes.PointsXYZ(:,2);
            %             h.ZData = Graph.Nodes.PointsXYZ(:,3);
            
            Graph.Nodes.Properties.UserData.pixSize = struct();
            Graph.Nodes.Properties.UserData.pixSize.x = .013;
            Graph.Nodes.Properties.UserData.pixSize.y = .013;
            Graph.Nodes.Properties.UserData.pixSize.z = .03;
            Graph.Nodes.Properties.UserData.pixSize.units = 'um';
            
            Graph.Nodes.PointsXYZ(:,1) = Graph.Nodes.PointsXYZ(:,1)*Graph.Nodes.Properties.UserData.pixSize.x - Graph.Nodes.Properties.UserData.pixSize.x/2;
            Graph.Nodes.PointsXYZ(:,2) = Graph.Nodes.PointsXYZ(:,2)*Graph.Nodes.Properties.UserData.pixSize.y - Graph.Nodes.Properties.UserData.pixSize.y/2;
            Graph.Nodes.PointsXYZ(:,3) = Graph.Nodes.PointsXYZ(:,3)*Graph.Nodes.Properties.UserData.pixSize.z - Graph.Nodes.Properties.UserData.pixSize.z/2;
            
            Graph.Nodes.TreeName = repmat({'Tree 001'}, [size(Graph.Nodes.PointsXYZ,1), 1]);    % add tree names to nodes
            Graph.Nodes.Radius = ones([size(Graph.Nodes.PointsXYZ,1), 1]);    % add node radius to nodes
            
            Graph.Nodes.ExtraParameter1 = ones([size(Graph.Nodes.PointsXYZ,1), 1])+1;    % add Extra parameter to nodes
            Graph.Nodes.ExtraParameter2 = repmat({'Comment'}, [size(Graph.Nodes.PointsXYZ,1), 1]);    % add Extra parameter to nodes
            
            obj.replaceGraph(Graph);
            Graph.Edges.Weight = ones([size(Graph.Edges,1), 1]);    % add weights to edges
            Graph.Edges.Length = ones([size(Graph.Edges,1), 1]);    % add length vector to edges
            
        end
        
        function updateNodeStrel(obj, nodeStrelSize)
            % function updateNodeStrel(obj, nodeStrelSize)
            % update strel element for showing nodes as circles
            
            if obj.matlabVersion < 9
                obj.nodeStrel = strel('disk', nodeStrelSize);
            else
                se = strel('sphere', nodeStrelSize);
                obj.nodeStrel = se.Neighborhood(:, :, ceil(nodeStrelSize/2));
            end
        end
        
        function [edge, edgeIds] = clipEdge(obj, Box)
            % function [edge, edgeIds] = clipEdge(obj, Box, orientation)
            % clip the edge using the Box matrix
            %
            % Parameters:
            % Box: a vector used for cliping the edges [xMin, xMax, yMin, yMax, zMin, zMax]
            %
            % Return values:
            % edge: a matrix of edges shown inside the clipping box, [x1 y1 z1 x2 y2 z2]
            % edgeIds: indices of the returned edges
            
            % the following codes are quite slow: 140ms, putting the
            % clipEdge3d into a try block seems to be faster
            
            % if isempty(obj.G.Edges); edge = []; edgeIds =[]; return; end
            %if size(obj.G.Edges, 1) < 1; edge = []; edgeIds =[]; return; end
            %if ismember('Edges', obj.G.Edges.Properties.VariableNames) == 0
            %    edge = []; edgeIds =[]; return;
            %end
            
            try
                % remove edges that are outside the bounding box
                % speeds up clipEdge3d in about 5-10 times
                Edges = obj.G.Edges.Edges;  % [x1 y1 z1 x2 y2 z2]
                Edges(Edges(:,1) < Box(1) & Edges(:,4) < Box(1), :) = [];
                Edges(Edges(:,1) > Box(2) & Edges(:,4) > Box(2), :) = [];
                Edges(Edges(:,2) < Box(3) & Edges(:,5) < Box(3), :) = [];
                Edges(Edges(:,2) > Box(4) & Edges(:,5) > Box(4), :) = [];
                Edges(Edges(:,3) < Box(5) & Edges(:,6) < Box(5), :) = [];
                Edges(Edges(:,3) > Box(6) & Edges(:,6) > Box(6), :) = [];
                
                % version 2, ~2 time slower
                % remove edges that are outside the bounding box
                %               xOut = obj.G.Edges.Edges(:,1) < Box(1) & obj.G.Edges.Edges(:,4) < Box(2);
                %                xOut2 = obj.G.Edges.Edges(:,1) > Box(1) & obj.G.Edges.Edges(:,4) > Box(2);
                %                yOut = obj.G.Edges.Edges(:,2) < Box(3) & obj.G.Edges.Edges(:,5) < Box(4);
                %                yOut2 = obj.G.Edges.Edges(:,2) > Box(3) & obj.G.Edges.Edges(:,5) > Box(4);
                %                zOut = obj.G.Edges.Edges(:,3) < Box(5) & obj.G.Edges.Edges(:,6) < Box(6);
                %                 zOut2 = obj.G.Edges.Edges(:,3) > Box(5) & obj.G.Edges.Edges(:,6) > Box(6);
                %                 edgesOut = xOut | xOut2 | yOut | yOut2 | zOut | zOut2;
                %                 Edges = obj.G.Edges.Edges(~edgesOut,:);
                
                edge = clipEdge3d(Edges, Box);
            catch err
                edge = []; edgeIds =[]; return;
            end
            edgeIds = find(~isnan(edge(:,1)));
            % remove NaN edges
            edge = edge(edgeIds, :);
            
        end
        
        function [nodes, indices] = findSliceNodes(obj, z, orientation)
            % function [nodes, indices] = findSliceNodes(obj, z, options)
            % find nodes that are shown on the current slice
            %
            % Parameters:
            % z: Z-value to obtain the nodes
            % orientation: [@em optional, default 4 for XY] a number that
            % specifies desired orientation, 4-yx, 1-xz, 2-yz
            %
            % Return values:
            % nodes: a matrix with coordinates of nodes [node; x, y, z]
            % indices: a vector with indices of returned nodes
            
            if nargin < 2; error('findSliceNodes: missing parameters'); end
            if nargin < 3; orientation = 4; end
            nodes = [];
            indices = [];
            
            pixSize = obj.G.Nodes.Properties.UserData.pixSize;
            
            if orientation == 4
                indices = find(obj.G.Nodes.PointsXYZ(:,3) >= z-pixSize.z/2 & obj.G.Nodes.PointsXYZ(:,3) < z+pixSize.z/2);
                nodes = obj.G.Nodes.PointsXYZ(indices, :);
            elseif orientation == 1
                indices = find(obj.G.Nodes.PointsXYZ(:,2) >= z-pixSize.y/2 & obj.G.Nodes.PointsXYZ(:,2) < z+pixSize.y/2);
                nodes = obj.G.Nodes.PointsXYZ(indices, :);
            elseif orientation == 2
                indices = find(obj.G.Nodes.PointsXYZ(:,1) >= z-pixSize.x/2 & obj.G.Nodes.PointsXYZ(:,1) < z+pixSize.x/2);
                nodes = obj.G.Nodes.PointsXYZ(indices, :);
            end
        end
        
        function img = addLinesToImage(obj, img, Box, options)
            % function img = addLinesToImage(obj, img, options)
            % add lines to the image
            %
            % Parameters:
            % img: image where lines should be added
            % Box: a vector with a clipping box [xmin xmax ymin ymax zmin zmax]
            % options: an optional structure with additional parameters
            % .orientation - a number that specifies desired orientation, 4-yx, 1-xz, 2-yz
            %
            % Return values:
            % img: an image with fused lines
            
            if nargin < 4; options = struct(); end
            if ~isfield(options, 'orientation'); options.orientation = 4; end
            
            pixSize = obj.G.Nodes.Properties.UserData.pixSize;
            maxColor = intmax(class(img));  % maximal color intensity
            imgHeight = size(img, 1);
            imgWidth = size(img, 2);
            imgColors = size(img, 3);
            
            % transpose the Box,
            % TransBox - is a clipping box where the TransBox(5:6) have the
            % z coordinate of for the current orientation
            % Box - is the clipping box oriented for the XY orientation,
            % needed for
            if options.orientation == 4
                TransBox = [Box(1:4) Box(5)-pixSize.z*obj.clipExtraThickness Box(6)+pixSize.z*obj.clipExtraThickness];     % transposed box to xy, stays the same
                Box = [Box(1:4) Box(5)-pixSize.z*obj.clipExtraThickness Box(6)+pixSize.z*obj.clipExtraThickness];           % transposed box to xy
                unitsPerPixelX = (TransBox(2)-TransBox(1)+pixSize.x)/imgWidth;    % magnification of the image
                unitsPerPixelY = (TransBox(4)-TransBox(3)+pixSize.y)/imgHeight;    % magnification of the image
            elseif options.orientation == 1
                TransBox = [Box(1:4) Box(5)-pixSize.y*obj.clipExtraThickness Box(6)+pixSize.y*obj.clipExtraThickness];     % transposed box to xz
                Box = [Box(3:4) Box(5)-pixSize.y*obj.clipExtraThickness Box(6)+pixSize.y*obj.clipExtraThickness Box(1:2)];  % transposed box to xy
                unitsPerPixelX = (TransBox(2)-TransBox(1)+pixSize.z)/imgWidth;    % magnification of the image
                unitsPerPixelY = (TransBox(4)-TransBox(3)+pixSize.x)/imgHeight;    % magnification of the image
            elseif options.orientation == 2
                TransBox = [Box(1:4) Box(5)-pixSize.x*obj.clipExtraThickness Box(6)+pixSize.x*obj.clipExtraThickness];     % transposed box to yz
                Box = [Box(5)-pixSize.x*obj.clipExtraThickness Box(6)+pixSize.x*obj.clipExtraThickness Box(3:4) Box(1:2)];  % transposed box to xy
                unitsPerPixelX = (TransBox(2)-TransBox(1)+pixSize.z)/imgWidth;    % magnification of the image
                unitsPerPixelY = (TransBox(4)-TransBox(3)+pixSize.y)/imgHeight;    % magnification of the image
            end
            
            % get coordinates of the edges
            [edgePnts, edgeIds] = obj.clipEdge(Box);   % result as [x1 y1 z1 x2 y2 z2]
            noEdges = size(edgePnts, 1);
            
            % find edges that belong to the active tree
            activeTreeEdges = [];
            if ~isempty(obj.activeNodeId)
                nodes1 = obj.G.Edges.EndNodes(edgeIds,1);
                nodes2 = obj.G.Edges.EndNodes(edgeIds,2);
                activeTreeEdges = unique([find(ismember(obj.G.Nodes.TreeName(nodes1), obj.G.Nodes.TreeName(obj.activeNodeId))),  ...
                    find(ismember(obj.G.Nodes.TreeName(nodes2), obj.G.Nodes.TreeName(obj.activeNodeId)))]);
            end
            
            if noEdges > 0
                if options.orientation == 4
                    edgePnts = edgePnts(:,[1 2 4 5]);   % [x1 y1 x2 y2], remove Z
                elseif options.orientation == 1
                    edgePnts = edgePnts(:,[3 1 6 4]);   % [x1 y1 x2 y2 z1 z2], remove Y
                elseif options.orientation == 2
                    edgePnts = edgePnts(:,[3 2 6 5]);   % [x1 y1 x2 y2 z1 z2], remove X
                end
                
                % shift coordinates to respect the bounding box of the image
                edgePnts(:,[1 3]) = edgePnts(:,[1 3]) - TransBox(1);
                edgePnts(:,[2 4]) = edgePnts(:,[2 4]) - TransBox(3);
                % shift points to respect magnification
                
                %edgePnts = edgePnts/unitsPerPixel;
                edgePnts(:,[1 3]) = edgePnts(:,[1 3])/unitsPerPixelX;
                edgePnts(:,[2 4]) = edgePnts(:,[2 4])/unitsPerPixelY;
                
                % allocate space
                edgesVec = cell([noEdges, 1]); % {edgeId}(x, y)
                
%                 colMap = jet(255);
%                 minPnt = 0;
%                 maxPnt = 30;
%                 weights = obj.G.Edges.Weight(edgeIds);
%                 weights = floor((weights-minPnt)/(maxPnt-minPnt)*255);
%                 weights(weights<1) = 1;
%                 weights(weights>255) = 255;
                
                % calculate points for each edge
                for edgeId=1:noEdges
                    minX = min([edgePnts(edgeId,1), edgePnts(edgeId,3)]);
                    maxX = max([edgePnts(edgeId,1), edgePnts(edgeId,3)]);
                    minY = min([edgePnts(edgeId,2), edgePnts(edgeId,4)]);
                    maxY = max([edgePnts(edgeId,2), edgePnts(edgeId,4)]);
                    
                    dX = maxX-minX;
                    dY = maxY-minY;
                    nPnts = ceil(max([dX dY]));
                    
                    edgesVec{edgeId}(:,1) = linspace(edgePnts(edgeId,1), edgePnts(edgeId,3), nPnts+1);  % x coordinate for each point of edge {edgeId}
                    edgesVec{edgeId}(:,2) = linspace(edgePnts(edgeId,2), edgePnts(edgeId,4), nPnts+1);  % y coordinate for each point of edge {edgeId}
                end
                
                % brake
                if ~isempty(activeTreeEdges)
                    nonActiveIndices = 1:size(edgesVec,1);
                    nonActiveIndices(activeTreeEdges) = [];
                    pointsVec{1} = round(cell2mat(edgesVec(nonActiveIndices)));     % matrix with all points
                    pointsVec{1}(pointsVec{1}==0) = 1;    % replace 0s with 1
                    pointsVec{2} = round(cell2mat(edgesVec(activeTreeEdges)));     % matrix with all points
                    pointsVec{2}(pointsVec{2}==0) = 1;    % replace 0s with 1
                else
                    pointsVec{1} = round(cell2mat(edgesVec));     % matrix with all points
                    pointsVec{1}(pointsVec{1}==0) = 1;    % replace 0s with 1
                end
                
                % calculate points required to make edge thicker
                if obj.edgeThickness > 1
                    for i=1:numel(pointsVec)
                        if isempty(pointsVec{i}); continue; end
                        thickVec = -(obj.edgeThickness-1):obj.edgeThickness-1; % generate vector of shifts
                        thickVec(thickVec==0) = [];     % remove the central point
                        newX = bsxfun(@plus, pointsVec{i}(:,1), thickVec);     % calculate shifts of the X coordinate
                        newX = reshape(newX, [numel(newX) 1]);   % reshape to a vector
                        pointsVec2 = [newX repmat(pointsVec{i}(:,2), [numel(thickVec) 1])];    % add y coordinate to each x coordinate
                        
                        newY = bsxfun(@plus, pointsVec{i}(:,2), thickVec);
                        newY = reshape(newY, [numel(newY) 1]);   % reshape to a vector
                        pointsVec2 = [pointsVec2; repmat(pointsVec{i}(:,1), [numel(thickVec) 1]) newY];    % add x coordinate to each y coordinate
                        % find and remove points that are out of the boundary
                        ids = [find(pointsVec2(:,1)<1); find(pointsVec2(:,1)>imgWidth); find(pointsVec2(:,2)<1); find(pointsVec2(:,2)>imgHeight)];
                        pointsVec2(ids,:) = [];
                        pointsVec{i} = [pointsVec{i}; pointsVec2];
                    end
                end
                
                %                 pointsVec = round(cell2mat(edgesVec));     % matrix with all points
                %                 pointsVec(pointsVec==0) = 1;    % replace 0s with 1
                %
                %                 % calculate points required to make edge thicker
                %                 if obj.edgeThickness > 1
                %                     thickVec = -(obj.edgeThickness-1):obj.edgeThickness-1; % generate vector of shifts
                %                     thickVec(thickVec==0) = [];     % remove the central point
                %                     newX = bsxfun(@plus, pointsVec(:,1), thickVec);     % calculate shifts of the X coordinate
                %                     newX = reshape(newX, [numel(newX) 1]);   % reshape to a vector
                %                     pointsVec2 = [newX repmat(pointsVec(:,2), [numel(thickVec) 1])];    % add y coordinate to each x coordinate
                %
                %                     newY = bsxfun(@plus, pointsVec(:,2), thickVec);
                %                     newY = reshape(newY, [numel(newY) 1]);   % reshape to a vector
                %                     pointsVec2 = [pointsVec2; repmat(pointsVec(:,1), [numel(thickVec) 1]) newY];    % add x coordinate to each y coordinate
                %                     % find and remove points that are out of the boundary
                %                     ids = [find(pointsVec2(:,1)<1); find(pointsVec2(:,1)>imgWidth); find(pointsVec2(:,2)<1); find(pointsVec2(:,2)>imgHeight)];
                %                     pointsVec2(ids,:) = [];
                %                     pointsVec = [pointsVec; pointsVec2];
                %                 end
                
                % add edges to the image
                for colId = 1:imgColors
                    if ~isempty(pointsVec{1})
                        pointsVec{1}(:,3) = colId;
                        pointsVecIndices = sub2ind([imgHeight, imgWidth, imgColors], pointsVec{1}(:,2), pointsVec{1}(:,1), pointsVec{1}(:,3));
                        img(pointsVecIndices) = obj.edgeColor(colId)*maxColor;
                    end
                    if numel(pointsVec) == 2
                        pointsVec{2}(:,3) = colId;
                        pointsVecIndices = sub2ind([imgHeight, imgWidth, imgColors], pointsVec{2}(:,2), pointsVec{2}(:,1), pointsVec{2}(:,3));
                        img(pointsVecIndices) = obj.edgeActiveColor(colId)*maxColor;
                    end
                end
            end
            
            % add nodes to the image
            % find nodes
            sliceId = mean([TransBox(5), TransBox(6)]);
            [nodes, nodeIds] = obj.findSliceNodes(sliceId, options.orientation);   % [x, y, z]
            
            % transpose coordinates
            if options.orientation == 1
                nodes = [nodes(:,3) nodes(:,1)];
            elseif options.orientation == 2
                nodes = [nodes(:,3) nodes(:,2)];
            end
            
            ids = unique([find(nodes(:,1)<TransBox(1)); find(nodes(:,1)>TransBox(2)); find(nodes(:,2)<TransBox(3)); find(nodes(:,2)>TransBox(4))]); % Box: [xmin xmax ymin ymax zmin zmax]
            %ids = unique([find(nodes(:,1)<Box(1)); find(nodes(:,1)>Box(2)); find(nodes(:,2)<Box(3)); find(nodes(:,2)>Box(4))]); % Box: [xmin xmax ymin ymax zmin zmax]
            nodes(ids, :) = [];     % remove nodes that are not in the field of view
            nodeIds(ids) = [];      % remove node indices that are not in the field of view
            
            if ~isempty(nodes)
                % shift coordinates to respect the bounding box of the image
                nodes(:,1) = nodes(:,1) - TransBox(1);
                nodes(:,2) = nodes(:,2) - TransBox(3);
                
                % shift points to respect magnification
                %nodes = round(nodes/unitsPerPixel);
                nodes(:,1) = round(nodes(:,1)/unitsPerPixelX);
                nodes(:,2) = round(nodes(:,2)/unitsPerPixelY);
                nodes(nodes==0) = 1;  % replace nodes that have value 0
                
                nodeStrelCopy = obj.nodeStrel;
                %                 % decrease strel for zoom out views
                %                 if magFactor < .1
                %                     radius = ceil(obj.nodeRadius/4);
                %                     se = strel('sphere', radius);
                %                     nodeStrelCopy = se.Neighborhood(:, :, radius+1);
                %                 elseif magFactor < .35
                %                     radius = ceil(obj.nodeRadius/2);
                %                     se = strel('sphere', radius);
                %                     nodeStrelCopy = se.Neighborhood(:, :, radius+1);
                %                 end
                seWidth = floor(size(nodeStrelCopy, 1)/2);
                
                if ~isempty(obj.activeNodeId)
                    activeNodeIndex = find(nodeIds == obj.activeNodeId);    % index of the active node, to show it with a different color
                else
                    activeNodeIndex = -1;
                end
                
                for nodeId = 1:size(nodes, 1)
                    % define color for the node
                    if nodeId == activeNodeIndex
                        currNodeColor = obj.nodeActiveColor;
                    else
                        currNodeColor = obj.nodeColor;
                    end
                    
                    dx = nodes(nodeId, 1)-seWidth;
                    dy = nodes(nodeId, 2)-seWidth;
                    x1 = max([1 dx]);
                    x2 = min([size(img, 2) nodes(nodeId, 1)+seWidth]);
                    y1 = max([1 dy]);
                    y2 = min([size(img, 1) nodes(nodeId, 2)+seWidth]);
                    if dx > 0
                        x0 = seWidth+1;
                    else
                        x0 = seWidth+dx;
                    end
                    if dy > 0
                        y0 = seWidth+1;
                    else
                        y0 = seWidth+dy;
                    end
                    
                    mask = zeros([y2-y1+1, x2-x1+1], 'uint8');
                    mask(y0, x0) = 1;
                    mask = imdilate(mask, nodeStrelCopy);
                    
                    for colId = 1:imgColors
                        imgCrop = img(y1:y2, x1:x2, colId);
                        imgCrop(mask==1) = currNodeColor(colId)*maxColor;
                        img(y1:y2, x1:x2, colId) = imgCrop;
                    end
                end
            end
        end
        
        function saveToFile(obj, filename, options)
            % function saveToFile(obj, filename, options)
            % save Lines3D to a file
            %
            % Parameters:
            % filename: full path to file
            % options: a structure with optional paramters
            %  .format - a char string
            %       'lines3d' - MIB lines3d format
            %       'amira-ascii' - amira ascii
            %       'amira-binary' - amira binary
            %       'excel' - Microsoft Excel format
            %  .treeId - a number with index of a tree to save, when empty save all graph
            %  .NodeFieldName - [@em optional] name of variable for nodes to save, only for Amira
            %  .EdgeFieldName - [@em optional] name of variable for edges to save, only for Amira
            %  .showWaitbar - [@em optional] a number 1-show; 0-do not show the waitbar
            
            
            if nargin < 3; options = struct(); end
            if nargin < 2; filename = []; end
            
            if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end
            
            % obtain filename if it is not provided
            if isempty(filename)
                Filters = {'*.lines3d;',  'Matlab format (*.lines3d)';...
                    '*.am',   'Amira Spatial Graph ASCII (*.am)';...
                    '*.am',   'Amira Spatial Graph BINARY (*.am)';...
                    '*.xls',   'Excel format (*.xls)'; };
                
                [filename, path, FilterIndex] = uiputfile(Filters, 'Save Lines3D...', filename); %...
                if isequal(filename,0); return; end % check for cancel
                
                filename = fullfile(path, filename);
                switch Filters{FilterIndex, 2}
                    case 'Matlab format (*.lines3d)'
                        options.format = 'lines3d';
                    case 'Amira Spatial Graph ASCII (*.am)'
                        options.format = 'amira-ascii';
                    case 'Amira Spatial Graph BINARY (*.am)'
                        options.format = 'amira-binary';
                    case 'Excel format (*.xls)'
                        options.format = 'excel';
                end
            end
            if options.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Saving Lines3D', 'WindowStyle','modal'); end
            % obtain format if it is not provided
            if isempty(options.format)
                [path, fn, ext] = fileparts(filename);
                switch ext
                    case '.lines3d'
                        options.format = 'lines3d';
                    case '.am'
                        options.format = 'amira-binary';
                    case '.xls'
                        options.format = 'excel';
                end
            end
            
            % update treeId structure
            if ~isfield(options, 'treeId'); options.treeId = []; end
            
            if isempty(options.treeId)
                Graph.G = obj.G;
                Graph.activeNodeId = obj.activeNodeId;
            else
                Graph.G = obj.getTree(options.treeId);
                Graph.activeNodeId = size(Graph.G.Nodes, 1);
            end
            Graph.Settings = obj.getOptions(); %#ok<STRNU>
            if options.showWaitbar; waitbar(0.05, wb); end
            
            switch options.format
                case 'lines3d'
                    save(filename, 'Graph', '-mat', '-v7.3');
                    obj.filename = filename;
                case 'excel'
                    warning('off', 'MATLAB:xlswrite:AddSheet');
                    
                    % Sheet 1
                    s = {sprintf('Lines3D filename: %s', obj.filename)};
                    s(4,1) = {'NODES'};
                    
                    Variables = obj.G.Nodes.Properties.VariableNames;
                    s(6,2) = {'NodeId'}; s(6,3) = {'TreeName'}; s(6,4) = {'NodeName'}; s(6,5) = {'X'}; s(6,6) = {'Y'}; s(6,7) = {'Z'};
                    Variables(ismember(Variables, {'PointsXYZ', 'TreeName', 'NodeName'})) = [];
                    s(6,8:8+numel(Variables)-1) = Variables;
                    %Units = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.Properties.VariableUnits;
                    %if ~isempty(Units)
                    %    s(7,2:2+numel(Variables)-1) = Units;
                    %end
                    
                    % sheet 2
                    s2 = {sprintf('Lines3D filename: %s', obj.filename)};
                    s2(4,1) = {'EDGES'};
                    
                    Variables = obj.G.Edges.Properties.VariableNames;
                    s2(6,2) = {'EndNode1'}; s2(6,3) = {'EndNode2'}; s2(6,4) = {'EndNode1Name'}; s2(6,5) = {'EndNode2Name'};
                    s2(6,6) = {'Weight'}; s2(6,7) = {'Length'};
                    Variables(ismember(Variables, {'EndNodes', 'Weight', 'Length', 'Edges'})) = [];
                    s2(6,8:8+numel(Variables)-1) = Variables;
                    %                 Units = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.Properties.VariableUnits;
                    %                 if ~isempty(Units)
                    %                     s2(7,2:2+numel(Variables)-1) = Units;
                    %                 end
                    
                    dy1 = 8;
                    dy2 = 8;
                    if options.showWaitbar; waitbar(.1, wb); end
                    
                    %nodesCount = 0;
                    if isempty(options.treeId)
                        treeIds = 1:obj.noTrees;
                    else
                        treeIds = options.treeId;
                    end
                    for treeId = treeIds
                        if treeId > obj.noTrees; error('the treeId is too large'); end
                        [curTree, nodeIds, EdgesTable, NodesTable] = obj.getTree(treeId);
                        %if numel(treeIds) == 1
                        %    nodesCount = min(EdgesTable.EndNodes(:))-1;
                        %end
                        TreeName = NodesTable.TreeName(1,:);
                        s(dy1, 1) = TreeName;
                        noRows = size(NodesTable, 1);
                        s(dy1:dy1+noRows-1, 2) = num2cell(nodeIds);
                        s(dy1:dy1+noRows-1, 3) = NodesTable.TreeName;
                        s(dy1:dy1+noRows-1, 4) = NodesTable.NodeName;
                        s(dy1:dy1+noRows-1, 5:7) = [num2cell(NodesTable.PointsXYZ(:,1)), num2cell(NodesTable.PointsXYZ(:,2)), num2cell(NodesTable.PointsXYZ(:,3))];
                        NodesTable.TreeName = [];
                        NodesTable.NodeName = [];
                        NodesTable.PointsXYZ = [];
                        [~, noCols] = size(NodesTable);
                        s(dy1:dy1+noRows-1, 8:8+noCols-1) = table2cell(NodesTable);
                        dy1 = dy1 + noRows;
                        
                        s2(dy2, 1) = TreeName;
                        noRows = size(EdgesTable, 1);
                        s2(dy2:dy2+noRows-1, 2) = num2cell(EdgesTable.EndNodes(:,1));
                        s2(dy2:dy2+noRows-1, 3) = num2cell(EdgesTable.EndNodes(:,2));
                        s2(dy2:dy2+noRows-1, 4) = obj.G.Nodes.NodeName(EdgesTable.EndNodes(:,1)); % NodeNames(EdgesTable.EndNodes(:,1)-nodesCount);
                        s2(dy2:dy2+noRows-1, 5) = obj.G.Nodes.NodeName(EdgesTable.EndNodes(:,2)); %NodeNames(EdgesTable.EndNodes(:,2)-nodesCount);
                        s2(dy2:dy2+noRows-1, 6) = num2cell(EdgesTable.Weight);
                        s2(dy2:dy2+noRows-1, 7) = num2cell(EdgesTable.Length);
                        EdgesTable.EndNodes = [];
                        EdgesTable.Weight = [];
                        EdgesTable.Length = [];
                        EdgesTable.Edges = [];  % do not save Edges
                        [~, noCols] = size(EdgesTable);
                        s2(dy2:dy2+noRows-1, 8:8+noCols-1) = table2cell(EdgesTable);
                        dy2 = dy2 + noRows;
                        %nodesCount = nodesCount + size(NodesTable,1);
                    end
                    
                    if options.showWaitbar; waitbar(.2, wb); end
                    xlswrite2(filename, s, 'Nodes', 'A1');
                    if options.showWaitbar; waitbar(.7, wb); end
                    xlswrite2(filename, s2, 'Edges', 'A1');
                case {'amira-ascii', 'amira-binary'}
                    if strcmp(options.format, 'amira-ascii')
                        amiraOptions.format = 'ascii';
                    else
                        amiraOptions.format = 'binary';
                    end
                    amiraOptions.overwrite = 1;
                    
                    extraNodeFieldsLocal = [];
                    extraEdgeFieldsLocal = [];
                    
                    if ~isempty(obj.extraNodeFields)
                        extraNodeFieldsLocal = obj.extraNodeFields(obj.extraNodeFieldsNumeric>0);
                    end
                    if ~isempty(obj.extraEdgeFields)
                        extraEdgeFieldsLocal = obj.extraEdgeFields(obj.extraEdgeFieldsNumeric>0);
                    end
                    
                    if ~isempty(extraEdgeFieldsLocal) || ~isempty(extraNodeFieldsLocal)
                        if ~isfield(options, 'NodeFieldName') || ~isfield(options, 'EdgeFieldName')
                            % add default fields
                            extraEdgeFieldsLocal = [{'Length'; 'Weight'}; extraEdgeFieldsLocal];
                            extraNodeFieldsLocal = [{'Radius'}; extraNodeFieldsLocal];
                            
                            if numel(extraNodeFieldsLocal) < 2
                                prompts = {'Field for nodes:'; 'Field for edges:'};
                                defAns = {[extraNodeFieldsLocal; 1]; extraEdgeFieldsLocal};
                            else
                                prompts = {'First field for nodes:'; 'Second field for nodes:'; 'Field for edges:'};
                                defAns = {[extraNodeFieldsLocal; 1]; ...
                                    [extraNodeFieldsLocal; 1]; ...
                                    extraEdgeFieldsLocal};
                            end
                            dlgTitle = 'Export to Amira';
                            options.WindowStyle = 'normal';       % [optional] style of the window
                            options.Title = sprintf('Select fields to export\n(only numerical fields can be exported)');
                            options.TitleLines = 2;
                            options.Focus = 1;      % [optional] define index of the widget to get focus
                            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                            if isempty(answer); return; end
                            if numel(extraNodeFieldsLocal) < 2
                                outputFieldNode = extraNodeFieldsLocal(selIndex(1));
                                outputFieldEdge = extraEdgeFieldsLocal(selIndex(2));
                            else
                                outputFieldNode = [extraNodeFieldsLocal(selIndex(1)); extraNodeFieldsLocal(selIndex(2))];
                                outputFieldEdge = extraEdgeFieldsLocal(selIndex(3));
                            end
                        else
                            outputFieldNode = options.NodeFieldName;
                            outputFieldEdge = options.EdgeFieldName;
                        end
                    else
                        outputFieldNode = {'Radius'};
                        outputFieldEdge = {'Weight'};
                        if isfield(options, 'EdgeFieldName')
                            if strcmp(options.EdgeFieldName, 'Length')
                                outputFieldEdge = {'Length'};
                            end
                        end
                    end
                    amiraOptions.NodeFieldName = outputFieldNode;
                    amiraOptions.EdgeFieldName = outputFieldEdge;
                    if options.showWaitbar; waitbar(.1, wb); end
                    
                    Graph.G.Nodes.XData = Graph.G.Nodes.PointsXYZ(:,1);
                    Graph.G.Nodes.YData = Graph.G.Nodes.PointsXYZ(:,2);
                    Graph.G.Nodes.ZData = Graph.G.Nodes.PointsXYZ(:,3);
                    %Graph.G.Nodes = removevars(Graph.G.Nodes, 'PointsXYZ');     % remove PointsXYZ
                    Graph.G.Nodes.PointsXYZ = [];   % remove PointsXYZ
                    
                    % generate points for edge segments
                    % require to have two points (starting and ending) for each
                    % edge
                    Graph.G.Edges.Points = repmat({zeros([2 6])}, [size(Graph.G.Edges,1) 1]);
                    if options.showWaitbar; waitbar(.2, wb); end
                    for edgeId = 1:size(Graph.G.Edges,1)
                        id1 = Graph.G.Edges.EndNodes(edgeId,1);
                        id2 = Graph.G.Edges.EndNodes(edgeId,2);
                        Graph.G.Edges.Points{edgeId, :} = ...
                            [Graph.G.Nodes.XData([id1 id2]), Graph.G.Nodes.YData([id1 id2]), Graph.G.Nodes.ZData([id1 id2])];
                    end
                    if options.showWaitbar; waitbar(.3, wb); end
                    graph2amiraSpatialGraph(filename, Graph.G, amiraOptions);
                otherwise
            end
            if options.showWaitbar; waitbar(1, wb); end
            if options.showWaitbar; delete(wb); end
        end
        
        
    end
end
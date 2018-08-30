function res = graph2amiraSpatialGraph(filename, G, options)
% function res = graph2amiraSpatialGraph(filename, G, options)
% generate Amira Spatial Graph Ascii file
%
% Parameters:
% filename: filename to save data
% G: a standard matlab graph object, see 'graph' function for details, with the following properties
% @li .Nodes - a table with following columns,
%   .XData - x coordinate of the node
%   .YData - y coordinate of the node
%   .ZData - z coordinate of the node
%   .PointsXYZ - alternative way (instead of XData, YData, ZData) to
%   specify the points. In this case is is a matrix [nodeId][x,y,z]
%   .Values - [@em optional] values for the nodes
% @li .Edges - a table with following columns,
%   .EndNodes - connectivity matrix for the nodes starting from 0
%   .Points - [@em optional] a cell array with coordinates of points for each of the edges, in minimalistic
%   case should have at least 2 points, starting and ending; format {edgeId}[pointId, x y z]
%   .Thickness - [@em optional] a cell array with thickness at each point of a node; format {edgeId}[pointId, thickness]
% options: - a structure with additional options
%   .overwrite - 1-automatically overwrite existing files
%   .format - a string with format: 'binary' or 'ascii'
%   .NodeFieldName - a cell array (max 2 elements) that specify which Field in the .Nodes to export, in this case Nodes.Values is not needed
%   .EdgeFieldName - a cell that specify which Field in the .Edges to export, in this case Edges.Thickness is not needed
%   
% Return values:
% res: result of the function run, @b 1 - success, @b 0 - fail

%| 
% @b Examples:
% @code 
% G = graph([1 2 4],[2 3 5]);   // creates a graph with five nodes and three edges: 1-2-4 and 3-5
% G.Nodes.XData = [1 2 3 4 5]';  // x coordinates of each node
% G.Nodes.YData = [5 4 3 2 5]';   // y coordinates of each node
% G.Nodes.ZData = [1 3 4 2 5]';  // z coordinates of each node
% G.Nodes.Values = [1 2 4 2 5]';  // value for each node
% G.Nodes.Values2 = [5 4 3 2 1]';  // optional second value for each node
% G.Edges.Thickness = ones([size(G.Edges,1) 1]);  // thickness value for the edges
% figure(1);  // test results
% p = plot(G); 
% p.XData = G.Nodes.XData;
% p.YData = G.Nodes.YData;
% p.ZData = G.Nodes.ZData;
% options.NodeFieldName = [{'Values'}, {'Values2'}]; // name of variables that should be exported for nodes
% options.EdgeFieldName = {'Thickness'};    // name of variables that should be exported for edges
% res = graph2amiraSpatialGraph('test.am', G, options);    // save to a file
% @endcode

% Copyright (C) 29.03.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

res = 0;

if nargin < 3
    options = struct();
end
if nargin < 2
    errordlg('graph2amiraSpatialGraph: Please provide filename for the Spatial Graph and graph with the data data!', 'Missing parameters');
    return;
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'format'); options.format = 'ascii'; end
if ~isfield(options, 'NodeFieldName'); options.NodeFieldName = {'Values'}; end
if ~isfield(options, 'EdgeFieldName'); options.EdgeFieldName = {'Thickness'}; end

if options.overwrite == 0
    if exist(filename,'file') == 2
        button = questdlg(sprintf('The file already exist!!!\nOverwrite?'), 'Overwrite', 'Yes', 'No', 'No');
        if strcmp(button, 'No'); return; end
    end
end

if ~ismember('Points', G.Edges.Properties.VariableNames)
    % generate points for each edge, in the minimalistic case there should
    % be two points that belong to two nodes that form the edge
    PointsCloud = zeros([size(G.Edges,1)*2, 3]);
    if ismember('PointsXYZ', G.Nodes.Properties.VariableNames)
        G.Nodes.XData = G.Nodes.PointsXYZ(:,1);
        G.Nodes.YData = G.Nodes.PointsXYZ(:,2);
        G.Nodes.ZData = G.Nodes.PointsXYZ(:,3);
        G.Nodes.PointsXYZ = [];
    end
    for objId2 = 1:size(G.Edges,1)
        id1 = G.Edges.EndNodes(objId2,1);
        id2 = G.Edges.EndNodes(objId2,2);
        PointsCloud(objId2*2-1:objId2*2,:) = [G.Nodes.XData([id1 id2]), G.Nodes.YData([id1 id2]), G.Nodes.ZData([id1 id2])];
    end
    PointsPerEdge = zeros([size(G.Edges,1),1])+2;
else
    PointsCloud = cell2mat(G.Edges.Points);     % extract points to a matrix
    PointsPerEdge = cellfun(@(x) size(x,1), G.Edges.Points);    % get number of points per edge
end

if ~ismember(options.EdgeFieldName{1}, G.Edges.Properties.VariableNames)
    Thickness = zeros([size(PointsCloud,1), 1])+1;
else
    % repeat thickness twice to accomodate for number of points
    PointsPerEdgeUnique = unique(PointsPerEdge);
    if numel(PointsPerEdgeUnique) == 1
        Thickness = repelem(G.Edges.(options.EdgeFieldName{1}), PointsPerEdgeUnique);
    else
        Thickness = repelem(G.Edges.(options.EdgeFieldName{1}), PointsPerEdge);
    end
end

% nodes should start from 0 in Amira
minEdgeIndex = min(G.Edges.EndNodes(:));

fid = fopen(filename,'w');
if strcmp(options.format, 'ascii')
    fprintf(fid,'# AmiraMesh 3D ASCII 2.0\n');
else
    fprintf(fid,'# AmiraMesh BINARY-LITTLE-ENDIAN 2.1\n');
end
fprintf(fid,'\n\n');

fprintf(fid,'define VERTEX %d\n', size(G.Nodes, 1));
fprintf(fid,'define EDGE %d\n', size(G.Edges, 1));
fprintf(fid,'define POINT %d\n', size(PointsCloud,1));
fprintf(fid,'\n');
fprintf(fid,'Parameters {\n');
fprintf(fid,'\tSpatialGraphUnitsVertex {\n');
fprintf(fid,'\t}\n');
fprintf(fid,'\tSpatialGraphUnitsEdge {\n');
fprintf(fid,'\t}\n');
fprintf(fid,'\tSpatialGraphUnitsPoint {\n');
fprintf(fid,'\t\t%s {\n', options.EdgeFieldName{1});
fprintf(fid,'\t\t\tUnit 1,\n');
fprintf(fid,'\t\t\tDimension 1\n');
fprintf(fid,'\t\t}\n');
fprintf(fid,'\t}\n');
fprintf(fid,'\tContentType "HxSpatialGraph"\n');
fprintf(fid,'}\n');
fprintf(fid,'\n');

fprintf(fid,'VERTEX { float[3] VertexCoordinates } @1\n');
fprintf(fid,'EDGE { int[2] EdgeConnectivity } @2\n');
fprintf(fid,'EDGE { int NumEdgePoints } @3\n');
fprintf(fid,'POINT { float[3] EdgePointCoordinates } @4\n');
fprintf(fid,'POINT { float %s } @5\n', options.EdgeFieldName{1});
if ismember(options.NodeFieldName{1}, G.Nodes.Properties.VariableNames)     % there are may be multiple fields: Values, Values2, Values3
    fprintf(fid, 'VERTEX { float %s } @6\n', options.NodeFieldName{1});
end
saveNodeSecondField = 0;   % switch to save or not the second node
if numel(options.NodeFieldName) > 1
    if ismember(options.NodeFieldName{2}, G.Nodes.Properties.VariableNames)     
        fprintf(fid, 'VERTEX { float %s } @7\n', options.NodeFieldName{2});
        saveNodeSecondField = 1;
    end
end

fprintf(fid,'\n');
fprintf(fid,'# Data section follows\n');
fprintf(fid,'@1\n');
if strcmp(options.format, 'ascii')
    % save nodes/vertices
    for i=1:size(G.Nodes, 1)
        fprintf(fid,'%.15e %.15e %.15e\n', G.Nodes.XData(i), G.Nodes.YData(i), G.Nodes.ZData(i));
    end
    
    % save connectivity
    fprintf(fid,'\n@2\n');
    for i=1:size(G.Edges, 1)
        fprintf(fid,'%d %d\n', G.Edges.EndNodes(i,1)-minEdgeIndex, G.Edges.EndNodes(i,2)-minEdgeIndex);
    end
    
    % save number of points for each edge
    fprintf(fid,'\n@3\n');
    for i=1:size(G.Edges, 1)
    	fprintf(fid, '%d\n', PointsPerEdge(i));
    end
    
    % save coordinates of points for each edge
    fprintf(fid,'\n@4\n');
    for i=1:size(PointsCloud,1)
        fprintf(fid,'%.15f %.15f %.15f\n', PointsCloud(i,1), PointsCloud(i,2), PointsCloud(i,3));
    end
    
    % save thickness at each point of the edge
    fprintf(fid,'\n@5\n');
    Thickness = Thickness'; % transpose thickness to have coorect indexing
    for i=1:numel(Thickness)
        %fprintf(fid,'%.15e\n', Thickness(i));
        fprintf(fid,'%f\n', Thickness(i));
    end
    
    % save values to a file
    if ismember(options.NodeFieldName{1}, G.Nodes.Properties.VariableNames)
        fprintf(fid,'\n@6\n');
        for i=1:size(G.Nodes, 1)
            fprintf(fid,'%.15f\n', G.Nodes.(options.NodeFieldName{1})(i));
        end
    end
    
    if saveNodeSecondField
        fprintf(fid,'\n@7\n');
        for i=1:size(G.Nodes, 1)
            fprintf(fid,'%.15f\n', G.Nodes.(options.NodeFieldName{2})(i));
        end
    end
else
    % save nodes/vertices
    for i=1:size(G.Nodes, 1)
        fwrite(fid, [G.Nodes.XData(i), G.Nodes.YData(i), G.Nodes.ZData(i)], 'float32', 0, 'l');
    end
    
    % save connectivity
    fprintf(fid,'\n@2\n');
    for i=1:size(G.Edges, 1)
        fwrite(fid, G.Edges.EndNodes(i,:)-minEdgeIndex, 'int', 0, 'l');
    end
    
    % save number of points for each edge
    fprintf(fid,'\n@3\n');
    for i=1:size(G.Edges, 1)
    	fwrite(fid, PointsPerEdge(i), 'int', 0, 'l');
    end
   
    % save coordinates of points for each edge
    fprintf(fid,'\n@4\n');
    for i=1:size(PointsCloud,1)
        fwrite(fid, PointsCloud(i,:), 'float32', 0, 'l');
    end
    
    % save thickness at each point of the edge
    fprintf(fid,'\n@5\n');
    fwrite(fid, Thickness', 'float32', 0, 'l');
    
    % save values to a file
    if ismember(options.NodeFieldName{1}, G.Nodes.Properties.VariableNames)
        fprintf(fid,'\n@6\n');
        fwrite(fid, G.Nodes.(options.NodeFieldName{1}), 'float32', 0, 'l');
    end
    
    if saveNodeSecondField
        fprintf(fid,'\n@7\n');
        fwrite(fid, G.Nodes.(options.NodeFieldName{2}), 'float32', 0, 'l');
    end
end
fprintf(fid,'\n');

fclose(fid);
res = 1;

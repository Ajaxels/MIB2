function [vertices, facets] = mibTriangulateCurvePair(curve1, curve2, threshold)
% [vertices, facets] = mibTriangulateCurvePair(curve1, curve2, threshold)
% Compute triangulation between a pair of 3D curves
%
% Parameters:
% curve1: point coordinates of the first curve [pointNo][x,y,z]
% curve2: point coordinates of the second curve [pointNo][x,y,z]
% threshold: [@em optional], an optional parameter that it used to define
% threshold for matching ends of two curves. Should be a number that is
% smaller than the closest possible distance between the points. The
% default value is .00000001
%
% Return values:
% vertices: coordinates of vertices
% facets:   connection between the vertices

% Mostly based on triangulateCurvePair.m a part of matGeom by David Legland
% https://github.com/mattools/matGeom
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2017-05-18,    using Matlab 9.1.0.441655 (R2016b)
% Copyright 2017 INRA - Cepia Software Platform.

% Copyright (C) 01.08.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 3; threshold = .00000001; end

%% Memory allocation
% number of vertices on each curve
n1 = size(curve1, 1);
n2 = size(curve2, 1);

% allocate the array of facets (each edge of each curve provides a facet)
nFacets = n1 + n2 - 2;
facets = zeros(nFacets, 3);

%% Init iteration
 
% % look for the closest ends of two curves and reverse the second curve if
% % needed, so that the point1 of vec1 is the closest to
% % the point1 of vec2
% dist = distancePoints(curve1(1, :), curve2(1,:)) - distancePoints(curve1(1, :), curve2(end,:));
% if dist > threshold
%     curve2 = curve2(end:-1:1,:);    % invert the second curve
% elseif dist > 0
%     if distancePoints(curve1(end, :), curve2(end,:)) > distancePoints(curve1(end, :), curve2(1,:))
%         curve2 = curve2(end:-1:1,:);    % invert the second curve
%     end
% end

dist1 = distancePoints(curve1(1, :), curve2(1,:)) + distancePoints(curve1(end, :), curve2(end,:));
dist2 = distancePoints(curve1(1, :), curve2(end,:)) + distancePoints(curve1(end, :), curve2(1,:));
if dist1 > dist2
    curve2 = curve2(end:-1:1,:);    % invert the second curve
end

currentIndex1 = 1;
currentIndex2 = 1;

% concatenate vertex coordinates for creating mesh
vertices = [curve1 ; curve2];

%% Main iteration
% For each diagonal, consider the two possible facets (one for each 'next'
% vertex on each curve), each create current facet according to the closest
% one.
% Then update current diagonal for next iteration.

for i = 1:nFacets
    nextIndex1 = mod(currentIndex1, n1) + 1;
    nextIndex2 = mod(currentIndex2, n2) + 1;
    
    if nextIndex1 > 1 && nextIndex2 > 1
        % compute lengths of diagonals
        dist1 = distancePoints(curve1(currentIndex1, :), curve2(nextIndex2,:));
        dist2 = distancePoints(curve1(nextIndex1, :), curve2(currentIndex2,:));
        if dist1 <= dist2
            % keep current vertex of curve1, use next vertex on curve2
            facet = [currentIndex1 currentIndex2+n1 nextIndex2+n1];
            currentIndex2 = nextIndex2;
        else
            % keep current vertex of curve2, use next vertex on curve1
            facet = [currentIndex1 currentIndex2+n1 nextIndex1];
            currentIndex1 = nextIndex1;
        end
    elseif nextIndex2 > 1
        facet = [currentIndex1 currentIndex2+n1 nextIndex2+n1];
        currentIndex2 = nextIndex2;
    elseif nextIndex1 > 1
        facet = [currentIndex1 currentIndex2+n1 nextIndex1];
        currentIndex1 = nextIndex1;      
    end
    
    % create the facet
    facets(i, :) = facet;
end


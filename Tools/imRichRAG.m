function varargout = imRichRAG(img, varargin)
% IMRICHRAG Region adjacency graph of a labeled image with edge infos,
% originating from the imRAG function
%
%   Usage:
%   ADJ = imRichRAG(IMG);
%   computes region adjacencies graph of labeled 2D or 3D image IMG. 
%   The result is a N*2 array, containing 2 indices for each couple of
%   neighbor regions. Two regions are considered as neighbor if they are
%   separated by a black   (i. e. with color 0) pixel in the horizontal or
%   vertical direction.
%   ADJ has the format [LBL1 LBL2], LBL1 and LBL2 being vertical arrays the
%   same size.
%
%   LBL1 is given in ascending order, LBL2 is given in ascending order for
%   each LBL1. Ex:
%   [1 2]
%   [1 3]
%   [1 4]
%   [2 3]
%   [2 5]
%   [3 4]
%
%   [ADJ, BORDER_IDXS] = imRichRAG(IMG);
%   Return two arrays:  ADJ is the adjacency previously described;
%   BORDER_IDXS a cell array of image indices that belong to the border
%   that separates two adjacent regions, implemented for GAP==1
%
%   [ADJ, MEAN_INTENSITY] = imRichRAG(IMG, 1, IMG2);
%   Return two arrays:  ADJ is the adjacency previously described;
%   MEAN_INTENSITY an array of mean intensity of IMG2 between each two
%   adjacent superpixels, 1 - is gap between superpixels, IMG2 - the image
%   to be used for MEAN_INTENSITY calculation
%
%   [ADJ, BORDER_IDXS, NODES] = imRichRAG(IMG);
%   Return three arrays: ADJ is the adjacency; BORDER_IDXS - border
%   indices; NODES [N*2] array containing centroids
%   of the N labeled region, For 3D images, the nodes array is [N*3].
%   
%   Example  (requires image processing toolbox)
%     % read and display an image with several objects
%     img = imread('coins.png');
%     figure(1); clf;
%     imshow(img); hold on; 
%     % compute the Skeleton by influence zones using watershed
%     bin = imfill(img>100, 'holes');
%     dist = bwdist(bin);
%     wat = watershed(dist, 4);
%     % compute overlay image for display
%     tmp = uint8(double(img).*(wat>0));
%     ovr = uint8(cat(3, max(img, uint8(255*(wat==0))), tmp, tmp));
%     imshow(ovr);
%     % show the resulting graph
%     [edgeList, edgeIndsList, nodeList] = imRichRAG(wat);
%     % allocate memory for results, still using 2 columns
%     nEdges = size(edgeList, 1);
%     stats2 = zeros(nEdges, 2);
% 
%     % for each edge, grablist of indices, compute length an average value
%     % within grayscale image
%     for iEdge = 1:nEdges
%       inds = edgeIndsList{iEdge};
%       stats2(iEdge, 3) = length(inds);
%       stats2(iEdge, 4) = mean(img(inds));
%     end
% 
%   % display result using blank image as background
%   figure; imshow(ones(size(img)));
%   hold on;
%   for iEdge = 1:size(edgeList, 1)
%       edge = edgeList(iEdge,:);
%       plot(nodeList(edge, 1), nodeList(edge, 2), 'linewidth', 1, 'color', 'b');
%       pos = (nodeList(edge(1), :) + nodeList(edge(2), :)) / 2;
%       text(pos(1)+2, pos(2)+2, sprintf('%d', stats2(iEdge, 3)));
%   end
%
%
%   % Create a basic 3D image with labels, and compute RAG
%     germs = [50 50 50;...
%         20 20 20;80 20 20;20 80 20;80 80 20; ...
%         20 20 80;80 20 80;20 80 80;80 80 80];
%     img = zeros([100 100 100]);
%     for i = 1:size(germs, 1)
%         img(germs(i,1), germs(i,2), germs(i,3)) = 1;
%     end
%     wat = watershed(bwdist(img), 6);
%     [edgeList, edgeIndsList, nodeList] = imRichRAG(wat);
%     figure; drawGraph(nodeList, edgeList);
%     view(3);
%

% ------
% Author: David Legland
% e-mail: david.legland@nantes.inra.fr
% Created: 2015-10-22,  
% Copyright 2007 INRA - BIA PV Nantes - MIAJ Jouy-en-Josas.

%   History
%   2007-10-12 update doc
%   2007-10-17 add example
%   2010-03-08 replace calls to regionprops by local centroid computation
%   2010-07-29 update doc
%   2012-07-20 remove the use of "diff", using less memory
%   2015-10-22 made from the imRAG function
%   2015-10-23 Ilya Belevich has adjusted and modified to use a new version
%               of the code to detect border indices for 3D
%   2015-11-05 Ilya Belevich added the 3rd input parameter, that is image
%               to be used for calculation of mean intensities between each superpixel
%
%% Initialisations
% size of image
dim = size(img);

% number of dimensions
nd = length(dim);

% Number of background pixels or voxels between two regions
% gap = 0 -> regions are contiguous
% gap = 1 -> there is a 1-pixel large line or surface between two adjacent
% 	pixels, for example the result of a watershed
gap = 1;
if ~isempty(varargin) && isnumeric(varargin{1})
    gap = varargin{1};
end
shift = gap + 1;

if nd == 2
    %% First direction of 2D image
    
    % identify transitions
    [i1, i2] = find(img(1:end-shift,:) ~= img((shift+1):end, :));
    
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2));
	val2 = img(sub2ind(dim, i1+shift, i2));

    % keep only changes not involving background, ordered such that n1 < n2
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    %edges = unique([val1(inds) val2(inds)], 'rows');
    edges = sort([val1(inds) val2(inds)], 2);

    % keep array of positions as linear indices
    posD1 = sub2ind(dim, i1(inds)+1, i2(inds));

    %% Second direction of 2D image
    
    % identify transitions
    [i1, i2] = find(img(:, 1:end-shift) ~= img(:, (shift+1):end));
    
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2));
	val2 = img(sub2ind(dim, i1, i2+shift));
    
    % keep only changes not involving background, ordered such that n1 < n2
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    % edges = [edges; unique([val1(inds) val2(inds)], 'rows')];
    edges = [edges ; sort([val1(inds) val2(inds)], 2)];
    
    % keep array of positions as linear indices
    posD2 = sub2ind(dim, i1(inds), i2(inds)+1);

    posList = [posD1 ; posD2];
    
elseif nd == 3
    %% First direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[shift 0 0], ...
        find(img(1:end-shift,:,:) ~= img((shift+1):end,:,:)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
	val2 = img(sub2ind(dim, i1+shift, i2, i3));

    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    
    % edges = unique([val1(inds) val2(inds)], 'rows');
    edges = sort([val1(inds) val2(inds)], 2);

    % keep array of positions as linear indices
    posD1 = sub2ind(dim, i1(inds)+1, i2(inds), i3(inds));

    %% Second direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[0 shift 0], ...
        find(img(:,1:end-shift,:) ~= img(:,(shift+1):end,:)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
	val2 = img(sub2ind(dim, i1, i2+shift, i3));

    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    % edges = [edges; unique([val1(inds) val2(inds)], 'rows')];
    edges = [edges ; sort([val1(inds) val2(inds)], 2)];
    
    % keep array of positions as linear indices
    posD2 = sub2ind(dim, i1(inds), i2(inds)+1, i3(inds));

    
    %% Third direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[0 0 shift], ...
        find(img(:,:,1:end-shift) ~= img(:,:,(shift+1):end)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
    val2 = img(sub2ind(dim, i1, i2, i3+shift));
    
    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    %edges = [edges; unique([val1(inds) val2(inds)], 'rows')];
    edges = [edges ; sort([val1(inds) val2(inds)], 2)];
    
    % keep array of positions as linear indices
    posD3 = sub2ind(dim, i1(inds), i2(inds), i3(inds)+1);

    posList = [posD1; posD2; posD3];
end

%%
% remove double edges, keeping in indsC indices of merged edge for each
% original edge
[edges, indsA, indsC] = unique(edges, 'rows'); %#ok<ASGLU>
if nd == 2
    % Original code, may be used for 2D cases
    nEdges = size(edges, 1);
    % original FOR loop - FASTEST FOR 2D
    if nargin==3    % when 3rd input parameter present return mean internsity at the edges between superpixels
        edgeInds = zeros(nEdges, 1);  % allocate space
        intImage = varargin{2};     % get image
        for iEdge = 1:nEdges        % when using parfor 1.889 times faster
            inds = indsC == iEdge;
            edgeInds(iEdge) = mean(intImage(posList(inds)));
        end
    else            % when the 3rd input parameter is missing return indices of borders
        edgeInds = cell(nEdges, 1);
        for iEdge = 1:nEdges        % when using parfor 1.889 times faster
            inds = indsC == iEdge;
            %edgeInds{iEdge} = unique(posList(inds));
            edgeInds{iEdge} = posList(inds);
        end
    end
else
    % % % Alternative version 2, faster than the FOR Loop especially for 3D cases
    [B,I] = sort(indsC);
    dB = diff(B);
    inds = [0; find(dB==1)];
    noInd = numel(inds);
    if nargin==3    % when 3rd input parameter present return mean internsity at the edges between superpixels
        edgeInds = zeros(noInd,1);  % allocate space
        intImage = varargin{2};     % get image
        for iEdge=2:noInd
            edgeInds(iEdge-1) = mean(intImage(posList(I(inds(iEdge-1)+1:inds(iEdge)))));
        end
        edgeInds(end) = mean(intImage(posList(I(inds(iEdge)+1:end))));
    else            % when the 3rd input parameter is missing return indices of borders
        edgeInds = cell(noInd,1);
        for iEdge=2:noInd
            edgeInds{iEdge-1} = posList(I(inds(iEdge-1)+1:inds(iEdge)));
        end
        edgeInds{end} = posList(I(inds(iEdge)+1:end));
    end
end
% % % Alternative version 2, faster for 3D than original, but not as good
% as alternative 1
% inds = arrayfun(@(i) find(indsC==i), 1:nEdges, 'UniformOutput', 0);
% %edgeInds = cellfun(@(idx) unique(posList(idx)), inds, 'UniformOutput', 0);
% edgeInds = cellfun(@(idx) posList(idx), inds, 'UniformOutput', 0);
%
% check and compare results, for tests
% D = 0;
% for i=1:nEdges
%     D = D + abs(sum(edgeInds2{i}) - sum(edgeInds{i}));
% end

%% Output processing

if nargout == 1
    varargout{1} = edges;
elseif nargout == 2
    varargout{1} = edges;
    varargout{2} = edgeInds;
elseif nargout == 3
    % Also compute region centroids
    N = max(img(:));
    points = zeros(N, nd);
    labels = unique(img);
    labels(labels==0) = [];
    
    if nd == 2
        % compute 2D centroids
        for i = 1:length(labels)
            label = labels(i);
            [iy, ix] = ind2sub(dim, find(img==label));
            points(label, 1) = mean(ix);
            points(label, 2) = mean(iy);
        end
    else
        % compute 3D centroids
        for i = 1:length(labels)
            label = labels(i);
            [iy, ix, iz] = ind2sub(dim, find(img==label));
            points(label, 1) = mean(ix);
            points(label, 2) = mean(iy);
            points(label, 3) = mean(iz);
        end
    end
    
    % setup output arguments
    varargout{1} = edges;
    varargout{2} = edgeInds;
    varargout{3} = points;
end
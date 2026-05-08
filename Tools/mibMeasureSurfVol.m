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
% Date: 24.04.2026

function results = mibMeasureSurfVol(fvArray, materialNames, outputFilename, options)
% function results = mibMeasureSurfVol(fvArray, materialNames, outputFilename, options)
% Compute surface area and volume of triangular meshes with automatic
% connected-component (per-object) analysis. Each material may contain
% multiple disconnected objects; every object is reported on its own row
% together with a closure flag, surface area, and volume.
%
% =========================================================================
% METHODS
% =========================================================================
%
% Surface area
%   For each triangle with vertices v1, v2, v3 the area equals half the
%   magnitude of the cross product of two edge vectors:
%
%       A_i = 0.5 * ||(v2 - v1) x (v3 - v1)||
%
%   The total surface area of an object is the sum of all its triangle
%   areas.  No assumptions about mesh topology are required; the formula
%   is valid for both closed and open meshes.
%
% Volume — closed (watertight) meshes  [exact]
%   For a closed triangular mesh the divergence theorem lets us express the
%   enclosed volume as a sum of signed tetrahedra, each formed by one
%   triangle and the coordinate origin:
%
%       V = | sum_i  v1_i . (v2_i x v3_i) | / 6
%
%   Because the divergence theorem applies to closed surfaces, the result
%   is independent of the choice of origin and gives the exact enclosed
%   volume.  Reference: Zhang & Chen (2001) "Efficient feature extraction
%   for 2D/3D objects in mesh representation", ICASSP.
%
% Volume — open (non-closed) meshes  [approximation only]
%   An open mesh has at least one boundary edge (an edge belonging to
%   exactly one triangle) — for example a hemisphere, a flat disc, or a
%   mesh with small holes.  When the divergence-theorem formula is applied
%   to an open mesh the "missing" faces are not accounted for, so the
%   result depends on the position of the mesh relative to the coordinate
%   origin and does NOT represent a physically meaningful enclosed volume.
%
%   The value reported for open meshes (when volumeType is 'both' or
%   'open_only') is this raw divergence-theorem integral.  It can serve
%   as a rough approximation when the mesh is *nearly* closed (e.g. very
%   small holes), but should be interpreted with caution.  Open objects
%   are always flagged in the IsClosed column so they can be filtered out.
%
% Closed-mesh detection
%   A triangular mesh (or connected component thereof) is watertight if
%   and only if every edge is shared by exactly two faces.  Boundary edges
%   (one face) and non-manifold edges (three or more faces) break closure.
%   The check builds a sorted edge list and uses accumarray to count edge
%   multiplicities in O(E log E) time.
%
% Connected-component analysis
%   Disconnected objects within a single material are found by building an
%   undirected graph whose nodes are mesh vertices and whose edges
%   correspond to triangle edges, then calling MATLAB's conncomp function
%   (Graph and Network Algorithms, available since R2015b).  Each component
%   receives its own ObjectId (1-based, restarting for each material).
%
% =========================================================================
% Parameters:
% fvArray: cell array of structs; each element represents one material and
%   must contain:
%   @li .faces    [Nf x 3] array of 1-based vertex indices (double or integer)
%   @li .vertices [Nv x 3] array of vertex coordinates in physical units
%   A single struct (not wrapped in a cell) is also accepted.
% materialNames: cell array of strings, one per element of fvArray.
%   A single string is also accepted.
% outputFilename: string, full path WITHOUT file extension; the appropriate
%   extension (.xlsx / .csv / .mat) is appended automatically based on
%   options.outputFormat.  Pass [] or '' to skip file output.
% options: [@em optional] struct with any combination of the following:
%   @li .outputFormat - string: output file format
%                       'excel'  (default) — writes an .xlsx file
%                       'csv'              — writes a .csv file
%                       'matlab'           — saves the results table as .mat
%   @li .calculate    - string: which measurements to perform
%                       'both'    (default) — surface area and volume
%                       'surface'           — surface area only
%                       'volume'            — volume only
%   @li .volumeType   - string: which objects receive a volume value
%                       'both'        (default) — all objects; open-mesh
%                                     volumes are approximate (see above)
%                       'closed_only'          — exact volume for closed
%                                     objects; NaN for open objects
%                       'open_only'            — approximate volume for
%                                     open objects; NaN for closed objects
%   @li .units        - string: physical unit label used in column headers
%                       (default: 'pixel').  The micro symbol µ is
%                       automatically replaced by 'u' for file compatibility.
%   @li .showWaitbar  - logical: show a progress waitbar (default: false)
%
% Return values:
% results: MATLAB table with one row per detected object:
%   MaterialName  string   name of the material
%   ObjectId      integer  1-based index of this object within its material
%   IsClosed      logical  true if the object mesh is watertight
%   SurfaceArea   double   in units^2; NaN when options.calculate = 'volume'
%   Volume        double   in units^3; NaN when not calculated or not
%                          applicable under the chosen volumeType
%
% =========================================================================
% EXAMPLE
% =========================================================================
%   % ---- single closed unit cube (6 faces x 2 triangles each = 12 tri) ----
%   vertices = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
%   faces    = [1 2 3; 1 3 4; ...  % bottom
%               5 7 6; 5 8 7; ...  % top
%               1 6 2; 1 5 6; ...  % front
%               2 6 7; 2 7 3; ...  % right
%               3 7 8; 3 8 4; ...  % back
%               4 8 5; 4 5 1];     % left
%   fv.faces    = faces;
%   fv.vertices = vertices;
%
%   options.outputFormat = 'excel';
%   options.calculate    = 'both';
%   options.volumeType   = 'both';
%   options.units        = 'um';
%
%   results = mibMeasureSurfVol({fv}, {'Cube'}, 'C:/tmp/cube_stats', options);
%   disp(results)
%   % Expected: IsClosed = true, SurfaceArea = 6.0, Volume = 1.0
%
%   % ---- two separate spheres stored in the same material ----------------
%   % (use isosurface to build fv, then concatenate; conncomp will split them)
%   results2 = mibMeasureSurfVol({fvTwoSpheres}, {'Cell'}, 'C:/tmp/cells', options);
%   % results2 will contain two rows, ObjectId 1 and 2
%
% See also: mibRenderModel, mibImage.saveModel, graph, conncomp, isosurface

% Updates
%

%% -----------------------------------------------------------------------
%  Input handling and defaults
%% -----------------------------------------------------------------------
if nargin < 4; options = struct(); end
if nargin < 3; outputFilename = []; end

if ~iscell(fvArray);       fvArray       = {fvArray};       end
if ~iscell(materialNames); materialNames = {materialNames}; end

if numel(fvArray) ~= numel(materialNames)
    error('mibMeasureSurfVol: fvArray and materialNames must have the same number of elements');
end

if ~isfield(options, 'outputFormat'); options.outputFormat = 'excel';  end
if ~isfield(options, 'calculate');    options.calculate    = 'both';   end
if ~isfield(options, 'volumeType');   options.volumeType   = 'both';   end
if ~isfield(options, 'units');        options.units        = 'pixel';  end
if ~isfield(options, 'showWaitbar');  options.showWaitbar  = false;    end

calcSurface = ismember(options.calculate, {'surface', 'both'});
calcVolume  = ismember(options.calculate, {'volume',  'both'});

% sanitise units string (µ → u) so column headers are file-safe
unitsStr = strrep(options.units, char(181), 'u');

%% -----------------------------------------------------------------------
%  Output accumulators
%% -----------------------------------------------------------------------
outMaterialName = {};
outObjectId     = [];
outIsClosed     = logical([]);
outSurfaceArea  = [];
outVolume       = [];

if options.showWaitbar
    wb = waitbar(0, 'Processing materials...', 'Name', 'mibMeasureSurfVol', 'WindowStyle', 'modal');
    wb.Children.Title.Interpreter = 'none';
end

%% -----------------------------------------------------------------------
%  Main loop — one iteration per material
%% -----------------------------------------------------------------------
for matIdx = 1:numel(fvArray)
    if options.showWaitbar
        waitbar((matIdx - 1) / numel(fvArray), wb, ...
            sprintf('Material %d/%d: %s', matIdx, numel(fvArray), materialNames{matIdx}));
        drawnow;
    end

    fv      = fvArray{matIdx};
    matName = materialNames{matIdx};

    % ensure face indices are double for graph/indexing operations
    faces  = double(fv.faces);
    nVerts = size(fv.vertices, 1);

    % -----------------------------------------------------------------
    % Find connected components (individual objects within this material)
    % -----------------------------------------------------------------
    allEdges = [faces(:,1), faces(:,2); ...
                faces(:,2), faces(:,3); ...
                faces(:,1), faces(:,3)];
    G    = graph(allEdges(:,1), allEdges(:,2), [], nVerts);
    bins = conncomp(G);   % bins(v) = component index of vertex v
    numObj = max(bins);

    for objId = 1:numObj
        % isolate faces whose three vertices all belong to this component
        faceMask = bins(faces(:,1)) == objId & ...
                   bins(faces(:,2)) == objId & ...
                   bins(faces(:,3)) == objId;
        objFaces = faces(faceMask, :);
        if isempty(objFaces); continue; end

        % -------------------------------------------------------------
        % Closed-mesh detection: every edge must be shared by exactly 2 faces
        % -------------------------------------------------------------
        objEdges   = sort([objFaces(:,[1,2]); objFaces(:,[2,3]); objFaces(:,[1,3])], 2);
        [~, ~, ic] = unique(objEdges, 'rows');
        edgeCounts = accumarray(ic, 1);
        isClosed   = all(edgeCounts == 2);

        % retrieve vertex coordinates for this object's triangles
        v1 = fv.vertices(objFaces(:,1), :);
        v2 = fv.vertices(objFaces(:,2), :);
        v3 = fv.vertices(objFaces(:,3), :);

        % -------------------------------------------------------------
        % Surface area  (cross-product formula, valid for any mesh)
        % -------------------------------------------------------------
        if calcSurface
            cp   = cross(v2 - v1, v3 - v1, 2);
            area = 0.5 * sum(sqrt(sum(cp.^2, 2)));
        else
            area = NaN;
        end

        % -------------------------------------------------------------
        % Volume  (divergence theorem / signed-tetrahedra decomposition)
        % -------------------------------------------------------------
        if calcVolume
            rawVol = abs(sum(dot(v1, cross(v2, v3, 2), 2)) / 6);
            switch options.volumeType
                case 'both'
                    vol = rawVol;                               % all objects
                case 'closed_only'
                    vol = nanIfFalse(rawVol, isClosed);         % NaN for open
                case 'open_only'
                    vol = nanIfFalse(rawVol, ~isClosed);        % NaN for closed
                otherwise
                    error('mibMeasureSurfVol: unknown volumeType ''%s''', options.volumeType);
            end
        else
            vol = NaN;
        end

        % accumulate results
        outMaterialName{end+1} = matName;   %#ok<AGROW>
        outObjectId(end+1)     = objId;     %#ok<AGROW>
        outIsClosed(end+1)     = isClosed;  %#ok<AGROW>
        outSurfaceArea(end+1)  = area;      %#ok<AGROW>
        outVolume(end+1)       = vol;       %#ok<AGROW>
    end
end

if options.showWaitbar; delete(wb); end

%% -----------------------------------------------------------------------
%  Build results table
%% -----------------------------------------------------------------------
results = table( ...
    outMaterialName(:), outObjectId(:), outIsClosed(:), outSurfaceArea(:), outVolume(:), ...
    'VariableNames', {'MaterialName', 'ObjectId', 'IsClosed', 'SurfaceArea', 'Volume'});

results.Properties.VariableUnits = {'', '', '', [unitsStr '^2'], [unitsStr '^3']};
results.Properties.VariableDescriptions = { ...
    'Material name', ...
    'Object index within material (1-based, restarted for each material)', ...
    'True when every edge in the object mesh is shared by exactly 2 faces (watertight)', ...
    sprintf('Surface area [%s^2] — sum of triangle areas via cross-product formula', unitsStr), ...
    sprintf(['Volume [%s^3] — exact for closed meshes (divergence theorem); ' ...
             'approximate/origin-dependent for open meshes'], unitsStr)};

%% -----------------------------------------------------------------------
%  Write output files
%% -----------------------------------------------------------------------
if ~isempty(outputFilename)
    areaHeader = sprintf('SurfaceArea_%s2', unitsStr);
    volHeader  = sprintf('Volume_%s3',      unitsStr);

    switch options.outputFormat
        case 'excel';  ext = 'xlsx';
        case 'csv';    ext = 'csv';
        case 'matlab'; ext = 'mat';
        otherwise
            error('mibMeasureSurfVol: unknown outputFormat ''%s''', options.outputFormat);
    end

    % convert logical to 'true'/'false' strings for broad Excel/CSV compat.
    isClosedCell = repmat({'false'}, numel(outIsClosed), 1);
    isClosedCell(outIsClosed) = {'true'};

    % -----------------------------------------------------------------
    % File 1: per-object stats  (_SurfVolObj)
    % -----------------------------------------------------------------
    objHeader = {'MaterialName', 'ObjectId', 'IsClosed', areaHeader, volHeader};
    objRows   = [outMaterialName(:), num2cell(outObjectId(:)), isClosedCell, ...
                 num2cell(outSurfaceArea(:)), num2cell(outVolume(:))];

    outFileObj = sprintf('%s_SurfVolObj.%s', outputFilename, ext);
    if strcmp(ext, 'mat')
        resultsObj = results; save(outFileObj, 'resultsObj'); %#ok<NASGU>
    else
        writecell([objHeader; objRows], outFileObj);
    end
    disp(['mibMeasureSurfVol: per-object results saved to ' outFileObj]);

    % -----------------------------------------------------------------
    % File 2: totals per material  (_SurfVol)
    % -----------------------------------------------------------------
    totHeader = {'MaterialName', 'NumObjects', 'NumClosedObjects', areaHeader, volHeader};
    [uniqueMats, ~, matGroupIdx] = unique(outMaterialName(:), 'stable');
    totRows = cell(numel(uniqueMats), 5);
    for m = 1:numel(uniqueMats)
        mask      = matGroupIdx == m;
        numObjs   = sum(mask);
        numClosed = sum(outIsClosed(mask));
        areas = outSurfaceArea(mask);
        vols  = outVolume(mask);
        if all(isnan(areas)); totalArea = NaN; else; totalArea = sum(areas(~isnan(areas))); end
        if all(isnan(vols));  totalVol  = NaN; else; totalVol  = sum(vols(~isnan(vols)));   end
        totRows(m, :) = {uniqueMats{m}, numObjs, numClosed, totalArea, totalVol};
    end

    outFileTot = sprintf('%s_SurfVol.%s', outputFilename, ext);
    if strcmp(ext, 'mat')
        resultsTot = cell2table(totRows, 'VariableNames', totHeader); %#ok<NASGU>
        save(outFileTot, 'resultsTot');
    else
        writecell([totHeader; totRows], outFileTot);
    end
    disp(['mibMeasureSurfVol: total results saved to ' outFileTot]);
end
end

%% -----------------------------------------------------------------------
%  Local helper: return val when condition is true, NaN otherwise
%% -----------------------------------------------------------------------
function out = nanIfFalse(val, condition)
if condition
    out = val;
else
    out = NaN;
end
end

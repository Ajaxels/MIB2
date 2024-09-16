% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 31.03.2022
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function handles = generateBoxPlot(dataset, label, options)
% function handles = generateBoxPlot(dataset, label, options)
% generate a box plot with points
%
% Parameters:
% dataset - a cell array with datasets
% label - a char array with labels ('Note that the labels should be the same length!'), use char(cell_array) to generate
% options - a structure with optional parameters
% .mode - a string, when 'preview' the plot is scaled to the figure
% .width - plot width in cm
% .height - plot height in cm
% .ylim - a vector with min and max y-value
% .xlabel - label for the x axis
% .ylabel - label for the y axis
% .showpoints - a switch to show or not the data points
% .spereadfactor - a number with a spread factor, from 0 to 1
% .nbins - a number of bins for the points spread
% .figIndex - an index of a figure to plot results
% .fontsize - font size
%
% Return values:
% handles: handle for the figure
%  .hFig - handle of the figure
%  .plotAxes - handle of the axes
%  .h2 - handle of the dot plot
%
% Example
%
% dataset{1} = normrnd(50,2,200,1);
% dataset{2} = normrnd(25,2,200,1);
% label = 'Distribution 1';
% label(2,:) = 'Distribution 2';
% options.xlabel = 'Specimen Id';
% options.ylabel = 'Distribution';
% options.figIndex = 1024;
% hFig = generateBoxPlot(dataset, label, options);


if nargin < 1
    dataset{1} = normrnd(50,2,200,1);
    dataset{2} = normrnd(25,2,200,1);
end

if nargin < 2
    label = repmat('label 001', [numel(dataset), 1]);
    for i=1:numel(dataset)
        label(i, :) = sprintf('label %03d', i);
    end
end

if nargin < 3; options = struct(); end
if ~isfield(options, 'mode'); options.mode = 'preview'; end
if ~isfield(options, 'width'); options.width = 4; end
if ~isfield(options, 'height'); options.height = 5; end
if ~isfield(options, 'ylim'); options.ylim = []; end
if ~isfield(options, 'xlabel'); options.xlabel = []; end
if ~isfield(options, 'ylabel'); options.ylabel = []; end
if ~isfield(options, 'showpoints'); options.showpoints = 1; end
if ~isfield(options, 'spereadfactor'); options.spereadfactor = 0.2; end
if ~isfield(options, 'nbins'); options.nbins = 20; end
if ~isfield(options, 'figIndex'); options.figIndex = 1024; end
if ~isfield(options, 'fontsize'); options.fontsize = []; end


handles.hFig = figure(options.figIndex);
clf;
if ~strcmp(options.mode, 'preview')
    handles.hFig.Units = 'centimeters';
    % -------setup graphic parameters
    bot = 1;
    lef = 1;
    wi = options.width;
    hi = options.height;
    handles.plotAxes = axes('Units', 'centimeters', 'position', [lef bot wi hi]);
else
    handles.plotAxes = axes();
end

% generate vectors with sample values and sample labels
samplesValues = [];
sampleIds = [];
for id = 1:numel(dataset)
    if size(dataset{id}, 1) > size(dataset{id},2)
        samplesValues = [samplesValues, dataset{id}']; %#ok<AGROW>
    else
        samplesValues = [samplesValues, dataset{id}]; %#ok<AGROW>
    end
    sampleIds = [sampleIds; repmat(label(id, :), numel(dataset{id}), 1)]; %#ok<AGROW>
end
boxplot(handles.plotAxes, samplesValues, sampleIds);

if ~isempty(options.ylim); handles.plotAxes.YLim = options.ylim; end
if ~isempty(options.xlabel); xlabel(options.xlabel); end
if ~isempty(options.ylabel); ylabel(options.ylabel); end


if options.showpoints
    hold on;

    % calculate spread of points
    xVec = calculateXSpread(dataset, options.spereadfactor, options.nbins);
    
    for id=1:numel(xVec)
        handles.h2(id) = plot(xVec{id}, dataset{id}, 'o');
        handles.h2(id).MarkerFaceColor = [.5 .5 .5];
        handles.h2(id).MarkerEdgeColor = 'k';
        handles.h2(id).MarkerSize = 3.5;
    end
    set(handles.h2, 'linewidth', .05);
    if ~isempty(options.fontsize)
        handles.plotAxes.FontSize = options.fontsize; 
    end 
    if ~isempty(options.ylim); handles.plotAxes.YLim = options.ylim; end
    %grid;
end
end

function xVec = calculateXSpread(datasets, spereadFactor, nbins)
% function xVec = calculateXSpread(datasets, spereadFactor, nbins)
% calculate spread of the x-points for each series
% 
% Parameters:
% datasets: a cell array with datasets
% spereadFactor: a number [0-1] with a spread factor
% nbins: number of bin points for the histogram

xVec = cell([numel(datasets), 1]);
for id = 1:numel(datasets)
    data = datasets{id};    
    xVec{id} = zeros([numel(data) 1]);
    [N, edgeVals] = histcounts(data, nbins);    
    spread = N./(max(N))*spereadFactor;  
    for binId = 1:numel(N)
        xVec{id}(data>=edgeVals(binId) & data<edgeVals(binId+1)) = ...
            (rand(numel(xVec{id}(data>=edgeVals(binId) & data<edgeVals(binId+1))), 1)-.5)*spread(binId) + id;
    end
end
end




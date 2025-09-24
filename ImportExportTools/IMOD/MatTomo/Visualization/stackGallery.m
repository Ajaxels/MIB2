%stackGallery   Create a gallery of an image stack
%
%   hAxes = stackGallery(stack, interpFactor, flagStrings)
%
%   hAxes       Handles to each of the axes
%
%   stack       The volume to be imaged.
%
%
%   flagStrings:
%     'caxis', [cmin cmax]
%     'grid'
%     'interp', factor
%     'nocolorbar'
%     'noticklabels'
%     'layout', [nR nC]
%     'scalebar', value
%
%   stackGallery displays a gallery of the z planes in the 3D array stack.
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2020/01/02 23:33:44 $
%
%  $Revision: ce44cef00aca $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hAxes = stackGallery(stack, varargin)

interpFactor = 1;
flgCaxis = 0;
flgColorbar = 1;
flgGrid = 0;
flgLayout = 0;
flgTickLabels = 1;
scaleBar = [];

if nargin > 2
  iArg = 1;
  while iArg <= length(varargin)
    switch lower(varargin{iArg})
      case 'caxis'
        flgCaxis = 1;
        iArg = iArg + 1;
        colorAxis = varargin{iArg};
      case 'grid'
        flgGrid = 1;
      case 'interp'
        iArg = iArg + 1;
        interpFactor = varargin{iArg};
      case 'layout'
        flgLayout = 1;
        iArg = iArg + 1;
        layout = varargin{iArg};
      case 'nocolorbar'
        flgColorbar = 0;
      case 'noticklabels'
        flgTickLabels = 0;
      case 'scalebar'
        iArg = iArg + 1;
        scaleBar = varargin{iArg};
      otherwise
        fprintf('Unknown flag string: %s\n', varargin{iArg});
    end
    iArg = iArg + 1;
  end
end

clf
[nX, nY, nZ] = size(stack);

minStack = min(stack(:));
maxStack = max(stack(:));

% Set the layout
if flgLayout
  nRows = layout(1);
  nCols = layout(2);
else
  nCols = ceil(sqrt(nZ));
  nRows = ceil(nZ / nCols);
end

leftMargin = 0.03;
if flgColorbar
  rightMargin = 0.15;
else
  rightMargin = 0.03;
end
bottomMargin  = 0.05;
topMargin = 0.03;

rStep = 1/nRows * (1 - bottomMargin - topMargin);
cStep = 1/nCols * (1 - leftMargin - rightMargin);
shrink = 0.97;

for iZ = 1:nZ
  if iZ > nRows * nCols
    break
  end
  left = rem(iZ-1, nCols) * cStep + leftMargin;
  bottom = (nRows - ceil(iZ / nCols)) * rStep + bottomMargin;

  hAxes(iZ) = subplot('position',                                      ...
                      [left bottom cStep*shrink rStep*shrink]); %#ok<AGROW>

  if interpFactor == 1
    intX = 1:nX;
    intY = 1:nY;
    im = stack(:,:,iZ);
  else
    intX = 1:1/interpFactor:nX;
    intY = (1:1/interpFactor:nY)';
    im = interp2(stack(:,:,iZ), intX, intY, 'spline');
  end
  showMRCImage(im, intX, intY);
  if ~isempty(scaleBar)
    sbLength = scaleBar(1);
    if length(scaleBar) > 1
      sbWidth = scaleBar(2);
    else
      sbWidth = sbLength / 5;
    end
    if length(scaleBar) > 3
      sbPos = [scaleBar(2) scaleBar(3)];
    else
      sbPos(1) = nX * 0.95 - sbLength;
      sbPos(2) = nY * 0.95;
    end
    hold on
    hSB = plot([sbPos(1) sbPos(1)+sbLength], [sbPos(2) sbPos(2)],      ...
      'linewidth', sbWidth, 'color', [0 1 0]); %#ok<NASGU>
  end
  if ~flgCaxis
    colorAxis =[minStack maxStack];
  end
  caxis(colorAxis);
  
  if flgGrid
    grid on
  end
  xlabel('');
  ylabel('');

  if flgTickLabels
    if iZ <= nCols
      % Top row
      set(gca, 'XTickLabel', []);
      % set(gca, 'XAxisLocation', 'top')
    elseif ceil((iZ) / nCols) == nRows
      % Bottom row
    else
      % Middle rows
      set(gca, 'XTickLabel', []);
    end

    if rem(iZ, nCols) == 1
      % Left colum
      set(gca, 'YAxisLocation', 'left')
    elseif rem(iZ, nCols) == 0
      % Right column
      %set(gca, 'YAxisLocation', 'right')
      set(gca, 'YTickLabel', []);
    else
      % Middle rows
      set(gca, 'YTickLabel', []);
    end
  else
    set(gca, 'XTickLabel', []);
    set(gca, 'XTick', []);
    set(gca, 'YTickLabel', []);
    set(gca, 'YTick', []);
  end
  %grid on
end

% Create colorbar
if flgColorbar
  colorbarMargin = 0.05;
  colorbarWidth = 0.08;
  subplot('position', ...
    [1-rightMargin+colorbarMargin bottomMargin colorbarWidth rStep*nRows])
  nMap = size(colormap, 1);
  image(1, linspace(colorAxis(1), colorAxis(2), nMap)', (1:nMap)')
  set(gca, 'ydir', 'normal');
  set(gca, 'XTickLabel', []);
  set(gca, 'box', 'on');
end

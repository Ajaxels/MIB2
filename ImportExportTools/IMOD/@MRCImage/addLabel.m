%addLabel       Calculate and update the statistics in the MRCImage
%
%   mRCImage = addLabel(mRCImage, label)
%
%   mRCImage    The MRCImage object.
%
%   label       The label to be added.
%
%   Add a label to the header section of an MRCImage object
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2012 The Regents of the University of Colorado & BLD3EMC:
%           The Boulder Laboratory For 3D Electron Microscopy of Cells.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2012/01/12 17:22:51 $
%
%  $Revision: 04b6cb6df697 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mRCImage = addLabel(mRCImage, label)
if mRCImage.header.nLabels < 10
  mRCImage.header.nLabels =  mRCImage.header.nLabels + 1;
  fullLabel = [label blanks(80 - length(label))];
  mRCImage.header.labels(mRCImage.header.nLabels, :) = fullLabel;

end


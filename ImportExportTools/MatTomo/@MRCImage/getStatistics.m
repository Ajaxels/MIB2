%getStatistics  Return the selected statistic(s) of the volume
%
%   stat = getStatistics(mRCImage, statistic, domain)
%
%   stat        The requested statistic(s)
%
%   mRCImage    The mRCImage object to analyze.
%
%   statistic   The statistic to calculate:
%               'min', 'max', 'mean', 'median'
%
%   domain      OPTIONAL: The domain over which the statistic will be
%               calculated: ('z')
%               'x', 'y', 'z', 'global'
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

function stat = getStatistics(mRCImage, statistic, domain)
this=mRCImage;

%  Permute/stack the data if according to the domain selection
if nargin < 3
  domain = 'z';
end

switch lower(domain)
 case 'x'
    data = reshape(permute(this.volume, [2 3 1]),                      ...
                   this.header.nY * this.header.nZ,                    ...
                   this.header.nX);
 case 'y'
    data = reshape(permute(this.volume, [1 3 2]),                      ...
                   this.header.nX * this.header.nZ, ...
                   this.header.nY);
 case 'z'
   data = reshape(this.volume, this.header.nX * this.header.nY,        ...
                  this.header.nZ);
 case 'global'
  data = this.volume(:);
 
 otherwise
  PEETError(['Invalid domain selector: ' domain]);
end


switch lower(statistic)
 case 'min'
  stat = min(data);
 
 case 'max'
   stat = max(data);
 
 case 'mean',
   stat = mean(double(data));
 
 case 'std',
   stat = std(double(data));
 
 case 'median',
    stat = median(data);
 
 otherwise
  PEETError(['Unimplemented statistic: ' statistic]);
end

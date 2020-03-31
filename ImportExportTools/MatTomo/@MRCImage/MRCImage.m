%MRCImage        MRCImage Constructor 
%
%   mRCImage = MRCImage
%   mRCImage = MRCImage(filename)
%   mRCImage = MRCImage(filename, flgLoad)
%   mRCImage = MRCImage(header)
%   mRCImage = MRCImage(header, filename)
%   mRCImage = MRCImage(header, filename, flgLoad)
%   mRCImage = MRCImage(volume)
%   mRCImage = MRCImage(MRCImage)
%   mRCImage = MRCImage(MRCImage, fileName)
%
%   mRCImage    The constructed MRCImage object
%
%   fileName    The name of an MRC image file to use in initializing the
%               object.
%
%   flgLoad     A flag specifying whether to load the volume into memory.
%               (default: 1, load volume).
%
%   header      A header for creating an empty (zeroed) volume.
%
%
%   MRCImage constructs an MRCImage object and optionally initializes it
%   with the specified MRC image file.
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
%  $Date: 2020/01/02 05:02:54 $
%
%  $Revision: 086c91347e19 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mRCImage = MRCImage(varargin)

% Create a default MRCImage image structure
mRCImage = default;
mRCImage = class(mRCImage, 'MRCImage');    

% Default constructor
if length(varargin) < 1
  return;
end

% Decide which type of constructor is being called
% - If the first argument is a string it is the name of the MRCImage file.
% - if the first argument is a struct it is (partial) header; create a
%   zero'd volume.
% - If numeric or logical, it is the volume to use.
% - If the first argument is another MRCImage then do a copy.
if isa(varargin{1}, 'char')
  if length(varargin) < 2
    mRCImage = open(mRCImage, varargin{1});
  else
    mRCImage = open(mRCImage, varargin{1}, varargin{2});
  end

elseif isa(varargin{1}, 'struct')
  if nargin > 2
    flgLoad = varargin{3};
    filename = varargin{2};
  else
    flgLoad = 1;
    filename = '';
  end
  mRCImage = emptyVolume(mRCImage, varargin{1}, filename, flgLoad);
  
elseif isa(varargin{1}, 'logical')
  mRCImage = setVolumeAndHeaderFromVolume(mRCImage, uint8(varargin{1}));
  
elseif isa(varargin{1}, 'numeric')
  mRCImage = setVolumeAndHeaderFromVolume(mRCImage, varargin{1});
  
else
  if nargin < 2
    % Direct copy
    mRCImage = varargin{1};
  else
    % Copy an existing MRCImage (file and object) and give it a new filename
    destFilename = varargin{2};
    if destFilename(1) ~= '/'
      workingDir = cd;
      destFilename = [workingDir '/' destFilename];
    end
    srcFilename = varargin{1}.filename;
    [stat, message] = copyfile(srcFilename,  destFilename);
    if ~ stat
      disp(message);
      PEETError('Unable to copy file!');
    end
    mRCImage = varargin{1};

    % Reset the file descriptor
    mRCImage.fid = [];

    % Open the copied file in the same form as the source MRCImage
    mRCImage = open(mRCImage, destFilename, mRCImage.flgVolume);   
  end
end

classdef MRCImage
% MRCImage        MRCImage Class Definition and Constructor 
%
%   Supported constructors:
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
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  properties (Access = protected)
    fid = [];
    filename = [];
    endianFormat = 'ieee-le';
    type = 'BL3DFS';
    version = '1.0';
    dataIndex = -Inf;
    volume = [];
    flgVolume = 0;

    header = struct(                                                   ...
    'nX', -Inf,                                                        ...
    'nY', -Inf,                                                        ...
    'nZ', -Inf,                                                        ...
    'mode', -Inf,                                                      ...
    'nXStart', -Inf,                                                   ...
    'nYStart', -Inf,                                                   ...
    'nZStart', -Inf,                                                   ...
    'mX', -Inf,                                                        ...
    'mY', -Inf,                                                        ...
    'mZ', -Inf,                                                        ...
    'cellDimensionX', -Inf,                                            ...
    'cellDimensionY', -Inf,                                            ...
    'cellDimensionZ', -Inf,                                            ...
    'cellAngleX', -Inf,                                                ...
    'cellAngleY', -Inf,                                                ...
    'cellAngleZ', -Inf,                                                ...
    'mapColumns', 1,                                                   ...
    'mapRows', 2,                                                      ...
    'mapSections', 3,                                                  ...
    'minDensity', -Inf,                                                ...
    'maxDensity', -Inf,                                                ...
    'meanDensity', -Inf,                                               ...
    'spaceGroup', -Inf,                                                ...
    'nBytesExtended', -Inf,                                            ...
    'creatorID', -Inf,                                                 ...
    'extraInfo1', char(zeros(1, 30, 'uint8')),                         ...
    'nBytesPerSection', -Inf,                                          ...
    'serialEMType', -Inf,                                              ...
    'extraInfo2', char(zeros(1, 20, 'uint8')),                         ...
    'imodStamp', -Inf,                                                 ...
    'imodFlags', -Inf,                                                 ...
    'idtype', -Inf,                                                    ...
    'lens', -Inf,                                                      ...
    'ndl', -Inf,                                                       ...
    'nd2', -Inf,                                                       ...
    'vdl', -Inf,                                                       ...
    'vd2', -Inf,                                                       ...
    'tiltAngles', [],                                                  ...
    'extra', [],                                                       ...
    'xOrigin', -Inf,                                                   ...
    'yOrigin', -Inf,                                                   ...
    'zOrigin', -Inf,                                                   ...
    'map', '',                                                         ...
    'machineStamp', '',                                                ...
    'densityRMS', -Inf,                                                ...
    'nLabels', -Inf,                                                   ...
    'labels', [blanks(80); blanks(80); blanks(80); blanks(80);         ...
               blanks(80); blanks(80); blanks(80); blanks(80);         ...
               blanks(80); blanks(80)]);

    extended = [];
    forceWriteByteMode = [];
  end

  methods (Access = protected)
    mRCImage = setStatisticsFromVolume(mRCImage);
  end

  methods
    function mRCImage = MRCImage(varargin)
      % Default constructor (no arguments)
      if length(varargin) < 1
        return;
      end

      % Decide which type of constructor is being called
      % - If the first argument is a string it is the name of a file.
      % - if the first argument is a struct it is (a partial) header; 
      %     create a zero'd volume.length(vararg
      % - If numeric or logical, it is the volume to use.
      % - If the first argument is another MRCImage then do a copy.
      if isa(varargin{1}, 'char')
        if length(varargin) < 2
          mRCImage = open(mRCImage, varargin{1});
        else
          mRCImage = open(mRCImage, varargin{1}, varargin{2});
        end

      elseif isa(varargin{1}, 'struct')
        if length(varargin) > 2
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
  
      elseif isa(varargin{1}, 'MRCImage')
        if length(varargin) < 2
          % Direct copy
          mRCImage = varargin{1};
        else
          % Copy an existing MRCImage and give it a new filename
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
      else
        PEETError('Illegal argument to MRCIMage!')
      end
    end
  end
end

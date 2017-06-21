function nrrdSaveWithMetadata( nrrd_filename, matlab_struct )
% function nrrdSaveWithMetadata( nrrd_filename, matlab_struct )
%
% This function saves a nrrd volume into MATLAB with the associated
% metadata. First input is a string with the nrrd volume
% filename. Second input is a MATLAB struct containing the data and
% the metadata according to the following conventions.
%
% The struct obeys the following conventions:
% - The fields in the struct are ordered as follows:
% -- 00 = data              (void *) nrrd->data
% -- 01 = space             (int) nrrd->space [enum]
% -- 02 = spacedirections   (double matrix) nrrd->axis[NRRD_DIM_MAX].spaceDirection[NRRD_SPACE_DIM_MAX]
% -- 03 = centerings        (int array) nrrd->axis[NRRD_DIM_MAX].center [enum]
% -- 04 = kinds             (int array) nrrd->axis[NRRD_DIM_MAX].kind [enum]
% -- 05 = spaceunits        (char * array) nrrd->spaceUnits[NRRD_SPACE_DIM_MAX]
% -- 06 = spaceorigin       (double array) nrrd->spaceOrigin[NRRD_SPACE_DIM_MAX]
% -- 07 = measurementframe  (double matrix) nrrd->measurementFrame[NRRD_SPACE_DIM_MAX][NRRD_SPACE_DIM_MAX]
% -- OPTIONAL:
% -- 08 = modality          (string) nrrd->kvp[1]
% -- 09 = bvalue            (double) bKVP
% -- 10 = gradientdirections(double matrix) info[dwiIdx]
%
% The following is an expansion of the enums for TEEM-1.9.0
%
% -- 01 = space:
%   nrrdSpaceUnknown,
%   nrrdSpaceRightAnteriorSuperior,     /*  1: NIFTI-1 (right-handed) */
%   nrrdSpaceLeftAnteriorSuperior,      /*  2: standard Analyze (left-handed) */
%   nrrdSpaceLeftPosteriorSuperior,     /*  3: DICOM 3.0 (right-handed) */
%   nrrdSpaceRightAnteriorSuperiorTime, /*  4: */
%   nrrdSpaceLeftAnteriorSuperiorTime,  /*  5: */
%   nrrdSpaceLeftPosteriorSuperiorTime, /*  6: */
%   nrrdSpaceScannerXYZ,                /*  7: ACR/NEMA 2.0 (pre-DICOM 3.0) */
%   nrrdSpaceScannerXYZTime,            /*  8: */
%   nrrdSpace3DRightHanded,             /*  9: */
%   nrrdSpace3DLeftHanded,              /* 10: */
%   nrrdSpace3DRightHandedTime,         /* 11: */
%   nrrdSpace3DLeftHandedTime,          /* 12: */
%   nrrdSpaceLast
%
% -- 03 = centerings:
%   nrrdCenterUnknown,         /* 0: no centering known for this axis */
%   nrrdCenterNode,            /* 1: samples at corners of things
%                                 (how "voxels" are usually imagined)
%                                 |\______/|\______/|\______/|
%                                 X        X        X        X   */
%   nrrdCenterCell,            /* 2: samples at middles of things
%                                 (characteristic of histogram bins)
%                                  \___|___/\___|___/\___|___/
%                                      X        X        X       */
%   nrrdCenterLast
%
% -- 04 = kinds:
%   nrrdKindUnknown,
%   nrrdKindDomain,            /*  1: any image domain */
%   nrrdKindSpace,             /*  2: a spatial domain */
%   nrrdKindTime,              /*  3: a temporal domain */
%   /* -------------------------- end domain kinds */
%   /* -------------------------- begin range kinds */
%   nrrdKindList,              /*  4: any list of values, non-resample-able */
%   nrrdKindPoint,             /*  5: coords of a point */
%   nrrdKindVector,            /*  6: coeffs of (contravariant) vector */
%   nrrdKindCovariantVector,   /*  7: coeffs of covariant vector (eg gradient) */
%   nrrdKindNormal,            /*  8: coeffs of unit-length covariant vector */
%   /* -------------------------- end arbitrary size kinds */
%   /* -------------------------- begin size-specific kinds */
%   nrrdKindStub,              /*  9: axis with one sample (a placeholder) */
%   nrrdKindScalar,            /* 10: effectively, same as a stub */
%   nrrdKindComplex,           /* 11: real and imaginary components */
%   nrrdKind2Vector,           /* 12: 2 component vector */
%   nrrdKind3Color,            /* 13: ANY 3-component color value */
%   nrrdKindRGBColor,          /* 14: RGB, no colorimetry */
%   nrrdKindHSVColor,          /* 15: HSV, no colorimetry */
%   nrrdKindXYZColor,          /* 16: perceptual primary colors */
%   nrrdKind4Color,            /* 17: ANY 4-component color value */
%   nrrdKindRGBAColor,         /* 18: RGBA, no colorimetry */
%   nrrdKind3Vector,           /* 19: 3-component vector */
%   nrrdKind3Gradient,         /* 20: 3-component covariant vector */
%   nrrdKind3Normal,           /* 21: 3-component covector, assumed normalized */
%   nrrdKind4Vector,           /* 22: 4-component vector */
%   nrrdKindQuaternion,        /* 23: (w,x,y,z), not necessarily normalized */
%   nrrdKind2DSymMatrix,       /* 24: Mxx Mxy Myy */
%   nrrdKind2DMaskedSymMatrix, /* 25: mask Mxx Mxy Myy */
%   nrrdKind2DMatrix,          /* 26: Mxx Mxy Myx Myy */
%   nrrdKind2DMaskedMatrix,    /* 27: mask Mxx Mxy Myx Myy */
%   nrrdKind3DSymMatrix,       /* 28: Mxx Mxy Mxz Myy Myz Mzz */
%   nrrdKind3DMaskedSymMatrix, /* 29: mask Mxx Mxy Mxz Myy Myz Mzz */
%   nrrdKind3DMatrix,          /* 30: Mxx Mxy Mxz Myx Myy Myz Mzx Mzy Mzz */
%   nrrdKind3DMaskedMatrix,    /* 31: mask Mxx Mxy Mxz Myx Myy Myz Mzx Mzy Mzz */
%   nrrdKindLast
%
% Contributed by John Melonakos, jmelonak@ece.gatech.edu, (2008).
%

end

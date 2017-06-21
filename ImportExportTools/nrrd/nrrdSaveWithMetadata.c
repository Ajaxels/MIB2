#include "mex.h"
#include "matrix.h"
#include "string.h"
#include <teem/nrrd.h>

int
typeMtoN(mxClassID mtype) {
  int ntype;

  switch(mtype) {
  case mxINT8_CLASS:
    ntype = nrrdTypeChar;
    break;
  case mxUINT8_CLASS:
    ntype = nrrdTypeUChar;
    break;
  case mxINT16_CLASS:
    ntype = nrrdTypeShort;
    break;
  case mxUINT16_CLASS:
    ntype = nrrdTypeUShort;
    break;
  case mxINT32_CLASS:
    ntype = nrrdTypeInt;
    break;
  case mxUINT32_CLASS:
    ntype = nrrdTypeUInt;
    break;
  case mxINT64_CLASS:
    ntype = nrrdTypeLLong;
    break;
  case mxUINT64_CLASS:
    ntype = nrrdTypeULLong;
    break;
  case mxSINGLE_CLASS:
    ntype = nrrdTypeFloat;
    break;
  case mxDOUBLE_CLASS:
    ntype = nrrdTypeDouble;
    break;
  default:
    ntype = nrrdTypeUnknown;
    break;

  }
  return ntype;
}

void mexFunction(int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[])
{
    char me[]="nrrdSave", *filename, *errPtr, errBuff[AIR_STRLEN_MED];
    int filenameLen, ntype;
    size_t sizeZ[NRRD_DIM_MAX];
    unsigned int dim, axIdx, sdIdx, dwiIdx, count, nfields;
    Nrrd *nrrd;
    airArray *mop;
    const mxArray *filenameMx, *structMx;
    /* Metadata stuff */
    int *space_temp;
    double *spacedirections_temp;
    int *centerings_temp;
    int *kinds_temp;
    double *spaceorigin_temp;
    double *measurementframe_temp;
    
    if (!(2 == nrhs && mxIsChar(prhs[0]) )) {
        sprintf(errBuff, "%s: requires two args: one string, one struct", me);
        mexErrMsgTxt(errBuff);
    }
    filenameMx = prhs[0];
    structMx = prhs[1];
    nfields = mxGetNumberOfFields(prhs[1]);
    
    /* Error checking on the data */
    if (mxIsComplex(mxGetFieldByNumber(prhs[1], 0, 0))) {
        sprintf(errBuff, "%s: sorry, array must be real", me);
        mexErrMsgTxt(errBuff);
    }
    ntype = typeMtoN(mxGetClassID(mxGetFieldByNumber(prhs[1], 0, 0)));
    if (nrrdTypeUnknown == ntype) {
        sprintf(errBuff, "%s: sorry, can't handle type %s",
                me, mxGetClassName(mxGetFieldByNumber(prhs[1], 0, 0)));
        mexErrMsgTxt(errBuff);
    }
    dim = mxGetNumberOfDimensions(mxGetFieldByNumber(prhs[1], 0, 0));
    if (!( 1 <= dim && dim <= NRRD_DIM_MAX )) {
        sprintf(errBuff, "%s: number of array dimensions %d outside range [1,%d]",
                me, dim, NRRD_DIM_MAX);
        mexErrMsgTxt(errBuff);
    }
  
    filenameLen = mxGetM(filenameMx)*mxGetN(filenameMx)+1;
    filename = mxCalloc(filenameLen, sizeof(mxChar));    /* managed by Matlab */
    mxGetString(filenameMx, filename, filenameLen);
  
    for (axIdx=0; axIdx<dim; axIdx++) {
        sizeZ[axIdx] = mxGetDimensions(mxGetFieldByNumber(prhs[1], 0, 0))[axIdx];
    }
    nrrd = nrrdNew();
    mop = airMopNew();
    airMopAdd(mop, nrrd, (airMopper)nrrdNix, airMopAlways);
    
    /** space **/
    nrrd->dim = dim;
    if (nfields == 11) {
        nrrd->spaceDim = dim-1;
    } else {
        nrrd->spaceDim = dim;
    }
    space_temp = (int *)mxGetData( mxGetFieldByNumber(prhs[1], 0, 1) );
    nrrd->space = *space_temp;
    /** spacedirections **/
    spacedirections_temp = (double *)mxGetData( mxGetFieldByNumber(prhs[1], 0, 2) );
    count = 0;
    for (axIdx=0; axIdx<nrrd->spaceDim; axIdx++) {
        for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
            nrrd->axis[axIdx].spaceDirection[sdIdx] = spacedirections_temp[count];
            count++;
        }
    }
    
    /** centerings **/
    centerings_temp = (int *)mxGetData( mxGetFieldByNumber(prhs[1], 0, 3) );
    for (axIdx=0; axIdx<nrrd->dim; axIdx++) {
        nrrd->axis[axIdx].center = centerings_temp[axIdx];
    }
    /** kinds **/
    kinds_temp = (int *)mxGetData( mxGetFieldByNumber(prhs[1], 0, 4) );
    for (axIdx=0; axIdx<nrrd->dim; axIdx++) {
        nrrd->axis[axIdx].kind = kinds_temp[axIdx];
    }
    /** spaceunits **/
    for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
        nrrd->spaceUnits[sdIdx] = malloc(200);
        sprintf( nrrd->spaceUnits[sdIdx],  mxArrayToString( mxGetCell( mxGetFieldByNumber(prhs[1], 0, 5), sdIdx) ) );
    }
    /** spaceorigin **/
    spaceorigin_temp = (double *)mxGetData( mxGetFieldByNumber(prhs[1], 0, 6) );
    for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
        nrrd->spaceOrigin[sdIdx] = spaceorigin_temp[sdIdx];
    }
    /** measurementframe **/
    measurementframe_temp = (double *)mxGetData( mxGetFieldByNumber(prhs[1], 0, 7) );
    count = 0;
    for (axIdx=0; axIdx<nrrd->spaceDim; axIdx++) {
        for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
            nrrd->measurementFrame[axIdx][sdIdx] = measurementframe_temp[count];
            count++;
        }
    }
    if (nfields == 11) {
        printf("TODO: Figure out how to set the key/value pairs by extracting the information from the matlab struct.\n");
    }
    
  
    if (nrrdWrap_nva(nrrd, mxGetPr(mxGetFieldByNumber(prhs[1], 0, 0)), ntype, dim, sizeZ)
        || nrrdSave(filename, nrrd, NULL)) {
        errPtr = biffGetDone(NRRD);
        airMopAdd(mop, errPtr, airFree, airMopAlways);
        sprintf(errBuff, "%s: error saving NRRD:\n%s", me, errPtr);
        airMopError(mop);
        mexErrMsgTxt(errBuff);
    }
    
    airMopOkay(mop);
    return;
}

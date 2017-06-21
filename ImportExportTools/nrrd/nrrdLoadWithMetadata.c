#include "mex.h"
#include "matrix.h"
#include "string.h"
#include <teem/nrrd.h>

mxClassID
    typeNtoM(int ntype) {
    mxClassID mtype;

    switch(ntype) {
    case nrrdTypeChar:
        mtype = mxINT8_CLASS;
        break;
    case nrrdTypeUChar:
        mtype = mxUINT8_CLASS;
        break;
    case nrrdTypeShort:
        mtype = mxINT16_CLASS;
        break;
    case nrrdTypeUShort:
        mtype = mxUINT16_CLASS;
        break;
    case nrrdTypeInt:
        mtype = mxINT32_CLASS;
        break;
    case nrrdTypeUInt:
        mtype = mxUINT32_CLASS;
        break;
    case nrrdTypeLLong:
        mtype = mxINT64_CLASS;
        break;
    case nrrdTypeULLong:
        mtype = mxUINT64_CLASS;
        break;
    case nrrdTypeFloat:
        mtype = mxSINGLE_CLASS;
        break;
    case nrrdTypeDouble:
        mtype = mxDOUBLE_CLASS;
        break;
    default:
        mtype = mxUNKNOWN_CLASS;
        break;
    }
    return mtype;
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    char me[]="nrrdLoadWithMetadata", *filename, *errPtr, errBuff[AIR_STRLEN_MED];
    int filenameLen, sizeI[NRRD_DIM_MAX];
    mxClassID mtype;
    unsigned int axIdx, sdIdx, dwiIdx, count; /* Loop iterators */
    Nrrd *nrrd;
    NrrdIoState *nio;
    airArray *mop;
    /* Meta data stuff */
    const char **fieldnames; /* matlab struct field names*/
    mxArray *nrrd_matlab; /* the return matlab struct */
    mxArray *data; /* the data */
    mxArray *space; int *space_temp; int space_size[1];
    mxArray *spacedirections; double *spacedirections_temp;
    mxArray *centerings; int *centerings_temp; int centerings_size[1];
    mxArray *kinds; int *kinds_temp; int kinds_size[1];
    mxArray *spaceunits, *spaceunits_temp; int spaceunits_size[1];
    mxArray *spaceorigin; double *spaceorigin_temp; int spaceorigin_size[1];
    mxArray *measurementframe; double *measurementframe_temp;
    Nrrd *ngradKVP=NULL, *nbmatKVP=NULL; double bKVP; double *info;
    mxArray *modality;
    mxArray *bvalue; double *bvalue_temp; int bvalue_size[1];
    mxArray *gradientdirections; double *gradientdirections_temp; int gradientdirections_size[1];

    if (!(1 == nrhs && mxIsChar(prhs[0]))) {
        sprintf(errBuff, "%s: requires one string argument (the name of the file)", me);
        mexErrMsgTxt(errBuff);
    }

    mop = airMopNew();
    filenameLen = mxGetM(prhs[0])*mxGetN(prhs[0])+1;
    filename = mxCalloc(filenameLen, sizeof(mxChar));  /* managed by Matlab */
    mxGetString(prhs[0], filename, filenameLen);

    nrrd = nrrdNew();
    airMopAdd(mop, nrrd, (airMopper)nrrdNix, airMopAlways);
    nio = nrrdIoStateNew();
    airMopAdd(mop, nio, (airMopper)nrrdIoStateNix, airMopAlways);
    nrrdIoStateSet(nio, nrrdIoStateSkipData, AIR_TRUE);

    /* read header, but no data */
    if (nrrdLoad(nrrd, filename, nio)) {
        errPtr = biffGetDone(NRRD);
        airMopAdd(mop, errPtr, airFree, airMopAlways);
        sprintf(errBuff, "%s: trouble reading NRRD header:\n%s", me, errPtr);
        airMopError(mop);
        mexErrMsgTxt(errBuff);
    }
    mtype = typeNtoM(nrrd->type);
    if (mxUNKNOWN_CLASS == mtype) {
        sprintf(errBuff, "%s: sorry, can't handle type %s (%d)", me,
                airEnumStr(nrrdType, nrrd->type), nrrd->type);
        airMopError(mop);
        mexErrMsgTxt(errBuff);
    }

    /* Create a MATLAB Struct and Set All the Fields */
    /** Setup the Fieldnames **/
    if (NULL != nrrd->kvp) { 
        fieldnames = mxCalloc(11, sizeof(*fieldnames));
    }
    else {
        fieldnames = mxCalloc(8, sizeof(*fieldnames));
    }
    fieldnames[0] = "data";
    fieldnames[1] = "space";
    fieldnames[2] = "spacedirections";
    fieldnames[3] = "centerings";
    fieldnames[4] = "kinds";
    fieldnames[5] = "spaceunits";
    fieldnames[6] = "spaceorigin";
    fieldnames[7] = "measurementframe";
    if (NULL != nrrd->kvp) { 
        fieldnames[8] = "modality";
        fieldnames[9] = "bvalue";
        fieldnames[10] = "gradientdirections";
        /** Create the Struct **/
        plhs[0] = mxCreateStructMatrix( 1, 1, 11, fieldnames ); 
    }
    else {
        plhs[0] = mxCreateStructMatrix( 1, 1, 8, fieldnames ); 
    }
    mxFree((void *)fieldnames);

    /** data **/
    for (axIdx=0; axIdx<nrrd->dim; axIdx++) {
        sizeI[axIdx] = nrrd->axis[axIdx].size;
    }
    data = mxCreateNumericArray( nrrd->dim, sizeI, mtype, mxREAL );
    nrrd->data = mxGetPr(data); 
    mxSetFieldByNumber( plhs[0], 0, 0, data );
    /** space **/
    if (NULL != &nrrd->space) {
        space_size[0] = 1;
        space = mxCreateNumericArray( 1, space_size, mxINT32_CLASS, mxREAL );
        space_temp = (int *)mxGetData(space);
        *space_temp = nrrd->space;
        mxSetFieldByNumber( plhs[0], 0, 1, space );
    }
    /** spacedirections **/
    spacedirections = mxCreateNumericMatrix( nrrd->spaceDim, nrrd->spaceDim, mxDOUBLE_CLASS, mxREAL );
    spacedirections_temp = (double *)mxGetData(spacedirections);
    count = 0;
    for (axIdx=0; axIdx<nrrd->spaceDim; axIdx++) {
        for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
            spacedirections_temp[count] = nrrd->axis[axIdx].spaceDirection[sdIdx];
            count++;
        }
    }
    mxSetFieldByNumber( plhs[0], 0, 2, spacedirections );
    /** centerings **/
    centerings_size[0] = nrrd->dim;
    centerings = mxCreateNumericArray( 1, centerings_size, mxINT32_CLASS, mxREAL );
    centerings_temp = (int *)mxGetData(centerings);
    for (axIdx=0; axIdx<nrrd->dim; axIdx++) {
        centerings_temp[axIdx] = nrrd->axis[axIdx].center;
    }
    mxSetFieldByNumber( plhs[0], 0, 3, centerings );
    /** kinds **/
    kinds_size[0] = nrrd->dim;
    kinds = mxCreateNumericArray( 1, kinds_size, mxINT32_CLASS, mxREAL );
    kinds_temp = (int *)mxGetData(kinds);
    for (axIdx=0; axIdx<nrrd->dim; axIdx++) {
        kinds_temp[axIdx] = nrrd->axis[axIdx].kind;
    }
    mxSetFieldByNumber( plhs[0], 0, 4, kinds );
    /** spaceunits **/
    spaceunits_size[0] = nrrd->spaceDim;
    spaceunits = mxCreateCellArray( 1, spaceunits_size );
    for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
        spaceunits_temp = mxCreateString( nrrd->spaceUnits[sdIdx] );
        mxSetCell(spaceunits, sdIdx, spaceunits_temp);
    }
    mxSetFieldByNumber( plhs[0], 0, 5, spaceunits );
    /** spaceorigin **/
    spaceorigin_size[0] = nrrd->spaceDim;
    spaceorigin = mxCreateNumericArray( 1, spaceorigin_size, mxDOUBLE_CLASS, mxREAL );
    spaceorigin_temp = (double *)mxGetData(spaceorigin);
    for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
        spaceorigin_temp[sdIdx] = nrrd->spaceOrigin[sdIdx];
    }
    mxSetFieldByNumber( plhs[0], 0, 6, spaceorigin );
    /** measurementframe **/
    measurementframe = mxCreateNumericMatrix( nrrd->spaceDim, nrrd->spaceDim, mxDOUBLE_CLASS, mxREAL );
    measurementframe_temp = (double *)mxGetData(measurementframe);
    count = 0;
    for (axIdx=0; axIdx<nrrd->spaceDim; axIdx++) {
        for (sdIdx=0; sdIdx<nrrd->spaceDim; sdIdx++) {
            measurementframe_temp[count] = nrrd->measurementFrame[axIdx][sdIdx];
            count++;
        }
    }
    mxSetFieldByNumber( plhs[0], 0, 7, measurementframe );
    /** modality, bvalue, & gradientdirections **/
    if (NULL != nrrd->kvp) { 
        /** modality **/
        modality = mxCreateString( nrrd->kvp[1] );
        mxSetFieldByNumber( plhs[0], 0, 8, modality );

        /* use tend to parse the key/value pairs */
        tenDWMRIKeyValueParse(&ngradKVP, &nbmatKVP, &bKVP, nrrd);
        info = (double *)(ngradKVP->data);

        /** bvalue **/
        bvalue_size[0] = 1;
        bvalue = mxCreateNumericArray( 1, bvalue_size, mxDOUBLE_CLASS, mxREAL );
        bvalue_temp = (double *)mxGetData(bvalue);
        *bvalue_temp = bKVP;
        mxSetFieldByNumber( plhs[0], 0, 9, bvalue );

        /** gradientdirections **/
        gradientdirections = mxCreateNumericMatrix( sizeI[nrrd->dim-1], nrrd->spaceDim, mxDOUBLE_CLASS, mxREAL );
        gradientdirections_temp = (double *)mxGetData(gradientdirections);
        for (dwiIdx=0; dwiIdx<sizeI[nrrd->dim-1]; dwiIdx++) {
            gradientdirections_temp[dwiIdx] = info[dwiIdx*nrrd->spaceDim];
            gradientdirections_temp[dwiIdx+sizeI[nrrd->dim-1]] = info[dwiIdx*nrrd->spaceDim+1];
            gradientdirections_temp[dwiIdx+sizeI[nrrd->dim-1]*2] = info[dwiIdx*nrrd->spaceDim+2];
        }
        mxSetFieldByNumber( plhs[0], 0, 10, gradientdirections );
    }

    /* read second time, now loading data */
    if (nrrdLoad(nrrd, filename, NULL)) {
        errPtr = biffGetDone(NRRD);
        airMopAdd(mop, errPtr, airFree, airMopAlways);
        sprintf(errBuff, "%s: trouble reading NRRD:\n%s", me, errPtr);
        airMopError(mop);
        mexErrMsgTxt(errBuff);
    }

    airMopOkay(mop);
    return;
}

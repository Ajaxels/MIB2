#include "mex.h"
#include "math.h"

/* RK4 is a function which performs one step of the Runge-Kutta 4 ray tracing
 *
 * EndPoint = RK4(StartPoint, GradientVolume, StepSize);
 *
 * inputs :
 *      StartPoint: 2D or 3D location in vectorfield
 *      GradientVolume: Vectorfield
 *      Stepsize : The stepsize
 *
 * outputs :
 *      EndPoint : The new location (zero if outside image)
 *
 * Function is written by D.Kroon University of Twente (July 2008)
 */

__inline int mindex2(int x, int y, int sizx)  { return y*sizx+x;}
__inline int mindex3(int x, int y, int z, int sizx, int sizy)  { return z*sizy*sizx+y*sizx+x;}


__inline int checkBounds2d( double *point, int *Isize) {
    if((point[0]<0)||(point[1]<0)||(point[0]>(Isize[0]-1))||(point[1]>(Isize[1]-1))) { return false; }
    return true;
}

__inline int checkBounds3d( double *point, int *Isize) {
    if((point[0]<0)||(point[1]<0)||(point[2]<0)||(point[0]>(Isize[0]-1))||(point[1]>(Isize[1]-1))||(point[2]>(Isize[2]-1))) { return false; }
    return true;
}

__inline double norm2(double *a) { return sqrt(a[0]*a[0]+a[1]*a[1]); }
__inline double norm3(double *a) { return sqrt(a[0]*a[0]+a[1]*a[1]+a[2]*a[2]); }


__inline void interpgrad2d(double *Ireturn, double *I, int *Isize, double *point) {
    /*  Linear interpolation variables */
    int xBas0, xBas1, yBas0, yBas1;
    double perc[4]={0, 0, 0, 0};
    double xCom, yCom, xComi, yComi;
    double fTlocalx, fTlocaly;
    int f;
    int index[4];
    
    fTlocalx = floor(point[0]); fTlocaly = floor(point[1]);
    xBas0=(int) fTlocalx; yBas0=(int) fTlocaly;
    xBas1=xBas0+1; yBas1=yBas0+1;
    
    /* Linear interpolation constants (percentages) */
    xCom=point[0]-fTlocalx; yCom=point[1]-fTlocaly;
    xComi=(1-xCom); yComi=(1-yCom);
    perc[0]=xComi * yComi;
    perc[1]=xComi * yCom;
    perc[2]=xCom * yComi;
    perc[3]=xCom * yCom;
    
    /* Stick to boundary */
    if(xBas0<0) { xBas0=0; if(xBas1<0) { xBas1=0; }}
    if(yBas0<0) { yBas0=0; if(yBas1<0) { yBas1=0; }}
    if(xBas1>(Isize[0]-1)) { xBas1=Isize[0]-1; if(xBas0>(Isize[0]-1)) { xBas0=Isize[0]-1; }}
    if(yBas1>(Isize[1]-1)) { yBas1=Isize[1]-1; if(yBas0>(Isize[1]-1)) { yBas0=Isize[1]-1; }}
    
    /* Get the neighbour intensities */
    index[0]=mindex2(xBas0, yBas0, Isize[0]);
    index[1]=mindex2(xBas0, yBas1, Isize[0]);
    index[2]=mindex2(xBas1, yBas0, Isize[0]);
    index[3]=mindex2(xBas1, yBas1, Isize[0]);
    f=Isize[0]*Isize[1];
    
    /* the interpolated color */
    Ireturn[0]=I[index[0]]*perc[0]+I[index[1]]*perc[1]+I[index[2]]*perc[2]+I[index[3]]*perc[3];
    Ireturn[1]=I[index[0]+f]*perc[0]+I[index[1]+f]*perc[1]+I[index[2]+f]*perc[2]+I[index[3]+f]*perc[3];
}

//__inline void interpgrad3d(double *Ireturn, double *I, int *Isize, double *point) {
static __inline void interpgrad3d(double *Ireturn, double *I, int *Isize, double *point) {    
    /*  Linear interpolation variables */
    int xBas0, xBas1, yBas0, yBas1, zBas0, zBas1;
    double perc[8];
    double xCom, yCom, zCom;
    double xComi, yComi, zComi;
    double fTlocalx, fTlocaly, fTlocalz;
    int f0, f1;
    int index[8];
    double temp;
    
    fTlocalx = floor(point[0]); fTlocaly = floor(point[1]); fTlocalz = floor(point[2]);
    xBas0=(int) fTlocalx; yBas0=(int) fTlocaly; zBas0=(int) fTlocalz;
    xBas1=xBas0+1; yBas1=yBas0+1; zBas1=zBas0+1;
    
    /* Linear interpolation constants (percentages) */
    xCom=point[0]-fTlocalx;  yCom=point[1]-fTlocaly;   zCom=point[2]-fTlocalz;
    xComi=(1-xCom); yComi=(1-yCom); zComi=(1-zCom);
    perc[0]=xComi * yComi; perc[1]=perc[0] * zCom; perc[0]=perc[0] * zComi;
    perc[2]=xComi * yCom;  perc[3]=perc[2] * zCom; perc[2]=perc[2] * zComi;
    perc[4]=xCom * yComi;  perc[5]=perc[4] * zCom; perc[4]=perc[4] * zComi;
    perc[6]=xCom * yCom;   perc[7]=perc[6] * zCom; perc[6]=perc[6] * zComi;
    
    /* Stick to boundary */
    if(xBas0<0) { xBas0=0; if(xBas1<0) { xBas1=0; }}
    if(yBas0<0) { yBas0=0; if(yBas1<0) { yBas1=0; }}
    if(zBas0<0) { zBas0=0; if(zBas1<0) { zBas1=0; }}
    if(xBas1>(Isize[0]-1)) { xBas1=Isize[0]-1; if(xBas0>(Isize[0]-1)) { xBas0=Isize[0]-1; }}
    if(yBas1>(Isize[1]-1)) { yBas1=Isize[1]-1; if(yBas0>(Isize[1]-1)) { yBas0=Isize[1]-1; }}
    if(zBas1>(Isize[2]-1)) { zBas1=Isize[2]-1; if(zBas0>(Isize[2]-1)) { zBas0=Isize[2]-1; }}
    
   /*Get the neighbour intensities */
    index[0]=mindex3(xBas0, yBas0, zBas0, Isize[0], Isize[1]);
    index[1]=mindex3(xBas0, yBas0, zBas1, Isize[0], Isize[1]);
    index[2]=mindex3(xBas0, yBas1, zBas0, Isize[0], Isize[1]);
    index[3]=mindex3(xBas0, yBas1, zBas1, Isize[0], Isize[1]);
    index[4]=mindex3(xBas1, yBas0, zBas0, Isize[0], Isize[1]);
    index[5]=mindex3(xBas1, yBas0, zBas1, Isize[0], Isize[1]);
    index[6]=mindex3(xBas1, yBas1, zBas0, Isize[0], Isize[1]);
    index[7]=mindex3(xBas1, yBas1, zBas1, Isize[0], Isize[1]);
    f0=Isize[0]*Isize[1]*Isize[2];
    f1=f0+f0;
    
   /*the interpolated color */
    temp=I[index[0]]*perc[0]+I[index[1]]*perc[1]+I[index[2]]*perc[2]+I[index[3]]*perc[3];
    Ireturn[0]=temp+I[index[4]]*perc[4]+I[index[5]]*perc[5]+I[index[6]]*perc[6]+I[index[7]]*perc[7];
    temp=I[index[0]+f0]*perc[0]+I[index[1]+f0]*perc[1]+I[index[2]+f0]*perc[2]+I[index[3]+f0]*perc[3];
    Ireturn[1]=temp+I[index[4]+f0]*perc[4]+I[index[5]+f0]*perc[5]+I[index[6]+f0]*perc[6]+I[index[7]+f0]*perc[7];
    temp=I[index[0]+f1]*perc[0]+I[index[1]+f1]*perc[1]+I[index[2]+f1]*perc[2]+I[index[3]+f1]*perc[3];
    Ireturn[2]=temp+I[index[4]+f1]*perc[4]+I[index[5]+f1]*perc[5]+I[index[6]+f1]*perc[6]+I[index[7]+f1]*perc[7];
}
 
bool RK4STEP_2D(double *gradientArray, int *gradientArraySize, double *startPoint, double *nextPoint, double stepSize) {
    /* Perform one step of the RK4 algorithm */
    double k1[2], k2[2], k3[2], k4[2];
    double tempPoint[2];
    double tempnorm;
    //double D[2],dl;
    
   /*Calculate k1 */
    interpgrad2d(k1, gradientArray, gradientArraySize, startPoint);
    tempnorm=norm2(k1);
    k1[0] = k1[0]*stepSize/tempnorm;
    k1[1] = k1[1]*stepSize/tempnorm;
    
    tempPoint[0]=startPoint[0] - k1[0]*0.5;
    tempPoint[1]=startPoint[1] - k1[1]*0.5;
    
   /*Check the if are still inside the domain */
    if (!checkBounds2d(tempPoint, gradientArraySize)) return false;
    
   /*Calculate k2 */
    interpgrad2d(k2, gradientArray, gradientArraySize, tempPoint);
    tempnorm=norm2(k2);
    k2[0] = k2[0]*stepSize/tempnorm;
    k2[1] = k2[1]*stepSize/tempnorm;
    
    tempPoint[0]=startPoint[0] - k2[0]*0.5;
    tempPoint[1]=startPoint[1] - k2[1]*0.5;
    
   /*Check the if are still inside the domain */
    if (!checkBounds2d(tempPoint, gradientArraySize)) return false;
    
   /*Calculate k3 */
    interpgrad2d(k3, gradientArray, gradientArraySize, tempPoint);
    tempnorm=norm2(k3);
    k3[0] = k3[0]*stepSize/tempnorm;
    k3[1] = k3[1]*stepSize/tempnorm;
    
    tempPoint[0]=startPoint[0] - k3[0];
    tempPoint[1]=startPoint[1] - k3[1];
    
   /*Check the if are still inside the domain */
    if (!checkBounds2d(tempPoint, gradientArraySize)) return false;
    
   /*Calculate k4 */
    interpgrad2d(k4, gradientArray, gradientArraySize, tempPoint);
    tempnorm=norm2(k4);
    k4[0] = k4[0]*stepSize/tempnorm;
    k4[1] = k4[1]*stepSize/tempnorm;
    
   /*Calculate final point */
    nextPoint[0] = startPoint[0] - (k1[0] + k2[0]*2.0 + k3[0]*2.0 + k4[0])/6.0;
    nextPoint[1] = startPoint[1] - (k1[1] + k2[1]*2.0 + k3[1]*2.0 + k4[1])/6.0;
    
    /* Set step to step size */
    /*
    D[0]=(nextPoint[0]-startPoint[0]);
    D[1]=(nextPoint[1]-startPoint[1]);
    dl=stepSize/(sqrt(D[0]*D[0]+D[1]*D[1])+1e-15);
    D[0]*=dl; D[1]*=dl;
    nextPoint[0]=startPoint[0]+D[0];
    nextPoint[1]=startPoint[1]+D[1];
    */
    
   /*Check the if are still inside the domain */
    if (!checkBounds2d(nextPoint, gradientArraySize)) return false;
    
    return true;
}


bool RK4STEP_3D(double *gradientArray, int *gradientArraySize, double *startPoint, double *nextPoint, double stepSize) {
    double k1[3], k2[3], k3[3], k4[3];
    double tempPoint[3];
    double tempnorm;
    
   /*Calculate k1 */
    interpgrad3d(k1, gradientArray, gradientArraySize, startPoint);
    tempnorm=norm3(k1);
    k1[0] = k1[0]*stepSize/tempnorm;
    k1[1] = k1[1]*stepSize/tempnorm;
    k1[2] = k1[2]*stepSize/tempnorm;
    
    tempPoint[0]=startPoint[0] - k1[0]*0.5;
    tempPoint[1]=startPoint[1] - k1[1]*0.5;
    tempPoint[2]=startPoint[2] - k1[2]*0.5;
            
   /*Check the if are still inside the domain */
    if (!checkBounds3d(tempPoint, gradientArraySize)) return false;
    
   /*Calculate k2 */
    interpgrad3d(k2, gradientArray, gradientArraySize, tempPoint);
    tempnorm=norm3(k2);
    k2[0] = k2[0]*stepSize/tempnorm;
    k2[1] = k2[1]*stepSize/tempnorm;
    k2[2] = k2[2]*stepSize/tempnorm;
    
    tempPoint[0]=startPoint[0] - k2[0]*0.5;
    tempPoint[1]=startPoint[1] - k2[1]*0.5;
    tempPoint[2]=startPoint[2] - k2[2]*0.5;
    
   /*Check the if are still inside the domain */
    if (!checkBounds3d(tempPoint, gradientArraySize)) return false;
    
   /*Calculate k3 */
    interpgrad3d(k3, gradientArray, gradientArraySize, tempPoint);
    tempnorm=norm3(k3);
    k3[0] = k3[0]*stepSize/tempnorm;
    k3[1] = k3[1]*stepSize/tempnorm;
    k3[2] = k3[2]*stepSize/tempnorm;
        
    tempPoint[0]=startPoint[0] - k3[0];
    tempPoint[1]=startPoint[1] - k3[1];
    tempPoint[2]=startPoint[2] - k3[2];
    
   /*Check the if are still inside the domain */
    if (!checkBounds3d(tempPoint, gradientArraySize)) return false;
    
   /*Calculate k4 */
    interpgrad3d(k4, gradientArray, gradientArraySize, tempPoint);
    tempnorm=norm3(k4);
    k4[0] = k4[0]*stepSize/tempnorm;
    k4[1] = k4[1]*stepSize/tempnorm;
    k4[2] = k4[2]*stepSize/tempnorm;
    
   /*Calculate final point */
    nextPoint[0] = startPoint[0] - (k1[0] + k2[0]*2.0 + k3[0]*2.0 + k4[0])/6.0;
    nextPoint[1] = startPoint[1] - (k1[1] + k2[1]*2.0 + k3[1]*2.0 + k4[1])/6.0;
    nextPoint[2] = startPoint[2] - (k1[2] + k2[2]*2.0 + k3[2]*2.0 + k4[2])/6.0;
     
   /*Check the if are still inside the domain */
    if (!checkBounds3d(nextPoint, gradientArraySize)) return false;
    
    return true;
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
    double *gradientArray;
    const mwSize *gradientArraySizeC;
    const mwSize *PointSizeC;
    mwSize gradientArraySize[3];
    mwSize PointDims;
    mwSize gradientDims;
    int PointLength=1;
    double *startPoint;
    double startPoint1[3];
    double *nextPoint;
    double stepSize;
    double *stepSizeArray;
    int i;
    
    /* Check for proper number of input and output arguments. */
    if(nrhs!=3) { mexErrMsgTxt("3 inputs are required."); }
    if(nlhs!=1) { mexErrMsgTxt("One output required"); }
    
    /*  Get the number of gradient dimensions */
    gradientDims=mxGetNumberOfDimensions(prhs[1]);
    
   /*Get the size of the gradient Array */
    gradientArraySizeC = mxGetDimensions(prhs[1]);
    
    /*  Get the number of startingpoint dimensions */
    PointDims=mxGetNumberOfDimensions(prhs[0]);
    
   /*Get the size of the startingpoint */
    PointSizeC = mxGetDimensions(prhs[0]);
    for (i=0; i<PointDims; i++) { PointLength=PointLength*PointSizeC[i]; }
    
   /*Check data input types  */
    if(mxGetClassID(prhs[0])!=mxDOUBLE_CLASS) { mexErrMsgTxt("inputs must be of class double"); }
    if(mxGetClassID(prhs[1])!=mxDOUBLE_CLASS) { mexErrMsgTxt("inputs must be of class double"); }
    if(mxGetClassID(prhs[2])!=mxDOUBLE_CLASS) { mexErrMsgTxt("inputs must be of class double"); }
    
   /*Connect inputs */
    startPoint =  mxGetPr(prhs[0]);
    gradientArray = mxGetPr(prhs[1]);
    stepSizeArray = mxGetPr(prhs[2]); stepSize=stepSizeArray[0];
    
   /*Create the output array */
    plhs[0] = mxCreateNumericArray(2, PointSizeC, mxDOUBLE_CLASS, mxREAL);
    nextPoint= mxGetPr(plhs[0]);
    
   /*Perform the RK4 raytracing step */
    if(PointLength==2) {
        gradientArraySize[0]=gradientArraySizeC[0];
        gradientArraySize[1]=gradientArraySizeC[1];
        startPoint1[0]=startPoint[0]-1.0; 
        startPoint1[1]=startPoint[1]-1.0;
        if(RK4STEP_2D(gradientArray, gradientArraySize, startPoint1, nextPoint, stepSize)) {
            nextPoint[0]=nextPoint[0]+1.0; 
            nextPoint[1]=nextPoint[1]+1.0;
        }
        else {
            nextPoint[0]=0; nextPoint[1]=0;
        }
    }
    else if(PointLength==3) {
        gradientArraySize[0]=gradientArraySizeC[0];
        gradientArraySize[1]=gradientArraySizeC[1];
        gradientArraySize[2]=gradientArraySizeC[2];
        startPoint1[0]=startPoint[0]-1.0; 
        startPoint1[1]=startPoint[1]-1.0; 
        startPoint1[2]=startPoint[2]-1.0;
        if(RK4STEP_3D(gradientArray, gradientArraySize, startPoint1, nextPoint, stepSize)) {
            nextPoint[0]=nextPoint[0]+1.0; 
            nextPoint[1]=nextPoint[1]+1.0; 
            nextPoint[2]=nextPoint[2]+1.0; 
        }
        else {
            nextPoint[0]=0; nextPoint[1]=0; nextPoint[2]=0;
        }
        
    }
    else {
        mexErrMsgTxt("Starting Point must be 2D or 3D");
    }
}

#include "mex.h"
#include "math.h"


/* The gateway routine */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  
  double *mean, *var, *list, *hist, value;
  int rows, cols, i, j, ival;

  /*  Check for proper number of arguments. */
  /* NOTE: You do not need an else statement when using 
     mexErrMsgTxt within an if statement. It will never 
     get to the else statement if mexErrMsgTxt is executed. 
     (mexErrMsgTxt breaks you out of the MEX-file.) 
  */ 
  if (nrhs != 1) 
    mexErrMsgTxt("One input required (listOfValues).");
  if (nlhs != 3) 
    mexErrMsgTxt("Three outputs required (mean, var, hist).");
  
  /* Create a pointer to the input arguments. */
  list = mxGetPr(prhs[0]);

  /* Get number of positions. */
  rows = mxGetM(prhs[0]);
  cols = mxGetN(prhs[0]);

  /* Set the output pointer to the output matrix. */
  plhs[0] = mxCreateDoubleMatrix(1,1, mxREAL);
  plhs[1] = mxCreateDoubleMatrix(1,1, mxREAL);  
  plhs[2] = mxCreateDoubleMatrix(1,10, mxREAL);  

  /* Create a C pointer to a copy of the output matrix. */
  mean = mxGetPr(plhs[0]);
  var = mxGetPr(plhs[1]);
  hist = mxGetPr(plhs[2]);

  for(i=0; i<rows; ++i){
    for(j=0; j<cols; ++j){
      value = *(list + i*rows + j);
      *mean += value;
      *var += value * value;	
      ival = (int) (value/10.0);
      *(hist + ((ival<10)?ival:9)) += 1;
    }
  } 

  *var = (*var - *mean*(*mean)/((double) rows*cols)) / ((double) rows*cols-1);
  *mean /= (double) rows*cols;
}



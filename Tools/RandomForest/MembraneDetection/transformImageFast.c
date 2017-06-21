#include "mex.h"
#include "math.h"

void transformImageFast(double *x, double *y, double *t, double *z, int mX, int nX, int mY, int nY)
{
  int i,j,count = 0;

  double t11,t21,t31,t12,t22,t32,t13,t23,t33;
  t11 = *(t); 
  t21 = *(t+1);
  t31 = *(t+2);
  t12 = *(t+3);
  t22 = *(t+4);
  t32 = *(t+5);
  t13 = *(t+6);
  t23 = *(t+7);
  t33 = *(t+8);

  /* 
   *
   * NOT NECESSARY AS ARRAY IS INITIALIZED WITH ZEROS
   *
   *for (i = 0; i < nX; i++)
   * {
   *   for (j = 0; j < mX; j++)
   *	{
   *	  *(z+count) = 0.0;
   *  count++;
   *}
   *}
   */
  count = 0;
  for (i = 0; i < nX; i++)
    {
      for (j = 0; j < mX; j++)
	{
	  double ynew1, ynew2, ynew3 = 0;

	  ynew1 = t11 * j + t21 * i + t31 * 100.0;
	  ynew2 = t12 * j + t22 * i + t32 * 100.0;
	  ynew3 = t13 * j + t23 * i + t33 * 100.0;

	  ynew1 = 100.0 * ynew1 / ynew3;
	  ynew2 = 100.0 * ynew2 / ynew3;

	  if ((ynew1 >= 0) & (ynew2 >= 0) & (ynew1 < mY) & (ynew2 < nY))
	    {
	      int ynew1a = ynew1;
	      int ynew2a = ynew2;

	      *(z + i*mX + j) = *(y + ynew2a*mY + ynew1a);
	    }
	  
	  
	}
    }
  
  /*
   * for c1=1:size(img1,1)
   * for c2=1:size(img1,2)
   *   ynew1 = T(1,1) * c1 + T(2,1) * c2 + T(3,1) * 100.0;
   *   ynew2 = T(1,2) * c1 + T(2,2) * c2 + T(3,2) * 100.0;
   *   ynew3 = T(1,3) * c1 + T(2,3) * c2 + T(3,3) * 100.0;
   *   ynew1 = int32(100.0 * ynew1 / ynew3);
   *   ynew2 = int32(100.0 * ynew2 / ynew3);
   *   if ((ynew1 > 0) & (ynew2 > 0) & (ynew1 <= size(img2,1)) & (ynew2 <= size(img2,2))) 
   *	img3(c1,c2) = img2(ynew1,ynew2);
   *      end;
   *    end;
   *  end;
   */  
}

/* The gateway routine */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  double *x, *y, *z, *t;
  int status,mXrows,nXcols,mYrows,nYycols;
  
  /*  Check for proper number of arguments. */
  /* NOTE: You do not need an else statement when using 
     mexErrMsgTxt within an if statement. It will never 
     get to the else statement if mexErrMsgTxt is executed. 
     (mexErrMsgTxt breaks you out of the MEX-file.) 
  */ 
  if (nrhs != 3) 
    mexErrMsgTxt("Three inputs required (ref image, image, matrix).");
  if (nlhs != 1) 
    mexErrMsgTxt("One output required.");
  
  
  /* Create a pointer to the input images x and y. */
  x = mxGetPr(prhs[0]);
  y = mxGetPr(prhs[1]);
  t = mxGetPr(prhs[2]);

  /* Get the dimensions of the matrix input y. */
  mXrows = mxGetM(prhs[0]);
  nXcols = mxGetN(prhs[0]);

  mYrows = mxGetM(prhs[1]);
  nYycols = mxGetN(prhs[1]);
  
  /* Set the output pointer to the output matrix. */
  plhs[0] = mxCreateDoubleMatrix(mXrows,nXcols, mxREAL);
  
  /* Create a C pointer to a copy of the output matrix. */
  z = mxGetPr(plhs[0]);
  
  /* Call the C subroutine. */
  transformImageFast(x,y,t,z,mXrows,nXcols, mYrows, nYycols);
}

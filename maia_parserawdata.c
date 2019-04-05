/*==========================================================
 * arrayProduct.c - example in MATLAB External Interfaces
 *
 * Multiplies an input scalar (multiplier) 
 * times a 1xN matrix (inMatrix)
 * and outputs a 1xN matrix (outMatrix)
 *
 * The calling syntax is:
 *
 *              outMatrix = arrayProduct(multiplier, inMatrix)
 *
 * This is a MEX-file for MATLAB.
 * Copyright 2007-2012 The MathWorks, Inc.
 *
 *========================================================*/

#include "mex.h"



void maia_parserawdata(double len, double *rawdata, double *addr, double *pd, double *td, double *ts)
{
  int i;  
  unsigned int val1,val2;
  unsigned int loop;

  loop=0;
  for (i=0; i<len; i=i+2) {
      val1 = *rawdata++;
      val2 = *rawdata++;

      /*addr[loop] = val1 & 0x000000FF;
      pd[loop] = (val1 & 0xFF000000) >> 24;
      td[loop] = val2 & 0x000000FF;
      ts[loop] = (val2 & 0xFF000000) >> 24; */
      
      
      addr[loop] = (val1 & 0x7FC00000) >> 22;  
      td[loop] =  (val1 & 0x003FF000) >> 12; 
      pd[loop] = (val1 & 0x00000FFF);
      ts[loop] = (val2 & 0x7FFFFFFF);
      loop++;
  }   
}



/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    double len;                     /* input scalar */
    double *rawdata;               /* 1xN input matrix */
    double *addr, *pd, *td, *ts;
    
    size_t ncols;                   /* size of matrix */
    
    /* check for proper number of arguments */
    if(nrhs!=2) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","Two inputs required.");
    }
    if(nlhs!=4) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nlhs","Four outputs required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsDouble(prhs[0]) ||
         mxIsComplex(prhs[0]) ||
         mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Input length must be a scalar.");
    }

    /* make sure the second input argument is type double */
    if( !mxIsDouble(prhs[1]) ||
         mxIsComplex(prhs[1])) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notDouble","Input matrix must be type double.");
    }
     
    /* check that number of rows in second input argument is 1 */
    if(mxGetM(prhs[1])!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notRowVector","Input must be a row vector.");
    }

    /* get the value of the scalar input  */
    len = mxGetScalar(prhs[0]);

    /* create a pointer to the real data in the input matrix  */
    rawdata = mxGetPr(prhs[1]);

    /* get dimensions of the input matrix */
    ncols = mxGetN(prhs[1]);

    /* create the output addr matrix */
    plhs[0] = mxCreateDoubleMatrix(1,(mwSize)ncols/2,mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,(mwSize)ncols/2,mxREAL);
    plhs[2] = mxCreateDoubleMatrix(1,(mwSize)ncols/2,mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1,(mwSize)ncols/2,mxREAL);

    
    

    /* get a pointer to the real data in the output matrix */
    addr = mxGetPr(plhs[0]);
    pd   = mxGetPr(plhs[1]);
    td   = mxGetPr(plhs[2]);
    ts   = mxGetPr(plhs[3]);  
    

    /* call the computational routine */
    maia_parserawdata(len,rawdata,addr,pd,td,ts);
}
                                                           

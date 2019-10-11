#include "mex.h"

#ifdef _WIN32
#include <Windows.h>
#elif __APPLE__
#include <mach-o/dyld.h>
#elif __linux__    
#include <unistd.h>
#else
#error Unsupported platform
#endif

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {  
    /* Preallocated buffer */
    char buffer[2048];
    unsigned int s = sizeof(buffer);
    // Call platform dependent function to obtain executable location
#ifdef _WIN32
    if(!GetModuleFileName(NULL,buffer,s)) {
        mexErrMsgTxt("Unabled to determine executable location\n");
    }
#elif __APPLE__
    if(_NSGetExecutablePath(buffer, &s)!=0) {
        mexErrMsgTxt("Unabled to determine executable location\n");
    }
#elif __linux__    
    if(readlink("/proc/self/exe", buffer, s)<0) {
        mexErrMsgTxt("Unabled to determine executable location\n");
    }
#endif
    /* Output the buffer in the form of a MATLAB character array */
    plhs[0] = mxCreateString(buffer);
}
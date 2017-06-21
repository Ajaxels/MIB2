% This script will compile all the C files of the registration methods
cd('functions');
files=dir('*.c');
clear msfm2d
%mex('msfm2d.c');
mex msfm2d.c -v;
clear msfm3d
%mex('msfm3d.c');
mex msfm3d.c -v;
cd('..');

cd('shortestpath');
clear rk4
%mex('rk4.c');
mex rk4.c -v;
cd('..')

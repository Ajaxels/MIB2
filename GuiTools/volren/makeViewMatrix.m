function Mview=makeViewMatrix(r,s,t)
% function makeViewMatrix construct a 4x4 transformation matrix from
% rotation, resize and translation variables.
%
% Mview=makeViewMatrix(R,S,T)
% 
% inputs,
%  R: Rotation vector [Rx, Ry, Rz];
%  S: Resize vector [Sx, Sy, Sz];
%  T: Translation vector [Tx, Ty, Tz];
%
% outputs,
%  Mview: 4x4 transformation matrix
%
% Example,
%   Mview=makeViewMatrix([45 45 0],[1 1 1],[0 0 0]);
%   disp(Mview);
%
% Function is written by D.Kroon University of Twente (October 2008)

R=RotationMatrix(r);
S=ResizeMatrix(s);
T=TranslateMatrix(t);
Mview=R*S*T;

function R=RotationMatrix(r)
% Determine the rotation matrix (View matrix) for rotation angles xyz ...
    Rx=[1 0 0 0; 0 cosd(r(1)) -sind(r(1)) 0; 0 sind(r(1)) cosd(r(1)) 0; 0 0 0 1];
    Ry=[cosd(r(2)) 0 sind(r(2)) 0; 0 1 0 0; -sind(r(2)) 0 cosd(r(2)) 0; 0 0 0 1];
    Rz=[cosd(r(3)) -sind(r(3)) 0 0; sind(r(3)) cosd(r(3)) 0 0; 0 0 1 0; 0 0 0 1];
    R=Rx*Ry*Rz;
    
function S=ResizeMatrix(s)
	S=[1/s(1) 0 0 0;
	   0 1/s(2) 0 0;
	   0 0 1/s(3) 0;
	   0 0 0 1];

function T=TranslateMatrix(t)
	T=[1 0 0 -t(1);
	   0 1 0 -t(2);
	   0 0 1 -t(3);
	   0 0 0 1];

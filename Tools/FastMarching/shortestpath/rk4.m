% RK4 is a function which performs one step of the Runge-Kutta 4 ray tracing
%
% EndPoint = RK4(StartPoint, GradientVolume, StepSize);
%
%  inputs :
%      StartPoint: 2D or 3D location in vectorfield
%      GradientVolume: Vectorfield
%      Stepsize : The stepsize
%
% outputs :
%      EndPoint : The new location (zero if outside image)
%
% note: This function is c-coded thus first compile it "mex rk4.c"
%
% Function is written by D.Kroon University of Twente (July 2008)

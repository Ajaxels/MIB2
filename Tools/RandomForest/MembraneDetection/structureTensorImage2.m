%[eig1, eig2, cw] = structureTensorImage2(im, s, sg)
%s: smoothing sigma
%sg: sigma gaussian for summation weights
%window size is adapted
function [eig1, eig2, cw] = structureTensorImage2(im, s, sg)
  w = 2*sg;
  [gx,gy,mag] = gradientImg(double(im),s);
  clear mag;
  
  S_0_x = gx.*gx;
  S_0_xy = gx.*gy;
  S_0_y = gy.*gy;
  
  clear gx
  clear gy
 
  sum_x = 1/(2*pi*sg^2) * S_0_x;
  sum_y = 1/(2*pi*sg^2) *S_0_y;
  sum_xy = 1/(2*pi*sg^2) *S_0_xy;
  
  %sum_x
  sl = sum_x;
  sr = sum_x;
  su = sum_x;
  sd = sum_x;
  for m = 1:w
    mdiag = sqrt(2*m^2);
    sl = shiftLeft(sl);
    sr = shiftRight(sr);
    su = shiftUp(su);
    sd = shiftDown(sd);
    
    sum_x = sum_x + 1/(2*pi*sg^2)*exp(-(-m^2)/(2*sg^2))*(sl + sr + su + sd) + 1/(2*pi*sg^2)*exp(-(mdiag^2+mdiag^2)/(2*sg^2))*(shiftLeft(su) + shiftRight(su) + shiftLeft(sd) + shiftRight(sd));
  end
  
  %sum_y
  sl = sum_y;
  sr = sum_y;
  su = sum_y;
  sd = sum_y;
  for m = 1:w
    mdiag = sqrt(2*m^2);
    sl = shiftLeft(sl);
    sr = shiftRight(sr);
    su = shiftUp(su);
    sd = shiftDown(sd);
    
    sum_y = sum_y + 1/(2*pi*sg^2)*exp(-(-m^2)/(2*sg^2))*(sl + sr + su + sd) + 1/(2*pi*sg^2)*exp(-(mdiag^2+mdiag^2)/(2*sg^2))*(shiftLeft(su) + shiftRight(su) + shiftLeft(sd) + shiftRight(sd));
  end
  
  %sum_xy
  sl = sum_xy;
  sr = sum_xy;
  su = sum_xy;
  sd = sum_xy;
  for m = 1:w
    mdiag = sqrt(2*m^2);
    sl = shiftLeft(sl);
    sr = shiftRight(sr);
    su = shiftUp(su);
    sd = shiftDown(sd);
    
    sum_xy = sum_xy + 1/(2*pi*sg^2)*exp(-(-m^2)/(2*sg^2))*(sl + sr + su + sd) + 1/(2*pi*sg^2)*exp(-(mdiag^2+mdiag^2)/(2*sg^2))*(shiftLeft(su) + shiftRight(su) + shiftLeft(sd) + shiftRight(sd));
  end
  
  clear sl 
  clear sr
  clear su
  clear sd

  eig1 = zeros(size(im));
  eig2 = zeros(size(im));
  for i=1:length(im(:))
    e2 = (sum_x(i) + sum_y(i))/2 + sqrt(4*sum_xy(i)*sum_xy(i)+(sum_x(i)-sum_y(i))^2)/2;
    e1 = (sum_x(i) + sum_y(i))/2 - sqrt(4*sum_xy(i)*sum_xy(i)+(sum_x(i)-sum_y(i))^2)/2;
    eig1(i) = e1;
    eig2(i) = e2;
  end
  
  cw = ((eig1-eig2)./(eig1+eig2)).^2;
  cw(isnan(cw)) = 0;
function T = th_maxlik(I,n)
% T =  th_maxlik(I,n)
%
% Find a global threshold for a grayscale image using the maximum likelihood
% via expectation maximization method.
%
% In:
%  I    grayscale image
%  n    maximum graylevel (defaults to 255)
%
% Out:
%  T    threshold
%
% References: 
%
% A. P. Dempster, N. M. Laird, and D. B. Rubin, "Maximum likelihood from
% incomplete data via the EM algorithm," Journal of the Royal Statistical
% Society, Series B, vol. 39, pp. 1-38, 1977.
%
% C. A. Glasbey, "An analysis of histogram-based thresholding algorithms,"
% CVGIP: Graphical Models and Image Processing, vol. 55, pp. 532-537, 1993.
%
%% Copyright (C) 2004-2013 Antti Niemistö
%%
%% This file is part of HistThresh toolbox.
%%
%% HistThresh toolbox is free software: you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation, either version 3 of the License, or
%% (at your option) any later version.
%%
%% HistThresh toolbox is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with HistThresh toolbox.  If not, see <http://www.gnu.org/licenses/>.

if nargin == 1
  n = 255;
end

I = double(I);

% Calculate the histogram.
y = hist(I(:),0:n);

% The initial estimate for the threshold is found with the MINIMUM
% algorithm.
T = th_minimum(I,n);

% Calculate initial values for the statistics.
mu = B(y,T)/A(y,T);
nu = (B(y,n)-B(y,T))/(A(y,n)-A(y,T));
p = A(y,T)/A(y,n);
q = (A(y,n)-A(y,T)) / A(y,n);
sigma2 = C(y,T)/A(y,T)-mu^2;
tau2 = (C(y,n)-C(y,T)) / (A(y,n)-A(y,T)) - nu^2;

% Return if sigma2 or tau2 are zero, to avoid division by zero
if sigma2 == 0 | tau2 == 0
  return
end

mu_prev = NaN;
nu_prev = NaN;
p_prev = NaN;
q_prev = NaN;
sigma2_prev = NaN;
tau2_prev = NaN;

while true
  for i = 0:n
    phi(i+1) = p/sqrt((sigma2)) * exp(-((i-mu)^2) / (2*sigma2)) / ...
        (p/sqrt(sigma2) * exp(-((i-mu)^2) / (2*sigma2)) + ...
         (q/sqrt(tau2)) * exp(-((i-nu)^2) / (2*tau2)));
  end

  ind = 0:n;
  gamma = 1-phi;
  F = phi*y';
  G = gamma*y';
  p_prev = p;
  q_prev = q;
  mu_prev = mu;
  nu_prev = nu;
  sigma2_prev = nu;
  tau2_prev = nu;
  p = F/A(y,n);
  q = G/A(y,n);
  mu = ind.*phi*y'/F;
  nu = ind.*gamma*y'/G;
  sigma2 = ind.^2.*phi*y'/F - mu^2;
  tau2 = ind.^2.*gamma*y'/G - nu^2;

  if (abs(mu-mu_prev) < eps | abs(nu-nu_prev) < eps | ...
      abs(p-p_prev) < eps | abs(q-q_prev) < eps | ...
      abs(sigma2-sigma2_prev) < eps | abs(tau2-tau2_prev) < eps)
    break;
  end

end

% The terms of the quadratic equation to be solved.
w0 = 1/sigma2-1/tau2;
w1 = mu/sigma2-nu/tau2;
w2 = mu^2/sigma2 - nu^2/tau2 + log10((sigma2*q^2)/(tau2*p^2));
  
% If the threshold would be imaginary, return with threshold set to zero.
sqterm = w1^2-w0*w2;
if sqterm < 0;
  T = 0;
  return
end

% The threshold is the integer part of the solution of the quadratic
% equation.
T = floor((w1+sqrt(sqterm))/w0);

function f = mibOscResampling(x)
% function f = mibOscResampling(x)
% resample image usng OSC method
%
% taken from https://se.mathworks.com/help/matlab/creating_plots/create-and-compare-resizing-interpolation-kernels.html
% Reference
% Hu, Min, and Jieqing Tan.
% "Adaptive Osculatory Rational Interpolation for Image Processing."
% Journal of Computational and Applied Mathematics 195, no. 1–2 (October 2006): 46–53.
% https://doi.org/10.1016/j.cam.2005.07.011.

absx = abs(x);
absx2 = absx.^2;

f = (absx <= 1) .* ...
    ((-0.168*absx2 - 0.9129*absx + 1.0808) ./ ...
    (absx2 - 0.8319*absx + 1.0808)) ...
    + ...
    ((1 < absx) & (absx <= 2)) .* ...
    ((0.1953*absx2 - 0.5858*absx + 0.3905) ./ ...
    (absx2 - 2.4402*absx + 1.7676));
end
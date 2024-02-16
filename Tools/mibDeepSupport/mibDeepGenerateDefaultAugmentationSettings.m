% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 06.11.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function augmentationSettings = mibDeepGenerateDefaultAugmentationSettings(mode)
% function augmentationSettings = mibDeepGenerateDefaultAugmentationSettings(mode)
% generate default augmentation settings from MIB 2.8455
%
% Parameters:
% mode: string '2D', '3D' specifying type of augmentation settings
%
% Return values:
% augmentationSettings: structure with augmentation settings

augmentationSettings = struct();
augmentationSettings.Fraction = 1;
augmentationSettings.FillValue = 255;
augmentationSettings.RandXReflection.Enable = true;
augmentationSettings.RandXReflection.Probability = 0.2;
augmentationSettings.RandXReflection.Min = [];
augmentationSettings.RandXReflection.Max = [];

augmentationSettings.RandYReflection.Enable = true;
augmentationSettings.RandYReflection.Probability = 0.2;
augmentationSettings.RandYReflection.Min = [];
augmentationSettings.RandYReflection.Max = [];

augmentationSettings.Rotation90.Enable = true;
augmentationSettings.Rotation90.Probability = 0.2;
augmentationSettings.Rotation90.Min = [];
augmentationSettings.Rotation90.Max = [];

augmentationSettings.ReflectedRotation90.Enable = true;
augmentationSettings.ReflectedRotation90.Probability = 0.2;
augmentationSettings.ReflectedRotation90.Min = [];
augmentationSettings.ReflectedRotation90.Max = [];

augmentationSettings.RandRotation.Enable = true;
augmentationSettings.RandRotation.Probability = 0.15;
augmentationSettings.RandRotation.Min = -10;
augmentationSettings.RandRotation.Max = 10;

augmentationSettings.PoissonNoise.Enable = true;
augmentationSettings.PoissonNoise.Probability = 0.1;
augmentationSettings.PoissonNoise.Min = [];
augmentationSettings.PoissonNoise.Max = [];

augmentationSettings.GaussianNoise.Enable = true;
augmentationSettings.GaussianNoise.Probability = 0.2;
augmentationSettings.GaussianNoise.Min = 0;
augmentationSettings.GaussianNoise.Max = 0.005;

augmentationSettings.ImageBlur.Enable = true;
augmentationSettings.ImageBlur.Probability = 0.2;
augmentationSettings.ImageBlur.Min = 0;
augmentationSettings.ImageBlur.Max = 0.5;

augmentationSettings.RandScale.Enable = true;
augmentationSettings.RandScale.Probability = 0.1;
augmentationSettings.RandScale.Min = 1;
augmentationSettings.RandScale.Max = 1.1;

augmentationSettings.RandXScale.Enable = true;
augmentationSettings.RandXScale.Probability = 0.1;
augmentationSettings.RandXScale.Min = 1;
augmentationSettings.RandXScale.Max = 1.1;

augmentationSettings.RandYScale.Enable = true;
augmentationSettings.RandYScale.Probability = 0.1;
augmentationSettings.RandYScale.Min = 1;
augmentationSettings.RandYScale.Max = 1.1;

augmentationSettings.RandXShear.Enable = true;
augmentationSettings.RandXShear.Probability = 0.1;
augmentationSettings.RandXShear.Min = -10;
augmentationSettings.RandXShear.Max = 10;

augmentationSettings.RandYShear.Enable = true;
augmentationSettings.RandYShear.Probability = 0.1;
augmentationSettings.RandYShear.Min = -10;
augmentationSettings.RandYShear.Max = 10;

augmentationSettings.BrightnessJitter.Enable = true;
augmentationSettings.BrightnessJitter.Probability = 0.2;
augmentationSettings.BrightnessJitter.Min = -0.1;
augmentationSettings.BrightnessJitter.Max = 0.1;

augmentationSettings.ContrastJitter.Enable = true;
augmentationSettings.ContrastJitter.Probability = 0.2;
augmentationSettings.ContrastJitter.Min = 0.9;
augmentationSettings.ContrastJitter.Max = 1.1;

augmentationSettings.HueJitter.Enable = true;
augmentationSettings.HueJitter.Probability = 0.2;
augmentationSettings.HueJitter.Min = -0.03;
augmentationSettings.HueJitter.Max = 0.03;

augmentationSettings.SaturationJitter.Enable = true;
augmentationSettings.SaturationJitter.Probability = 0.2;
augmentationSettings.SaturationJitter.Min = -0.05;
augmentationSettings.SaturationJitter.Max = 0.05;

if strcmp(mode, '3D')
    augmentationSettings.RandZReflection.Enable = true;
    augmentationSettings.RandZReflection.Probability = 0.2;
    augmentationSettings.RandZReflection.Min = [];
    augmentationSettings.RandZReflection.Max = [];
end


end
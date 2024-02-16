% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 06.11.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function augSettingsNew = mibDeepConvertOldAugmentationSettingsToNew(augSettingsOld, mode)
% function augSettingsNew = mibDeepConvertOldAugmentationSettingsToNew(augSettingsOld, mode)
% supporting function for DeepMIB, the function converts old augmentation
% settings to the new set of settings from MIB 2.8455
%
% Parameters:
% augSettingsOld: structure with old augmentation settings 
% mode: string '2D', '3D' specifying type of augmentation settings
% Return values:
% augSettingsNew: structure with new augmentation settings 

oldFieldNames = fieldnames(augSettingsOld);
augSettingsNew = struct();

if numel(augSettingsOld.RandXReflection) == 1   % very old augmentation settings
    augSettingsNew = mibDeepGenerateDefaultAugmentationSettings(mode);
    return;
end

% one of other ways to switch off augmentation was to make the
% variation to 0 or 1
augsDisabledWhenVariationZero = {'RandRotation', 'GaussianNoise', 'ImageBlur', ...
    'RandXShear', 'RandYShear', 'BrightnessJitter', ...
    'HueJitter', 'SaturationJitter'};
augsDisabledWhenVariationOne = {'RandScale', 'RandXScale', 'RandYScale', ...
    'ContrastJitter'};

for fieldId=1:numel(oldFieldNames)
    switch oldFieldNames{fieldId}
        case {'Fraction', 'FillValue'}
            augSettingsNew.(oldFieldNames{fieldId}) = augSettingsOld.(oldFieldNames{fieldId});
        otherwise
            augSettingsNew.(oldFieldNames{fieldId}).Enable = true;
            augSettingsNew.(oldFieldNames{fieldId}).Probability = 0;
            augSettingsNew.(oldFieldNames{fieldId}).Min = [];
            augSettingsNew.(oldFieldNames{fieldId}).Max = [];

            if numel(augSettingsOld.(oldFieldNames{fieldId})) == 2
                augSettingsNew.(oldFieldNames{fieldId}).Enable = logical(augSettingsOld.(oldFieldNames{fieldId})(1));
                augSettingsNew.(oldFieldNames{fieldId}).Probability = augSettingsOld.(oldFieldNames{fieldId})(2);
            else
                augSettingsNew.(oldFieldNames{fieldId}).Min = augSettingsOld.(oldFieldNames{fieldId})(1);
                augSettingsNew.(oldFieldNames{fieldId}).Max = augSettingsOld.(oldFieldNames{fieldId})(2);
                augSettingsNew.(oldFieldNames{fieldId}).Probability = augSettingsOld.(oldFieldNames{fieldId})(3);
                if augSettingsNew.(oldFieldNames{fieldId}).Probability == 0 || ...
                        augSettingsNew.(oldFieldNames{fieldId}).Min == augSettingsNew.(oldFieldNames{fieldId}).Max
                    augSettingsNew.(oldFieldNames{fieldId}).Enable = false;
                end
            end
    
            % when probability is 0, make sure that the augmentation is
            % turned off
            if augSettingsNew.(oldFieldNames{fieldId}).Probability == 0
                augSettingsNew.(oldFieldNames{fieldId}).Enable = false;
            end
            
            % one of other ways to switch off augmentation was to make the
            % variation to 0 or 1
            if ismember(oldFieldNames{fieldId}, augsDisabledWhenVariationZero) && ...
                        augSettingsNew.(oldFieldNames{fieldId}).Min == 0 && augSettingsNew.(oldFieldNames{fieldId}).Max == 0
                augSettingsNew.(oldFieldNames{fieldId}).Enable = false;
            end
            if ismember(oldFieldNames{fieldId}, augsDisabledWhenVariationOne) && ...
                        augSettingsNew.(oldFieldNames{fieldId}).Min == 1 && augSettingsNew.(oldFieldNames{fieldId}).Max == 1
                augSettingsNew.(oldFieldNames{fieldId}).Enable = false;
            end
            
    end
end
end

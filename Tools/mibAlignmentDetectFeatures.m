function points = mibAlignmentDetectFeatures(image, detector, options)
% function points = mibAlignmentDetectFeatures(image, detector, options)
% detect feature points for image, this function is used in
% AutomaticFeatureBasedAlignment function in mibAlignmentController
%
% Parameters:
% image: image that should be used to detect features
% detector: string with defenition of point detector type
%  @li 'Blobs: Speeded-Up Robust Features (SURF) algorithm' -> detectSURFFeatures
%  @li 'Blobs: Detect scale invariant feature transform (SIFT)' -> detectSIFTFeatures
%  @li 'Regions: Maximally Stable Extremal Regions (MSER) algorithm' -> detectMSERFeatures
%  @li 'Corners: Harris-Stephens algorithm' -> detectHarrisFeatures
%  @li 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)' -> detectBRISKFeatures
%  @li 'Corners: Features from Accelerated Segment Test (FAST)' -> detectFASTFeatures
%  @li 'Corners: Minimum Eigenvalue algorithm' -> detectMinEigenFeatures
%  @li 'Oriented FAST and rotated BRIEF (ORB)' -> detectORBFeatures
% options: structure with settings for each
% .detectSURFFeatures
% .detectMSERFeatures
% .detectHarrisFeatures
% .detectBRISKFeatures
% .detectFASTFeatures
% .detectMinEigenFeatures
% .detectORBFeatures
%
% Return values:
% points: structure with parameters that describe the detected points,
% below the list of fields for detectSURFFeatures
% .Scale - [661×1 single]
% .SignOfLaplacian - [661×1 int8]
% .Orientation - [661×1 single]
% .Location - [661×2 single]
% .Metric - [661×1 single]
% .Count - 661

points = [];

switch detector
    case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
        detectOpt = options.detectSURFFeatures;
        points  = detectSURFFeatures(image,  'MetricThreshold', detectOpt.MetricThreshold, 'NumOctaves', detectOpt.NumOctaves, 'NumScaleLevels', detectOpt.NumScaleLevels);
    case 'Blobs: Detect scale invariant feature transform (SIFT)'
        detectOpt = options.detectSIFTFeatures;
        points  = detectSIFTFeatures(image,  'ContrastThreshold', detectOpt.ContrastThreshold, 'EdgeThreshold', detectOpt.EdgeThreshold, ...
            'NumLayersInOctave', detectOpt.NumLayersInOctave, 'Sigma', detectOpt.Sigma);
    case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
        detectOpt = options.detectMSERFeatures;
        points  = detectMSERFeatures(image, 'ThresholdDelta', detectOpt.ThresholdDelta, 'RegionAreaRange', detectOpt.RegionAreaRange, 'MaxAreaVariation', detectOpt.MaxAreaVariation);
    case 'Corners: Harris-Stephens algorithm'
        detectOpt = options.detectHarrisFeatures;
        points  = detectHarrisFeatures(image, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
    case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
        detectOpt = options.detectBRISKFeatures;
        points  = detectBRISKFeatures(image, 'MinContrast', detectOpt.MinContrast, 'MinQuality', detectOpt.MinQuality, 'NumOctaves', detectOpt.NumOctaves);
    case 'Corners: Features from Accelerated Segment Test (FAST)'
        detectOpt = options.detectFASTFeatures;
        points  = detectFASTFeatures(image, 'MinQuality', detectOpt.MinQuality, 'MinContrast', detectOpt.MinContrast);
    case 'Corners: Minimum Eigenvalue algorithm'
        detectOpt = options.detectMinEigenFeatures;
        points  = detectMinEigenFeatures(image, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
    case 'Oriented FAST and rotated BRIEF (ORB)'
        detectOpt = options.detectORBFeatures;
        points  = detectORBFeatures(image, 'ScaleFactor', detectOpt.ScaleFactor, 'NumLevels', detectOpt.NumLevels);
end

end
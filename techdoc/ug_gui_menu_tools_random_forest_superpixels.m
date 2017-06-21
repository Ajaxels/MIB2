%% Classifier of superpixels / supervoxels
% Classifier of superpixels/supervoxels is a good method for automatic segmentation of images
% using _train_ and _predict_ scheme. 
%
% This classifier uses the <http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html 
% *SLIC (Simple Linear Iterative Clustering) algorithm*> written by Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, 
% Pascal Fua, and Sabine Süsstrunk, Ecole Polytechnique Federale de
% Lausanne (EPFL), Switzerland to simplify the dataset by clustering of
% pixels into groups: superpixels for 2D or supervoxels for 3D. Each of
% these superpixels/voxels is characterized and these characteristics are
% used for the classification.
% 
% The example of use is presented below.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools*>
%
%% Dataset and the aim of the segmentation
% Below is a dataset imaged with light microscopy where the aim is to
% segment the outlines of the cells (in green). The cells have different
% intensity and can't be directly segemented using the black-and-white
% thresholding.
% 
% 
% <<images/superpix_01.jpg>>
% 
%
%% Training the classifier
% The first part of the classification is to select areas that belong to
% the object of interest and background.
% 
%
% * Start a new model: |Segmentation Panel->the Create button|
% * Add two materials for the model: |Segmentation Panel->the + button|
% * Rename material 1 to |Object| and material 2 to |Background|. Highlight
% material in the left list box, press the right mouse button and select
% |Rename| in the popup menu
% 
% 
% <<images/random_forest_2.jpg>>
% 
% 
% * Select the Brush tool and select some profiles of the endoplasmic
% reticulum and assign them to the |Object| material of the model (_select
% '1' in the 'Add to' list and press the 'A' shortcut_)
% * Select few areas of the background and add those to the |Background|
% material of the model (_select '2' in the 'Add to' list and press the 'A' shortcut_)
% 
% 
% 
% <<images/superpix_02.jpg>>
% 
% * Start the Classifier: |Menu->Tools->Classifier->Superpixel classification|
% * Specify a directory to keep temporary data. By default, MIB offers to
% use |RF_Temp| located next to the data.
% 
% 
% <<images/superpix_03.jpg>>
% 
%
% * Select the mode to use: |2D| for 2D images and superpixels or 3D for 3D datasets and supervoxels
% * Select the type of superpixels to calculate: |SLIC| for objects with
% distinct intensity vs background or |Watershed| for objects that have
% distinct boundaries
% * Select the color channel that should be used to generate superpixels/voxels: |Color channel|
% * Define size for superpixels/voxels and their compactness: |Size| and
% |Compactness|. For the |Watershed| superpixels the |Size| field defines a
% factor that regulates size of superpixels (larger number gives bigger
% superpixels) and the |Black on white| field. When the boundaries of objects are
% bright over dark background, the |Black on white| should be 0; otherwise
% any number bigger than 0.
% * If needed the area for processing can be modified using the Subarea
% panel. 
% * Press the |Calculate superpixels| button to generate SLIC superpixels
% * Press the |Preview superpixels| button to see the generated superpixels
% 
% 
% <<images/superpix_04.jpg>>
% 
%
%
% * If size and quality of superpixels is acceptable press the |Calculate
% features| button to calculate features for the superpixels.
% * Press the |Train & Predict button| to access settings for the
% classification
% 
% 
% 
% <<images/superpix_05.jpg>>
% 
% In this window it is possible either load classifier from the training
% session done earlier (|the Load classifier button|), or train a new one if labels exist.
% 
%
% * Select |Object| in the |Object| popup menu
% * Select |Background| in the |Background| popup menu
% * Choose type of the classifier to use in the |Classifier| popup menu
% * Press the |Train classifier| to start the training session
% * Press the |Predict dataset| to start the prediction session
% * Check results in the |Image View panel|. If needed add more markers for
% the Object and Background and repeat Training and Prediction.
% 
% <<images/superpix_06.jpg>>
% 
%
%% Wiping the temp directory
% During the prediction the classifier creates files
% in the |RF_Temp| directory. This directory can be deleted by pressing the
% |Wipe Temp dir| button or manually using any file explorer.
%
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools*>
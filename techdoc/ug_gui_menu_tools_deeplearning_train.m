%% Deep MIB - Train tab
% This tab contains settings for generating deep convolutional network and training.
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools
% Menu*> |*-->*| <ug_gui_menu_tools_deeplearning.html *Deep learning segmentation*>
% 
%
%% Train tab
% 
% <<images\DeepLearningTrain.png>>
%
%
% <html>
% Before starting the training process it is important to check and adapt
% the default settings to needs of the specific project.<br>
% As the starting point make sure the name of the output network is selected using 
% the <span class="kbd">Network filename</span> button of the <b>Network
% panel</b>.
% </html>
%
%% Network design
%
% The *Network design* section is used to set the network configuration
% settings. Please check the following list to understand details of available 
% configuration options.
%
% <<images\DeepLearningTrain_networkdesign.png>>
%
% [dtls][smry] *Widgets of the Network design section* [/smry]
%
% <html>
% <ul>
% <li><span class="dropdown">Input patch size...</span>, this is an important field that has to be defined 
% based on available memory of GPU, desired size of image area that network can see at once, dimensions of the training dataset and 
% number of color channels.<br>
% The input patch size defines dimensions of a single image block that will be
% directed into the network for training. The dimensions are always
% defined with 4 numbers representing <em>height, width, depth, colors</em> of the
% image patch (for example, type "572 572 1 2" to specify a 2D patch of
% 572x572 pixels, 1 z-slice and 2 color channels).<br>
% The patches are taken randomly from the volume/image and number of those
% patches can be specified in the <span class="dropdown">Patches per
% image...</span> editbox.
% </li>
% <li><span class="dropdown">Padding &#9660;</span> defines type of the convolution padding, depending on
% the selected padding the <em>Input patch size</em> may have to be
% adjusted; use the <span class="kbd">Check network</span> button to make
% sure that the input patch size is correctly matching the selected padding.
% <ul>
% <li><b><em>same</em></b> - zero padding is applied to the inputs to convolution 
% layers such that the output and input feature maps are the same size</li>
% <li><b><em>valid</em></b> - zero padding is not applied to the inputs to 
% convolution layers. The convolution layer returns only values of the convolution 
% that are computed without zero padding. The output feature map is smaller 
% than the input feature map. <b><em>Valid</em></b> padding in general produces results with less edge artefacts, 
% but the overlap prediction mode for <b><em>Same</em></b> padding is capable to also minimize the artefacts.</li>
% </ul>
% </li>
% <li><span class="dropdown">Number of classes...</span> - number of materials of the model <b>including Exterior</b>, specified as a positive number</li>
% <li><span class="dropdown">Encoder depth...</span> - number of encoding and decoding layers of the
% network. U-Net is composed of an encoder subnetwork and a corresponding decoder subnetwork. 
% The depth of these networks determines the number of times the input image is 
% downsampled or upsampled during processing. The encoder network downsamples 
% the input image by a factor of 2^D, where D is the value of EncoderDepth. 
% The decoder network upsamples the encoder network output by a factor of 2^D.<br>
% The <span class="dropdown">Downsampling factor...</span> editbox in the
% <em><b>Beta version</em></b> can be used to tweak the downsampling factor
% to increase the input patch size so that network sees a larger area.</li>
% <li><span class="dropdown">Filters...</span> - number of output channels for the
% first encoder stage, <em>i.e.</em> number of convolitional filters used to process the input image patch during the first stage.
% In each subsequent encoder stage, the number of output channels doubles. 
% The unetLayers function sets the number of output channels in each decoder 
% stage to match the number in the corresponding encoder stage</li>
% <li><span class="dropdown">Filter size...</span> - convolutional layer filter size; typical values are <span class="code">3</span>, 
% <span class="code">5</span>, <span class="code">7</span></li>
% <li>The <span class="kbd">Input layer</span> button - press to specify
% settings for normalization of images during training. </li>
% <li><span class="kbd">[&#10003;] <b>use ImageNet weights</b></span> (<b><em>only for MATLAB version of MIB</em></b>), 
% when checked the networks of the 2D patch-wise workflow are initialized
% using pretrained weights from training on more than a million images from the <a href="http://www.image-net.org">ImageNet database</a>
% This requires that supporting packages for the corresponding networks are installed and allows to boost the training process significantly</li>
% <li><span class="dropdown">Activation layer &#9660;</span> - specifies type of the activation layers of
% the network. When the layer may have additional options, the settings
% button <img src="images\DeepLearningTrainSettingsBtn.png"> on the right-hand side becomes available.
% </li>
% </ul>
% </html>
% 
% [dtls][smry] *List of available activation layers* [/smry]
%
% <html>
% With DeepMIB, the users have a possibility to define the activation layer
% using one of the options listed below. For comparison of the different
% activation layers check <a
% href="https://se.mathworks.com/help/deeplearning/ug/compare-activation-layers.html">this
% link</a><br><br>
% <ul>
% <li><em>reluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.relulayer.html">
% Rectified Linear Unit (ReLU) layer</a>, it is a default activation layer of the networks, 
% however it can be replaced with any of other layer below</li>
% <li><em>leakyReluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.leakyrelulayer.html">
% Leaky Rectified Linear Unit layer</a> performs a threshold operation, 
% where any input value less than zero is multiplied by a fixed scalar</li>
% <li><em>clippedReluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.clippedrelulayer.html">
% Clipped Rectified Linear Unit (ReLU) layer</a> performs a threshold 
% operation, where any input value less than zero is set to zero and any value above the 
% clipping ceiling is set to that clipping ceiling</li>
% <li><em>eluLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.elulayer.html">
% Exponential linear unit (ELU) layer</a> performs the identity operation on positive inputs and an 
% exponential nonlinearity on negative inputs</li>
% <li><em>swishLayer</em> - A <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.swishlayer.html">
% swish activation layer</a> applies the applies the swish function (f(x) = x / (1+e^(-x)) ) on the layer inputs</li>
% <li><em>tanhLayer</em> - <a href="https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.tanhlayer.html">
% Hyperbolic tangent (tanh) layer</a> applies the tanh function on the layer inputs</li>
% </ul>
% </html>
%
% [/dtls]
%
% <html>
% <ul>
% <li><span class="dropdown">Segmentation layer &#9660;</span> - specifies the output layer of the
% network; depending on selection the settings button <img src="images\DeepLearningTrainSettingsBtn.png"> on the right-hand side
% becomes available to bring access to additional parameters.
% </li>
% </ul>
% </html>
% 
% [dtls][smry] *List of available segmentation layers* [/smry]
%
% <html>
% <ul>
% <li><em>pixelClassificationLayer</em> - semantic segmentation with the 
% <a href="https://se.mathworks.com/help/vision/ref/nnet.cnn.layer.pixelclassificationlayer.html">crossentropyex loss function</a></li>
% <li><em>focalLossLayer</em> - semantic segmentation using 
% <a href="https://se.mathworks.com/help/vision/ref/nnet.cnn.layer.focallosslayer.html">focal loss</a>
% to deal with imbalance between foreground and background classes. 
% To compensate for class imbalance, the focal loss function multiplies the cross entropy 
% function with a modulating factor that increases the sensitivity of the network to misclassified observations
% </li>
% <li><em>dicePixelClassificationLayer</em> - semantic segmentation using 
% <a href="https://se.mathworks.com/help/vision/ref/nnet.cnn.layer.dicepixelclassificationlayer.html">
% generalized Dice loss</a> to alleviate the problem of class imbalance in semantic segmentation problems. 
% Generalized Dice loss controls the contribution that each class makes to the loss 
% by weighting classes by the inverse size of the expected region</li>
% <li><em>dicePixelCustomClassificationLayer</em> - a modification of the dice loss, 
% with better control for rare classes</li>
% </ul>
% </html>
% 
% [/dtls]
%
% <html>
% <ul>
% <li><span class="kbd">Check network</span> - press to preview and check the network.
% The standalone version of MIB shows only limited information about the
% network and does not check it.
% </li>
% </ul>
% </html>
%
% [dtls][smry] *Snapshots of the network check window for the MATLAB and standalone versions of MIB* [/smry]
%
% A snapshot of the network check preview for the MATLAB version of MIB:
%
% <<images\DeepLearning_OrganizationDiagram.jpg>>
% 
% A snapshot of the network check preview for the standalone version of MIB:
%
% <<images\DeepLearning_OrganizationDiagram_deployed.jpg>>
% 
%
% [/dtls]
%
% [/dtls]
%
%% Augmentation design
% 
% Augmentation of the training sets is an easy way to extend the training
% base by applying variouos image processing filters to the input image
% patches. Depending on the selected 2D or 3D network architecture
% a different sets of augmentation filters are available (17 for 2D and 18 for 3D).[br]
%
% <<images\DeepLearningTrain_augdesign.png>>
% 
% These operations are configurable
% using the 2D and 3D settings buttons on the right-hand side from the
% [class.kbd][&#10003;] *augmentation*[/class] checkbox[br]
% It is possible to specify percentage of image patches that are going to
% be augmented and each augmentation can be fine tuned by providing its
% probability and its variation. Note that an image patch may be subjected
% to multiple augmentation filters at the same time, depending on their
% probability factor.
%
% <html>
% <ul>
% <li><span class="kbd">[&#10003;] <b>Augmentation</b></span> - augment
% data during training. When this checkbox is checked the input image patches are
% additionally filtered with number of defined filters. The exact
% augmentation options are available upon hitting the <span
% class="kbd"><b>2D</b></span> and <span class="kbd"><b>3D</b></span> buttons</li>
% <li><span class="kbd">2D</span> - press to specify augmentation settings
% for 2D networks. There are 17 augmentation operations and it is possible
% to specify fraction of images patches that have to be
% augmented and set variation and probability for each augmentation filter
% to be triggered. Expand the following section to learn about
% 2D/3D augmentation settings.
% </li>
% <li><span class="kbd"><b>3D</b></span> - press to specify augmentation settings
% for 3D networks. There are 18 augmentation operations and it is possible
% to specify fraction of images patches that have to be
% augmented and set variation and probability for each augmentation filter
% to be triggered. Expand the following section to learn about
% 2D/3D augmentation settings.
% </li>
% </ul>
% </html>
% 
% [dtls][smry] *2D/3D augmentation settings* [/smry]
%
% Upon pressing of the [class.kbd]2D[/class] or [class.kbd]3D[/class]
% buttons, a dialog will be displayed that provides access to select
% augmentation settings. [br]
%
% <<images\DeepLearning_3DAug_settings.jpg>>
%
% <html>
% Each augmentation may be  can be toggled on or off using a checkbox next to its name. 
% Additionally it is possible to specify the probability for each augmentation
% to be triggered using yellow spinboxes 
% (<span class="dropdown" style="background-color: #FAFAD1">probability</span>), 
% as well as their variation range using light blue spinboxes 
% (<span class="dropdown">variation</span>).
% </html>
%
% The augmentation settings can be reset to their default states by
% clicking the [class.kbd]Reset[/class] button or disabled altogether using the
% [class.kbd]Disable[/class] button.
%
% <html>
% <ul>
% <li><span class="dropdown" style="background-color: #FAFAD1">Fraction</span> allows you to specify the probability
% that a patch will be augmented. When set to <span class="code">Fraction==1</span>
% all patches are augmented using the selected set of augmentations.
% When set to <span class="code">Fraction==0.5</span> only 50% of the patches
% will be augmented.</li>
% <li><span class="dropdown" style="background-color: white">FillValue</span> allows you to specify the 
% background color when patches are downsampled or rotated. When 
% <span class="code">FillValue==0</span> the background color is black, when 
% <span class="code">FillValue==255</span> the background color is white
% (for 8-bit images)</li>
% <li><img src="images\DeepLearning_3DAug_settings_checkbox.jpg"> use these
% checkboxes to toggle augmentations on and off</li>
% <li><img src="images\eye.png"> is used to preview input image patches that are
% generated using augmentor. It is useful for evaluation of augmenter
% operations and understanding performance. Depending on a value in  
% <span class="dropdown">Radnom seed</span> the same (when set to "0") or a random image patch will be used
% </li>
% <li><img src="images\DeepLearning_3DAug_settings_preview_settings.jpg"> allows to specify
% parameters used to preview the augmentations.<br>
% [dtls][smry] <b>Details settings for preview</b> [/smry]
% Snapshot of settings to preview the selected augmentation operations:<br>
% <img src="images\DeepLearning_input_patches_gallery_settings.png"><br>
% Example of augmentations generated by press of the <span
% class="kbd">Preview</span> button:<br>
% <img src="images\DeepLearning_input_patches_gallery.jpg">
% [/dtls]
% </li>
% <li><span class="kbd">Help</span> press to jump to the Training details
% section of the help system</li>
% <li><span class="dropdown">Random seed</span> when set to "0" a random
% patch is shown each time the augmentations are previews, when set to any
% other number a fixed random patch is displayed</li>
% <li><span class="kbd">Previous seed</span> when using a random seed (<span class="code">Random seed==0</span>)
% you can restore the previous random seed and populate the <span
% class="dropdown">Random seed</span> with it. When done like that, the
% preview patches will be the same as during the previous preview call</li>
% <li><span class="kbd">OK</span> press to accept the current set of
% augmentations and close the dialog</li>
% <li><span class="kbd">Cancel</span>, close the dialog without
% accepting the updated augmentations</li>
% </ul>
% </html> 
%
% [/dtls]
%
%
%% Training process design
%
% In this section a user can specify details on of the training process
% that is started upon press of the [class.kbd]Train[/class] button.
% 
% <<images\DeepLearningTrain_traindesign.png>>
% 
% [dtls][smry] *Widgets of the Training process design section* [/smry]
%
% <html>
% <ul>
% <li><span class="dropdown">Patches per image...</span> - specify number of image patches that will be taken 
% from each an image or a 3D dataset at each epoch. According to our experience, the best strategy is to take
% 1 patch per image and train network for larger number of epochs. When taking a single patch per image
% it is important to set <em>Training settings (Training button)->Shuffling->every-epoch</em>). 
% However, fill free to use any sensible number</li>
% <li><span class="dropdown">Mini Batch Size...</span> - number of patches processed at the same time by the network. 
% More patches speed up the process, but it is important to understand that the 
% resulting loss is averaged for the whole mini-batch. Max number of mini batches is limited by available GPU memory</li>
% <li><span class="dropdown">Random seed...</span> set a seed for a random number generator used during initialization of training. 
% We recommend to use a fixed value for reproducibility, otherwise use <span class="code">0</span> for random initialization each time
% the network training is started
% </li>
% <li><span class="kbd">Training</span> - define multiple parameters used for training, for details please refer to 
% <a
% href="https://se.mathworks.com/help/deeplearning/ref/trainingoptions.html">trainingOptions</a>
% function<br><br>
% <b>Tip, <em>setting the Plots switch to "none" in the training settings may
% speed up the training time by up to 25%</em></b><br>
% </li>
% <li><span class="kbd">[&#10003;] <b>Save checkpoint networks</b></span> when ticked DeepMIB  
% saves the training progress in checkpoint files after each epoch to
% <span class="code">3_Results\ScoreNetwork</span> directory.<br>
% It will be possible to choose any of those networks and continue training from that checkpoint. If the checkpoint networks
% are present, a choosing dialog is displayed upon press of the <span
% class="kbd">Train</span> button.<br>
% In R2022a or newer it is possible to specify frequency of saving the checkpoint files.
% </li>
% <li><span class="kbd">[&#10003;] <b>Export training plots</b></span> when ticked accuracy and loss scores are
% saved to <span class="code">3_Results\ScoreNetwork</span> directory. DeepMIB uses the
% network filename as a template and generates a file in MATLAB format
% (*.score) and several files in CSV format
% </li>
% <li><span class="kbd">[&#10003;] <b>Send reports to email</b></span> when
% ticked information about progress and finishing of the training run is
% sent to email. Press on the checkbox starts a configuration window to
% define SMTP server and user details<br>
% [dtls][smry]<b>Configuration of email notifications</b>[/smry]
% <img src="images\DeepLearningTrain_traindesign_sendreports.png"><br>
% Check below the configuration settings for sending email with the
% progress information of the run.<br>
% <b>Important!</b><br>
% Please note that the password for the server is not encoded in any way
% and stored in the configuration file. Do not use your email account
% details, but rather use a dedicated services that are providing access to
% SMTP servers!<br>
% For example, you can use <a href="https://www.brevo.com">https://www.brevo.com</a> service that we've
% tested.<br>
% [dtls][smry]<b>Configuration of brevo.com SMTP server</b>[/smry]
% <ul>
% <li>Open <a href="https://www.brevo.com/">https://www.brevo.com</a> in a
% browser and Sign up for a free account</li>
% <li>Open the <b>SMTP and API</b> entry in the top right corner menu:<br>
% <img src="images\DeepLearningTrain_traindesign_sendreports2.png"></li>
% <li>Press the <span class="kbd">Generate a new SMTP key</span> button to generate a new password
% to access SMTP server</li>
% <li>Copy the generated pass-key into the password field in the email
% configuration settings. You can also check the server details on this page</li>
% </ul>
% [/dtls]
% <ul>
% <li><span class="dropdown">Destination email</span>, provide email address to which the
% notifications should be addressed</li>
% <li><span class="dropdown">STMP server address</span>, address of SMTP server that will be used to send notifications</li>
% <li><span class="dropdown">STMP server port</span>, port number on the server</li>
% <li><span class="kbd">[&#10003;] <b>STMP authentication</b></span>, checkbox indicating that the authentification is required by the server</li>
% <li><span class="kbd">[&#10003;] <b>STMP use starttls</b></span>, checkbox indicating that the server is using secure protocol with Transport Layer Security (TLS) or Secure Sockets Layer(SSL)</li>
% <li><span class="dropdown">STMP username</span>, username on the STMP server, a user's email for brevo.com</li>
% <li><span class="dropdown">STMP password</span>, password to access the server. You can use this field to type a new password; the password is hidden with ****, if you want to see it check
% <span class="kbd">[&#10003;] <b>Check to seethe password in plain text after OK press</b></span></li>
% <li><span class="kbd">[&#10003;] <b>Send email when training is finished</b></span>, when checked, an email is send at the end of the training run</li>
% <li><span class="kbd">[&#10003;] <b>Send progress emails</b></span>, when checked, emails with the progress of the run are sent with frequency specified in the checkpoint save parameter 
% (<b><em>only for the custom training dialog</b></em></li>
% <li><span class="kbd">Test connection</span>, it is highly recommended to test connection. To do that press <span class="kbd">OK</span> to accept the settings; reopen this dialog and press
% <span class="kbd">Test connection</span></li>
% [/dtls]
% </li>
% </ul> 
% </html>
%
% [/dtls]
%
%% Start the training process
%
% <html>
% <br>
% To start training press the <span class="kbd">Train</span> button highlighted under the
% panel. If a network file already exists under the provided <span class="dropdown">Network filename...</span>
% it is possible to continue training from that point 
% (a dialog with possible options appears upon restart of training). After
% starting of the training process a config file (with *.mibCfg) is created
% in the same directory. The config file can be loaded from <em><b>Options
% tab->Config files-></b></em><span class="kbd">Load</span>
% <br><br>
% Upon training a plot with the loss function is shown; the idea of the
% training is to minimize the loss function as much as possible. The blue
% curve displays the loss function calculated for the train set, while the
% red curve for the validation set. The accuracy of the prediction for both
% train and validation sets is displayed using the linear gauge widgets at
% the left bottom corner of the window.<br>
% <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg">
% right mouse click</span> over the plot opens a popup menu, that can be
% used to scale the plot.
% <br><br>
% It is possible to stop training at any moment by pressing the <span class="kbd">Stop</span> or
% <span class="kbd">Emergency brake</span> buttons. When the <span class="kbd">Emergency brake</span> button
% is pressed DeepMIB will stop the training as fast as possible, which may lead to
% not finalized network in situations when the batch normalization layer is
% used.
% <br><br>
% Please note that by default DeepMIB is using a custom progress plot. If you want to use 
% the progress plot provided with MATLAB (available only in MATLAB version
% of MIB), navigate to <b><em>Options tab->Custom training plot->Custom
% training progress window: uncheck</em></b><br>
% The plot can be completely disabled to improve performance: 
% <em><b>Train tab->Training->Plots, plots to display during network
% training->none</em></b>
% <br><br>
% The right bottom corner of the window displays used input image and model
% patches. Display of those decreases training performace, but the frequency
% of the patch updates can be modified in <b><em>Options tab->Custom training
% plot->Preview image patches and Fraction of images for preview</em></b>. When
% fraction of image for preview is 1, all image patches are shown. If the value
% is 0.01 only 1% of patches is displayed.<br>
% <img src="images\DeepLearning_TrainingProcess.jpg"><br>
% After the training, the network and config files with all paramters are generated in location specified in the
% <span class="dropdown">Network filename...</span> editbox of the <em>Network</em> panel.
% </html>
%
% 
% *Back to* <im_browser_product_page.html *Index*> |*-->*| <im_browser_user_guide.html *User Guide*> 
% |*-->*| <ug_gui_menu.html *Menu*> |*-->*| <ug_gui_menu_tools.html *Tools
% Menu*> |*-->*| <ug_gui_menu_tools_deeplearning.html *Deep learning segmentation*>
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #e0f5ff; 
% 	padding: 0.1em 0.4em; 
% 	font-family: inherit; 
% 	font-size: 1em;
% }
% .kbd { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	-moz-border-radius: 0.2em; 
% 	-webkit-border-radius: 0.2em; 
% 	border-radius: 0.2em; 
% 	-moz-box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	-webkit-box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	box-shadow: 0.1em 0.2em 0.2em #ddd; 
% 	background-color: #f9f9f9; 
% 	background-image: -moz-linear-gradient(top, #eee, #f9f9f9, #eee); 
% 	background-image: -o-linear-gradient(top, #eee, #f9f9f9, #eee); 
% 	background-image: -webkit-linear-gradient(top, #eee, #f9f9f9, #eee); 
% 	background-image: linear-gradient(&#91;&#91;:Template:Linear-gradient/legacy]], #eee, #f9f9f9, #eee); 
% 	padding: 0.1em 0.4em; 
% 	font-family: inherit; 
% 	font-size: 1em;
% }
% .h3 {
% color: #E65100;
% font-size: 12px;
% font-weight: bold;
% }
% .code {
% font-family: monospace;
% font-size: 10pt;
% background: #eee;
% padding: 1pt 3pt;
% }
% [/cssClasses]
%%
% <html>
% <script>
%   var allDetails = document.getElementsByTagName('details');
%   toggle_details(0);
% </script>
% </html>
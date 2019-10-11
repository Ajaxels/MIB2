%% Acknowledgements
%
% *Back to* <im_browser_product_page.html *Index*>
%
%
% <html>
% Developed during 2010-2017 by<br>
% Core developer:<br>
% <a href="http://www.biocenter.helsinki.fi/~ibelev/">Ilya Belevich</a><br>
% Developers:<br>
% Merja Joensuu, Darshan Kumar, Helena Vihinen and Eija
% Jokitalo<br><br>
% <i><a href="http:\\www.biocenter.helsinki.fi/bi/em">Electron Microscopy Unit</a><br>
% Institute of Biotechnology<br>
% PO Box 56 (Viikinkaari 9)<br>
% 00014, University of Helsinki<br>
% Finland</i>
% </html>
%
%
% Special thanks come to
%%
% 
% * *Konstantin Kogan*, University of Helsinki for assistance with Mac OS
% * *Radhakrishna Achanta*, Ecole Polytechnique F?d?rale de Lausanne (EPFL)
% for the mex code for SLIC supervoxels and superpixels
% * *David Legland*, INRA, France for modification of the
% <http://www.mathworks.com/matlabcentral/fileexchange/16938-region-adjacency-graph--rag-
% Region Adjacency Graph (imRAG)> function for detection of indices between
% watershed regions
% * *John Heumann*, The Boulder Laboratory For 3-D Electron Microscopy of
% Cells for help with Mattomo
% * *Tom Boissonnet* (EMBL) and *Elena Bertseva* (University of Copenhagen) for extensive testing
%
% Microscopy Image Browser team would like to acknowledge the <http://www.mathworks.se/matlabcentral/ User Community of Matlab-Central> and the authors whose code was used during MIB development. 
% Microscopy Image Browser adapts partially or completely codes from the
% following sources:
%
%%
% 
% * Inspired by <http://www.mathworks.com/matlabcentral/fileexchange/13000-imageviewer *IMAGEVIEWER*>
% by Jiro Doke, MathWorks 2010
% * Documentation done with <http://www.mathworks.com/matlabcentral/fileexchange/33826-mtoc++-doxygen-filter-for-matlab-and-tools *MTOC++ - Doxygen filter for Matlab and tools*>
% written by Martin Drohmann (Universit?t M?nster) and Daniel Wirtz (Universit?t Stuttgart), 2011-2013
% * <http://www.mathworks.se/matlabcentral/fileexchange/24531-accurate-fast-marching
% *Accurate Fast Marching function*> by Dirk-Jan Kroon, University of Twente, 2011 is utilized in the Membrane Click Tracker tool
% * <http://www.csse.uwa.edu.au/~pk/Research/MatlabFns/#anisodiff *ANISODIFF*> function written by Peter Kovesi, 2000-2002
% * <http://www.loci.wisc.edu/software/bio-formats *BIO-FORMATS*> by Melissa Linkert, Curtis Rueden et al. 2002-2013
% * <http://www.cs.tut.fi/~foi/GCF-BM3D/ *BMxD external filters*> by Kostadin Dabov
% et al., Tampere University of Technology, Finland 2007-2014 can be used with MIB, when separately installed on the system
% * <http://www.mathworks.se/matlabcentral/fileexchange/15455-3d-euclidean-distance-transform-for-variable-data-aspect-ratio
% *BWDISTSC*> for 3D Euclidean distance transform for variable data aspect ratio written by Yuriy Mishchenko, Toros University, 2007-2013
% * <http://www.peterkovesi.com/projects/segmentation/ *DRAWREGIONBOUNDARIES*>
% a function to draw boundaries of labeled regions in an image, written by Peter Kovesi
% Centre for Exploration Targeting, School of Earth and Environment, The
% University of Western Australia, 2013.
% * <https://se.mathworks.com/matlabcentral/fileexchange/45453-drifty-shifty-deluxe-m
% *DRIFTY_SHIFTY_DELUXE*>, written by Joshua D. Sugar, Sandia National
% Laboratories, Livermore, CA (2014); part of code from this function was adopted in mibCalcShifts.m
% * <http://www.mathworks.com/matlabcentral/fileexchange/23629-export-fig
% *EXPORT_FIG*> function to add measurements to snapshots is written by Oliver Woodford and Yair Altman 
% * <http://www.mathworks.com/matlabcentral/fileexchange/41666-fast-3d-2d-region-growing--mex-
% *Fast 3D/2D Region Growing (MEX)*> by Christian Wuerslin, Stanford
% University, 2013-2015.
% * *Fiji Connect* is using <http://bigwww.epfl.ch/sage/soft/mij/ *MIJ*>, a Java package for bi-directional communication and data exchange from Matlab to ImageJ/Fiji,
% developed by Daniel Sage, Dimiter Prodanov, Jean-Yves Tinevez and Johannes Schindelin, 2012
% * <http://www.mathworks.com/matlabcentral/fileexchange/14317-findjobj-find-java-handles-of-matlab-graphic-objects 
% *FINDJOBJ*> - find java handles of Matlab graphic objects by Yair Altman, 2007-2013
% * <http://www.mathworks.com/matlabcentral/fileexchange/24409-hessian-based-frangi-vesselness-filter 
% *FRANGI filter*> by Marc Schrijver and Dirk-Jan Kroon, University of Twente 2001-2009
% * <https://se.mathworks.com/matlabcentral/fileexchange/55115-extended-depth-of-field *FSTACK*> extended depth-of-field image from focus sequence using noise-robust selective all-in-focus algorithm by Said Pertuz, Universitat
% Rovira i Virgili, Tarragona, Spain 2013
% * <https://github.com/carandraug/histthresh *HistThresh toolbox*> by Antti Niemist&ouml;, Tampere University of Technology, Finland is used for most of the global histogram-based thresholding methods
% * <http://www.mathworks.com/matlabcentral/fileexchange/25449-image-edge-enhancing-coherence-filter-toolbox *Image Edge Enhancing Coherence Filter*> Dirk-Jan Kroon, Pascal Getreuer University of Twente. 
% * <http://www.scs2.net/next/index.php?id=110 *IceImarisConnector*> written by Aaron C. Ponti, ETH Zurich is used for connection
% to Imaris
% * <http://www.mathworks.com/matlabcentral/fileexchange/25964-image-measurement-utility *Image Measurement Utility*> written by Jan Neggers, 
% Eindhoven Univeristy of Technology was used as a basis for the Measure
% Tool and re-written roiRegion class
% * <http://www.mathworks.com/matlabcentral/fileexchange/28708-imclipboard *IMCLIPBOARD*> function
% by  Jiro Doke, MathWorks, 2010 is used in the snapshot tool and import from system clipboard
% * <http://www.mathworks.com/matlabcentral/fileexchange/25397-imgaussian *IMGAUSSIAN*> 
% by Dirk-Jan Kroon, University of Twente, implementation 2009 is used in the 3D Gaussian filter
% * <http://bio3d.colorado.edu/PEET/index.html *MATTOMO*> is a part of PEET 
% (Particle Estimation for Electron Tomography) package, developed at Boulder Laboratory for 3-D Electron Microscopy of Cells
% was used for export of models to IMOD format
% * <http://pub.ist.ac.at/~vnk/software.html *MAXFLOW/MINCUT algorithm, v.2.22*> written by Yuri Boykov, University of Western Ontario and Vladimir Kolmogorov, Microsoft research, Cambridge. 
% * <http://www.mathworks.com/matlabcentral/fileexchange/21310-maxflow
% *MAXFLOW/MINCUT Matlab wrapper*> is written by Michael Rubinstein, Google
% * <https://se.mathworks.com/matlabcentral/fileexchange/8472-num2clip-copy-numerical-arrays-to-clipboard *NUM2CLIP*> function
% by Grigor Browning, 2005 is used to copy column items to the system clipboard
% * *NRRD*, Nearly Raw Raster Data format is implemented using  
% <http://www.na-mic.org/Wiki/index.php/Projects:MATLABSlicerExampleModule
% *Projects:MATLABSlicerExampleModule*> written by John Melonakos for NRRD
% reading using <http://teem.sourceforge.net/ TEEM>; and a custom function for reading metadata based on
% <http://www.mathworks.com/matlabcentral/fileexchange/34653-nrrd-format-file-reader
% *NRRD Format File Reader*> written by Jeff Mather, 2012
% * <http://www.openmicroscopy.org/site/products/omero/downloads *OMERO Matlab bindings*> (included into the compiled version, but should be downloaded separetly for the Matlab version) are used for
% connection to OMERO servers
% * <http://www.mathworks.com/matlabcentral/fileexchange/25713-highly-portable-json-input-parser
% *P_JSON*>, highly portable JSON parser function is written by Nedialko, 2009
% * <https://se.mathworks.com/matlabcentral/fileexchange/24330-patch-normals *PATCHNORMALS*> 
% by Dirk-Jan Kroon, University of Twente, implementation 2009 is used for
% calculation of normals during export of surfaces to Imaris
% * *Random Forest Classifier* is based on <http://www.kaynig.de/demos.html Verena Kaynig> implementation with utilization of <https://code.google.com/p/randomforest-matlab/ *randomforest-matlab*> by Abhishek Jaiantilal
% * <http://www.mathworks.com/matlabcentral/fileexchange/16938-region-adjacency-graph--rag- *Region Adjacency Graph (RAG)*> function is written by David Legland,
% INRA, France, 2013
% * <http://www.mathworks.com/matlabcentral/fileexchange/47578-regionprops3
% *REGIONPROPS3*> function is written by Chaoyuan Yeh, University of Southern
% California, 2014
% * <http://www.mathworks.com/matlabcentral/fileexchange/26940-render-rgb-text-over-rgb-or-grayscale-image 
% *RENDERTEXT*> function by Davide Di Gloria, Universita di Genova, 2010 is utilized for addition of text to image
% * Rendering with Fiji is based on
% <http://www.mathworks.com/matlabcentral/fileexchange/32344-hardware-accelerated-3d-viewer-for-matlab
% *Hardware accelerated 3D viewer for MATLAB*> written by Jean-Yves Tinevez, Institut Pasteur, 2011  
% * Rendering with Matlab is using <http://www.mathworks.com/matlabcentral/fileexchange/334-view3d-m *VIEW3D*> function
% written by  Torsten Vogel, 1999  
% * <http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html 
% *SLIC (Simple Linear Iterative Clustering)*> written by Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, 
% Pascal Fua, and Sabine S?sstrunk, Ecole Polytechnique Federale de
% Lausanne (EPFL), Switzerland, 2015 was utilized for the superpixels mode of the Brush tool and for the Graphcut segmentation.
% * <http://www.mathworks.com/matlabcentral/fileexchange/20922-stlwrite-filename--varargin-
% *STLWRITE*> by Sven Holcombe, University of Michigan 2008-2015 for saving models
% using the STL format
% * <https://se.mathworks.com/matlabcentral/fileexchange/32555-uigetfile_n_dir-select-multiple-files-and-directories 
% *UIGETFILE_N_DIR*> by Tiago / Peugas was used for selection of multiple directories
% * <http://se.mathworks.com/matlabcentral/fileexchange/21993-viewer3d 
% *VIEWER3D*> by Dirk-Jan Kroon, Focal Machine Vision en Optical Systems
% was used as a basis for the volume rendering of datasets
% * <https://se.mathworks.com/matlabcentral/fileexchange/38591-xlwrite--generate-xls-x--files-without-excel-on-mac-linux-win 
% *XLWRITE: Generate XLS(X) files without Excel on Mac/Linux/Win*> by Alec
% de Zegher, NV Bekaert SA 2013
% * <http://www.mathworks.com/matlabcentral/fileexchange/27236-improved-xlswrite-m 
% *XLSWRITE mod*> by Barry Dillon, AON Insurance Brokers 2010
% * <http://www.mathworks.com/matlabcentral/fileexchange/28518-xml2struct 
% *XML2STRUCT*> and <http://www.mathworks.com/matlabcentral/fileexchange/28639-struct2xml *STRUCT2XML*> by Wouter Falkena, Delft University of Technology, 2010
% 
%
% Color palettes are generated with help of
%
% * <http://jfly.iam.u-tokyo.ac.jp/color/ Yasuyo G. Ichihara, Masataka
% Okabe, Koichi Iga, Yosuke Tanaka, Kohei Musha, Kei Ito. Color Universal Design - The selection of four
% easily distinguishahle colors for all color vision types. Proc Spie 6807 (2008)> 
% * <http://colorbrewer2.org/ Cynthia Brewer, Mark Harrower, Ben Sheesley,
% Andy Woodruff, David Heyman. ColorBrewer 2.0>
% * <https://sashat.me/2017/01/11/list-of-20-simple-distinct-colors/ Sasha Trubetskoy, List of 20 Simple, Distinct Colors>
%
%
% Some icons used in MIB were provided by Icons8.com
% (<https://icons8.com https://icons8.com>), <https://icons8.com/license/ license information>
%
% *OLDER SCRIPTS*
%%
% * <http://www.diplib.org/ *DIPLIB*> is a platform independent scientific image processing library written in C
% developed by Quantitative Imaging Group at the Faculty of Applied
% Sciences, Delft University of Technology. When installed, Microscopy Image Browser can use several additional methods for anisotropic
% diffusion filtering available from DipLib (used in MIB 0.x and 1.x).
% * <http://www.mathworks.com/matlabcentral/fileexchange/12275-extrema-m-extrema2-m *EXTREMA functions*>
% by Carlos Adrian Vargas Aguilera, Universidad de Guadalajara, 2006-2007
% (used in MIB 0.x and 1.x)
% * <http://www.mathworks.com/matlabcentral/fileexchange/24925-fastrobust-template-matching *Fast/Robust Template Matching*>
% (2009-2011) by Dirk-Jan Kroon, University of Twente was used for
% alignment of datasets (used in MIB 0.x and 1.x-1.22).
% *Image Edge Enhancing Coherence Filter*> by Dirk-Jan Kroon & Pascal
% Getreuer, University of Twente, 2009 (used in MIB 0.x and 1.x).
% * <http://www.mathworks.com/matlabcentral/fileexchange/8303-local-normalization *Local normalization*> by 
% Guanglei Xiong at Tsinghua University, Beijing, China, 2005 (used in MIB 0.x and 1.x).
%
% *Back to* <im_browser_product_page.html *Index*>

 




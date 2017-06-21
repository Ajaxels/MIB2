1. Download and install Doxygen (http://www.stack.nl/~dimitri/doxygen/)
2. Download mtoc++ (http://www.morepas.org/software/mtocpp/docs/index.html) binaries and m-file
3. Download and install dot (http://www.graphviz.org/Download_windows.php)
4. Copy mtocpp.exe and mtocpp_post.exe to a directory within system PATH (for example Matlab/Rxxx/bin)
5. Place the MatlabDocMaker.m file im_browser/techdoc and add it to Matlab path.
6. Change the MatlabDocMaker.getProjectName method in MatlabDocMaker.m to return your project's name
7. Copy the contents of the <mtoc++-source-dir>/tools/config folder into im_browser/techdoc
8. Delete class_substitutes.c from /tools/config
9. Call the MatlabDocMaker.setup
10. Make documentation with MatlabDocMaker.create

syntax help:
@b - to make word in bold
@em - to make word in italic
@type to define new work as a data type
use '-' to make a list
@note - a tag for notes

@new{<mainversionnumber>, <mainversionnumber>, <developerkey>[, <date>]} <description>
@new{0.9930, ib, 2011-01-01} Added a fancy new feature 

@change{<mainversionnumber>, <mainversionnumber>, <developerkey>[, <date>]} <change-text>
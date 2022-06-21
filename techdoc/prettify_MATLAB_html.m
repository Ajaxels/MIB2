function prettify_MATLAB_html(inputhtmlFile, verbose, overloadPublish, addCommandsToToolbar)
%%  prettify_MATLAB_html(inputhtmlFile, verbose, overloadPublish, addCommandsToToolbar)
%
%   Given a MATLAB-generated HTML file as an input, this function adds additional
%   features such as disclosure boxes and expand-all/collapse-all links. This makes
%   the document more closely resemble "official" MATLAB help files.
%   It also gives extended formatting options, provides an optional dark theme, and
%   automatically enhances the formatting of inline code and images.
%
%	Version 6.5
%
%   Inputs:
%
%   inputhtmlFile:    Character vector. The name or full path of the MATLAB-generated
%                     HTML file to be processed. The file is automatically over-
%                     written by the processed file.
%
%   verbose:          Logical. Optional input to suppress the begin and end messages
%                     that are printed to the command line when prettify_MATLAB_html
%                     is run. Set to "false" to suppress the messages.
%
%   overloadPublish:  Logical. When used, the first two inputs are ignored. This is an
%                     optional input to configure an overload for MATLAB's publish
%                     function, so that when you press "publish" in the toolbar of a
%                     MATLAB editor window, the generated HTML will automatically be
%                     processed by prettify_MATLAB_html. This only needs to be done
%                     once per MATLAB session. If you put a call to:
%                     prettify_MATLAB_html([], [], true);
%                     in your startup.m file, publish will get overloaded every time
%                     you run MATLAB. To stop overloading the built-in publish
%                     function, set overloadPublish to false:
%                     prettify_MATLAB_html([], [], false);
%
%   addCommandsToToolbar:
%                     Logical. When used, the first two inputs are ignored. This is
%                     an optional input used to add shortcuts to the quick-access
%                     toolbar that then allow you to easily add prettify_MATLAB_html
%                     tags to your .m files. Set to true to add the commands.
%                     In MATLAB versions prior to 2018a, the buttons are added to your
%                     shortcuts, and you have to restart to get them to be added to the
%                     Quick-Access Toolbar. If anyone knows how to add shortcuts to the
%                     Quick-Access Toolbar programatically, without requiring a
%                     restart, please let me know: harry.dymond@bristol.ac.uk
%
%   Most prettify_MATLAB_html features require you to use additional markup "tags" in
%   the original source .m file, for example to indicate where you want the disclosure
%   boxes (the "expand"/"collapse" links are automatically generated).
%
%   See the <a href="matlab:ans=dir(which('prettify_MATLAB_html.m'));
%   open([ans.folder filesep 'prettify documentation' filesep 'html' filesep 'prettify_MATLAB_html_helpdoc.html']);
%   clear ans">help document</a> for more information

%% ==========================================================================================================================================================
%
%% Documentation :
%
%   Please see the help document: /prettify documentation/html/prettify_MATLAB_html_helpdoc.html for more information (type "help prettify_MATLAB_html" at
%   the MATLAB command line to get a clickable link to the help document).
%
%============================================================================================================================================================
%
%% Version history :
%
%   Version history is at the end of this file
%
%============================================================================================================================================================
%
%% Notes :
%
%   This file uses "sections" to help segment the code for readability. It is recommended to enable folding of sections in MATLAB's preferences, so
%   that sections can be collapsed/expanded. Lines are 157 characters wide. The position of the vertical text-limit line (if shown) may be moved by going to
%   MATLAB preferences -> Editor/Debugger -> Display -> Right-hand text limit
%
%   The code uses the following naming convention :
%       _____________________________________________
%                         |
%           Item(s)       |   Naming convention
%       __________________|__________________________
%           Variables     |   initialLowerTitleCase
%       ------------------+--------------------------
%           Functions     |   lower_case(...)
%       ------------------+--------------------------
%           constants     |   UPPER_CASE
%       __________________|__________________________
%
%============================================================================================================================================================
%
%% Authorship:
%
%   Written by Harry Dymond, Electrical Energy Management Group, University of Bristol, UK; harry.dymond@bris.ac.uk. If you find any bugs, please email me!
%   Developed with MATLAB R2018a running on Windows 10 and macOS Mojave.
%
%% ==========================================================================================================================================================

    %% Constants
    HELP_URL     = ['    Click <a href="matlab:ans=dir(which(''prettify_MATLAB_html.m''));' ...
                    'open([ans.folder filesep ''prettify documentation'' filesep ''html'' filesep ''prettify_MATLAB_html_helpdoc.html'']);' ...
                    'clear ans">here</a> to see the help document for more information.'];
    NO_START_ERR = 'ERROR: couldn''t find start of content in html file';
    DEBUG        = getappdata(0,'PRETTY_DEBUG'); if isempty(DEBUG), DEBUG = false; end
    %% Check sufficient inputs
    assert(nargin>=1,['    Call syntax error. Call syntax is:' NL ...
                      '    prettify_MATLAB_html(inputhtmlFile, verbose, overloadPublish, addCommandsToToolbar)' NL ...
                      '    Where inputs verbose, overloadPublish, and addCommandsToToolbar are optional.' NL HELP_URL NL]);
    try
    %% Clear show_warning and write_fstrm_to_file sub-functions
    show_warning(true)
    write_fstrm_to_file([], [], [])
    %% Overload publish
    if nargin>=3 && islogical(overloadPublish)
        PUBLISH_OVERLOAD_FOLDER_NAME = 'publish overload';
        ERROR_MSG_START = 'Not installed correctly. In the folder that contains the prettify_MATLAB_html.m file, there should be a ';
        if ~exist([my_path PUBLISH_OVERLOAD_FOLDER_NAME],'dir'), error([ERROR_MSG_START 'folder named "' PUBLISH_OVERLOAD_FOLDER_NAME '"']); end
        pathList     = strsplit(path,':');
        overloadPath = pathList(cellfun(@(str)contains(str,PUBLISH_OVERLOAD_FOLDER_NAME),pathList));
        if ~isempty(overloadPath)
            for i=1:length(overloadPath)
                overloadPath{i} = strsplit(overloadPath{i},';');
                overloadPath{i} = overloadPath{i}{1};
                rmpath(overloadPath{i});
            end
        end
        if overloadPublish
            save_publish_handle;
            if ~isempty(overloadPath), for i=1:length(overloadPath), addpath(overloadPath{i}); end
            else                                                   , addpath([my_path PUBLISH_OVERLOAD_FOLDER_NAME]); end
        end
        if nargin == 3, return; end
    end
    %% Execute toolbar functions
    if nargin==4
        if islogical(addCommandsToToolbar) && addCommandsToToolbar
            add_pretty_commands_to_toolbar;
        elseif ischar(addCommandsToToolbar)
            document = matlab.desktop.editor.getActive;
            if isempty(document), return, end
            tagName = addCommandsToToolbar;
            switch tagName
                case {'[dtls]','[smry]','[cssClasses]'}, wrap_text_in_tag(document, tagName);
                case 'target'                          , insert_target(document);
                case 'jumpto'                          , jumpton_wrap(document);
                case 'class'                           , class_wrap(document);
                case 'scale'                           , wrap_text_in_tag(document, '[scale', 'x');
                case 'colour'                          , colour_wrap(document);
                case 'table'                           , insert_table(document);
            end
        end
        return
    end
    %% Some input checking
    assert(ischar(inputhtmlFile),['ERROR: First input to prettify_MATLAB_html should be a character vector specifying '...
                                  'the html file to be processed, either by just file name, or by full path.' NL HELP_URL NL]);
    if nargin < 2 || ~islogical(verbose), verbose = true; end
    if verbose, fprintf(1,'\nReading input file...\n'); end
    fInfo = dir(inputhtmlFile);
    assert(~isempty(fInfo),['ERROR: Specified html file could not be found. Make sure the html file '...
                            'is in the present working directory, or otherwise on the MATLAB path']);
    %% Open input file
    fstrm = read_file_to_mem(inputhtmlFile);
    if verbose, fprintf(1,'Processing:\n'); end
    %% Find [cssClass] tags
    [fstrm, classNames, userCSS] = process_cssClasses_tags(fstrm);
    % add built-in classes as valid class names (not done in process_cssClasses_tags so as not to pollute class list when "class" Toolbar button is used)
    classNames     = [classNames {'codeinput', 'codeoutput', 'error', 'keyword', 'comment', 'string', 'untermstring', 'syscmd'}];
    %% Themes
    themeSwitchPos = strfind(fstrm,'<div class="content">');
    assert (~isempty(themeSwitchPos), NO_START_ERR);
    themeSwitchPos = themeSwitchPos(1) + 20;
    if ~strcmp(char(fstrm(themeSwitchPos+1:themeSwitchPos+4)),'<h1>') ...
    || strcmp(char(fstrm(themeSwitchPos+1:themeSwitchPos+9)),'<h1></h1>'), extraStr = '<div>&nbsp;</div>'; %#ok<ALIGN>
    else                                                                 , extraStr = ''                 ; end
    themeSwitch    = '';
    if contains(char(fstrm),'[themesEnabled]')
        classNames     = [classNames {'show-if-light', 'show-if-dark'}];
        themeSwitch    = ['<div><p onclick="toggle_theme()" style="text-align:right; float:right; padding-left:10px; margin:0;">'...
                          '<a href="javascript:void(0);" id="ToggleTheme">&nbsp;</a></p></div>'...
                          '<script>set_theme(null)</script>' extraStr];
        fstrm = [fstrm(1:themeSwitchPos) themeSwitch fstrm(themeSwitchPos+1:end)];
        fstrm = strrep(fstrm,'[themesEnabled]','');
    else
        fstrm = [fstrm(1:themeSwitchPos) '<script>document.getElementById("dark-theme").sheet.disabled = true;</script>' fstrm(themeSwitchPos+1:end)];
    end
    %% Define extra css
    extraCSS = [userCSS NL ...
                '#tooltiptext {' NL ...
                '  visibility: hidden;' NL ...
                '  padding: 5px 10px;' NL ...
                '  font-size: 75%;' NL ...
                '  line-height:110%;' NL ...
                '  text-align: center;' NL ...
                '  background-color: black;' NL ...
                '  color: #ddd;' NL ...
                '  border-radius: 6px;' NL ...
                '  position: fixed;' NL ...
                '  bottom: 11px;' NL ...
                '  right: 62px;' NL ...
                '  z-index: 2;' NL ...
                '}' NL ...
                '#tooltiptext::after {' NL ...
                '  content: " ";' NL ...
                '  position: absolute;' NL ...
                '  top: 50%;' NL ...
                '  left: 100%;' NL ...
                '  margin-top: -5px;' NL ...
                '  border-width: 5px;' NL ...
                '  border-style: solid;' NL ...
                '  border-color: transparent transparent transparent black;' NL ...
                '}' NL ...
                '.tooltip:hover #tooltiptext {' NL ...
                '  visibility: visible;' NL ...
                '}' NL ...
                '#return-link {' NL ...
                '    position: fixed;' NL ...
                '    bottom: 10px;' NL ...
                '    right: 10px;' NL ...
                '    overflow: visible;' NL ...
                '    font-size:120%;' NL ...
                '    background: rgba(0, 0, 0, 0.75);' NL ...
                '    border-style: solid;' NL ...
                '    border-width: 3pt;' NL ...
                '    border-color: #202020;' NL ...
                '    border-radius: 4px;' NL ...
                '    cursor: pointer;' NL ...
                '    }' NL ...
                '#return-link > p { padding:3px; margin:0; color:#C0C0C0;}' NL ...
                '.MATLAB-Help {' NL ...
                'width: 100%;' NL ...
                'margin-bottom: 12px;' NL ...
                'border: 1px solid #ccc;' NL ...
                'border-right: none;' NL ...
                'border-bottom: none;' NL ...
                'font-size: 96%;' NL ...
                'line-height: 1.4;' NL ...
                'table-layout: fixed;' NL ...
                'overflow:hidden;}' NL ...
                NL ...
                '.MATLAB-Help > thead > tr > th {' NL ...
                'padding: 6px 5px;' NL ...
                'border: none;' NL ...
                'border-right: 1px solid #ccc;' NL ...
                'border-bottom: 1px solid #ccc;' NL ...
                'background: #F2F2F2;' NL ...
                'color: #000;' NL ...
                'font-weight: bold;' NL ...
                'text-align: left;' NL ...
                'vertical-align: middle;}' NL ...
                NL ...
                '.MATLAB-Help td{padding: 5px 5px;' NL ...
                'border: none;' NL ...
                'border-right: 1px solid #ccc;' NL ...
                'border-bottom: 1px solid #ccc;' NL ...
                'vertical-align: middle;}' NL ...
                NL...
                '.language-matlab { line-height:135% }' NL NL...
                '.collapse-link {float:right; line-height:200%; padding-left:10px; margin:0}' NL NL ...
                NL ...
                'details > summary,' NL ...
                '.details-div {' NL ...
                '  padding: 8px 20px;' NL ...
                '  border-style: solid;' NL ...
                '  border-width: 1.2pt;' NL ...
                '  border-color: #E0E0E0;' NL ...
                '}' NL ...
                'details > summary {' NL ...
                '  border-radius:6px 6px 0 0;' NL ...
                '  background-color: #F2F2F2;' NL ...
                '  cursor: pointer;' NL ...
                '}' NL ...
                '.details-div {' NL ...
                '  border-top-style: none;' NL ...
                '  border-radius: 0 0 6px 6px;' NL ...
                '}' NL ...
                '.image-fit-svg,' NL ...
                '.image-fit {' NL ...
                '    max-width:  95%;' NL ...
                '    max-height: 100%;' NL ...
                '    margin:     auto;' NL ...
                '}' NL ...
                '.image-fit-svg{ padding:0px; max-width:500px; }' NL ...
                'details > img.image-fit-svg{ padding: 0px 0px 10px; }' NL ...
                '@media (max-width: 580px) {' NL ...
                '  .image-fit-svg { max-width: 95%; }' NL ...
                '}' NL ...
                '.pretty-link  { color:#001188 !important; }' NL
                ];
    darkTheme = [NL '<style id="dark-theme">' NL ...
                '    h2, h3       { color: #B0B0B0; }' NL ...
                '    html body    { background-color: #101010; color: #B0B0B0; }' NL ...
                '    .pretty-link { color: #C46313 !important; }' NL ...
                '    a, a:visited { color: #C46313 }' NL ...
                '    a:hover      { color: orange; }' NL ...
                '    details > summary,' NL ...
                '    .details-div      { border-color:     #505050; }' NL ...
                '    details > summary { background-color: #202020; }' NL ...
                '    pre.codeinput     { border-width: 1.2pt; border-color:#001B33; background:#001129; color:#F0F0F0; }' NL ...
                '    pre.codeoutput    { color:#A5A5A5; }' NL ...
                '    span.keyword      { color:#FF9D00; }' NL ...
                '    span.comment      { color:#808080; }' NL ...
                '    span.string       { color:#3AD900; }' NL ...
                '    span.untermstring { color:#FFEE80; }' NL ...
                '    span.syscmd       { color:#CCCCCC; }' NL ...
                '    .MATLAB-Help, .MATLAB-Help > thead > tr > th, .MATLAB-Help td { border-color:#505050; }' NL ...
                '    .MATLAB-Help > thead > tr > th { background: #202020; color: #B0B0B0; }' NL ...
                '    .summary-sub-heading { color:#909090; }' NL ...
                '    .show-if-light    { display:none }' NL ...
                '</style>' NL ...
                '<style id="hide-dark">' NL ...
                '     .show-if-dark { display:none }' NL ...
                '</style>'...
                NL];
    jumpShift = [NL '<style id="anchor-offsets">' NL ...
                '    h2::before, a[id]::before{' NL ...
                '    content: "";' NL ...
                '    display: block;' NL ...
                '    height: 100px;' NL ...
                '    margin: -100px 0 0;' NL ...
                '    visibility: hidden;' NL ...
                '    width:10%;' NL ...
                '    z-index: -1;' NL ...
                '}' NL ...
                '</style>' ...
                NL];
    %% Define javascript
    javaScript =   ['<script>' NL ...
                    '          var returnElem = null;' NL ...
                    '          var skipCheck  = false;' NL NL ...
                    '          function hide_back_link()' NL ...
                    '          {' NL ...
                    '              returnButton.style.display = "none";' NL ...
                    '              try{' NL ...
                    '                 window.removeEventListener("scroll", update_back_position, true);' NL ...
                    '                 window.removeEventListener("resize", update_back_position, true);' NL ...
                    '                 parent.window.removeEventListener("scroll", update_back_position, true);' NL ...
                    '                 parent.window.removeEventListener("resize", update_back_position, true);}' NL ...
                    '              catch(e){}' NL ...
                    '          }' NL NL ...
                    '          function get_offset(element)' NL ...
                    '          {' NL ...
                    '              if (!element.getClientRects().length){ return { top: 0, left: 0 }; }' NL ...
                    '              var rect = element.getBoundingClientRect();' NL ...
                    '              var win  = element.ownerDocument.defaultView;' NL ...
                    '              return ( {top:  rect.top  + win.pageYOffset,' NL ...
                    '                        left: rect.left + win.pageXOffset} );' NL ...
                    '          }' NL NL ...
                    '          function jump_to()' NL ...
                    '          {' NL ...
                    '              var clickedElem = event.target;' NL ...
                    '              var clickedID   = clickedElem.closest("span");' NL ...
                    '              if (clickedID){' NL ...
                    '                clickedID = clickedID.getAttribute("id");' NL ...
                    '                if (clickedID.localeCompare("jump-close")===0) { return };}' NL ...
                    '              clickedID = clickedElem.closest("div").getAttribute("id");' NL ...
                    '              if (clickedID && clickedID.localeCompare("return-link")===0)' NL ...
                    '              {' NL ...
                    '                  if (returnElem)' NL ...
                    '                  {' NL ...
                    '                      event.preventDefault();' NL ...
                    '                      hide_back_link();' NL ...
                    '                      returnElem.scrollIntoView();' NL ...
                    '                      if (contentDiv.getAttribute("data-isHelpBrowser")){' NL ...
                    '                         contentDiv.scrollTop = contentDiv.scrollTop-100; }' NL ...
                    '                      if (contentDiv.getAttribute("data-isMATLABCentral")){' NL ...
                    '                         parent.window.scrollBy(0,-100)}' NL ...
                    '                      returnElem = null;' NL ...
                    '                  }' NL ...
                    '              }' NL ...
                    '              else' NL ...
                    '              {' NL ...
                    '                  var href = clickedElem.closest("a").getAttribute("href");' NL ...
                    '                  if ( href && href[0] == "#" )' NL ...
                    '                  {' NL ...
                    '                     var target = document.getElementById(href.substring(1));' NL ...
                    '                     var enclosingBox = target;' NL ...
                    '                     while ( enclosingBox )' NL ...
                    '                     {' NL ...
                    '                        prevBox      = enclosingBox;' NL ...
                    '                        enclosingBox = enclosingBox.closest("details");' NL ...
                    '                        if ( enclosingBox===prevBox ){' NL ...
                    '                           enclosingBox = enclosingBox.parentElement' NL ...
                    '                           if ( enclosingBox ) { enclosingBox = enclosingBox.closest("details"); }  }' NL ...
                    '                        if (enclosingBox && !enclosingBox.open) { open_details(enclosingBox.id) }' NL ...
                    '                     }' NL ...
                    '                     if (target && in_iFrame() && !contentDiv.getAttribute("data-isHelpBrowser") ){' NL ...
                    '                        event.preventDefault();' NL ...
                    '                        target.scrollIntoView(); }' NL ...
                    '                     var nextElem = target.nextElementSibling;' NL ...
                    '                     var nextNode = target.nextSibling;' NL ...
                    '                     while ( nextNode && nextNode.nodeType==Node.TEXT_NODE && nextNode.data.trim().length == 0 ){' NL ...
                    '                        nextNode = nextNode.nextSibling;}' NL ...
                    '                     if ( nextElem && nextElem===nextNode && nextElem.localName.localeCompare("details")===0 && '...
                                                                                                                                    '!nextElem.open){' NL ...
                    '                        open_details(nextElem.id);}' NL ...
                    '                  }' NL ...
                    '                  else { return }' NL ...
                    '                  if (!contentDiv.getAttribute("data-isHelpBrowser"))' NL ...
                    '                  {' NL ...
                    '                      update_back_position();' NL ...
                    '                      returnButton.style.display = "block";' NL ...
                    '                      var linkTop   = clickedElem.offsetTop;' NL ...
                    '                      var targetTop = target.offsetTop;' NL ...
                    '                      if (targetTop>linkTop){' NL ...
                    '                          document.getElementById("down").style.display = "none";' NL ...
                    '                          document.getElementById("up").style.display   = "inline"; }' NL ...
                    '                      else{' NL ...
                    '                          document.getElementById("up").style.display   = "none";' NL ...
                    '                          document.getElementById("down").style.display = "inline"; }' NL ...
                    '                      returnElem = clickedElem;' NL ...
                    '                  }' NL ...
                    '              }' NL ...
                    '          }' NL NL ...
                    '          function open_details(detailsID)' NL ...
                    '          {' NL ...
                    '              var details  = document.getElementById(detailsID);' NL ...
                    '              skipCheck    = true;' NL ...
                    '              state_check(details.id);' NL ...
                    '              details.open = true;' NL ...
                    '          }' NL NL ...
                    '          function update_back_position()' NL ...
                    '          {' NL ...
                    '              try' NL ...
                    '              {' NL ...
                    '                  window.addEventListener("scroll", update_back_position, true);' NL ...
                    '                  window.addEventListener("resize", update_back_position, true);' NL ...
                    '                  var scrollPos;' NL ...
                    '                  if (in_iFrame())' NL ...
                    '                  {' NL ...
                    '                      parent.window.addEventListener("scroll", update_back_position, true);' NL ...
                    '                      parent.window.addEventListener("resize", update_back_position, true);' NL ...
                    '                      var iFrame         = window.frameElement;' NL ...
                    '                      var frameOffset    = get_offset(iFrame);' NL ...
                    '                      var documentBottom = parent.window.innerHeight  + parent.window.scrollY;' NL ...
                    '                      var extHeight      = Math.round(frameOffset.top + iFrame.getBoundingClientRect().height - documentBottom);' NL ...
                    '                      if (extHeight<0) { extHeight = 0; }' NL ...
                    '                      returnButton.style.bottom = (10+extHeight) + "px";' NL ...
                    '                      document.getElementById("tooltiptext").style.bottom = (11+extHeight) + "px";' NL ...
                    '                      scrollPos = contentDiv.scrollTop - 25 + iFrame.getBoundingClientRect().height - extHeight;' NL ...
                    '                  }' NL ...
                    '                  else{' NL ...
                    '                      scrollPos = window.scrollY + window.innerHeight - 25;}' NL ...
                    '                  if (returnElem.offsetTop>scrollPos){' NL ...
                    '                      document.getElementById("down").style.display = "inline";' NL ...
                    '                      document.getElementById("up").style.display   = "none";   }' NL ...
                    '                  else{' NL ...
                    '                      document.getElementById("down").style.display = "none";' NL ...
                    '                      document.getElementById("up").style.display   = "inline"; }' NL ...
                    '              }' NL ...
                    '              catch(e){}' NL ...
                    '          }' NL ...
                    '          function set_theme(themePref)' NL ...
                    '          {' NL ...
                    '            var themeSwitch     = document.getElementById("ToggleTheme");' NL ...
                    '            var themeSwitchText = "switch to";' NL ...
                    '            var switchToText    = null;' NL ...
                    '            if (!themePref){ themePref = get_theme_pref(); }' NL ...
                    '            if (themePref.localeCompare("light")===0){' NL ...
                    '                document.getElementById("dark-theme").sheet.disabled = true;' NL ...
                    '                document.getElementById("hide-dark").sheet.disabled  = false;' NL ...
                    '                switchToText = " dark theme";}' NL ...
                    '            else{' NL ...
                    '                document.getElementById("dark-theme").sheet.disabled = false;' NL ...
                    '                document.getElementById("hide-dark").sheet.disabled  = true;' NL ...
                    '                switchToText = " light theme";}' NL ...
                    '            themeSwitch.innerHTML = themeSwitchText + switchToText;' NL ...
                    '            set_theme_pref(themePref);' NL ...
                    '          }' NL NL ...
                    '          function toggle_theme()' NL ...
                    '          {' NL ...
                    '            if (document.getElementById("dark-theme").sheet.disabled) { set_theme("dark");  }' NL ...
                    '            else                                                      { set_theme("light"); }' NL ...
                    '          }' NL NL ...
                    '          function set_theme_pref(themePref)' NL ...
                    '          {' NL ...
                    '              var d = new Date();' NL ...
                    '              d.setTime(d.getTime() + (2*365*24*60*60*1000));' NL ...
                    '              var expires = "expires="+ d.toUTCString();' NL ...
                    '              document.cookie = "themepref=" + themePref + ";" + expires + "path=/";' NL ...
                    '              localStorage.setItem("PRETTY_THEME", themePref);' NL ...
                    '          }' NL ...
                    NL ...
                    '          function get_theme_pref() {' NL ...
                    '              var name = "themepref=";' NL ...
                    '              var decodedCookie = decodeURIComponent(document.cookie);' NL ...
                    '              var ca = decodedCookie.split('';'');' NL ...
                    '              for(var i = 0; i < ca.length; i++) {' NL ...
                    '                var c = ca[i];' NL ...
                    '                while (c.charAt(0) == '' '') {' NL ...
                    '                  c = c.substring(1);' NL ...
                    '                }' NL ...
                    '                if (c.indexOf(name) == 0) {' NL ...
                    '                  return c.substring(name.length, c.length);' NL ...
                    '                }' NL ...
                    '              }' NL ...
                    '              var docTheme = localStorage.getItem("PRETTY_THEME");' NL ...
                    '              if (docTheme) { return docTheme }' NL ...
                    '              else          { return "light"  }' NL ...
                    '          }' NL ...
                    NL ...
                    '          function toggle_details(section)' NL ...
                    '          {' NL ...
                    '            var link;' NL ...
                    '            var subSection;' NL ...
                    '            var details;' NL ...
                    '            var linkText;' NL ...
                    '            var i;' NL ...
                    '            var openState  = true;' NL ...
                    '            var border     = "6px 6px 0 0;"' NL ...
                    '            if (section===0)' NL ...
                    '            {' NL ...
                    '              link = document.getElementById("Toggle"+section.toString());' NL ...
                    '              if (link.innerHTML.localeCompare("collapse all on page")===0){' NL ...
                    '                  openState = false;' NL ...
                    '                  border    = "6px;"' NL ...
                    '                  linkText  = "expand all";}' NL ...
                    '              else{' NL ...
                    '                  linkText   = "collapse all";}' NL ...
                    '              link.innerHTML = linkText + " on page";' NL ...
                    '              for (i = 0; i < allDetails.length; i++){' NL ...
                    '                 allDetails[i].open = openState;' NL ...
                    '                 allDetails[i].children[0].setAttribute( ''style'', "border-radius:"+border );' NL ...
                    '                 link = document.getElementById("Toggle"+allDetails[i].id.split(".", 1));' NL ...
                    '                 if (allDetails[i].id.charAt(0).localeCompare("0") && link){link.innerHTML = linkText;}}' NL ...
                    '            }' NL ...
                    '            else' NL ...
                    '            {' NL ...
                    '               link = document.getElementById("Toggle"+section.toString());' NL ...
                    '               subSection = 1;' NL ...
                    '               if (link.innerHTML.localeCompare("collapse all")===0){' NL ...
                    '                  openState      = false;' NL ...
                    '                  border         = "6px;"' NL ...
                    '                  link.innerHTML = "expand all";}' NL ...
                    '               else{' NL ...
                    '                  link.innerHTML = "collapse all";}' NL ...
                    '               details = document.getElementById(section.toString()+"."+subSection.toString());' NL ...
                    '               while (details){' NL ...
                    '                    details.open = openState;' NL ...
                    '                    details.children[0].setAttribute( ''style'', "border-radius:"+border );' NL ...
                    '                    subSection++;' NL ...
                    '                    details = document.getElementById(section.toString()+"."+subSection.toString());}' NL ...
                    '               var allCollapsed = true;' NL ...
                    '               var allExpanded  = true;' NL ...
                    '               for (i = 0; i < allDetails.length; i++){' NL ...
                    '                   check_if_open(allDetails[i]);}' NL ...
                    '               link = document.getElementById("Toggle0");' NL ...
                    '               if (allExpanded) {link.innerHTML = "collapse all on page";}' NL ...
                    '               if (allCollapsed){link.innerHTML = "expand all on page";}' NL ...
                    '            }' NL ...
                    '            function check_if_open(details)' NL ...
                    '            {' NL ...
                    '                if (details.open){allCollapsed = false;}' NL ...
                    '                else             {allExpanded  = false;}' NL ...
                    '            }' NL ...
                    '          }' NL NL ...
                    '          function state_check(detailsID)' NL ...
                    '          {' NL ...
                    '              // first deal with just the section' NL ...
                    '              if (event.detail){document.activeElement.blur();}' NL ...
                    '              var clickedElem   = event.target;' NL ...
                    '              if (!skipCheck && clickedElem.localName.localeCompare("summary"))' NL ...
                    '              { ' NL ...
                    '                if (!(clickedElem.closest("summary"))) { return };' NL ...
                    '              };' NL ...
                    '              var details       = document.getElementById(detailsID);' NL ...
                    '              if ( !skipCheck ) {' NL ...
                    '                  var parentID  = clickedElem.closest("details").id;' NL ...
                    '                  if (details.id.localeCompare(parentID)) { return };}' NL ...
                    '              skipCheck         = false;' NL ...
                    '              var clickedStatus = details.open;' NL ...
                    '              var section       = detailsID.split(".", 1);' NL ...
                    '              var subSection    = 1;' NL ...
                    '              var allCollapsed  = true;' NL ...
                    '              var allExpanded   = true;' NL ...
                    '              var link          = document.getElementById("Toggle"+section);' NL ...
                    '              if (clickedStatus) { details.children[0].setAttribute( ''style'', "border-radius:6px;" ); }' NL ...
                    '              else               { details.children[0].setAttribute( ''style'', "border-radius:6px 6px 0 0;" ); }' NL ...
                    '              if (link)' NL ...
                    '              {' NL ...
                    '                  details = document.getElementById(section+"."+subSection.toString());' NL ...
                    '                  while (details){' NL ...
                    '                    check_if_open(details);' NL ...
                    '                    subSection++;' NL ...
                    '                    details = document.getElementById(section+"."+subSection.toString());}' NL ...
                    '                  if (allExpanded) {link.innerHTML = "collapse all";}' NL ...
                    '                  if (allCollapsed){link.innerHTML = "expand all";}' NL ...
                    '              }' NL ...
                    '              // then the whole page' NL ...
                    '              allCollapsed   = true;' NL ...
                    '              allExpanded    = true;' NL ...
                    '              for (var i = 0; i < allDetails.length; i++){' NL ...
                    '                  check_if_open(allDetails[i]);}' NL ...
                    '              link = document.getElementById("Toggle0");' NL ...
                    '              if (allExpanded) {link.innerHTML = "collapse all on page";}' NL ...
                    '              if (allCollapsed){link.innerHTML = "expand all on page";}' NL NL ...
                    '              function check_if_open(details)' NL ...
                    '              {' NL ...
                    '                  var openStatus' NL ...
                    '                  if (detailsID.localeCompare( details.id )===0 ){openStatus = !clickedStatus;}' NL ...
                    '                  else                                           {openStatus = details.open;}' NL ...
                    '                  if (openStatus){allCollapsed = false;}' NL ...
                    '                  else           {allExpanded  = false;}' NL ...
                    '              }' NL ...
                    '          }' NL ...
                    NL ...
                    '          function in_iFrame ()' NL ...
                    '          {' NL ...
                    '               try {' NL ...
                    '                   return window.self !== window.top;' NL ...
                    '               } catch (e) {' NL ...
                    '                   return true;' NL ...
                    '               }' NL ...
                    '          }' NL ...
                    '</script>' NL];
    %% Insert extra css and javascript
    STYLE_CLOSE = '</style>';
    cssClose    = strfind(fstrm,STYLE_CLOSE);
    cssClose    = cssClose(1);
    rewindCount = 0;
    while fstrm(cssClose)~=NL, rewindCount = rewindCount+1; cssClose = cssClose-1; end
    fstrm = [fstrm(1:cssClose-1+length(STYLE_CLOSE)+rewindCount) NL javaScript fstrm(cssClose+length(STYLE_CLOSE)+rewindCount:end)];
    fstrm = [fstrm(1:cssClose-1) extraCSS '</style>' darkTheme jumpShift fstrm(cssClose+length(STYLE_CLOSE)+rewindCount:end)];
    %% Fix/tweak publish's css
    fstrm = strrep(fstrm, '.content { font-size:1.2em; line-height:140%;', '.content { font-size:1.2em; line-height:160%;');
    fstrm = strrep(fstrm, 'pre { margin:0px 0px 20px; }', 'pre { margin:0px 0px 15px; overflow-x:auto; }');
    fstrm = strrep(fstrm, 'pre, code { font-size:12px; }', 'pre { font-size:12px; }');
    fstrm = strrep(fstrm, 'tt { font-size: 1.2em; }','code { font-size: 1.15em; }');
    fstrm = strrep(fstrm, 'pre.codeoutput { padding:10px 11px; margin:0px 0px 20px;','pre.codeoutput { padding:10px 11px; margin:0px 0px 15px;');
    %% html validation fixes
    fstrm = strrep(fstrm, ['<!DOCTYPE html' NL '  PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'],'<!DOCTYPE html>');
    fstrm = strrep(fstrm, '<html>', '<html lang="en">');
    fstrm = strrep(fstrm, '<style type="text/css">','<style>');
    fstrm = strrep(fstrm, ':focus{outine:0}','');
    fstrm = strrep(fstrm, '<tt','<code'); fstrm = strrep(fstrm, '</tt>','</code>');
    %% Insert floating "return" link
    fstrm = strrep(fstrm,'<div class="content">',...
                         ['<div class="content">' NL ...
                          '<div id="return-link" style="display:none;" class="tooltip">' NL ...
                          '<p onclick="jump_to()">' NL ...
                          '    <span onclick="jump_to()"><span id="up">&#8679;</span><span id="down">&#8681;</span>' NL ...
                          '    <span onclick="hide_back_link()" style="padding:2px; font-size:120%;" id="jump-close">' ...
                              '<b onclick="hide_back_link()">&times;</b></span></span>' NL ...
                          '</p>' NL ...
                          '<div id="tooltiptext">click to return<br>(click <b>&times;</b> to hide)</div>' NL ...
                          '</div>']);
    %% Find start and end of page body source
    [sourceStart, htmlEnd] = find_source(fstrm);
    if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'input.html', 1); end
    %% Move any <style></style> section to before the body
    styleStart = strfind(fstrm(sourceStart:htmlEnd),'<style');
    if ~isempty(styleStart)
        styleStart = styleStart + sourceStart - 1;
        styleEnd   = strfind(fstrm(sourceStart:htmlEnd),'</style>');
        assert(length(styleStart)==length(styleEnd),'ERROR: Imbalanced <style></style> tags; there are %i opening tags and %i closing tags', ...
                                                    length(styleStart), length(styleEnd));
        styleEnd = styleEnd + sourceStart - 1;
        for i = 1:length(styleStart)
            sectionLength = 1+styleEnd(i)+7-styleStart(i);
            fstrm = [fstrm(1:sourceStart-1) fstrm(styleStart(i):styleEnd(i)+7) fstrm(sourceStart:end)];
            styleStart(i) = styleStart(i) + sectionLength;
            styleEnd(i)   = styleEnd(i)   + sectionLength;
            sourceStart   = sourceStart   + sectionLength;
            fstrm(styleStart(i):styleEnd(i)+7) = [];
        end
    end
    %% Process [h2] tags
    if verbose, fprintf(1,'   [h2] tags...\n'); end
    userHeadingCounter = 0;
    fstrm = strrep(fstrm,'[h2]' ,'<h2>' );
    fstrm = strrep(fstrm,'[/h2]','</h2>');
    userHeadings = strfind(fstrm(sourceStart:htmlEnd),'[h2.CElink]');
    if ~isempty(userHeadings)
        userHeadings = userHeadings + sourceStart - 1;
        for i = 1:length(userHeadings)
            userHeadingCounter = userHeadingCounter+1;
            headingTag = ['<h2 id="userHeading' num2str(userHeadingCounter) '">'];
            fstrm = [fstrm(1:userHeadings(i)-1) headingTag fstrm(userHeadings(i)+11:end)];
            userHeadings = userHeadings + length(headingTag)-11;
            htmlEnd      = htmlEnd      + length(headingTag)-11;
        end
    end
    if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'after processing [h2] tags.html', 1); end
    %% Process [targetn] and [jumpton] tags
    if verbose, fprintf(1,'   target and jump tags...\n'); end
    [fstrm, htmlEnd] = process_target_and_jump_tags(fstrm, htmlEnd);
    if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'after processing internal links.html', 1); end
    %% Process colour, scale, and class tags
    if verbose, fprintf(1,'   colour, scale, and class tags...\n'); end
    tagList = {'colour','scale','class'};
    validValList = {[],[],classNames};
    for i = 1:length(tagList)
        tagName = tagList{i};
        [tagOpens, tagCloses] = get_tag_pairs(['[' tagName ']'], fstrm, htmlEnd);
        [fstrm, htmlEnd, tagOpens, tagCloses, vals, tagEnds] = find_valid_prettify_tags(tagName, tagOpens, tagCloses, validValList{i}, fstrm, htmlEnd);
        [fstrm, htmlEnd] = prettyTag2htmlTag(tagName, tagOpens, tagCloses, vals, tagEnds, fstrm, sourceStart, htmlEnd, DEBUG);
        if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), ['after processing ' tagName '.html'], 1); end
    end
    %% Find [dtls] and [smry] tags
    if verbose, fprintf(1,'   dtls tags...\n'); end
    [detailsOpens, detailsCloses] = get_tag_pairs('[dtls]', fstrm, htmlEnd);
    [summaryOpens, summaryCloses] = get_tag_pairs('[smry]', fstrm, htmlEnd);
    assert(length(summaryOpens)==length(detailsOpens), 'ERROR: Number of [smry] tags does not match the number of [dtls] tags');
    detailsTags = {detailsOpens, detailsCloses};
    wrapTags = {'<span','<pre'};
    for i = 1:2
        if i == 1, slash = '';
        else     , slash = '/'; end
        for j = 1:length(detailsOpens)
            for k = 1:length(wrapTags)
                wrapTag  = wrapTags{k};
                wrapIdxs = strfind(fstrm(sourceStart:detailsTags{i}(j)), wrapTag) + sourceStart - 1;
                if ~isempty(wrapIdxs)
                    wrapIdxs = wrapIdxs(end);
                    if ~contains(fstrm(wrapIdxs:detailsTags{i}(j)),['</' wrapTag(2:end) '>'])
                        if k == 1, warnStr1 = 'appears inside a comment section of';  warnStr2 = 'forgotten a space';
                        else     , warnStr1 = 'is wrapped in <pre>...</pre> tags in'; warnStr2 = 'put too many spaces'; end
                        show_warning(sprintf(['[%cdtls] tag %i %s the html document - this may cause an error.\n' ...
                                              'Possibly you have forgotten to start a new section in the source .m file, or %s '    ...
                                              'between the start-of-line "%%" and the [%cdtls] tag.'], slash, j, warnStr1, warnStr2, slash));
                        break
                    end
                end
            end
        end
    end
    [countOfDtlsTags, detailsCloses] = sort_tag_closes(detailsOpens, detailsCloses);
    for i = 1:countOfDtlsTags
        assert(summaryOpens (i)>detailsOpens (i),'ERROR: [smry] tag %i opened before [dtls] tag %i', i, i);
        assert(summaryCloses(i)<detailsCloses(i),'ERROR: [dtls] tag pair %i closed before [smry] tag pair %i', i, i);
    end
    imgTags = [];
    %% Process [dtls] and [smry] tags
    if ~isempty(detailsOpens)
        dummySections        = 0;
        revertedCount        = false;
        revertAt             = 0;
        subSectionCounterBak = NaN;
        collapseAllStyle = 'class="collapse-link"';
        collapseAllPos   = strfind(fstrm(sourceStart:htmlEnd),'<h2>Contents</h2>') + sourceStart - 1;
        noSections       = false;
        insertPoint      = detailsOpens(1)-1;
        if isempty(collapseAllPos) || any(detailsOpens<collapseAllPos(1))
            if isempty(collapseAllPos), noSections = true; collapseAllPos=0; end
            firstP = strfind(fstrm(sourceStart:htmlEnd),'<div class="content">') + sourceStart - 1;
            firstP = strfind(fstrm(firstP(1):htmlEnd),'<p>') + firstP(1) - 1;
            assert (~isempty(firstP),[NO_START_ERR ' - is entire source .m file comment-only? Did you forget to start a section?']);
            if isempty(themeSwitch)
                collapseAll = ['<p style="margin:0px; line-height:0;">&nbsp;</p><p onclick="toggle_details(0)"'...
                               ' style="float:right; padding-left:10px; margin:0;"><a href="javascript:void(0);" id="Toggle0">collapse all on page</a></p>'];
                fstrm       = strrep(fstrm,'<script>document.getElementById("dark-theme")',[collapseAll '<script>document.getElementById("dark-theme")']);
            else
                newThemeSwitch = strrep(themeSwitch,['<p onclick="toggle_theme()" style="text-align:right; float:right; padding-left:10px; margin:0;">'...
                                                     '<a '],...
                                                    ['<p style="text-align:right; float:right; padding-left:10px; margin:0;"><span ' ...
                                                     'onclick="toggle_theme()" style="line-height:100%; padding-bottom:1px; border-bottom:1px ' ...
                                                     'solid #d6d4d4;"><a ']);
                newThemeSwitch = strrep(newThemeSwitch,'</a>','</a></span>');
                fstrm          = strrep(fstrm,themeSwitch,newThemeSwitch);

                update_idxs(length(newThemeSwitch)-length(themeSwitch));
                collapseAll = '<br><span onclick="toggle_details(0)"><a href="javascript:void(0);" id="Toggle0">collapse all on page</a></span>&nbsp;';
                fstrm       = strrep(fstrm,'</p></div><script>set_theme(null)</script>',[collapseAll '</p></div><script>set_theme(null)</script>']);
            end
        else
            collapseAllPos = collapseAllPos(1);
            collapseAll = ['<p style="margin:0px; line-height:0;">&nbsp;</p><p onclick="toggle_details(0)" ' collapseAllStyle '>'...
                           '<a href="javascript:void(0);" id="Toggle0">collapse all on page</a></p>'];
            fstrm = [fstrm(1:collapseAllPos-1) collapseAll fstrm(collapseAllPos:end)];
        end
        update_idxs(length(collapseAll));
        collapseAllPos = collapseAllPos(1)+length(collapseAll);
        sectionsCounter   = 0;
        subSectionCounter = 1;
        detailsBeforeContents = detailsOpens<collapseAllPos;
        for detailsSectionCounter = 1:countOfDtlsTags
            if revertAt && detailsOpens(detailsSectionCounter)>detailsCloses(revertAt)
                sectionsCounter      = sectionsCounterBak;
                subSectionCounter    = subSectionCounterBak;
                subSectionCounterBak = NaN;
                revertedCount        = true;
                revertAt             = 0;
            end
            if ~noSections
                if detailsBeforeContents(detailsSectionCounter)
                    sectionsCounter=-1;
                    if subSectionCounter==1
                        sectionCollapseState = ['<div style="display:none;"><p id="Toggle' num2str(sectionsCounter) '">collapse all</p></div>'];
                        fstrm = [fstrm(1:detailsOpens(detailsSectionCounter)-1) sectionCollapseState fstrm(detailsOpens(detailsSectionCounter):end)];
                        insertPoint = detailsOpens(detailsSectionCounter)-1;
                        update_idxs(length(sectionCollapseState));
                    end
                elseif sectionsCounter==-1
                    sectionsCounter = 0;
                end
            elseif sectionsCounter == 0
                sectionsCounter = 1;
            end
            if detailsSectionCounter==1, headingSearchStart = 1;
            else                       , headingSearchStart = detailsOpens(detailsSectionCounter-1); end
            headingIdx = strfind( fstrm(headingSearchStart:detailsOpens(detailsSectionCounter)), '<h2 id="' );
            if ~isempty(headingIdx)
                skipHeading = false;
                headingIdx  = headingSearchStart-1+headingIdx(end);
                idEnd       = strfind(fstrm(headingIdx+9:detailsOpens(detailsSectionCounter)),'"');
                if isempty(idEnd), error('ERROR: malformed <h2> tag (no closing " for id)'); end
                idEnd = idEnd(1) + headingIdx + 7;
                headingNum = str2double(fstrm(headingIdx+8:idEnd));
                if isnan(headingNum), isDummySection = true;
                else                , isDummySection = false; end
                headingNestLevel = sum(headingIdx<detailsCloses(1:detailsSectionCounter-1));
                if detailsSectionCounter>1 && headingNestLevel
                    if ~isDummySection
                        error('ERROR: Section heading %i is inside a [dtls] box: this is not supported', headingNum);
                    elseif headingNestLevel > sum(detailsOpens(detailsSectionCounter)<detailsCloses(1:detailsSectionCounter-1))
                        skipHeading = true;
                    elseif ~noSections
                        revertAt = find(headingIdx<detailsCloses(1:detailsSectionCounter-1),1,'last');
                    end
                end
                if ~skipHeading
                    sectionsCounter = sectionsCounter + 1;
                    if ~isDummySection
                        subSectionCounterBak = NaN;
                    else
                        if isnan(subSectionCounterBak)
                            sectionsCounterBak   = sectionsCounter - 1;
                            subSectionCounterBak = subSectionCounter;
                        end
                    end
                    if revertedCount, sectionsCounter = sectionsCounter + dummySections; end
                    revertedCount = false;
                    subSectionCounter = 1;
                    headingClose  = strfind(fstrm(headingIdx:detailsOpens(detailsSectionCounter)),'</h2>');
                    headingClose  = headingClose(1) + headingIdx - 1;
                    if ~contains(fstrm(headingIdx:headingClose),'display:none')
                        sectionHeader     = ['<p style="margin:0px; line-height:0;">&nbsp;</p><p onclick="toggle_details(' num2str(sectionsCounter)...
                                             ')" class="collapse-link"><a href="javascript:void(0);" id="Toggle' num2str(sectionsCounter) ...
                                             '">collapse all</a></p>'];
                        fstrm = [fstrm(1:headingIdx-1) sectionHeader fstrm(headingIdx:end)];
                        insertPoint = headingIdx-1;
                        update_idxs(length(sectionHeader));
                    end
                    if isDummySection, dummySections = dummySections+1; end
                end
            end
            % <p>...[dtls] -> ...[dtls][smry]...[/smry]<p>
            % look for unbalanced <p></p> tags before the [dtls] tag
            pBeforeDtls = strfind(fstrm(sourceStart:detailsOpens(detailsSectionCounter)),'<p') + sourceStart - 1;
            if ~isempty(pBeforeDtls)
                closepBeforeDtls = strfind(fstrm(sourceStart:detailsOpens(detailsSectionCounter)),'</p>') + sourceStart - 1;
                if length(pBeforeDtls) > length(closepBeforeDtls)
                    while closepBeforeDtls(end)>pBeforeDtls(end)
                        closepBeforeDtls(end) = [];
                        pBeforeDtls(end)      = [];
                    end
                    % move pBeforeDtls(end) to after the [/smry] tag associated with this [dtls] tag, but only if the pBeforeDtls is a plain "<p>"
                    if strcmp(fstrm(pBeforeDtls(end):pBeforeDtls(end)+2),'<p>')
                        fstrm(pBeforeDtls(end):pBeforeDtls(end)+2) = [];
                        detailsOpens ( detailsSectionCounter ) = detailsOpens ( detailsSectionCounter ) - 3;
                        summaryCloses( detailsSectionCounter ) = summaryCloses( detailsSectionCounter ) - 3;
                        fstrm = [fstrm(1:summaryCloses(detailsSectionCounter)+6) '<p>' fstrm(summaryCloses(detailsSectionCounter)+7:end)];
                    end
                end
            end
            % [/dtls]...</p> -> [/dtls]<p>...</p> + delete the previous <p>
            % or [/dtls]</p> -> [/dtls] + delete the previous <p>
            closepAfterDtls = strfind(fstrm(detailsCloses(detailsSectionCounter):htmlEnd),'</p>') + detailsCloses(detailsSectionCounter) - 1;
            if ~isempty(closepAfterDtls)
                closepAfterDtls = closepAfterDtls(1);
                pAfterDtls      = strfind(fstrm(detailsCloses(detailsSectionCounter):htmlEnd),'<p') + detailsCloses(detailsSectionCounter) - 1;
                if isempty(pAfterDtls) || pAfterDtls(1)>closepAfterDtls
                    if strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+10),'</p>')
                        fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+10) = [];
                        insertPoint = detailsCloses(detailsSectionCounter);
                        update_idxs(-4);
                    else
                        fstrm = [fstrm(1:detailsCloses(detailsSectionCounter)+6) '<p>' fstrm(detailsCloses(detailsSectionCounter)+7:end)];
                        insertPoint = detailsCloses(detailsSectionCounter);
                        update_idxs(3);
                    end
                    pInDtls = strfind(fstrm(detailsOpens(detailsSectionCounter):detailsCloses(detailsSectionCounter)),'<p>');
                    if ~isempty(pInDtls)
                        pInDtls = pInDtls(end) + detailsOpens(detailsSectionCounter) - 1;
                        fstrm(pInDtls:pInDtls+2) = [];
                        insertPoint = pInDtls;
                        update_idxs(-3);
                    end
                end
            end
            % [dtls] -> <details open onclick="state_check(<ID>)" id="<ID>">
            detailsId     = [num2str(sectionsCounter) '.' num2str(subSectionCounter)];
            detailsOpener = ['<details open onclick="state_check(''' detailsId ''')" id="' detailsId '">'];
            fstrm = [fstrm(1:detailsOpens(detailsSectionCounter)-1) detailsOpener fstrm(detailsOpens(detailsSectionCounter)+6:end)];
            insertPoint = detailsOpens(detailsSectionCounter)-1;
            update_idxs(length(detailsOpener)-6);
            % [/dtls] -> </div></details>
            addBreak = '';
            % add line break after [dtls] section, if necessary
            if ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+13),'<p></p>')                ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+14),'<p> </p>')               ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+14),['<p>' char(160) '</p>']) ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+24),'<p class="footer">')     ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+12),'<p><br')                 ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+12),'<p>[br')                 ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+9) ,'<br')                    ...
            && ~strcmp(fstrm(detailsCloses(detailsSectionCounter)+7:detailsCloses(detailsSectionCounter)+9) ,'[br')
                addBreak = '<br>';
            end
            dtlsClose = ['</div></details>' addBreak];
            fstrm = [fstrm(1:detailsCloses(detailsSectionCounter)-1) dtlsClose fstrm(detailsCloses(detailsSectionCounter)+7:end)];
            insertPoint = detailsCloses(detailsSectionCounter)-1;
            update_idxs(length(dtlsClose)-7);
            subSectionCounter = subSectionCounter + 1;
            if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), ['after replacing [dtls] tag set ' num2str(detailsSectionCounter) '.html'], 1); end
        end
        fstrm = strrep(fstrm,'[smry]','<summary>');
        fstrm = strrep(fstrm,'[/smry]','</summary><div class="details-div">');
        if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'after replacing [smry] tags.html', 1); end
        insertPoint = detailsOpens(1)-1;
        update_idxs(31*countOfDtlsTags);
        %%     Remove excess line breaks after any tables in details sections
        detailsOpens  = strfind(fstrm(sourceStart:htmlEnd),'<details open ') + sourceStart - 1;
        detailsCloses = strfind(fstrm(sourceStart:htmlEnd),'</details>') + sourceStart - 1;
        [countOfDtlsTags, detailsCloses] = sort_tag_closes(detailsOpens, detailsCloses);
        for detailsCounter = 1:countOfDtlsTags
            tableCloseIdxs = strfind(fstrm(detailsOpens(detailsCounter):detailsCloses(detailsCounter)),'</table>')  + detailsOpens(detailsCounter) - 1;
            for i = 1:length(tableCloseIdxs)
                brIdx = strfind(fstrm(tableCloseIdxs(i)+8:detailsCloses(detailsCounter)-5),'<br>');
                if isempty(brIdx), continue, end
                brIdx = brIdx(1) + tableCloseIdxs(i) + 7;
                if strcmp(sscanf( fstrm(tableCloseIdxs(i)+8:brIdx+3),'%s' ),'<br>')
                    fstrm(brIdx:brIdx+3) = [];
                    tableCloseIdxs = tableCloseIdxs-4;
                    insertPoint    = brIdx;
                    update_idxs(-4);
                end
            end
        end
        %%     Remove excess spacing after any lists at the end of details sections
        for listTag = {'ul','ol'}
            for detailsCounter = 1:countOfDtlsTags
                listIdxs = strfind(fstrm(detailsOpens(detailsCounter):detailsCloses(detailsCounter)),['<' listTag{:} '>']);
                listIdxs = sort( [listIdxs strfind(fstrm(detailsOpens(detailsCounter):detailsCloses(detailsCounter)),['<' listTag{:} ' style="'])] );
                if ~isempty(listIdxs)
                    listIdxs   = listIdxs(end) + detailsOpens(detailsCounter) - 1;
                    listTagEnd = strfind(fstrm(listIdxs:detailsCloses(detailsCounter)),'>');
                    listTagEnd = listTagEnd(1) + listIdxs - 1;
                    listEnd  = strfind(fstrm(listIdxs:detailsCloses(detailsCounter)),['</' listTag{:} '>']) + listIdxs - 1;
                    if ~isempty(listEnd) && ~contains(fstrm(listIdxs:listTagEnd),'margin')
                        if strcmp(fstrm(listEnd:detailsCloses(detailsCounter)),['</' listTag{:} '></div></span></div><']) ...
                        || strcmp(fstrm(listEnd:detailsCloses(detailsCounter)),['</' listTag{:} '></div></div><']) ...
                        || strcmp(fstrm(listEnd:detailsCloses(detailsCounter)),['</' listTag{:} '></span></div><']) ...
                        || strcmp(fstrm(listEnd:detailsCloses(detailsCounter)),['</' listTag{:} '></div><'])
                            if fstrm(listIdxs+3)=='>'
                                fstrm = [fstrm(1:listIdxs+2) ' style="margin-bottom:0px;"' fstrm(listIdxs+3:end)];
                                insertPoint = listIdxs+2;
                                update_idxs(27);
                            else % <ul style="blah -> <ul style="margin-bottome:0px; blah
                                fstrm = [fstrm(1:listIdxs+10) 'margin-bottom:0px; ' fstrm(listIdxs+11:end)];
                                insertPoint = listIdxs+10;
                                update_idxs(19);
                            end
                        end
                    end
                end
            end
        end
        if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'before adding breaks between tables and images.html', 1); end
        %%     Add breaks between tables and images
        for detailsCounter = 1:countOfDtlsTags
            tableThenImage = strfind(fstrm(detailsOpens(detailsCounter):detailsCloses(detailsCounter)),'</table><img ')  + detailsOpens(detailsCounter) - 1;
            for i = 1:length(tableThenImage)
                fstrm = [fstrm(1:tableThenImage(i)+7) '[br15]' fstrm(tableThenImage(i)+8:end)];
                insertPoint = tableThenImage(i)+7;
                update_idxs(6);
                tableThenImage = tableThenImage+6;
            end
        end
        if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'after adding [br15].html', 1); end
    end
    %% Process [bottomMarginx] tags
    if verbose, fprintf(1,'   bottom margin tags...\n'); end
    marginTagList = strfind(fstrm(sourceStart:htmlEnd),'[bottomMargin') + sourceStart - 1;
    [fstrm, htmlEnd, marginTagList, ~ , margins, marginTagEnds] = find_valid_prettify_tags('bottomMargin', marginTagList, [], [], fstrm, htmlEnd);
    for i = 1:length(marginTagList)
        tagLength = 1+marginTagEnds(i)-marginTagList(i);
        if strcmp(fstrm(marginTagList(i)-3:marginTagList(i)-1),'<p>')
            style     = [' style="margin-bottom: ' num2str(margins(i)) 'px;"'];
            if strcmp(fstrm(marginTagEnds(i)+1:marginTagEnds(i)+9),'</p><div>')
                % <p>[bottomMarginx]</p><div> -> <div style="margin-bottom:xpx;">
                fstrm = [fstrm(1:marginTagEnds(i)+8) style fstrm(marginTagEnds(i)+9:end)];
                fstrm(marginTagList(i)-3:marginTagEnds(i)+4) = [];
                charsAdded = length(style) - (tagLength+7);
            else
                % <p>[bottomMarginx] -> <p style="margin-bottom:xpx;">
                fstrm = [fstrm(1:marginTagList(i)-2) style fstrm(marginTagList(i)-1:end)];
                fstrm(marginTagList(i)+length(style):marginTagEnds(i)+length(style)) = [];
                charsAdded = length(style) - tagLength;
            end
        else
            fstrm(marginTagList(i):marginTagEnds(i)) = [];
            charsAdded = -tagLength;
        end
        marginTagList = marginTagList + charsAdded;
        marginTagEnds = marginTagEnds + charsAdded;
        htmlEnd       = htmlEnd       + charsAdded;
    end
    if DEBUG && ~isempty(marginTagList), write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'after processing bottomMarginx.html', 1); end
    %% Assign image-fit class to all images
    imgTags = strfind(fstrm(sourceStart:htmlEnd),'<img ') + sourceStart - 1;
    for i = 1:length(imgTags)
        srcIdx    = strfind(fstrm(imgTags(i):htmlEnd),' src=');
        srcIdx    = srcIdx(1) + imgTags(i) - 1;
        imgTagEnd = strfind(fstrm(imgTags(i):htmlEnd),'>');
        imgTagEnd = imgTagEnd(1) + imgTags(i) - 1;
        assert(~isempty(srcIdx) && ~isempty(imgTagEnd),'ERROR: malformed image tags found');
        if contains(fstrm(srcIdx:imgTagEnd),'.svg'), fitClass = 'image-fit-svg';
        else                                       , fitClass = 'image-fit';     end
        classStrs = {'class="','class ="','class= "','class = "'};
        for classStr = classStrs
            classIdx = strfind(fstrm(imgTags(i):imgTagEnd),classStr{:});
            if ~isempty(classIdx)
                classIdx = classIdx(1) + imgTags(i) - 1;
                if contains(fstrm(imgTags(i):imgTagEnd),'image-fit')
                    break
                end
                fstrm       = [fstrm(1:classIdx-1) classStr{:} fitClass ' ' fstrm(classIdx+length(classStr{:}):end)];
                insertPoint = classIdx-1;
                update_idxs(length(fitClass)+1);
                break
            end
        end
        if isempty(classIdx)
            classToAdd    = ['class="' fitClass '"'];
            if contains(fstrm(imgTags(i):imgTagEnd),'vspace="5" hspace="5"')
                charsToRemove = srcIdx - imgTags(i) - 5;
                fstrm         = [fstrm(1:imgTags(i)+4) classToAdd fstrm(srcIdx:end)];
            else
                charsToRemove = -1;
                fstrm         = [fstrm(1:imgTags(i)+4) classToAdd ' ' fstrm(imgTags(i)+5:end)];
            end
            insertPoint = imgTags(i)+4;
            update_idxs(length(classToAdd)-charsToRemove);
        end
    end
    %% Process undocumented [png2svg] tags
    % WARNING - MATLAB central does not support .svg images, so they have to be hosted externally
    [png2svgOpens, png2svgCloses] = get_tag_pairs('[png2svg]', fstrm, htmlEnd);
    imageFolder = strfind(fstrm(1:htmlEnd),'[imageFolder=');
    if ~isempty(imageFolder)
        imageFolder    = imageFolder(1);
        imageFolderEnd = strfind(fstrm(imageFolder:htmlEnd),']');
        imageFolder    = fstrm(imageFolder+13:imageFolder+imageFolderEnd(1)-2);
    end
    for i = 1:length(png2svgOpens)
        imgTags = strfind(fstrm(png2svgOpens(i):png2svgCloses(i)),'<img ') + png2svgOpens(i) - 1;
        for j = 1:length(imgTags)
            srcIdx    = strfind(fstrm(imgTags(j):png2svgCloses(i)),' src=');
            srcIdx    = srcIdx(1) + imgTags(j) - 1;
            imgTagEnd = strfind(fstrm(srcIdx:png2svgCloses(i)),'>');
            imgTagEnd = imgTagEnd(1) + srcIdx - 1;
            if contains(fstrm(srcIdx:imgTagEnd),'.png" alt="">')
                fstrm = [fstrm(1:srcIdx-1) strrep(fstrm(srcIdx:imgTagEnd),'.png" alt="">','_.svg" alt="">') fstrm(imgTagEnd+1:end)];
                imgTags(j+1:end) = imgTags(j+1:end) + 1;
                imgTagEnd        = imgTagEnd + 1;
                % image-fit -> image-fit-svg
                fstrm = [fstrm(1:imgTags(j)-1) strrep(fstrm(imgTags(j):imgTagEnd),'image-fit','image-fit-svg') fstrm(imgTagEnd+1:end)];
                insertPoint = imgTags(j)-1;
                update_idxs(5);
                png2svgOpens  = png2svgOpens  + 5;
                png2svgCloses = png2svgCloses + 5;
                if ~isempty(imageFolder)
                    fstrm = [fstrm(1:srcIdx+9) imageFolder '/' fstrm(srcIdx+10:end)];
                    insertPoint = srcIdx+9;
                    update_idxs(length(imageFolder)+1);
                    png2svgOpens  = png2svgOpens  + length(imageFolder)+1;
                    png2svgCloses = png2svgCloses + length(imageFolder)+1;
                end
            end
        end
    end
    %% Process undocumented [removepng] tags
    [removepngOpens, removepngCloses] = get_tag_pairs('[removepng]', fstrm, htmlEnd);
    for i = 1:length(removepngOpens)
        imgTags = strfind(fstrm(removepngOpens(i):removepngCloses(i)),'<img ') + removepngOpens(i) - 1;
        for j = 1:length(imgTags)
            srcIdx    = strfind(fstrm(imgTags(j):removepngCloses(i)),' src=');
            srcIdx    = srcIdx(1) + imgTags(j) - 1;
            imgTagEnd = strfind(fstrm(srcIdx:removepngCloses(i)),'>');
            imgTagEnd = imgTagEnd(1) + srcIdx - 1;
            if contains(fstrm(srcIdx:imgTagEnd),'.png" alt="">')
                fstrm(imgTags(j):imgTagEnd) = [];
                imgTagLength = (imgTagEnd+1-imgTags(j));
                insertPoint  = imgTags(j);
                update_idxs(-imgTagLength);
                removepngOpens   = removepngOpens   - imgTagLength;
                removepngCloses  = removepngCloses  - imgTagLength;
            end
        end
    end
    %% Process [darkAlt] tags
    if verbose, fprintf(1,'   darkAlt tags...\n'); end
    IMG_EXTS = {'png','jpg','jpeg','svg'};
    IMG_EXTS = [IMG_EXTS upper(IMG_EXTS)];
    [darkAltOpens, darkAltCloses] = get_tag_pairs('[darkAlt]', fstrm, htmlEnd);
    for i = 1:length(darkAltOpens)
        imgTags = strfind(fstrm(darkAltOpens(i):darkAltCloses(i)),'<img ') + darkAltOpens(i) - 1;
        if ~isempty(imgTags)
            fstrm = [fstrm(1:darkAltOpens(i)-1) ...
                     strrep(fstrm(darkAltOpens(i):darkAltCloses(i)),'image-fit"','image-fit show-if-light"') ...
                     fstrm(darkAltCloses(i)+1:end)];
            fstrm = [fstrm(1:darkAltOpens(i)-1) ...
                     strrep(fstrm(darkAltOpens(i):darkAltCloses(i)),'image-fit-svg','image-fit-svg show-if-light') ...
                     fstrm(darkAltCloses(i)+1:end)];
            insertPoint = darkAltOpens(i)-1;
            update_idxs(14*length(imgTags))
            darkAltOpens(i+1:end)  = darkAltOpens(i+1:end) + 14*length(imgTags);
            darkAltCloses          = darkAltCloses         + 14*length(imgTags);
        end
        imgTags = strfind(fstrm(darkAltOpens(i):darkAltCloses(i)),'<img ') + darkAltOpens(i) - 1;
        for j = 1:length(imgTags)
            srcIdx    = strfind(fstrm(imgTags(j):darkAltCloses(i)),' src=');
            srcIdx    = srcIdx(1) + imgTags(j) - 1;
            imgTagEnd = strfind(fstrm(srcIdx:darkAltCloses(i)),'>');
            imgTagEnd = imgTagEnd(1) + srcIdx - 1;
            duplicate = fstrm(imgTags(j):imgTagEnd);
            for ext = IMG_EXTS
                if contains(fstrm(srcIdx:imgTagEnd),['.' ext{:} '" alt="">'])
                    fstrm = [fstrm(1:imgTagEnd) ...
                             strrep(strrep(duplicate,['.' ext{:} '" alt="">'],['_dark.' ext{:} '" alt="">']),'show-if-light','show-if-dark') ...
                             fstrm(imgTagEnd+1:end)];
                    insertPoint = imgTagEnd;
                    update_idxs(length(duplicate)+4);
                    darkAltOpens(i+1:end)  = darkAltOpens(i+1:end) + length(duplicate)+4;
                    darkAltCloses          = darkAltCloses         + length(duplicate)+4;
                end
            end
        end
    end
    %% Replace [br] with <br>
    if verbose, fprintf(1,'   [br] tags...\n'); end
    fstrm = strrep(fstrm,'[br]','<br>');
    %% Process undocumented [rembr] and [delbr] tags
    rembrTags = strfind(fstrm(sourceStart:htmlEnd),'[rembr]') + sourceStart - 1;
    for i = 1:length(rembrTags)
        brTag = strfind(fstrm(sourceStart:rembrTags(i)),'<br>');
        brTag = brTag(end) + sourceStart - 1;
        if strcmp(sscanf(fstrm(brTag:rembrTags(i)-1),'%s'),'<br>')
            fstrm(brTag:brTag+3) = [];
            rembrTags = rembrTags - 4;
            htmlEnd   = htmlEnd   - 4;
        end
    end
    delbrTags = strfind(fstrm(sourceStart:htmlEnd),'[delbr]') + sourceStart - 1;
    for i = 1:length(delbrTags)
        brTag = strfind(fstrm(delbrTags(i):htmlEnd),'<br>');
        brTag = brTag(1) + delbrTags(i) - 1;
        if strcmp(sscanf(fstrm(delbrTags(i)+7:brTag+3),'%s'),'<br>')
            fstrm(brTag:brTag+3) = [];
            delbrTags = delbrTags - 4;
            htmlEnd   = htmlEnd   - 4;
        end
    end
    if verbose, fprintf(1,'   [delsp] tags...\n'); end
    delspTags = strfind(fstrm(sourceStart:htmlEnd),'[delsp]') + sourceStart - 1;
    for i = 1:length(delspTags)
        if fstrm(delspTags(i)+7) == ' '
            fstrm(delspTags(i)+7) = [];
            delspTags = delspTags - 1;
            htmlEnd   = htmlEnd   - 1;
        end
    end
    %% Insert breaks of specified pixel height ([brx] tags)
    if verbose, fprintf(1,'   [brx] tags...\n'); end
    brxTagList = strfind(fstrm(sourceStart:htmlEnd),'[br') + sourceStart - 1;
    [fstrm, htmlEnd, brxTagList, ~ , ~, brTagEnds] = find_valid_prettify_tags('br', brxTagList, [], [], fstrm, htmlEnd);
    for j = 1:length(brxTagList)
        %[brx] -> <br style="display:block; content:''; margin-top:xpx;">
        fstrm = [fstrm(1:brxTagList(j)-1) '<br style="display:block; content:''''; margin-top:' fstrm(brxTagList(j)+3:brTagEnds(j)-1) ...
                 'px;">' fstrm(brTagEnds(j)+1:end)];
        brxTagList = brxTagList + 50;
        brTagEnds  = brTagEnds  + 50;
        htmlEnd    = htmlEnd    + 50;
    end
    %% Remove excess spacing after codeoutput sections
    codeoutLoc = strfind(fstrm(sourceStart:htmlEnd),'<pre class="codeoutput">') + sourceStart - 1;
    for i = 1:length(codeoutLoc)
        codeoutEnd = strfind(fstrm(codeoutLoc(i):htmlEnd),'</pre>');
        charsDeleted = 0;
        if ~isempty(codeoutEnd)
            codeoutEnd = codeoutEnd(1) + codeoutLoc(i) - 1;
            while fstrm(codeoutEnd-1-charsDeleted)==NL
                fstrm(codeoutEnd-1-charsDeleted)=[];
                charsDeleted = charsDeleted + 1;
            end
        end
        htmlEnd             = htmlEnd             - charsDeleted;
        codeoutLoc(i+1:end) = codeoutLoc(i+1:end) - charsDeleted;
        if strcmp(fstrm(codeoutEnd-charsDeleted+6:codeoutEnd-charsDeleted+21),'</div></details>')
            fstrm = [fstrm(1:codeoutLoc(i)+4) 'style=margin-bottom:0px; ' fstrm(codeoutLoc(i)+5:end)];
            htmlEnd             = htmlEnd             + 25;
            codeoutLoc(i+1:end) = codeoutLoc(i+1:end) + 25;
        end
    end
    %% Remove erroneous <p></p> tags
    pOpens    = strfind(fstrm(sourceStart:htmlEnd),'<p ')  + sourceStart - 1;
    unstyledP = strfind(fstrm(sourceStart:htmlEnd),'<p>') + sourceStart - 1;
    pOpens    = sort([pOpens unstyledP]);
    pCloses   = strfind(fstrm(sourceStart:htmlEnd),'</p>') + sourceStart - 1;
    assert(length(pOpens)==length(pCloses),'ERROR: Imbalanced <p></p> tags detected. There are %i opening tags and %i closing tags',...
                                            length(pOpens),length(pCloses))
    [~, pCloses] = sort_tag_closes(pOpens, pCloses);
    pCloses      = pCloses(ismember(pOpens,unstyledP));
    pOpens       = pOpens (ismember(pOpens,unstyledP));
    for i = 1:length(pOpens)
        if contains(fstrm(pOpens(i):pCloses(i)), {'</p>','</table>','</ol>','</ul>','</pre>','</div>','</img>','</dl>','</h1>','</h2>','</h3>','</h4>', ...
                                                  '</h5>','</h6>'})
            fstrm(pOpens(i):pOpens(i)+2) = [];
            pCloses(pCloses>pOpens(i)) = pCloses(pCloses>pOpens(i)) - 3;
            pOpens (pCloses>pOpens(i)) = pOpens (pCloses>pOpens(i)) - 3;
            fstrm(pCloses(i):pCloses(i)+3) = [];
            pOpens (pCloses>pCloses(i)) = pOpens (pCloses>pCloses(i)) - 4;
            pCloses(pCloses>pCloses(i)) = pCloses(pCloses>pCloses(i)) - 4;
        end
    end
    %% Insert link to FEX page
    % handle defunct [frameBufferx] tag
    frameBufferTag = strfind(fstrm(sourceStart:htmlEnd),'[frameBuffer') + sourceStart - 1;
    if ~isempty(frameBufferTag)
        assert(length(frameBufferTag)==1,'ERROR: only one [frameBufferx] tag is allowed');
        frameBufferTagEnd = strfind(fstrm(frameBufferTag:htmlEnd),']') + frameBufferTag - 1;
        fstrm(frameBufferTag:frameBufferTagEnd) = [];
    end
    frameBuffer = '<p id="iFrameBuf">&nbsp;</p>';
    finalA = strfind(fstrm(sourceStart:htmlEnd),'<a');
    finalA = finalA(end) + sourceStart - 1;
    if strcmp(fstrm(finalA-4:finalA-1),'<br>'), fstrm(finalA-4:finalA-1) = []; end
    finalCloseA = strfind(fstrm(sourceStart:htmlEnd),'</a>');
    finalCloseA = finalCloseA(end) + sourceStart - 1;
    % get version number from opening comments
    fid    = fopen([mfilename('fullpath') '.m'],'r');
    line   = ''; while ~contains(line,'Version'), line = fgetl(fid); end
    verStr = sscanf(line,'%%   Version %s');
    fclose(fid);
    % add link and frame buffer to footer
    fstrm  = [fstrm(1:finalCloseA+3) ' and subsequently processed by ' ...
              '<a class="pretty-link" href="https://www.mathworks.com/matlabcentral/fileexchange/78059-prettify-matlab-html">prettify_MATLAB_html</a>' ...
              ' V' verStr '</p>' frameBuffer fstrm(finalCloseA+12:end)]; % skip over <br></p> in original source
    %% Remove/modify remaining prettify_MATLAB_html tags
    tagsToRemove = {'[rembr]','[delbr]','[delsp]','[png2svg]','[/png2svg]','[removepng]','[/removepng]','[darkAlt]','[/darkAlt]','[imageFolder='};
    for tag = tagsToRemove
        if tag{:}(end)~=']'
            tagStarts = strfind(fstrm,tag{:});
            for tagStart = tagStarts
                tagEnd = strfind(fstrm(tagStart:end),']');
                fstrm(tagStart:tagStart+tagEnd(1)-1)=[];
            end
        else
            fstrm = strrep(fstrm,tag{:},'');
        end
    end
    fstrm = strrep(fstrm,'[ targetn]','[target<i>n</i>]');
    fstrm = strrep(fstrm,'[ jumpton]','[jumpto<i>n</i>]');
    fstrm = strrep(fstrm,'[ scalex]' ,'[scale<i>x</i>]');
    fstrm = strrep(fstrm,'[ class.class-name]' ,'[class.<i>class-name</i>]');
    fstrm = strrep(fstrm,'[ brx]'    ,'[br<i>x</i>]');
    fstrm = strrep(fstrm,'[ bottomMarginx]'    ,'[bottomMargin<i>x</i>]');
    tagsToModify = {'[ br','[ bottomMargin','[ target','[ rembr]','[ delbr]','[ delsp]','[ frameBufferx]'};
    for tag = tagsToModify
        fstrm = strrep(fstrm,tag{:},[tag{:}(1) tag{:}(3:end)]);
    end
    tagsToModify = {'[ dtls]','[ smry]','[ jumpto','[ cssClasses','[ colour','[ scale','[ class','[ themesEnabled]','[ darkAlt]','[ h2]','[ h2.CElink]'};
    for tag = tagsToModify
        fstrm = strrep(fstrm,tag{:},[tag{:}(1) tag{:}(3:end)]);
        fstrm = strrep(fstrm,[tag{:}(1:2) '/' tag{:}(3:end)],[tag{:}(1) '/' tag{:}(3:end)]);
    end
    %% Final bit of javascript
    fstrm = strrep(fstrm,'</body>',['<script>' NL ...
                                    'var allDetails   = document.getElementsByTagName(''details'');' NL ...
                                    'var contentDiv   = document.getElementsByClassName("content"); contentDiv = contentDiv[0];' NL ...
                                    'var returnButton = document.getElementById("return-link");' NL ...
                                    'document.getElementById("iFrameBuf").style.display = "none";' NL ...
                                    'if(in_iFrame())' NL ...
                                    '{' NL ...
                                    '   try{' NL ...
                                    '      var footerNav = parent.document.getElementsByClassName("footernav");' NL ...
                                    '      var tabPane   = parent.document.getElementsByClassName("tab-pane");}' NL ...
                                    '   catch(err) { var footerNav = []; var tabPane = [];};' NL ...
                                    '   if(!(footerNav.length) || tabPane.length)' NL ... we are embedded in a frame that's not a MATLAB help browser frame
                                    '   {' NL ...
                                    '      contentDiv.style.overflowY = "scroll";'   NL ...
                                    '      contentDiv.style.overflowX = "hidden";'   NL ...
                                    '      contentDiv.style.position  = "absolute";' NL ...
                                    '      contentDiv.style.width     = "95%";'      NL ...
                                    '      contentDiv.style.top       = 0;'          NL ...
                                    '      contentDiv.style.bottom    = 0;'          NL ...
                                    '      if (tabPane.length){' NL ...
                                    '         contentDiv.setAttribute("data-isMATLABCentral","1");' NL ...
                                    '         returnButton.style.right = "40px";' NL ...
                                    '         document.getElementById("tooltiptext").style.right = "92px"; }' NL ...
                                    '      document.getElementById("iFrameBuf").style.display = "block";' NL ...
                                    '   }' NL ...
                                    '   else { contentDiv.setAttribute("data-isHelpBrowser","1"); }' NL ...
                                    '}' NL ...
                                    'if (!contentDiv.getAttribute("data-isHelpBrowser") && !contentDiv.getAttribute("data-isMATLABCentral") ){' NL ...
                                    '   document.getElementById("anchor-offsets").sheet.disabled = true; }' NL ...
                                    'var jumpLinks = document.getElementsByTagName("a");' NL ...
                                    'for (var i = 0; i < jumpLinks.length; i++){' NL ...
                                    '  href = jumpLinks[i].getAttribute("href");' NL ...
                                    '  if (href && href[0] == "#") { jumpLinks[i].onclick = jump_to;}}' NL ...
                                    '</script></body>']);
    %% Write the output file
    if verbose, fprintf(1,'Writing output file...\n'); end
    write_fstrm_to_file(fstrm, inputhtmlFile);
    if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), 'processing complete.html', 1); end
    if verbose, fprintf(1,'Processing complete.\n'); end
    show_warning_dialogue;
    catch MEx
        show_warning_dialogue;
        throwError = false;
        if ~isempty(MEx.identifier)
            fprintf(2,'\nPLEASE REPORT BUGS TO: <a href="mailto:harry.dymond@bristol.ac.uk">harry.dymond@bristol.ac.uk</a>\n\n');
            errorMsg = ['Error!' NL 'Please see MATLAB command line for more information'];
            throwError = true;
        else
            errorMsg = MEx.message;
        end
        callStack = dbstack;
        if length(callStack)>1 && strcmp(callStack(2).file,'publish.m')
            uiwait(msgbox(errorMsg,'','error','modal'));
        else
            fprintf(2,errorMsg);
        end
        if throwError
            fprintf(2,'Error in %s on <a href="matlab:opentoline(''%s'', %i)">line %i</a>:\n', ...
                      MEx.stack(1).name, MEx.stack(1).file, MEx.stack(1).line, MEx.stack(1).line)
            throw(MEx)
        end
    end
    %% Subroutines
    function update_idxs(insertionLength)
        %%     Index updater
        detailsOpens ( detailsOpens  > insertPoint ) = detailsOpens ( detailsOpens  > insertPoint ) + insertionLength;
        detailsCloses( detailsCloses > insertPoint ) = detailsCloses( detailsCloses > insertPoint ) + insertionLength;
        summaryCloses( summaryCloses > insertPoint ) = summaryCloses( summaryCloses > insertPoint ) + insertionLength;
        imgTags      ( imgTags       > insertPoint ) = imgTags      ( imgTags       > insertPoint ) + insertionLength;

        htmlEnd = htmlEnd + insertionLength;
    end

    function show_warning_dialogue
        %%     Show warning dialogue if warnings were generated
        callStack = dbstack;
        if length(callStack)>1 && ismember('publish.m',{callStack.file}) && ~isempty(show_warning([]))
            uiwait(msgbox([num2str(show_warning([])) ' warnings generated' NL 'Please see MATLAB command line for more information'],'','warn','modal'));
        end
    end
end

%% ==========================================================================================================================================================
%% Helper functions
%%     Tag processing
function [fstrm, classNames, userCSS] = process_cssClasses_tags(fstrm, getClassNamesOnly)
    if nargin<2, getClassNamesOnly = false; end
    if getClassNamesOnly,     htmlEnd  = length(fstrm);
    else                , [~, htmlEnd] = find_source(fstrm); end
    [cssOpens, cssCloses] = get_tag_pairs('[cssClasses]', fstrm, htmlEnd);
    userCSS = '';
    if isempty(cssOpens), classNames = {}; return, end
    if length(cssOpens)>1
        throwAsCaller(MException('prettify:too many cssClass blocks','There should only be one pair of [cssClasses][/cssClasses] tags in your source file'))
    end
    openBraces   = strfind(fstrm(cssOpens:cssCloses),'{') + cssOpens - 1;
    closeBraces  = strfind(fstrm(cssOpens:cssCloses),'}') + cssOpens - 1;
    classNames{length(openBraces)} = '';
    fileIdx      = cssOpens + 12;
    for classCounter = 1:length(openBraces)
        % check first char after [cssClass]
        % [/cssClass]
        warnMsg        = '';
        WARN_MSG_START = ['css class ' num2str(classCounter) ' is malformed: '];
        while fileIdx<cssCloses && char(fstrm(fileIdx))~='.'
            fileIdx = fileIdx + 1;
        end
        if fstrm(fileIdx) ~= '.'
            warnMsg = [WARN_MSG_START 'css class declarations should start with a dot'];
        else
            if isempty(warnMsg) && openBraces(classCounter)>closeBraces(classCounter)
                warnMsg = [WARN_MSG_START 'opening ''{'' found after closing ''}'''];
            end
            classNames{classCounter} = sscanf(char(fstrm(fileIdx:openBraces(classCounter)-1)),'.%s');
            if any( cellfun( @(x)isequal(x,classNames{classCounter}), classNames( 1:length(classNames)~=classCounter ) )  )
                warnMsg = [WARN_MSG_START classNames{classCounter} ' has already been declared'];
                classNames{classCounter} = '';
            end
        end
        if ~isempty(warnMsg)
            show_warning(warnMsg)
        elseif ~getClassNamesOnly
            userCSS = [userCSS '.' classNames{classCounter} ' ' fstrm(openBraces(classCounter):closeBraces(classCounter)) NL]; %#ok<AGROW>
        end
        fileIdx = closeBraces(classCounter) + 1;
        if ~isempty(warnMsg), openBraces(classCounter) = 0; end
    end
    classNames(openBraces==0)=[];
    if getClassNamesOnly
        clear userCSS;
    else
        fstrm(cssOpens:cssCloses+12) = [];
    end
end

function [sourceStart, sourceEnd] = find_source(fstrm)
    sourceStart = strfind(fstrm,'</head>');
    sourceStart = sourceStart(1);
    sourceEnd   = strfind(fstrm,'##### SOURCE BEGIN #####');
    try
        assert(~isempty(sourceEnd),'ERROR: Format of MATLAB-generated html file has changed.');
    catch MEx
        throwAsCaller(MEx);
    end
    sourceEnd = sourceEnd(1);
end

function [fstrm, htmlEnd] = process_target_and_jump_tags(fstrm, htmlEnd)
    targetTagList  = strfind(fstrm(1:htmlEnd),'[target');
    [fstrm, htmlEnd, targetTagList, ~ , targetIDList, targetTagEnds] = find_valid_prettify_tags('target', targetTagList, [], [], fstrm, htmlEnd);
    for j = 1:length(targetTagList)
        % [targetn] -> <a id="targetn"></a>
        fstrm = [fstrm(1:targetTagList(j)-1) '<a id="' fstrm(targetTagList(j)+1:targetTagEnds(j)-1) '"></a>' fstrm(targetTagEnds(j)+1:end)];
        targetTagList = targetTagList + 11;
        targetTagEnds = targetTagEnds + 11;
        htmlEnd       = htmlEnd + 11;
    end

    [jumpOpens, jumpCloses] = get_tag_pairs('[jumpto]', fstrm, htmlEnd);
    [fstrm,htmlEnd,jumpOpens,jumpCloses,jumpIDList,jumpTagEnds] = find_valid_prettify_tags('jumpto', jumpOpens, jumpCloses, targetIDList, fstrm, htmlEnd);
    for j = 1:length(jumpOpens)
        % [jumpton] -> <a href="#targetn">
        fstrm = [fstrm(1:jumpOpens(j)-1) '<a href="#target' num2str(jumpIDList(j)) '">' fstrm(jumpTagEnds(j)+1:end)];
        jumpCloses  = jumpCloses  + 10;
        % [/jumpto] -> "</a>"
        fstrm = [fstrm(1:jumpCloses(j)-1) '</a>' fstrm(jumpCloses(j)+9:end)];
        jumpCloses  = jumpCloses  - 5;
        jumpOpens   = jumpOpens   + 5;
        jumpTagEnds = jumpTagEnds + 5;
        htmlEnd     = htmlEnd     + 5;
    end
end

function [fstrm, htmlEnd, tagList, tagCloseList, valList, tagEnds] = find_valid_prettify_tags(type, tagList, tagCloseList, validValList, fstrm, htmlEnd)
    if isempty(tagList), valList = []; tagEnds = []; return, end
    switch type
        case {'target','jumpto'}, sscanfFormat = ['[' type '%i'];  generic = 'n'; valDescriptor = 'target identifier'; valType = 'integer'; long = 3;
        case 'br'               , sscanfFormat = ['[' type '%g'];  generic = 'x'; valDescriptor = 'padding';           valType = 'number';  long = 3;
        case 'scale'            , sscanfFormat = ['[' type '%g'];  generic = 'x'; valDescriptor = 'scaling';           valType = 'positive number'; long = 5;
        case 'colour'           , sscanfFormat = ['[' type '%s'];  generic = '#'; valDescriptor = 'colour code';       valType = 'str';     long = 6;
        case 'class'            , sscanfFormat = ['[' type '.%s']; generic = '' ; valDescriptor = 'class name';        valType = 'str';     long = 100;
        case 'bottomMargin'     , sscanfFormat = ['[' type '%g'];  generic = 'x'; valDescriptor = 'margin';            valType = 'number';  long = 6;
    end
    WARN_MSG_START = ['[' type '] tag %i is malformed: '];
    if strcmp(valType, 'str'), valList{length(tagList)} = '';
    else                     , valList(length(tagList)) = NaN;  end
    tagEnds{length(tagList)} = [];
    for i = 1:length(tagList)
        warningMsg = '';
        tagEnds{i} = strfind(fstrm(tagList(i):htmlEnd),']');
        if isempty(tagEnds{i}), error(['ERROR: ' sprintf(WARN_MSG_START,i) 'there is no closing bracket.']); end
        tagEnds{i} = tagEnds{i}(1) + tagList(i) - 1;
        if (tagEnds{i}-tagList(i)-1-length(type))>long
            show_warning(['The ' valDescriptor ' for ' type generic ' tag ' num2str(i) ' is more than '...
                          num2str(long) ' characters long. Possible malformed tag?']);
        end
        val = sscanf(fstrm(tagList(i):tagEnds{i}-1),sscanfFormat);
        if strcmp(valType, 'str') && isempty(val)
            warningMsg = sprintf([WARN_MSG_START '%c should be a valid %s.'], i, generic, valDescriptor);
        elseif ~strcmp(valType, 'str') && ( isempty(val) || (contains(valType,'positive') && val<=0) )
            warningMsg = sprintf([WARN_MSG_START '%c should be a %s.'], i, generic, valType);
        else
            switch type
                case 'target' , if any(valList == val)
                    warningMsg = sprintf([WARN_MSG_START '%i has already been used as a target.'], i, val); end
                case 'jumpto' , if ~any(validValList == val) %#ok<ALIGN>
                    warningMsg = sprintf([WARN_MSG_START '%i has not been specified as a jump target (no [target%i] tag in source).'],...
                                         i, val, val); end
                case 'colour'
                    valid = true;
                    if length(val)~=6                , valid = false; end
                    if valid, try hex2dec(val); catch, valid = false; end, end
                    if ~valid, warningMsg = sprintf([WARN_MSG_START val ' is not a valid colour code.']); end
                case 'class', if ~any(cellfun(@(x)isequal(x,val),validValList))
                    warningMsg = sprintf([WARN_MSG_START '%s has not been defined as a CSS class.'], i, val); end
            end
        end
        if ~isempty(warningMsg)
            show_warning(warningMsg);
        elseif ischar(val)
            valList{i} = val;
        else
            valList(i) = val;
        end
    end
    tagEnds = cell2mat(tagEnds);
    if strcmp(valType, 'str'), invalidIdxs = find(cellfun(@isempty,valList));
    else                     , invalidIdxs = find(isnan(valList));                end
    for i = invalidIdxs
        fstrm(tagList(i):tagEnds(i)) = [];
        noOfCharsDeleted = (tagEnds(i)-tagList(i)+1);
        tagList(i+1:end) = tagList(i+1:end) - noOfCharsDeleted;
        tagEnds(i+1:end) = tagEnds(i+1:end) - noOfCharsDeleted;
        htmlEnd          = htmlEnd - noOfCharsDeleted;
        if ismember(type,{'jumpto','scale','colour','class'})
            noOfCharsToRemove = 3 + length(type);
            tagCloseList(i:end)   = tagCloseList(i:end) - noOfCharsDeleted;
            fstrm(tagCloseList(i):tagCloseList(i)+2+length(type)) = [];
            tagCloseList(i)       = 0;
            tagCloseList(i+1:end) = tagCloseList(i+1:end) - noOfCharsToRemove;
            tagList     (i+1:end) = tagList     (i+1:end) - noOfCharsToRemove;
            tagEnds     (i+1:end) = tagEnds     (i+1:end) - noOfCharsToRemove;
            htmlEnd               = htmlEnd - noOfCharsToRemove;
        end
        tagList(i) = 0;
    end
    valList(tagList==0)=[];
    tagEnds(tagList==0)=[];
    tagList(tagList==0)=[];
    tagCloseList(tagCloseList==0)=[];
end

function [fstrm, htmlEnd] = prettyTag2htmlTag(type, tagOpens, tagCloses, vals, tagEnds, fstrm, sourceStart, htmlEnd, DEBUG)
    switch type
        case 'scale' , kind = 'style'; get_val = @(x, idx)sprintf('font-size: %.3g%%;',x(idx)*100);
        case 'colour', kind = 'style'; get_val = @(x, idx)['color: #' x{idx} ';'];
        case 'class' , kind = 'class'; get_val = @(x, idx)x{idx};
    end
    if strcmp(type,'class'), [countOfTags, tagCloses] = sort_tag_closes(tagOpens, tagCloses);
    else                   , countOfTags = length(tagOpens);                                  end

    for i = 1:countOfTags
        % <p>[/type]</p> -> [/type]
        if strcmp(fstrm(tagCloses(i)-3:tagCloses(i)-1),'<p>') ...
        && strcmp(fstrm(tagCloses(i)+length(type)+3:tagCloses(i)+length(type)+6),'</p>')
            fstrm([tagCloses(i)-3:tagCloses(i)-1 tagCloses(i)+length(type)+3:tagCloses(i)+length(type)+6]) = [];
            update_idxs(tagCloses(i), -7);
            tagCloses(i) = tagCloses(i)-3;
        end
    end

    % Deal with [type] ... [/type] tags enclosing non-compatible html tags such as <p></p>, <table></table>, <ul></ul>, etc.:
    % [type] ... [/type] fully encloses non-enclosable section:
    % [type] ... <nonEnclosable>...</nonEnclosable> ... [/type] -> [type] ... [/type]<nonEnclosable kind="">...</nonEnclosable>[type] ... [/type] (note kind
    % added to <nonEnclosable>)
    %
    % [type] ... [/type] encloses opening non-enclosable tag only:
    % [type] ... <nonEnclosable>... [/type] ... </nonEnclosable>  -> [type] ... [/type]<nonEnclosable>[type] ... [/type] ...</nonEnclosable>  (note kind NOT
    % added to <nonEnclosable>)
    %
    % [type] ... [/type] encloses closing non-enclosable tag only:
    % <nonEnclosable> ... [type] ... </nonEnclosable> ... [/type] -> <nonEnclosable>...[type] ... [/type]</nonEnclosable>[type]... [/type]  (note kind NOT
    % added to <nonEnclosable>)
    %
    % nested [type] tags -> what might happen?
    %   1o                            2o                               2c     1c
    % [type] ... <nonEnclosable>... [type] ... </nonEnclosable> ... [/type][/type] type pair 1 processed gives ->
    %   1o       1c (new)                              3o (shift)                  2o (new)  3c (shift) 2c (shift)
    % [type] ... [/type]<nonEnclosable kind="kind1">... [type] ... </nonEnclosable>[type] ... [/type][/type] type pair 2 processed gives no change, type
    % pair 3 processed gives ->
    %   1o          1c                                    3o       3c (new)             4o (new)  2o      4c (shift) 2c
    % [type] ... [/type]<nonEnclosable kind="kind1">... [type] ... [/type]</nonEnclosable>[type][type] ... [/type][/type] ->

    changesMade = true;
    while changesMade
        changesMade = false;
        i = 1;
        while i<=length(tagOpens)
            for nonEnclosableTag = {'<p>','<table>','<ol>','<ul>','<pre>','<div>','<img>','<dl>','<h1>','<h2>','<h3>','<h4>','<h5>','<h6>'}
                nonEnclosableTagAlt    = [nonEnclosableTag{:}(1:end-1) ' '];
                nonEnclosableTagCloser = [nonEnclosableTag{:}(1) '/' nonEnclosableTag{:}(2:end)];
                if contains(fstrm(tagOpens(i):tagCloses(i)), nonEnclosableTag{:}) ...
                || contains(fstrm(tagOpens(i):tagCloses(i)), nonEnclosableTagAlt) ...
                || contains(fstrm(tagOpens(i):tagCloses(i)), nonEnclosableTagCloser)
                    nonEnclosableTagOpens  = strfind(fstrm(tagOpens(i):tagCloses(i)), nonEnclosableTag{:}) + tagOpens(i) - 1;
                    nonEnclosableTagOpens  = sort( [ nonEnclosableTagOpens strfind(fstrm(tagOpens(i):tagCloses(i)), nonEnclosableTagAlt)+tagOpens(i)-1 ] );
                    nonEnclosableTagCloses = strfind(fstrm(tagOpens(i):tagCloses(i)), nonEnclosableTagCloser) + tagOpens(i) - 1;
                    addKindToTag = false;
                    if ~isempty(nonEnclosableTagOpens) && ~isempty(nonEnclosableTagCloses) && nonEnclosableTagOpens(1)<nonEnclosableTagCloses(end)
                        if ~strcmp(nonEnclosableTag{:},'<img>'), addKindToTag = true; end
                        newTagCloseInsertPos = nonEnclosableTagOpens(1)-1;
                        newTagOpenInsertPos  = nonEnclosableTagCloses(end)+length(nonEnclosableTagCloser) + length(type)+2;
                    elseif ~isempty(nonEnclosableTagOpens)
                        newTagCloseInsertPos = nonEnclosableTagOpens(1)-1;
                        newTagOpenInsertPos  = strfind(fstrm(nonEnclosableTagOpens(1):tagCloses(i)),'>') + nonEnclosableTagOpens(1) - 1;
                        newTagOpenInsertPos  = newTagOpenInsertPos(1) + length(type)+3;
                    else
                        newTagCloseInsertPos = nonEnclosableTagCloses(end)-1;
                        newTagOpenInsertPos  = nonEnclosableTagCloses(end)+length(nonEnclosableTagCloser) + length(type)+2;
                    end
                    if addKindToTag
                        tagClose = strfind(fstrm(nonEnclosableTagOpens(1):tagCloses(i)),'>');
                        tagClose = tagClose(1) + nonEnclosableTagOpens(1) - 1;
                        [insertStr, insertIdx] = add_to_html_tag(kind, get_val(vals,i), fstrm, nonEnclosableTag{:}(2:end-1),...
                                                                 nonEnclosableTagOpens(1), tagClose);
                        fstrm = [fstrm(1:insertIdx-1) insertStr fstrm(insertIdx:end)];
                        update_idxs(insertIdx, length(insertStr));
                        newTagOpenInsertPos = newTagOpenInsertPos + length(insertStr);
                    end
                    % insert new [/type] tag
                    fstrm = [fstrm(1:newTagCloseInsertPos) '[/' type ']' fstrm(newTagCloseInsertPos+1:end)];
                    update_idxs(newTagCloseInsertPos+1, length(type)+3);
                    % insert new [type] tag
                    tagLength = 1+tagEnds(i)-tagOpens(i);
                    fstrm = [fstrm(1:newTagOpenInsertPos) fstrm(tagOpens(i):tagEnds(i)) fstrm(newTagOpenInsertPos+1:end)];
                    tagOpens  = [tagOpens(1:i)    newTagOpenInsertPos+1         tagOpens(i+1:end)];
                    tagEnds   = [tagEnds(1:i)     newTagOpenInsertPos+tagLength tagEnds(i+1:end) ];
                    tagCloses = [tagCloses(1:i-1) newTagCloseInsertPos+1        tagCloses(i:end) ];
                    update_idxs(newTagOpenInsertPos, tagLength);
                    tagOpens(i+1) = newTagOpenInsertPos+1;
                    tagEnds(i+1)  = newTagOpenInsertPos+tagLength;
                    vals = [vals(1:i) vals(i) vals(i+1:end)];
                    changesMade = true;
                    break;
                end
            end
            i = i + 1;
        end
    end
    if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), ['after processing [' type '] tags enclosing html tags.html'], 1); end
    % delete consecutive [type][/type] tags
    i = 1;
    while i <= length(tagOpens)
        if tagEnds(i)+1==tagCloses(i)
            fstrm(tagOpens(i):tagCloses(i)+length(type)+2) = [];
            update_idxs(tagCloses(i), -(tagCloses(i)+length(type)+3-tagOpens(i)));
            tagOpens(i)  = [];
            tagCloses(i) = [];
            tagEnds(i)   = [];
            vals(i)      = [];
        else
            i = i + 1;
        end
    end
    if DEBUG, write_fstrm_to_file(fstrm(sourceStart:htmlEnd), ['after removing consecutive [' type '][' type 'close] tags.html'], 1); end

    for i = 1:length(tagOpens)
        if strcmp(type,'class') && ismember(get_val(vals,i),{'codeinput','codeoutput','error'}), htmlTag = 'pre';
        else                                                                                   , htmlTag = 'span'; end
        spanOpen = strfind(fstrm(1:tagOpens(i)),['<' htmlTag ' ']); % could be "pre" rather than "span", but haven't changed variable names
        if ~isempty(spanOpen)
            spanOpen  = spanOpen(end);
            spanClose = strfind(fstrm(spanOpen:tagOpens(i)),'>');
            if ~isempty(spanClose), spanClose = spanClose(1) +spanOpen-1; end
            if ~strcmp(sscanf(fstrm(spanClose:tagOpens(i)),'%s'),'>[')
                spanOpen = [];
            end
        end % '</span>'
        if ( ~isempty(spanOpen) || strcmp(fstrm(tagEnds(i)+1:tagEnds(i)+length(htmlTag)+2),['<' htmlTag ' ']) ) ...
        && (   strcmp(fstrm(tagCloses(i)-(length(htmlTag)+3):tagCloses(i)-1),['</' htmlTag '>'])                           ...
            || strcmp(fstrm(tagCloses(i)+length(type)+3:tagCloses(i)+length(type)+3+length(htmlTag)+2),['</' htmlTag '>'])    )
            % [typex]<span kind="blah> -> <span kind="x blah (or "pre" rather than "span")
            % or <span kind="blah>[typex] -> <span kind="x blah
            if isempty(spanOpen)
                spanOpen  = tagEnds(i)+1;
                spanClose = strfind(fstrm(tagEnds(i):tagCloses(i)),'>');
                spanClose = spanClose(1) + tagEnds(i) - 1;
            end
            [insertStr, insertIdx] = add_to_html_tag(kind, get_val(vals,i), fstrm, htmlTag, spanOpen, spanClose);
            % remove </span> or </pre> (will be replaced later)
            if strcmp(fstrm(tagCloses(i)-(length(htmlTag)+3):tagCloses(i)-1),['</' htmlTag '>'])
                fstrm(tagCloses(i)-(length(htmlTag)+3):tagCloses(i)-1)=[];
                tagCloses(tagCloses>tagCloses(i)-1) = tagCloses(tagCloses>tagCloses(i)-1) - (length(htmlTag)+3);
            else
                fstrm(tagCloses(i)+length(type)+3:tagCloses(i)+length(type)+3+length(htmlTag)+2)=[];
                tagCloses(tagCloses>tagCloses(i)) = tagCloses(tagCloses>tagCloses(i)) - (length(htmlTag)+3);
            end
            tagEnds (tagEnds >tagCloses(i)) = tagEnds (tagEnds >tagCloses(i)) - (length(htmlTag)+3);
            tagOpens(tagOpens>tagCloses(i)) = tagOpens(tagOpens>tagCloses(i)) - (length(htmlTag)+3);
        else
            % [type] -> <span kind="x"> or <pre kind="x">
            insertStr = ['<' htmlTag ' ' kind '="' get_val(vals,i) '">'];
            insertIdx = tagEnds(i)+1;
        end
        fstrm = [fstrm(1:insertIdx-1) insertStr fstrm(insertIdx:end)];
        if insertIdx<tagOpens(i), fstrm(tagOpens(i)+length(insertStr):tagEnds(i)+length(insertStr)) = [];
        else                    , fstrm(tagOpens(i):tagEnds(i)) = []; end
        noOfCharsToRemove = 1+tagEnds(i)-tagOpens(i);
        charIncrease      = length(insertStr) - noOfCharsToRemove;
        update_idxs(insertIdx-1, charIncrease);
        % [/"type"] -> </span> or </pre>
        closeTagLength = length(type)+3;
        insertPoint    = tagCloses(i)-1;
        fstrm = [fstrm(1:insertPoint) ['</' htmlTag '>'] fstrm(insertPoint+1+closeTagLength:end)];
        update_idxs(tagCloses(i), (length(htmlTag)+3) - closeTagLength)
    end

    function update_idxs(insertPoint, idxAdj)
        tagEnds  (tagOpens >insertPoint) = tagEnds  (tagOpens >insertPoint) + idxAdj;
        tagCloses(tagCloses>insertPoint) = tagCloses(tagCloses>insertPoint) + idxAdj;
        tagOpens (tagOpens >insertPoint) = tagOpens (tagOpens >insertPoint) + idxAdj;
        htmlEnd = htmlEnd + idxAdj;
    end
end

function [insertStr, insertIdx] = add_to_html_tag(kind, val, fstrm, htmlTag, tagOpen, tagClose)
% kind:     String defining the kind of attribute to be added to the htmlTag, e.g. 'style' or 'class'
% val :     The value of the attribute e.g. 'margin-bottom:10px'
% fstrm:    The html file in memory
% htmlTag:  String defining the html tag that the style or class will be applied to, and should not include the "<" or ">". e.g., if adding a style to a
%           table, htmlTag would be set to 'table'
% tagOpen:  Position of opening of tag in fstrm
% tagClose: Position of closing of tag (i.e., the tag's ">" character
    for lookForStr = {[kind '="'],[kind ' ="'],[kind '= "'],[kind ' = "']}
        lookForIdx = strfind(fstrm(tagOpen:tagClose),lookForStr{:});
        if ~isempty(lookForIdx)
            lookForIdx = lookForIdx(1) + tagOpen - 1;
            insertStr  = [val ' '];
            insertIdx  = lookForIdx+length(lookForStr{:});
            break;
        end
    end
    if isempty(lookForIdx)
        insertStr = [' ' kind '="' val '"'];
        insertIdx = tagOpen+length(htmlTag)+1;
    end
end

function [tagOpens, tagCloses] = get_tag_pairs(tag, fstrm, htmlEnd)
    closeTag  = ['[/' tag(2:end)];
    if ismember(tag,{'[jumpto]','[scale]','[colour]','[class]'}), openTag = tag(1:end-1);
    else                                                        , openTag = tag;         end
    tagOpens  = strfind(fstrm(1:htmlEnd),openTag);
    tagCloses = strfind(fstrm(1:htmlEnd),closeTag);
    try
        assert( length(tagOpens)==length(tagCloses), 'ERROR: Number of %s tags (%i) does not match number of %s tags (%i)', ...
                                                             tag, length(tagOpens), closeTag, length(tagCloses));
        if ~ismember(tag,{'[class]','[dtls]'}), check_tag_pairs(tagOpens, tagCloses, tag); end
    catch MEx
        throwAsCaller(MEx)
    end
end

function check_tag_pairs(tagOpens, tagCloses, type)
    if isempty(tagOpens), return, end
    try
        closeBeforeOpenError = 'ERROR: %s close tag %i appears before open tag %i';
        for i = 1:length(tagOpens)-1
            assert(tagOpens(i)<tagCloses(i),closeBeforeOpenError,type,i,i);
            assert(tagCloses(i)<tagOpens(i+1),'ERROR: %s open tag %i appears before close tag %i',type,i+1,i);
        end
        if isempty(i), i = 1; end
        assert(tagOpens(i)<tagCloses(i),closeBeforeOpenError,type,i,i);
    catch MEx
        throwAsCaller(MEx)
    end
end

function [countOfTags, tagCloses] = sort_tag_closes(tagOpens, tagCloses)
    countOfTags       = length(tagOpens);
    tagClosesUnsorted = tagCloses;
    tagCloses(:) = 0;
    for i = 1:countOfTags
        tagCloseIdx = 1;
        while i+tagCloseIdx<=countOfTags && tagClosesUnsorted(tagCloseIdx)>tagOpens(i+tagCloseIdx), tagCloseIdx = tagCloseIdx+1; end
        tagCloses(i) = tagClosesUnsorted(tagCloseIdx);
        tagClosesUnsorted(tagCloseIdx) = [];
    end
    assert(~any(tagCloses==0),'prettifyMATLABhtml:internalError','Failed to sort nested tags');
end

%%     Get path of this .m file
function myPath = my_path()
%
%   NOTE: path returned includes trailing file separator
%
    myName = mfilename();
    myPath = mfilename('fullpath');
    myPath = myPath(1:end-length(myName));
end

%%     Save handle to built-in Publish function
function save_publish_handle
    publishName = which('publish');
    if ~strcmp(publishName(end-1:end),'.p')
        error(['ERROR: You must run this before MATLAB''s "publish" function has been overloaded.'...
               ' In other words, the custom "publish" function must not be on the MATLAB path when you run save_publish_handle.']);
    else
        setappdata(0,'real_publish',@publish);
    end
end

%%     Warning functions
function warningsIssued = show_warning(msg)
    persistent warnCounter
    if islogical(msg), warnCounter = []; return; end
    if isempty(msg), warningsIssued = warnCounter; return, end
    if isempty(warnCounter)
        fprintf(1, wrap_text(sprintf('\n%s: prettify_MATLAB_html [\\bWARNING%cmessages:]\\b\n', datestr(now),char(160)),'')); warnCounter = 0;
    end
    warnCounter = warnCounter + 1;
    fprintf(1,'\n%i. [\b%s]\b\n', warnCounter, wrap_text(msg,'   '));
end

function wrappedText = wrap_text(str, lineStart)
    commandWindowSize = get(0, 'CommandWindowSize');
    numCols           = commandWindowSize(1)-2-length(lineStart);

    if length(str)<= numCols, wrappedText = str; return; end
    lines = strsplit(str,'\n');
    lineCounter = 1;
    while lineCounter<=length(lines)
        if length(lines{lineCounter}) > numCols
            lastChar = 1;
            spaces   = strfind(lines{lineCounter},' ');
            insertNewLine = spaces(find(spaces<=numCols,1,'last'));
            if isempty(insertNewLine)
                insertNewLine = numCols;
                lastChar      = 0;
            end
            lines = [lines(1:lineCounter) {lines{lineCounter}(insertNewLine+1:end)} lines(lineCounter+1:end)];
            lines{lineCounter} = lines{lineCounter}(1:insertNewLine-lastChar);
        end
        lineCounter = lineCounter + 1;
    end
    wrappedText = strjoin(lines,[NL lineStart]);
end

%%     Toolbar button functions
function insert_target(document)
    targetTagList = strfind(document.Text,'[target');
    [~, ~, ~, ~, targetIDList, ~] = find_valid_prettify_tags('target', targetTagList, [], [], document.Text, length(document.Text));
    if ~isempty(targetIDList), targetID = max(targetIDList)+1;
    else                     , targetID = 1; end
    document.insertTextAtPositionInLine(['[target' num2str(targetID) ']'], document.Selection(1), document.Selection(2))
end

function insert_table(document)
    if document.Selection(2)>1, document.goToPositionInLine(document.Selection(1)+1,1); end
    HTML_TABLE_TEMPLATE = ['%' NL ...
                           '% <html>' NL ...
                           '% <table class="MATLAB-Help">' NL ...
                           '% <thead><tr>' NL ...
                           '%    <th>COLUMN1 HEADING</th>' NL ...
                           '%    <th>COLUMN2 HEADING</th>' NL ...
                           '% </tr></thead>' NL ...
                           '%    <tr><td>CELL1</td><td>CELL2</td></tr>' NL ...
                           '%    <tr><td>CELL3</td><td>CELL4</td></tr>' NL ...
                           '% </table>' NL ...
                           '% </html>' NL ...
                           '%' NL];
    document.insertTextAtPositionInLine(HTML_TABLE_TEMPLATE, document.Selection(1), document.Selection(2))
end

function jumpton_wrap(document)
    targetTagList = strfind(document.Text,'[target');
    [~, ~, ~, ~, targetIDList, ~] = find_valid_prettify_tags('target', targetTagList, [], [], document.Text, length(document.Text));
    targetIDList(targetIDList==0) = [];
    targetID = 0;
    if ~isempty(targetIDList)
        if length(targetIDList) > 1
            targetIDList = sort(targetIDList);
            targetList   = arrayfun(@num2str,targetIDList,'UniformOutput',false);
            [indx, tf]   = listdlg('PromptString','Select target ID','ListString',targetList,'SelectionMode','single');
            if tf, targetID = targetIDList(indx); end
        else
            targetID = targetIDList;
        end
    end
    wrap_text_in_tag(document, '[jumpto', targetID);
end

function class_wrap(document)
    [~, classNames] = process_cssClasses_tags(document.Text, true);
    if contains(document.Text,'[themesEnabled]'), classNames = [classNames {'show-if-light', 'show-if-dark'}]; end
    className = 'CLASS-NAME';
    if ~isempty(classNames)
        if length(classNames) > 1
            [indx, tf]   = listdlg('PromptString','Select class name','ListString',classNames,'SelectionMode','single');
            if tf, className = classNames(indx);
            else , return, end
        else
            className = classNames{1};
        end
    end
    if iscell(className), className = className{1}; end
    wrap_text_in_tag(document, '[class', ['.' className]);
end

function colour_wrap(document)
    c = uisetcolor;
    if c==0, return;
    else   , c = round(255*c); c = [upper(dec2hex(c(1),2)) upper(dec2hex(c(2),2)) upper(dec2hex(c(3),2))]; end
    wrap_text_in_tag(document, '[colour', c);
end

function wrap_text_in_tag(document, openTag, n)
    WHITE_SPACE  = char([9:13 32 133 160]);
    PUNCTUATION  = '(),.;:';
    if strcmp(openTag,'[cssClasses]') && contains(document.Text, openTag)
        uiwait(msgbox(['A cssClasses block already exists' NL 'Source files should have only one cssClasses block'],'','help','modal')); return, end
    selectedText = document.SelectedText;
    closeTag = [openTag(1) '/' openTag(2:end)];
    if nargin==3
        if ~ischar(n)
            if n == 0, n = 'n';
            else     , n = num2str(n); end
        end
        openTag = [openTag n ']'];
        closeTag(end+1) = ']';
    end
    % convert the selection from Lines/Columns to index
    selectionPosition = document.Selection;
    startPos          = matlab.desktop.editor.positionInLineToIndex(document, selectionPosition(1), selectionPosition(2));
    endPos            = matlab.desktop.editor.positionInLineToIndex(document, selectionPosition(3), selectionPosition(4));

    if ~isempty(selectedText)
        while startPos>1
            if ~ismember(document.Text(startPos-1),[WHITE_SPACE PUNCTUATION ']']), startPos = startPos-1;
            else                                                                 , break,                 end
        end
        while endPos<=(length(document.Text)-1)
            if ~ismember(document.Text(endPos),[WHITE_SPACE PUNCTUATION '[']), endPos = endPos+1;
            else                                                             , break,             end
        end
        if ismember(document.Text(startPos),{'*','_','<','|','$'}), openTag(end+1)  = ' ';     end
        if ismember(document.Text(endPos-1),{'*','_','>','|','$'}), closeTag = [' ' closeTag]; end
    end
    wrappedText   = [openTag document.Text(startPos:endPos-1) closeTag];
    document.Text = [document.Text(1:startPos-1) wrappedText document.Text(endPos:end)];
    % Re-select
    [selectionPosition(1), selectionPosition(2)] = matlab.desktop.editor.indexToPositionInLine(document, startPos+length(openTag));
    [selectionPosition(3), selectionPosition(4)] = matlab.desktop.editor.indexToPositionInLine(document, endPos  +length(openTag));
    document.Selection = selectionPosition;
end

function add_pretty_commands_to_toolbar
    PRETTY_CATEGORY = 'PRETTIFY';
    COMMAND_LIST    = {'dtls','smry','targetn','jumpton','cssClasses','class','scale','colour','html table'};
    COMMAND_START   = 'prettify_MATLAB_html([],[],[],';
    COMMAND_FUNC    = {[COMMAND_START '''[dtls]'')'],[COMMAND_START '''[smry]'')'],[COMMAND_START '''target'')'],[COMMAND_START '''jumpto'')'],...
                       [COMMAND_START '''[cssClasses]'')'],[COMMAND_START '''class'')'],[COMMAND_START '''scale'')'],[COMMAND_START '''colour'')'],...
                       [COMMAND_START '''table'')']};
    fprintf(1,'\n');
    foundFlag(length(COMMAND_LIST)) = false;
    if verLessThan('matlab','9.4')
        % add shortcuts
        scUtils   = com.mathworks.mlwidgets.shortcuts.ShortcutUtils;
        scVector  = scUtils.getShortcutsByCategory(PRETTY_CATEGORY);
        scArray   = scVector.toArray;  % Java array
        for scIdx = 1:length(scArray)
           scName = char(scArray(scIdx));
           [alreadyExists, idx] = ismember(scName, COMMAND_LIST);
           if alreadyExists, foundFlag(idx) = true; end
        end
        i = 1:length(COMMAND_LIST);
        for i = i(~foundFlag)
            scUtils.addShortcutToBottom(COMMAND_LIST{i},COMMAND_FUNC{i},['Lower Case ' COMMAND_LIST{i}(1)], PRETTY_CATEGORY, 'true');
        end
        if isempty(i), fprintf(1,'[\bAll shortcuts already exist]\b\n');
        else         , fprintf(1,'[\bShortcuts created]\b\n'); end
        MSG_END = ' - please add the shortcuts to the Quick-Access Toolbar manually]\b\n';
        QA_XML  = [prefdir filesep 'MATLABQuickAccess.xml'];
        if ~exist(QA_XML,'file')
            fprintf(1,['[\bCouldn''t find the Quick Access xml file' MSG_END]);
        elseif exist([QA_XML '.bak'],'file') ...
            || (   ~exist([QA_XML '.bak'],'file') ...
                && copyfile(QA_XML, [QA_XML '.bak']) )
            fstrm        = read_file_to_mem(QA_XML);
            configStart  = strfind(fstrm,'<quick_access_configuration>');
            if length(configStart)~=1, fprintf(1,['[\bUnexpected Quick Access xml file format' MSG_END]); return, end
            linesToAdd = '';
            for command = COMMAND_LIST
                if ~contains(char(fstrm), command{:})
                linesToAdd = [linesToAdd '   <tool display_condition="always" label_visible="true" section_id="PRETTIFY" tab_id="shortcuts" tool_id="' ...
                              command{:} '" toolset_id="matlab_shortcut_toolset"/>' NL]; %#ok<AGROW>
                end
            end
            if isempty(linesToAdd)
                fprintf('[\bAll shortcuts already in Quick-Access Toolbar]\b\n');
            else
                fstrm = [fstrm(1:configStart+28) linesToAdd fstrm(configStart+29:end)];
                write_fstrm_to_file(fstrm, QA_XML);
                fprintf(1,'[\bPlease restart MATLAB to get the Prettify MATLAB html shortcuts in the Quick-Access Toolbar]\b\n');
            end
        end
    else
        % add favourites
        FAV_XML = [prefdir filesep 'FavoriteCommands.xml'];
        if ~exist(FAV_XML,'file')
            fprintf(1,'[\bCouldn''t find Favourites xml file; may result in duplicate Favourites]\b\n');
        else
            fstrm = read_file_to_mem(FAV_XML);
            for i = 1:length(COMMAND_LIST), if contains(char(fstrm), COMMAND_LIST{i}), foundFlag(i) = true; end, end
        end
        if all(foundFlag)
            fprintf(1,'[\bAll Toolbar buttons already exist]\b\n');
        else
            fc = com.mathworks.mlwidgets.favoritecommands.FavoriteCommands.getInstance();
            i = 1:length(COMMAND_LIST);
            for i = i(~foundFlag)
                % thanks to Martin Lechner at https://uk.mathworks.com/matlabcentral/answers/411846-how-to-create-favorites-by-code-command-window
                % for this code!
                command = com.mathworks.mlwidgets.favoritecommands.FavoriteCommandProperties();
                command.setCategoryLabel(PRETTY_CATEGORY);
                command.setLabel(COMMAND_LIST{i});
                command.setCode(COMMAND_FUNC{i});
                command.setIsOnQuickToolBar(true);
                command.setIsShowingLabelOnToolBar(true);
                command.setIconName(['favorite_command_' COMMAND_LIST{i}(1)]);
                fc.addCommand(command);
            end
            fprintf(1,'[\bToolbar buttons created]\b\n');
        end
    end
    fprintf(1,'\n');
end

%%     File read & write
function fstrm = read_file_to_mem(fileName)
    try
        fileH = fopen(fileName,'r');
        fstrm = fread(fileH, 'uchar')';
    catch MEx
        fclose(fileH);
        throwAsCaller(MException('prettify:fileread', sprintf('ERROR: Unable to read file %s: %s', fileName, MEx.message) ));
    end
    fclose(fileH);
end

function write_fstrm_to_file(fstrm, fileName, isDebug)
    persistent debugCount
    if     nargin<3, isDebug = false;
    elseif   isempty(isDebug), debugCount = []; return, end
    if isDebug
        if isempty(debugCount), debugCount = 0; end
        debugCount = debugCount + 1;
        fileName = ['debug ' sprintf('%03i',debugCount) '. - ' fileName];
    end
    if length(fileName)>=5 && strcmp(fileName(end-4:end),'.html')
        % Insert some line breaks to make source html a bit more readable
        if isDebug
            % have to be careful as this could change how the html renders, so be conservative when doing this for non-debug output
            fstrm = strrep(fstrm,'><',['>' NL '<']);
        else
            [sourceStart, htmlEnd] = find_source(fstrm);
            fstrm = strrep(fstrm,'><details',['>' NL '<details']);
            fstrm = strrep(fstrm,'</div></details>',[NL '</div>' NL '</details>']);
            fstrm = strrep(fstrm,'><div',['>' NL '<div']);
            fstrm = strrep(fstrm,'</li><li>',['</li>' NL '<li>']);
            fstrm = strrep(fstrm,'><p',['>' NL '<p']);
            preLocs = strfind(fstrm(sourceStart:htmlEnd),'<pre') + sourceStart - 1;
            if isempty(preLocs)
                fstrm = strrep(fstrm,'<br',[NL '<br']);
            else
                preCloseLocs = strfind(fstrm(sourceStart:htmlEnd),'</pre>') + sourceStart - 1;
                [countOfPreTags, preCloseLocs] = sort_tag_closes(preLocs, preCloseLocs);
                preLocs        = [2 preLocs];
                preCloseLocs   = [1 preCloseLocs];
                countOfPreTags = countOfPreTags + 1;
                for i = 2:countOfPreTags
                    if preLocs(i)>max(preCloseLocs(1:i-1))
                        lengthBefore = length(fstrm);
                        fstrm = [fstrm(1:max(preCloseLocs(1:i-1))) ...
                                 strrep(fstrm(max(preCloseLocs(1:i-1))+1:preLocs(i)),'<br',[NL '<br']) fstrm(preLocs(i)+1:end)];
                        charsAdded = length(fstrm) - lengthBefore;
                        preLocs     ( preLocs      > max(preCloseLocs(1:i-1)) ) = preLocs     ( preLocs      > max(preCloseLocs(1:i-1))) + charsAdded;
                        preCloseLocs( preCloseLocs > max(preCloseLocs(1:i-1)) ) = preCloseLocs( preCloseLocs > max(preCloseLocs(1:i-1))) + charsAdded;
                    end
                end
                fstrm = [fstrm(1:max(preCloseLocs)) ...
                         strrep(fstrm(max(preCloseLocs)+1:htmlEnd),'<br',[NL '<br']) fstrm(htmlEnd+1:end)];
            end
        end
    end
    try
        fileH = fopen(fileName,'w');
        fwrite(fileH, fstrm, 'char*1');
    catch MEx
        fclose(fileH);
        throwAsCaller(MException('prettify:filewrite', sprintf('ERROR: Unable to write file %s: %s',fileName, MEx.message) ));
    end
    fclose(fileH);
end

%%     New line constant
function CONST = NL, CONST = char(10); end %#ok<CHARTEN> for backwards compatibility

%% ==========================================================================================================================================================
%
%% Version history:
%
%   1.0     -- Original release
%   1.1     -- Improved method of closing <details> sections
%           -- Better handling of consecutive [/dtls][dtls] tags
%   1.2     -- Minor change to warning shown if a targetn, jumpton, or brx tag seems a bit long
%           -- Documentation tweaks
%           -- Minor code tidying; mainly adding sections
%   2.0     -- Added support functions for adding shortcuts to Quick-Access Toolbar, that then allow easy adding of tags to source .m file
%           -- Fixed bug that occurred when removing malformed [targetn] and [jumpton] tags
%   2.1     -- Improved method of adding Toolbar buttons
%   3.0     -- Added support for new tags: [cssClasses], [class.class-name], [scalex], [colour#], [themesEnabled], and [darkAlt]
%           -- Added dark theme
%           -- Improved handling of Toolbar buttons
%           -- Other minor code cleanups and bug fixes
%   3.1     -- Added workaround for MATLAB central miscalculating page height
%   3.2     -- Improved method of assigning classes and styles
%   3.3     -- Fixed bug with "collapse/expand all on page" link when page has no sections
%   3.4     -- Added support for nesting of css classes e.g. [class.a][class.b]this item will be formatted according to css classes a and b[/class][/class]
%           -- Increased robustness of enclosing inline html in [dtls] sections
%   3.5     -- Improved enclosing of inline html into [dtls] sections (again)
%           -- Improved handling of nested [colour#], [scalex], [class.class-name] tags
%   3.6     -- Fixed bug when multiple images appear inside [dtls] sections
%           -- Added Toolbar button to insert an html-table template
%   3.7     -- Added "built-in" MATLAB publish CSS classes codeinput, codeoutput, error, keyword, comment, string, untermstring, and syscmd, as valid class
%              names when using the [class.class-name] tag, although these won't appear in the list presented when using the "class" Toolbar button
%           -- Handles some incorrect syntax more gracefully
%   3.7.1   -- Minor code tidy
%   3.8     -- Fixed bug with "collapse/expand all" controls for pages with 10 or more sections
%   3.9     -- Added [frameBufferx] tag
%   3.10    -- Fixed bug associated with [frameBufferx] tag
%   3.11    -- Better handling of malformed syntax
%   3.12    -- Improved error handling
%   3.13    -- Added [imageFolder=x] tag (undocumented companion to undocumented [png2svg] tag)
%   3.14    -- Fixed bug that occured when any [dtls] sections were placed before MATLAB's auto-generated page contents list
%   4.0     -- Enables nesting of [dtls] boxes
%           -- [dtls] boxes are now rounded on all four corners when closed
%           -- Improved syntax checking for [/dtls] tags
%           -- Uses new method to save theme preference for better compatibility with the MATLAB web browser
%           -- [bottomMarginx] tags are now documented
%           -- [bottomMarginx] now processed after [dtls] and [smry] tags
%           -- Processes [class.codeinput], [class.codeoutput], and [class.error] correctly by using html <pre> elements instead of <span>
%           -- Added undocumented [removepng] tags
%   4.1     -- Improved syntax checking for [dtls] tags
%           -- Improved handling of html in [dtls] boxes (also fixes potential bug when nesting [dtls] boxes)
%   4.2     -- Fixed issue with collapse-all/expand-all links in help browser of recent versions of MATLAB
%           -- Improved spacing after generated code output and lists that appear at the end of [dtls] boxes
%   4.3     -- No longer creates extra space after monospaced text (e.g. |text| ) that is wrapped in [class], [scale], or [colour] tags
%           -- Added the [delsp] tag
%   4.4     -- Now includes version number of prettify_MATLAB_html in the footer link
%   4.5     -- In-page links now jump to correct location if page is viewed on Matlab Central (e.g. in the "Examples" tab) or the MATLAB help browser (the
%              former, and some versions of the latter, put a floating banner across the top of the page that must be accounted for when jumping)
%           -- If viewed on MATLAB Central, pages now have a scroll bar, so the [framebufferx] tag is no longer required
%           -- Makes in-page links work for most browsers, if the page is viewed in the "Examples" tab on MATLAB Central
%   5.0     -- Bug fix - improved spacing after numbered lists that appear at the end of [dtls] boxes now works
%           -- Improved spacing if a [dtls] box is the last element on the page
%           -- Adds a "return" floating button/link when user follows an in-page link (but not if page is viewed in MATLAB help browser)
%           -- Documented a method for adding headings with collapse/expand links without adding the heading to the page's contents list
%   5.1     -- Improved floating back button functionality when page is viewed on MATLAB Central
%           -- More robust positioning of collapse/expand links
%   6.0     -- Fixed html 5 compliance issues, some due to the built-in publish, and some due to prettify
%           -- Added [h2] and [h2.CElink] tags to create headings that are not added to the page's contents list
%           -- Enhanced functionality of floating "return" link - arrow direction now updates as user scrolls up/down past the return target
%   6.1     -- Fixed bug when processing <style></style> tags in embedded html
%   6.2     -- Fixed bug when processing nested [class.<class name>] tags
%   6.3     -- Now allows negative values for the [brx] tag
%   6.4     -- Fixed bug that could occur when using [h2.CElink] tags in conjunction with nested [dtls] sections.
%   6.4.1   -- Fixed bug that could occur when <tt> tags are replaced by <code> tags (HTML5 validation fix)
%   6.5     -- 15 May 2021
%           -- Details boxes now open automatically if they are closed and the user clicks an internal page link that links to the box
%
%============================================================================================================================================================

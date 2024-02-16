%% Test example for prettify_MATLAB_html
% here is an example of prettify_MATLAB_html usage
% - process m-files with MATLAB publish command
% - process resulting html files with prettify_MATLAB_html
% 
%%
% Key examples:
%
% * Shift:  [class.kbd]&#8679; Shift[/class]  / <span class="kbd">&#8679; Shift</span>
% * Button:  [class.kbd]Button[/class]  / <span class="kbd">Button</span>
% * LMB (html only): <span class="kbd"><img style="height: 1em" src="images\LMB_click.svg"> left mouse click</span>
% * RMB (html only): <span class="kbd"><img style="height: 1em" src="images\RMB_click.svg"> right mouse click</span>
% * left arrow:  [class.kbd] &#8592; [/class] /  <span class="kbd">&#8592; </span>
% * right arrow:  [class.kbd] &#8594; [/class] / <span class="kbd">&#8594; </span>
% * up arrow [class.kbd] >&#8593; [/class] / <span class="kbd">&#8593; up</span>
% * down arrow [class.kbd] &#8595; [/class] / <span class="kbd">&#8595; down</span>
% * Ctrl:  [class.kbd]^ Ctrl[/class]   /   <span class="kbd">^ Ctrl</span>
% * Checkbox: [class.kbd][&#10003;] *Bio*[/class]  / <span class="kbd">[&#10003;] <b>Bio</b></span>
% * Dropdown: [class.dropdown]dropdown &#9660;[/class]  / <span class="dropdown">Dropdown &#9660;</span>
% * Editbox: [class.dropdown]editbox...[/class] / <span class="dropdown">editbox...</span>
% * Radio: [class.kbd]&#9673; *Radio*[/class]  / <span class="kbd">&#9673; <b>Radio</b></span>
%
%% Custom elements to use in the source .m file
%
% [dtls][smry] *Markup "tags"* [/smry]
% Most |prettify_MATLAB_html| features require the use of additional markup "tags" in the original source |.m| file, for example to indicate where you want
% the disclosure boxes. You can click on the tag names in the table below to jump to examples of what these tags do and how to use them. If you [jumpto5]add 
% the helper buttons to the Toolbar[/jumpto], you can insert the *[ dtls]*, *[ smry]*, *[ targetn]*, *[ jumpton]*, *[ cssClasses]*, *[ class.class-name]*,
% *[ scalex]*, and *[ colour#]* tags <#15 using those buttons>.[br]
%
% <html>
% <table class="MATLAB-Help">
% <thead><tr>
%    <th style="width:26ch; text-align: center;">Tag(s)</th>
%    <th>Purpose</th>
% </tr></thead>
%    <tr><td style="text-align: center;"><b>[ br]</b></td><td>Place anywhere to introduce an HTML line break.</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#5">[ br<i>x</i>]</a></b></td><td>Insert a line break with specified pixel height <b><i>x</i></b>;
%                                                                     useful for creating spacing between lines where any empty line is too large a gap, or a
%                                                                     large gap is required.
%                                                                     </td></tr>
%    <tr><td style="text-align: center;"><b><a href="#target11">[ bottomMargin<i>x</i>]</a></b></td><td>Specify the size of the bottom margin of the current
%                                                                     paragraph, in pixels <b><i>x</i></b>;
%                                                                     useful for controlling spacing between text and inserted elements such as lists,
%                                                                     images, embedded html, etc.
%                                                                     </td></tr>
%    <tr><td style="text-align: center;"><b><a href="#target12">[ delsp]</a></b></td><td>Control spacing when using <code>publish</code> text markup 
%                                                                     <code>*</code>...<code>*</code> (<b>bold</b>), _..._ (<i>italic</i>), or 
%                                                                     <code>|</code>...<code>|</code> (<code>monospaced</code>). In order to function 
%                                                                     correctly, text that you markup with <code>*</code>, _, or <code>|</code> must often
%                                                                     be preceded by a space, but this can sometimes cause word-spacing issues. To solve this
%                                                                     problem, the <b>[ delsp]</b> tag deletes a space character immediately following this 
%                                                                     tag.</td></tr>   
%    <tr><td style="text-align: center;"><b><a href="#6">[ dtls] ... [ /dtls]</a></b></td>
%        <td>Wrapped around a block of text will create a normally-open disclosure box around that text. These tags must be accompanied by a set of 
%            <b>[ smry]</b> ... <b>[ /smry]</b> tags (see below).</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#6">[ smry] ... [ /smry]</a></b></td>
%        <td>These wrap around text inside a <b>[ dtls] ... [ /dtls]</b> block. The text wrapped in the <b>[ smry]</b> ... <b>[ /smry]</b> block is
%            always displayed, regardless of the state of the disclosure arrow. The opening <b>[ smry]</b> tag must immediately follow the opening 
%            <b>[ dtls]</b> tag.</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#9">[ h2] ... [ /h2]</a><br><a href="#9">[ h2.CElink] ... [ /h2]</a></b></td>
%        <td>Used to create a second-level heading. This is the heading style used by <code>publish</code> for section headings, so these tags enable you to
%            insert headings without starting a new section. If the heading is inserted above [ dtls] boxes, you can choose whether or not the heading
%            includes a collapse/expand link. The <b>[ h2] ... [ /h2]</b> tags create a heading with no link, whilst headings created with 
%            <b>[ h2.CElink] ... [ /h2]</b> tags include a link.</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#10">[ target<i>n</i>]</a></b></td>
%        <td>Where <b><i>n</i></b> is any integer, e.g. <b>[ target1]</b>, <b>[ target14]</b>. Used to insert a link target for in-page linking. A link to
%            the target is created using the <b>[ jumpto<i>n</i>] ... [ /jumpto]</b> tags (see below). Note that no closing tag is required.</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#10">[ jumpto<i>n</i>] ... [ /jumpto]</a></b></td>
%        <td>These wrap around any text that you wish to serve as an in-page link to a target that you have specified with a <b>[ target<i>n</i>]</b> tag.
%        </td></tr>
%    <tr><td style="text-align: center;"><b><a href="#11">[ cssClasses] ... [ /cssClasses]</a></b></td>
%        <td>These wrap around text where you define CSS classes that you wish to apply to other parts of the page using the
%        <b>[ class.<i>class-name</i>] ... [ /class]</b> tags (see below).</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#11">[ class.<i>class-name</i>] ... [ /class]</a></b></td>
%        <td>These wrap around text to which you wish to apply one of your CSS classes that are defined in the  <b>[ cssClasses] ... [ /cssClasses]</b>
%        block.</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#12">[ scale<i>x</i>] ... [ /scale]</a></b></td>
%        <td>Where <i><b>x</b></i> is any positive number, e.g. <b>[ scale0.5]</b>, <b>[ scale1.2]</b>. These wrap around text to which you would like to
%        apply the specified scaling factor.</td></tr>
%    <tr><td style="text-align: center;"><a href="#13"><b>[ colour<i>#</i>] ... [ /colour]</b></a></td>
%        <td>Where <i><b>#</b></i> is a six-digit hexadecimal number specifying the desired colour in RGB, e.g. <b>[ colourFF5614]</b>. These wrap around
%        text to which you would like to apply the specified colour.</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#14">[ themesEnabled]</a></b></td>
%        <td>Place this tag anywhere in your <code>.m</code> file to enable switching between <i>light</i> and <i>dark</i> themes. When enabled, a clickable
%        link is provided at the top-right of the page to allow the user to select a theme (see top of this page for example).</td></tr>
%    <tr><td style="text-align: center;"><b><a href="#14">[ darkAlt] ... [ /darkAlt]</a></b></td>
%        <td>Wrap these around any block that contains one or more images (including images that are auto-generated by code), where you wish to provide an 
%        alternative image in the case where the user selects the <i>dark</i> theme.</td></tr>
% </table>
% <div class="info">
% Info block! Requires .info and .info:before styles!
% </div>
% </html>
%
% [/dtls]
%
%
%
% [h2.CElink]Heading text[/h2]
%
% [dtls][smry] *Disclosure box after heading*[/smry]
% [class.codeoutput]
% [br]function data = preprocessTrainingData(data, imageSize)[/class]
% [class.comment]     % Resize the training image and associated pixel label image.[/class]
% [class.codeoutput]  data{1} = imresize(data{1},imageSize);
% [br]  data{2} = imresize(data{2},imageSize); [/class]
%
% [class.syscmd]
% data{1} = repmat(data{1},1,1,3);
% [br]end
% [/class]
% [/dtls]
%
% [dtls][smry] *List* [/smry]
% test2[br]
% test3[br]
% [/dtls]
%
% [class.h3]h3-tag Sub-header[/class]
%
%% Preprocessing of files
%
%
% [cssClasses]
% .dropdown { 
%   font-family: monospace;
% 	border: 1px solid #aaa; 
% 	border-radius: 0.2em; 
% 	background-color: #fff; 
% 	background-color: #e0f5ff; 
% 	background-color: #e8f5e8; 
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
% .info {
%  position: relative;
%  left: 40px;
%  width: 600px;
%  padding: 1em 1em 1em 4em;
%  margin: 2em 0;
%  color: #555;
%  background: #e7f2fa;
%  border-left: 4px solid #93cfeb;
% }
% .info:before {
%  content: url(images\\info.png);
%  position: absolute;
%  top: 10px;
%  left: 10px;
% }
% [/cssClasses]
%%
% <html>
% <script>
%   var allDetails = document.getElementsByTagName('details');
%   toggle_details(0);
% </script>
% </html>
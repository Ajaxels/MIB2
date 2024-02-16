% generate html help files
path =  which('publish_html_im_browser');
path = fileparts(path);
cd(path);

list_of_files = dir(fullfile('*.m'));
wb = waitbar(0,'Generating HTML...');
for i=1:numel(list_of_files)
    waitbar(i/numel(list_of_files),wb);
    fprintf('%d Processing: %s...', i, list_of_files(i).name);
    if strcmp(list_of_files(i).name,'publish_html_im_browser.m'); fprintf('skipped!\n'); continue; end
    if strcmp(list_of_files(i).name,'prettify_MATLAB_html.m'); fprintf('skipped!\n'); continue; end
    if strcmp(list_of_files(i).name,'prettify_demo.m'); fprintf('skipped!\n'); continue; end
    if strcmp(list_of_files(i).name,'im_browser_release_notes_doxygen_beta.m'); fprintf('skipped!\n'); continue; end  % this file is for doxegen documentation
    if strcmp(list_of_files(i).name,'im_browser_release_notes_doxygen.m'); fprintf('skipped!\n'); continue; end  % this file is for doxegen documentation
    if strcmp(list_of_files(i).name,'MatlabDocMaker.m'); fprintf('skipped!\n'); continue; end
    publish(list_of_files(i).name, 'html'); 
    %[~, fnOnly] = fileparts(list_of_files(i).name);
    %prettify_MATLAB_html(fullfile('html', [fnOnly '.html']), false);
    fprintf('done!\n');
end
db_path = [path '\html'];
builddocsearchdb(db_path);
delete(wb);
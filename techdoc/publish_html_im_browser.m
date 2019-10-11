% generate html help files
path =  which('publish_html_im_browser');
path = fileparts(path);
cd(path);

list_of_files = dir(fullfile('*.m'));
wb = waitbar(0,'Generating HTML...');
for i=1:numel(list_of_files)
    waitbar(i/numel(list_of_files),wb);
    if strcmp(list_of_files(i).name,'publish_html_im_browser.m'); continue; end
    if strcmp(list_of_files(i).name,'im_browser_release_notes_doxygen_beta.m'); continue; end  % this file is for doxegen documentation
    if strcmp(list_of_files(i).name,'im_browser_release_notes_doxygen.m'); continue; end  % this file is for doxegen documentation
    if strcmp(list_of_files(i).name,'MatlabDocMaker.m'); continue; end
    publish(list_of_files(i).name, 'html');
end
db_path = [path '\html'];
builddocsearchdb(db_path);
delete(wb);
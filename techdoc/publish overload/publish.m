function output = publish(varargin)
%
%   Use this function to overload MATLAB's publish function,
%   to automatically run generated html files through
%   prettify_MATLAB_html.
%
%   <a href="matlab:disp(getappdata(0,'publishHelp'))">Click here</a> to see help of built-in publish function.
%
    real_publish = getappdata(0,'real_publish');
    if isempty(real_publish), prettify_MATLAB_html([],[],true); real_publish = getappdata(0,'real_publish'); end
    if isempty(real_publish), error('Unable to find MATLAB''s publish function'); end
    output = real_publish(varargin{:});
    if length(output)>=5 && strcmp(output(end-4:end),'.html')
        prettify_MATLAB_html(output, false);
    end
    if nargout==0, clear output, end
end
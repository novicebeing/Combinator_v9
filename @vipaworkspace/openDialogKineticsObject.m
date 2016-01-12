function openDialogKineticsObject(this)
    [filename,filepath] = uigetfile( ...
    {  '*.mat','Kinetics Object Files (*.mat)'; ...
       '*.*',  'All Files (*.*)'}, ...
       'Pick a file', ...
       'MultiSelect', 'on');

    % Check to see if there is only one file
    if ischar(filename)
        filename = {filename};
    end
    
    % Iterate over files and import them one by one
    for i = 1:numel(filename)
        % Load in the data file
        [fname,~,ext] = fileparts(filename{i});
        if strcmp(ext,'.mat')
            h = kineticsobject(fullfile(filepath,filename{i}));
            h.name
            this.SpectraList.addItem(h,0,0,strrep(h.name,' ','_'));
        else
            error('Unsupported file type');
        end 
    end
end
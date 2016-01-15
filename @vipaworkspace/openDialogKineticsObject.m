function openDialogKineticsObject(this)
    [filename,filepath] = uigetfile( ...
    {  '*.mat','Kinetics Object Files (*.mat)'; ...
       '*.*',  'All Files (*.*)'}, ...
       'Pick a file', ...
       'MultiSelect', 'on');

    if filepath == 0
        return
    end
   
    % Check to see if there is only one file
    if ischar(filename)
        filename = {filename};
    end
    
    % Iterate over files and import them one by one
    hwait = waitbar(0,'Loading Files...', 'WindowStyle', 'modal');
    for i = 1:numel(filename)
        % Load in the data file
        [~,fname,ext] = fileparts(filename{i});
        if strcmp(ext,'.mat')
            h = spectraobjects.spectraobject(fullfile(filepath,filename{i}));
            this.SpectraList.addItem(h,0,0,strrep(fname,' ','_'));
        else
            error('Unsupported file type');
        end 
        waitbar(i/numel(filename),hwait);
    end
    close(hwait);
end
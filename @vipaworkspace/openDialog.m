function openDialog(this)
    [filename,filepath] = uigetfile( ...
        {  '*.mat','MAT-files (*.mat)'; ...
           '*.*',  'All Files (*.*)'}, ...
           'Pick a file', ...
           'MultiSelect', 'on');

    % Check to see if there is only one file
    if ischar(filename)
        filename = {filename};
    end
       
    % Iterate over files and import them one by one
    hwait = waitbar(0,'Loading Files...', 'WindowStyle', 'modal');
    for i = 1:numel(filename)
        % Load in the data file
        [~,~,ext] = fileparts(filename{i});
        if strcmp(ext,'.mat')
            data = load(fullfile(filepath,filename{i}),'-mat');
        else
            error('Unsupported file type');
        end
        
        % Import the variables
        fields = fieldnames(data);
        for j = 1:numel(fields)
            switch class(data.(fields{j}))
                case 'kineticsobject'
                    h = data.(fields{j});
                    if isempty(h.name)
                        this.SpectraList.addItem(h,0,0,fields{j});
                    else
                        this.SpectraList.addItem(h,0,0,strrep(h.name,' ','_'));
                    end
                case 'spectraobjects.spectraobject'
                    h = data.(fields{j});
                    if isempty(h.name)
                        this.SpectraList.addItem(h,0,0,fields{j});
                    else
                        this.SpectraList.addItem(h,0,0,strrep(h.name,' ','_'));
                    end
                case 'fitspectraobjects.linelist'
                    h = data.(fields{j});
                    if isempty(h.name)
                        this.FitSpectraList.addItem(h,0,0,fields{j});
                    else
                        this.FitSpectraList.addItem(h,0,0,strrep(h.name,' ','_'));
                    end
                case 'kineticsfitobject'
                    h = data.(fields{j});
                    if isempty(h.name)
                        this.FitsList.addItem(h,0,0,fields{j});
                    else
                        this.FitsList.addItem(h,0,0,strrep(h.name,' ','_'));
                    end
                case 'imagesobjects.imagesobject'
                    h = data.(fields{j});
                    if isempty(h.name)
                        this.ImagesList.addItem(h,0,0,fields{j});
                    else
                        this.ImagesList.addItem(h,0,0,strrep(h.name,' ','_'));
                    end
            end
        end
        waitbar(i/numel(filename),hwait);
    end
    close(hwait);
end
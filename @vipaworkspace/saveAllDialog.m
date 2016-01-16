function saveAllDialog(this)
    [filename,filepath] = uiputfile( ...
        {  '*.mat','MAT-files (*.mat)'; ...
           '*.*',  'All Files (*.*)'}, ...
           'Pick a file');

    if filepath == 0
        return
    end
       
    [~,fname,ext] = fileparts(filename);
    
    this.ImagesList.saveToFile(1:numel(this.ImagesList.Plants),fullfile(filepath,sprintf('%s_images%s',fname,ext)));
    this.CalibrationList.saveToFile(1:numel(this.ImagesList.Plants),fullfile(filepath,sprintf('%s_calibration%s',fname,ext)));
    this.SpectraList.saveToFile(1:numel(this.ImagesList.Plants),fullfile(filepath,sprintf('%s_spectra%s',fname,ext)));
    this.FitSpectraList.saveToFile(1:numel(this.ImagesList.Plants),fullfile(filepath,sprintf('%s_fitspectra%s',fname,ext)));
    this.FitsList.saveToFile(1:numel(this.ImagesList.Plants),fullfile(filepath,sprintf('%s_fits%s',fname,ext)));
end
function saveToFile(this, plantids)
    % Get the spectra objects
    if isempty(plantids)
        return
    end
    if isnumeric(plantids)
        idx = plantids;
    else
        idx = [];
        for i = 1:length(plantids)
            idx = [idx;find(strcmp(this.PlantNames, plantids{i}))]; %#ok<AGROW>
        end
    end
    plants = this.Plants(idx);
    dupids = [];
    
    % Make the save structure
    plantsSave = cell2struct(this.Plants(idx),this.PlantNames(idx));
    
    % Select a file
    [file,path] = uiputfile('*.mat','Save Spectra As...');

    % Save the file
    save(fullfile(path,file),'-struct','plantsSave');
end
function h = createCalibration(this, plantids)
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

    % Create Calibration
    h = calibrationobjects.vipacalibration();
    
    h.fringeImage = plants{1}.images(:,:,1);
end
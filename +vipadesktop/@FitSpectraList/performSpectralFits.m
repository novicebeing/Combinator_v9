function hfig = performSpectralFits(this, plantids)
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

    % Open the plot browsers
    for i = 1:length(plants)
        plants{i}.loadDOCOtemplates();
        hfig = plants{i}.performDOCOfit();
    end
end
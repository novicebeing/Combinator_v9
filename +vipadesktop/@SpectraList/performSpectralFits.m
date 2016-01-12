function fitobj = performSpectralFits(this, plantids, fitspectra, fitoptions)
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
        fitobj = vipadesktop.linearSpectrumFit(plants{i},fitspectra,fitoptions);
    end
end
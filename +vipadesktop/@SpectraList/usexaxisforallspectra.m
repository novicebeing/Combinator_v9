function hfig = usexaxisforallspectra(this, plantids)
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

    % Get the x axis
    wavenum = plants{1}.wavenum;
    
    % Open the plot browsers
    for i = 1:length(this.Plants)
        pp = this.Plants{i};
        pp.wavenum = wavenum;
    end
end
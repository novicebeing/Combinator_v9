function hfig = averageImages(this, plantids,images,time,refImagesBoolean)
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

    % Open the plot browsers
    for i = 1:length(plants)
        plants{i}.averageImages(images,time,refImagesBoolean);
    end
end
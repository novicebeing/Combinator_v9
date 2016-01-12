function h = averageImages(this, plantids)
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

    h = imagesobjects.imagesobject();
    h.time = 0;
    % Open the plot browsers
    %for i = 1:length(plants)
        h.images = nanmean(double(plants{1}.images),3);
    %end
end
function [wavenum,spectra,spectraTime] = createSpectra(this, plantids,images,time,refImageBoolean)
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
    %for i = 1:length(plants)
        [wavenum,spectra,spectraTime] = plants{1}.createSpectra(images,time,refImageBoolean);
    %end
end
function hfig = runfitanalysisfunction(this, plantids,fitanalysisfunction)    
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
    plantnames = this.PlantNames(idx);
    dupids = [];

    x = zeros(1,numel(plants));
    y = zeros(1,numel(plants));
    ODmean = zeros(1,numel(plants));
    DOCOmean = zeros(1,numel(plants));
    O3 = zeros(1,numel(plants));
    CO = zeros(1,numel(plants));
    D2 = zeros(1,numel(plants));
    % Run the fit analysis function
    for i = 1:length(plants)
        [x(i),y(i),ODmean(i),DOCOmean(i),O3(i),CO(i),D2(i)] = fitanalysisfunction(plantnames{i},plants{i});
        
    end
    
    assignin('base','x',x);
    assignin('base','y',y);
    assignin('base','ODmean',ODmean);
    assignin('base','DOCOmean',DOCOmean);
    assignin('base','O3',O3);
    assignin('base','CO',CO);
    assignin('base','D2',D2);
    
    figure(10);scatter(x,y);
end
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

%     x = zeros(1,numel(plants));
%     y = zeros(1,numel(plants));
%    ODmean = zeros(1,numel(plants));
%    DOCOmean = zeros(1,numel(plants));
    O3 = zeros(1,numel(plants));
    CO = zeros(1,numel(plants));
    D2 = zeros(1,numel(plants));
    % Run the fit analysis function
    for i = 1:length(plants)
        if i == 1
            [x,y,ODmean,DOCOmean,O3(i),CO(i),D2(i)] = fitanalysisfunction(plantnames{i},plants{i});
        else
            [x(i),y(i),ODmean(i),DOCOmean(i),O3(i),CO(i),D2(i)] = fitanalysisfunction(plantnames{i},plants{i});
        end
        
    end
    
    assignin('base','x',x);
    assignin('base','y',y);
    assignin('base','ODmean',ODmean);
    assignin('base','DOCOmean',DOCOmean);
    assignin('base','O3',O3);
    assignin('base','CO',CO);
    assignin('base','D2',D2);
    
    xval = zeros(size(x));
    xerr = zeros(size(x));
    yval = zeros(size(x));
    yerr = zeros(size(x));
    for i = 1:numel(xval);
        xval(i) = x(i).value;
        xerr(i) = x(i).errorbar;
        yval(i) = y(i).value;
        yerr(i) = y(i).errorbar;
    end
    
    figure(10);errorbarxy(xval,yval,xerr,yerr,{'ro', 'r', 'r'});
end
function hfig = setInitialConcentrations(this, plantids)
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
    plantNames = this.PlantNames(idx);
    dupids = [];
    
    ttot = table();
    % Open the plot browsers
    for i = 1:length(plants)
        t = plants{i}.initialConditionsTable;
        if isempty(t)
            varNames = {'O3','CO','D2','NO','N2'};
            rowNames = plantNames(i);
            data = num2cell(zeros(1,numel(varNames)));
            t = table(data{:},'RowNames',rowNames,'VariableNames',varNames);
            plants{i}.initialConditionsTable = t;
        else
            t.Properties.RowNames = plantNames(i);
        end
        if isempty(ttot)
            ttot = t;
        else
            ttot = vertcat(ttot,t);
        end
        %plants{i}.exportDOCOglobals();
    end
    
    tout = uiedittable(ttot);
    
    for i = 1:length(plants)
        plants{i}.initialConditionsTable = tout(strcmp(tout.Properties.RowNames,plantNames(i)),:);
    end
end
function data = runsimbiologyscanincurrentworkspace(dataToFit,variants)
% Need to provide modelobj, cs, variants, dataToFit
modelobj = evalin('base','modelobj');
cs = getconfigset(modelobj,'active');
set(cs, 'StopTime', 100)

% RUNSIMULATION simulate SimBiology model, modelobj, for each
% individual in the dataset.

% Data definition
groupVar       	  = 'ID';
independentVar 	  = 'time';
dependentVar   	  = {'OD','trans_DOCO','D2O'};
doseVar        	  = {'O3','D2','CO','N2'};
rateVar        	  = {'','','',''};
timeUnits      	  = 'microsecond';
doseUnits      	  = {'molecule','molecule','molecule','molecule'};
rateUnits      	  = {'','','',''};
dependentVarUnits = {'molecule','molecule','molecule'};

% Model Definition
responseVar(1) = modelobj.Compartments(1).Species(16);
responseVar(2) = modelobj.Compartments(1).Species(17);
responseVar(3) = modelobj.Compartments(1).Species(18);
doseTargets    = {'[HOCO Reaction Cell].O3','[HOCO Reaction Cell].D2','[HOCO Reaction Cell].CO','[HOCO Reaction Cell].N2'};

% Handle Unit Conversion
[dataToFit, dependentVar, unitConversionMap] = handleUnitConversion(dataToFit, cs, dependentVar, dependentVarUnits, responseVar);
    
% Configure StatesToLog.
originalStatesToLog = get(cs.RuntimeOptions, 'StatesToLog');
set(cs.RuntimeOptions, 'StatesToLog', responseVar);

% Configure StopTime.
originalStopTime = get(cs, 'StopTime');

% Cleanup code to restore StatesToLog and StopTime.
cleanup = onCleanup(@() restore(cs, originalStatesToLog, originalStopTime));

% Extract the group names. A dose will be created for each group. The 
% dose will be applied to the model. The model will be simulated using
% that dose.
groupNames = getGroupNames(dataToFit, groupVar);

% Initialize the output.
data = cell(length(groupNames), 1);

hwait = waitbar(0,'Running Simulations...', 'WindowStyle', 'modal');
for j = 1:length(groupNames)
    % Simulate the next individual in the data set.
    groupName = groupNames{j};
    doseObjs  = cell(1, length(doseVar));
    csMaxTime = 0;
    
    % Create a dose for each dose variable.
    for i = 1:length(doseVar) 
        % Construct the dose.
        name           = ['dose' num2str(i)];
        [obj, maxTime] = constructDoseFromDataSet(dataToFit, name, groupVar, independentVar, doseVar{i}, rateVar{i}, groupName);
        
        % Store the highest time in the dose.
        if (maxTime > csMaxTime)
            csMaxTime = maxTime;
        end
        
        % Configure units.
        if ~isempty(obj)
            set(obj, 'TimeUnits', timeUnits);
            set(obj, 'AmountUnits', doseUnits{i});
            set(obj, 'RateUnits', rateUnits{i});
            doseObjs{i} = obj;
        end
        
        set(obj, 'Target', doseTargets{i});
    end
    
    % Convert into an array.
    doseObjs = [doseObjs{:}];    
   
    if ~isempty(doseObjs)
        set(cs, 'StopTime', csMaxTime);
    else
        set(cs, 'StopTime', originalStopTime);
    end
    
    % Simulate the model.
    warning('off','SimBiology:DimAnalysisNotDone_MatlabFcn');
    data{j} = sbiosimulate(modelobj, cs, variants, doseObjs);
    warning('on','SimBiology:DimAnalysisNotDone_MatlabFcn');
    waitbar(j/length(groupNames),hwait);
end
close(hwait);

% Convert the results into an array.
data = [data{:}]';

% ---------------------------------------------------------
function restore(cs, originalStatesToLog, originalStopTime)

% Restore StatesToLog.
set(cs.RuntimeOptions, 'StatesToLog', originalStatesToLog);

% Restore StopTime.
set(cs, 'StopTime', originalStopTime);

% ---------------------------------------------------------
function groupNames = getGroupNames(dataset, groupLabel)

if isempty(groupLabel)
    groupNames = {''};
else
    groupNames = unique(dataset.(groupLabel), 'stable');
    
    if (isnumeric(groupNames))
        groupNames = num2cell(groupNames);
    end
end

% ---------------------------------------------------------
function [doseObj, maxTime] = constructDoseFromDataSet(ds, name, id, time, dose, rate, groupValue)

% If ID is specified, extract it from the dataset.
if ~isempty(id)
    ds = getDataFromDataSet(ds, id, groupValue);
end

% Define the time, dose and rate data.
timeData = ds.(time);
doseData = ds.(dose);
maxTime  = max(timeData);

if ~isempty(rate)
    rateData = ds.(rate);
else
    rateData = zeros(length(timeData),1);
end

% Remove zeros.
removeIDX           = (doseData == 0);
timeData(removeIDX) = [];
doseData(removeIDX) = [];
rateData(removeIDX) = [];

% Remove the NaN values.
removeIDX           = isnan(doseData);
timeData(removeIDX) = [];
doseData(removeIDX) = [];
rateData(removeIDX) = [];

% Remove the Inf values.
removeIDX           = isinf(doseData);
timeData(removeIDX) = [];
doseData(removeIDX) = [];
rateData(removeIDX) = [];

% Sort the data.
[timeData, idx] = sort(timeData);
doseData        = doseData(idx);
rateData        = rateData(idx);

if ~isempty(doseData)
    % Create the object.
    doseObj        = sbiodose(name, 'schedule');
    doseObj.Time   = timeData;
    doseObj.Amount = doseData;
    doseObj.Rate   = rateData;
else
    doseObj = [];
end

% ---------------------------------------------------------
function ds = getDataFromDataSet(ds, id, groupValue)

% If ID is specified, extract it from the dataset.
if ~isempty(id)    
    idData = ds.(id);    
    if isnumeric(idData)
        if ischar(groupValue)
            groupValue = str2double(groupValue);
        end
        indices = (idData == groupValue);
    elseif iscellstr(idData)
        indices = strcmp(groupValue, idData);
    else
        indices = 0;
    end
    
    % Extract the new dataset.
    ds = ds(indices, :); 
end

% ---------------------------------------------------------
function ds = getGroupsFromDataSet(ds, groupVar, groupNames)

% Cleanup the data to contain only those groups being simulated.
if ~isempty(groupNames)
    for i = 1:length(groupNames)        
        groupNames{i} = num2str(groupNames{i});        
    end
    
    groupData = ds.(groupVar);
    removeRow = false(1, length(groupData));
    for i=1:length(groupData)
        if iscell(groupData)
            next = groupData{i};
        else
            next = num2str(groupData(i));
        end
        removeRow(i) = ~any(strcmp(groupNames, next)); 
    end
    
    ds(removeRow,:) = [];
end

% ----------------------------------------------------------
function [dataToFit, dataColumns, unitConversionMap] = handleUnitConversion(dataToFit, cs, dataColumns, dataColumnUnits, responses)
% If unit conversion is turned on build a map with the original dependent
% as key and the unit converted columnName as the value. This is then used
% by groupSimulationPlot to plot the correct responses when only some
% responses are selected in the Plots to generate.
unitConversionMap = containers.Map;
if (cs.CompileOptions.UnitConversion)
    for i=1:length(dataColumns)
        dataUnit  = dataColumnUnits{i};
        modelUnit = getUnitsForResponse(responses(i));
        if ~strcmp(dataUnit, modelUnit)
            
            newColumn   = getUniqueColumnName(dataColumns{i}, dataToFit.Properties.VarNames);            
            nextData    = dataToFit.(dataColumns{i});
            
            % Convert the units.
            try
                nextData = sbiounitcalculator(dataUnit, modelUnit, nextData);
            catch ex
                
            end
            
            % Add column to dataset.
            dataToFit.(newColumn)   = nextData;
            unitConversionMap( dataColumns{i}) = newColumn;       
            dataColumns{i}          = newColumn;
        end
    end
end

% ----------------------------------------------------------
function out = getUnitsForResponse(response)
    out = '';
    type = response.Type;
    switch(type)
        case 'species'
            out = response.InitialAmountUnits;
        case 'compartment'
            out = response.CapacityUnits;
        case  'parameter'
            out = response.ValueUnits;
    end
    
% ----------------------------------------------------------
function out = getUniqueColumnName(nameIn, columns)
    
out  = nameIn;
obj   = find(strcmp(columns, nameIn));
count = 1;

while ~isempty(obj)
    out   = sprintf('%s_%d', nameIn, count);
    count = count + 1;
    obj   = find(strcmp(columns, out));
end



% ----------------------------------------------------------
function plottype_Group_Simulation(taskresult, responsesToPlot, axesStyle)
%GROUPSIMULATIONPLOT Plots simulation results for each individual.
%
%    GROUPSIMULATIONPLOT(TASKRESULT, RESPONSESTOPLOT, PROPS) plots the
%    simulation results for each individual on top of the experimental data
%    for each individual from the TASKRESULT.TaskInfo.DataToFit dataset.
%
%    RESPONSESTOPLOT specifies a subset of the data to plot. The columns in
%    the experimental data with names, RESPONSESTOPLOT.DataColumn will be
%    plotted along with the simulation results for the model components,
%    RESPONSESTOPLOT.ModelComponent. If RESPONSESTOPLOT is empty then all
%    experimental data dependent variables will be plotted along with all
%    simulation results.
%
%    AXESSTYLE is a structure that contains axes property value pairs.
%
%    See also GETDATA, SBIOTRELLIS, SELECTBYNAME.

% Error checking.
if ~isfield(taskresult, 'TaskInfo') && ~isfield(taskresult.TaskInfo, 'GroupVar')
    error('SimBiology:INVALID_PLOT_TYPE','This plot is supported only for Group Simulation tasks.');
end

% Extract the data.
dataToFit     = taskresult.TaskInfo.DataToFit; 
groupVar      = taskresult.TaskInfo.GroupVar; 
time          = taskresult.TaskInfo.IndependentVar; 
dependentVars = taskresult.TaskInfo.DependentVar; 

% Plot only the data columns that were selected.
if ~isempty(responsesToPlot)
    dependentVars = getDependentVars(taskresult.TaskInfo, responsesToPlot.DataColumn);
end

% Plot the external data.
h = sbiotrellis(dataToFit, groupVar, time, dependentVars);
haxes = h.plots;
hline = findall(haxes, 'Type', 'line');
set(hline, 'Marker', '+', 'LineStyle', 'none');

% Get the limits.
xlim = get(haxes(1), 'XLim');
xmin = xlim(1);
xmax = xlim(2);

ylim = get(haxes(1), 'YLim');
ymin = ylim(1);
ymax = ylim(2);

% Label the trellis plot.
labelArgs   = groupSimulationGetLabels(axesStyle);
h.plottitle = labelArgs{2};
h.labelx    = labelArgs{4};
h.labely    = labelArgs{6};

% Configure trellis plot to hold additional lines.
set(haxes, 'NextPlot', 'add')

if feature('HGUsingMATLABClasses')
    set(haxes, 'ColorOrderIndex', 1);
end

% Plot the results.
names = {};
tobj  = taskresult.data;
for i = 1:length(tobj)
    dataToPlot  = tobj(i);
    haxesHandle = haxes(i); 
    
    % Get the data associated with the model components that are to 
    % be plotted.
    if isempty(responsesToPlot)
        [t,x,names] = getdata(dataToPlot);
    else
        [t,x,names] = selectbyname(dataToPlot, responsesToPlot.ModelComponent);
        if ~(size(x, 2) == length(responsesToPlot.ModelComponent))
            error('The Model Component Name was not found in the data. Check the settings for Plots to Generate.');
        end
    end
    
    % Check limits.    
    val = min(min(t));
    if val < xmin
        xmin = val;
    end
    
    val = max(max(t));
    if val > xmax
        xmax = val;
    end
    
    val = min(min(x));
    if val < ymin
        ymin = val;
    end
    
    val = max(max(x));
    if val > ymax
        ymax = val;
    end    

    % Plot the data.
    if size(x,2) == 1
        colorOrder = get(haxesHandle, 'ColorOrder');
        plot(haxesHandle,t,x, 'Color', colorOrder(2,:));
    else
        plot(haxesHandle,t,x);
    end
end

% Configure the limits.
set(haxes, 'XLim', [xmin xmax]);
set(haxes, 'YLim', [ymin ymax]);

% Configure the axes properties.
if isfield(axesStyle, 'Properties') 
    set(haxes, axesStyle.Properties);
end

% Update the legend.
legendHandle = findall(h.hFig, 'Type', 'legend');

legendNames  = get(legendHandle, 'String');
legendNames  = legendNames(1:length(dependentVars));
% Get the legendNames if the unit conversion is turned on.
legendNames  = getLegendNames(taskresult.TaskInfo, legendNames);
legendNames  = [legendNames names{:}];

updateLegend(h, legendNames);

% Restore the NextPlot state.
set(haxes, 'NextPlot', 'replace');

% ---------------------------------------------------------
function out = groupSimulationGetLabels(axesStyle)

out = {'title', '', 'xlabel', '', 'ylabel', ''};

if isfield(axesStyle, 'Labels')
    allLabels = axesStyle.Labels;
    
    if isfield(allLabels, 'Title')
        out{2} = allLabels.Title;
    end
    
    if isfield(allLabels, 'XLabel')
        out{4} = allLabels.XLabel;
    end
    
    if isfield(allLabels, 'YLabel')
        out{6} = allLabels.YLabel;
    end
end

% ---------------------------------------------------------
function dependentVars = getDependentVars(taskInfo, dependentVars)
    % If the Unit Conversion is on get the dependent vars from the
    % taskInfos UnitConversionMap. 
    if isfield(taskInfo, 'UnitConversionMap') && ~isempty(taskInfo.UnitConversionMap)
        map = taskInfo.UnitConversionMap;
        for i = 1: numel(dependentVars)
            if isKey(map, dependentVars{i})
                dependentVars{i} = map(dependentVars{i});
            end
        end
    end

% ---------------------------------------------------------
function legendNames = getLegendNames(taskInfo, legendNames)
    % If the Unit Conversion is on, the legend names should be restored back to
    % the names of the data columns.
    if isfield(taskInfo, 'UnitConversionMap') && ~isempty(taskInfo.UnitConversionMap)
        map = taskInfo.UnitConversionMap;
        values = map.values;
        keys   = map.keys;
        for i = 1: numel(legendNames)
            ind = find(ismember(values, legendNames{i}), 1);
            if ~isempty(ind)
                legendNames{i} = keys{ind};
            end
        end
    end
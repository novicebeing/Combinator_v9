function hf = displayAveragingBarChart(obj)
    if ~isempty(obj.plotHandles)
        obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
    else
        obj.plotHandles = {};
    end
    if ~isempty(obj.plotHandles)
        n = numel(obj.plotHandles);
        obj.plotHandles{n+1} = spectraobjects.averagingbarchart(obj);
        hf = obj.plotHandles{n+1}.figureHandle;
    else
        obj.plotHandles = {spectraobjects.averagingbarchart(obj)};
        hf = obj.plotHandles{1}.figureHandle;
    end
end
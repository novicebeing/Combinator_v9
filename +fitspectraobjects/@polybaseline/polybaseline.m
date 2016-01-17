classdef polybaseline < handle
    % Line List Class
    
    properties
        name = '';
        
        % Polynomial Order is our only parameter
        polynomialOrder = 3;
    end
    properties (Transient = true)
        % Live Image Views
        plotHandles;
    end
    methods
        function obj = polybaseline(varargin)
            
        end
        function updatePlots(obj)
            % Remove deleted plot handles
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            
            for i = 1:numel(obj.plotHandles)
                obj.plotHandles{i}.Update();
            end
        end
        function hf = spectrumsimulationbrowser(obj)
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = fitspectraobjects.spectrumsimulationbrowser(obj);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {fitspectraobjects.spectrumsimulationbrowser(obj)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end
    end
end


classdef linelist < handle
    % Line List Class
    
    properties
        name = '';
        
        % Line List Parameters
        lineposition;
        linestrength;
        
        % Spectrum Cache
        spectrumCacheParams = [];
        spectrumCacheWavenum = [];
        spectrumCacheCrossSection = [];
        
        % Live Image Views
        plotHandles;
    end
    methods (Static)
        areaNormGaussian;
        areaNormLorentzian;
        areaNormPseudoVoigt;
        areaNormVoigt;
    end
    methods
        function obj = linelist(varargin)
            
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


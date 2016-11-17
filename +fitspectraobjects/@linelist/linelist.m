classdef linelist < handle & JavaVisible
    % Line List Class
    
    properties
        name = '';
        
        % Line List Parameters
        lineposition;
        linestrength;
    end
    properties (Transient = true, Hidden = true)
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
        function this = linelist(varargin)
            % Check inputs
            p = inputParser;
            addParameter(p,'pgopherfile',[],@ischar);
            parse(p,varargin{:});
            
            % Load data from the pgopher file
            if ~isempty(p.Results.pgopherfile)
                this.pgopherLoad(p.Results.pgopherfile);
            end
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
        function deleteCache(this)
            this.spectrumCacheParams = [];
            this.spectrumCacheWavenum = [];
            this.spectrumCacheCrossSection = [];
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
        function hf = spectrumstembrowser(obj)
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = fitspectraobjects.spectrumstembrowser(obj);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {fitspectraobjects.spectrumstembrowser(obj)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end
    end
end


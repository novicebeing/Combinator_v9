classdef spectraobject < handle & JavaVisible
    %kineticsobject
    
    properties
        name;
        
        % Raw spectrum input
            t;
            wavenum;
            ysum; % Sum of y/sigma^2
            wsum; % Sum of 1/sigma^2
            deltay;
        
        yWavenumRef;
        
        % Spectrum average parameters
            tavg;
            yavg;
            ystderror;
    end
    properties (Transient = true)
        % Live Image Views
        plotHandles;
    end
    methods
        function obj = spectraobject(varargin)
            if nargin > 0
                filename = varargin{1};
            else
                filename = [];
            end
            if ischar(filename)
                if strcmp(filename,'gui')
                    [filename,filepath] = uigetfile;
                    data = load(fullfile(filepath,filename),'-mat');
                else
                    data = load(filename,'-mat');
                end
                obj.wavenum = data.wavenum;
                obj.ysum = data.ysum;
                obj.wsum = data.wsum;
                obj.deltay = zeros(size(data.ysum));
                obj.t = data.t;
                obj.yWavenumRef = [];
                return
            end
            obj.wavenum = [];
            obj.ysum = [];
            obj.wsum = [];
            obj.yWavenumRef = [];
            obj.t = [];
        end
        function delete(obj)
            % Remove deleted plot handles
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            
            for i = 1:numel(obj.plotHandles)
                delete(obj.plotHandles{i});
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
        
        
        function obj = addSpectrum(obj,specWavenum,specY,t)
            if ndims(specWavenum) > 2 || ndims(specY) > 2
               error('Too many dimensions'); 
            end
            if isempty(obj.wavenum)
                obj.wavenum = specWavenum;
            elseif obj.wavenum ~= specWavenum
                error();
            end
            if isempty(obj.y)
                obj.y = specY;
            else
                obj.y(:,:,end+1) = specY;
            end
            obj.t(end+1) = t;
        end
        function obj = averageSpectra(obj)
            %# unique values in B, and their indices
            [obj.tavg,~,subs] = unique(obj.t);
            
%             if size(subs,1) == 1
%                 subscell = {};
%                 for i = 1:numel(obj.t)
%                     subscell{i} = i;
%                 end
%             else
                subscell = accumarray(reshape(subs,[],1), reshape(1:numel(obj.t),[],1), [], @(x) {x});
%             end
            
            obj.yavg = zeros(size(obj.ysum,1),size(obj.ysum,2),numel(obj.tavg));
            for i = 1:numel(subscell)
                sub = subscell{i};
                ysum = zeros([size(obj.ysum,1) size(obj.ysum,2)]);
                wsum = zeros([size(obj.ysum,1) size(obj.ysum,2)]);
                for j = 1:numel(sub)
                	ysum = ysum + obj.ysum(:,:,sub(j));
                    wsum = wsum + obj.wsum(:,:,sub(j));
                end
                obj.yavg(:,:,i) = ysum./wsum;
                obj.ystderror(:,:,i) = sqrt(1./wsum);
            end
        end
        function hf = plotbrowser(obj,varargin)
            % Set plot options
            if nargin == 2
                options = varargin{1};
            else
                options = '';
            end
            
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = spectraobjects.spectrabrowser(obj,options);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {spectraobjects.spectrabrowser(obj,options)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end
        function resetSpectra(obj,ax,hp,hplus,hminus,sliderobj,options)
            % Re-average the spectra
            obj.averageSpectra();
            
            % Update the plot
            obj.updatePlot(ax,hp,hplus,hminus,round(get(sliderobj,'Value')),options)
        end
    end
end


classdef imagesobject < handle
    % Line List Class
    
    properties
        name = '';
        
        % Images Parameters
        images;
        time;
        refImagesBoolean;
		avgcounter = 0;
    end
    properties (Transient = true)
        % Live Image Views
        plotHandles;
    end
    methods
        function obj = imagesobject(varargin)
            obj.time = [];
            obj.images = [];
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

        function hf = imagebrowser(obj)
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = imagesobjects.imagebrowser(obj);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {imagesobjects.imagebrowser(obj)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end
        function hf = lineProfileBrowser(obj)
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = imagesobjects.lineprofilebrowser(obj);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {imagesobjects.lineprofilebrowser(obj)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end

        % Adding, replacing, clearing images
		function clearImages(obj)
			obj.images = [];
			obj.time = [];
			obj.avgcounter = 0;
            obj.refImagesBoolean = [];
		end
        function setImages(obj,images,time,refImagesBoolean)
            obj.images = images;
            obj.time = time;
            obj.avgcounter = 0;
            obj.refImagesBoolean = refImagesBoolean;
            
            % Update the plots
            obj.updatePlots();
        end
        function obj = addImages(obj,images,time,refImagesBoolean)
            if isempty(obj.images)
                obj.images = images;
            else
                obj.images(:,:,end+1) = images;
            end
            obj.time(end+1) = time;
            obj.refImagesBoolean(end+1) = refImagesBoolean;

            % Update the plots
            obj.updatePlots();
        end
		function averageImages(obj,images,time)
            if isempty(obj.images)
                obj.images = images;
				obj.avgcounter = 1;
            else
                obj.images = (obj.avgcounter*obj.images+images)/(obj.avgcounter+1);
				obj.avgcounter = obj.avgcounter+1;
            end
            obj.time = time;
            obj.refImagesBoolean = zeros(size(time));

            % Update the plots
            obj.updatePlots();
		end
    end
end


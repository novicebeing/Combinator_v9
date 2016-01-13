classdef imagesobject < handle
    % Line List Class
    
    properties
        name = '';
        
        % Images Parameters
        images;
        time;
        
        % Live Image Views
        liveImagePlotHandles;
        plotHandles;
    end
    methods
        function obj = imagesobject(varargin)
            obj.time = [];
            obj.images = [];%rgb2gray(imread('peppers.png'));
        end
        function h = imagePlot(obj,ax,ind)
            h = imagesc(obj.images(:,:,ind),'Parent',ax);
        end
        function updateImagePlot(obj,hp,ind)
            set(hp,'CData',obj.images(:,:,ind));
        end
        function h = lineProfilePlot(obj,ax,ind)
            x = 1:size(obj.images(:,:,ind),2);
            y = obj.images(round(size(obj.images(:,:,ind),2)/2),:,ind);
            h = plot(x,y,'Parent',ax);
            ylim([0 6000]);
        end
        function updateLineProfilePlot(obj,hp,ind)
            x = 1:size(obj.images(:,:,ind),2);
            y = obj.images(round(size(obj.images(:,:,ind),2)/2),:,ind);
            set(hp,'XData',x);
            set(hp,'YData',y);
        end
        function hf = imagebrowser(obj,varargin)
            if isempty(obj.name)
                hf = figure;
            else
                hf = figure('Name',obj.name,'NumberTitle','off');
            end
            ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
            [hp] = obj.imagePlot(ax,1);
            obj.liveImagePlotHandles(end+1) = hp;
            obj.updateImagePlot(hp,round(1));
            b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(obj.time),'sliderstep',[1/numel(obj.time) 10/numel(obj.time)]);
            set(b,'Callback',@(es,ed) obj.updateImagePlot(hp,round(get(es,'Value'))));
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
%         function hf = lineProfileBrowser(obj)
%             if isempty(obj.name)
%                 hf = figure;
%             else
%                 hf = figure('Name',obj.name,'NumberTitle','off');
%             end
%             ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
%             [hp] = obj.lineProfilePlot(ax,1);
%             obj.liveImagePlotHandles(end+1) = hp;
%             obj.updateLineProfilePlot(hp,round(1));
%             b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
%               'value',1, 'min',1, 'max',numel(obj.time),'sliderstep',[1/numel(obj.time) 10/numel(obj.time)]);
%             set(b,'Callback',@(es,ed) obj.updateLineProfilePlot(hp,round(get(es,'Value'))));
%         end
        function setImages(obj,images,time)
            obj.images = images;
            obj.time = time;
            obj.liveImagePlotHandles = obj.liveImagePlotHandles(ishandle(obj.liveImagePlotHandles));
            hs = obj.liveImagePlotHandles;
            for h = hs
                obj.updateImagePlot(h,1)
            end
        end
        function obj = addImages(obj,images,time)
            if isempty(obj.images)
                obj.images = images;
            else
                obj.images(:,:,end+1) = images;
            end
            obj.time(end+1) = time;
        end
    end
end


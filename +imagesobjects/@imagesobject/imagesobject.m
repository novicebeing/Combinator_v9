classdef imagesobject < handle
    % Line List Class
    
    properties
        name = '';
        
        % Images Parameters
        images;
        time;
    end
    methods
        function obj = imagesobject(varargin)
            obj.time = [];
            obj.images = [];%rgb2gray(imread('peppers.png'));
        end
        function h = imagePlot(obj,ax,ind)
            h = imagesc(obj.images(:,:,ind),'Parent',ax);
        end
        function updateImagePlot(obj,ax,hp,ind)
            set(hp,'CData',obj.images(:,:,ind));
        end
        function hf = imagebrowser(obj,varargin)
            if isempty(obj.name)
                hf = figure;
            else
                hf = figure('Name',obj.name,'NumberTitle','off');
            end
            ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
            [hp] = obj.imagePlot(ax,1);
            obj.updateImagePlot(ax,hp,round(1));
            b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(obj.time),'sliderstep',[1/numel(obj.time) 10/numel(obj.time)]);
            set(b,'Callback',@(es,ed) obj.updateImagePlot(ax,hp,round(get(es,'Value'))));
        end
        function setImages(obj,images,time)
            obj.images = images;
            obj.time = time;
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


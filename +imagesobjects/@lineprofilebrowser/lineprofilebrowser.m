classdef lineprofilebrowser < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        Parent
        
        % Handles
        figureHandle
        axesHandle
        plotHandle
        sliderHandle
    end
    
    methods
        function this = lineprofilebrowser(ParentObject)
            this.Parent = ParentObject;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
            else
                this.figureHandle = figure('Name',this.Parent.name,'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.plotHandle = this.lineProfilePlot(1);
            this.updateLineProfilePlot(this.plotHandle,round(1));
            this.sliderHandle = uicontrol('Parent',this.figureHandle,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(this.Parent.time),'sliderstep',[1/numel(this.Parent.time) 10/numel(this.Parent.time)]);
            set(this.sliderHandle,'Callback',@(es,ed) this.updateLineProfilePlot(this.plotHandle,round(get(es,'Value'))));
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
        end
        function Update(this)
            this.updateLineProfilePlot(this.plotHandle,round(get(this.sliderHandle,'Value')));
        end
        
        % Internal Functions
        function hp = lineProfilePlot(obj,ind)
            x = 1:size(obj.Parent.images(:,:,ind),2);
            y = obj.Parent.images(round(size(obj.Parent.images(:,:,ind),2)/2),:,ind);
            hp = plot(x,y,'Parent',obj.axesHandle);
            ylim([0 6000]);
        end
        function updateLineProfilePlot(obj,hp,ind)
            x = 1:size(obj.Parent.images(:,:,ind),2);
            y = obj.Parent.images(round(size(obj.Parent.images(:,:,ind),2)/2),:,ind);
            set(hp,'XData',x);
            set(hp,'YData',y);
        end
    end
end
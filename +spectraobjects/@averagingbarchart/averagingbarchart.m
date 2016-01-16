classdef averagingbarchart < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        Parent
        
        % Bar chart options
        wavenumMin = 2682;
        wavenumMax = 2686;
        
        % Handles
        figureHandle
        axesHandle
        blueBarHandle
        blackBarHandle
    end
    
    methods
        function this = averagingbarchart(ParentObject)
            this.Parent = ParentObject;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
            else
                this.figureHandle = figure('Name',sprintf('%s Simulation',this.Parent.name),'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.imagePlot();
            this.updateImagePlot();
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
        end
        function Update(this)
            this.updateImagePlot();
        end
        
        % Internal Functions
        function imagePlot(obj)
            % Gather the errors
            [tplot,averageErrorPlot,averageStdMean] = obj.Parent.averageError(obj.wavenumMin,obj.wavenumMax);

            % Sort t,averageError
            [~,isort] = sort(tplot);

            obj.blackBarHandle = bar(1./averageStdMean(isort),'k','Parent',obj.axesHandle); hold(obj.axesHandle,'on');
            obj.blueBarHandle = bar(1./averageErrorPlot(isort),'b','Parent',obj.axesHandle); hold(obj.axesHandle,'off');
        end
        function updateImagePlot(obj)
            % Gather the errors
            [tplot,averageErrorPlot,averageStdMean] = obj.Parent.averageError(obj.wavenumMin,obj.wavenumMax);

            % Sort t,averageError
            [~,isort] = sort(tplot);
            
            set(obj.blackBarHandle,'XData',1:numel(isort));
            set(obj.blackBarHandle,'YData',1./averageStdMean(isort));
            set(obj.blueBarHandle,'XData',1:numel(isort));
            set(obj.blueBarHandle,'YData',1./averageErrorPlot(isort));
        end
    end
end
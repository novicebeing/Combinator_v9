classdef imagebrowser < handle
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
        function this = imagebrowser(ParentObject)
            this.Parent = ParentObject;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
            else
                this.figureHandle = figure('Name',this.Parent.name,'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.plotHandle = this.imagePlot(1);
            this.updateImagePlot(this.plotHandle,round(1));
            this.sliderHandle = uicontrol('Parent',this.figureHandle,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(this.Parent.time),'sliderstep',[1/numel(this.Parent.time) 10/numel(this.Parent.time)]);
            set(this.sliderHandle,'Callback',@(es,ed) this.updateImagePlot(this.plotHandle,round(get(es,'Value'))));
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
        end
        function Update(this)
            % Save the previous value
            oldSliderValue = round(get(this.sliderHandle,'Value'));
            oldSliderMax = this.sliderHandle.Max;

            % Reset the slider bounds
            newSliderMax = numel(this.Parent.time);
            if oldSliderMax == oldSliderValue || oldSliderValue > newSliderMax
                newSliderValue = newSliderMax;
            else
                newSliderValue = oldSliderValue;
            end

            % Apply the slider bounds
            this.sliderHandle.Value = newSliderValue;
            this.sliderHandle.Max = newSliderMax;
            this.sliderHandle.SliderStep = [1/newSliderMax 10/newSliderMax];

            % Hide the slider if necessary
            if newSliderMax == 1
                this.sliderHandle.Visible = 'off';
            else
                this.sliderHandle.Visible = 'on';
            end

            this.updateImagePlot(this.plotHandle,round(get(this.sliderHandle,'Value')));
        end
        
        % Internal Functions
        function hp = imagePlot(obj,ind)
            hp = imagesc(obj.Parent.images(:,:,ind),'Parent',obj.axesHandle);
        end
        function updateImagePlot(obj,hp,ind)
            set(hp,'CData',obj.Parent.images(:,:,ind));
        end
    end
end
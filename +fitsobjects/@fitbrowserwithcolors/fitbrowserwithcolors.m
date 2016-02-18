classdef fitbrowserwithcolors < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        Parent
        
        % Handles
        figureHandle
        axesHandle
        plotHandle
        sliderHandle
        simPlotHandles
        
        noImageBoolean
        
        options
    end
    
    methods
        function this = fitbrowserwithcolors(ParentObject,options)
            this.Parent = ParentObject;
            this.options = options;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
            else
                this.figureHandle = figure('Name',this.Parent.name,'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.sliderHandle = uicontrol('Parent',this.figureHandle,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',1,'sliderstep',[1 1]);
            this.imagePlot();
            this.Update();
            set(this.sliderHandle,'Callback',@(es,ed) this.updateImagePlot());
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
        end
        function delete(obj)
            % Remove figure handles
            delete(obj.figureHandle);
        end
        function Update(this)
            % Save the previous value
            oldSliderValue = round(get(this.sliderHandle,'Value'));
            oldSliderMax = this.sliderHandle.Max;

            % Reset the slider bounds
            newSliderMax = numel(this.Parent.t);
            if newSliderMax == 0
                newSliderMax = 1;
            end
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

            this.updateImagePlot();
        end
        
        % Internal Functions
        function imagePlot(this)
            ind = round(this.sliderHandle.Value);
            if ishandle(this.plotHandle)
                delete(this.plotHandle)
            end
            
            if isempty(this.Parent.t)
                this.plotHandle = plot(NaN,NaN,'Parent',this.axesHandle);
                this.noImageBoolean = true;
            else
                plotcolor = [0,0,0];
                this.plotHandle = plot(this.axesHandle,this.Parent.wavenum(:),reshape(this.Parent.y(:,:,ind),[],1),'Color',plotcolor);
                hold(this.axesHandle,'on');
                this.simPlotHandles = [];
                for i = 1:numel(this.Parent.fitbNames)
                    indx = this.Parent.fitbNamesInd(i);
                    this.simPlotHandles(i) = plot(this.axesHandle,this.Parent.wavenum(:),this.Parent.fitM(:,indx).*this.Parent.fitb(indx,ind),'-');
                    hold on;
                end
                hold(this.axesHandle,'off');
                legend({'Experiment',this.Parent.fitbNames{:}});

                if strcmp(this.options,'fft')
                    xlabel(this.axesHandle,'Etalon Length [cm]');
                    ylabel(this.axesHandle,'FFT Amplitude');
                else
                    xlabel(this.axesHandle,'Wavenumber [1/cm]');
                    ylabel(this.axesHandle,'Absorbance');
                end
                this.noImageBoolean = false;
            end
        end
        function updateImagePlot(this)
            ind = round(this.sliderHandle.Value);
            
            set(this.plotHandle,'XData',this.Parent.wavenum(:));
            set(this.plotHandle,'YData',reshape(this.Parent.y(:,:,ind),[],1));
            for i = 1:numel(this.Parent.fitbNames)
                indx = this.Parent.fitbNamesInd(i);
                set(this.simPlotHandles(i),'XData',this.Parent.wavenum(:));
                set(this.simPlotHandles(i),'YData',this.Parent.fitM(:,indx).*this.Parent.fitb(indx,ind));
            end
            
            title(this.axesHandle,sprintf('T = %i us',this.Parent.t(ind)));
        end
    end
end
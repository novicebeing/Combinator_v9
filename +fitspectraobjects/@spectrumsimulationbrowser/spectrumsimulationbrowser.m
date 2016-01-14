classdef spectrumsimulationbrowser < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        Parent
        
        % Simulation Parameters
        wavenumMin = 2600;
        wavenumMax = 2700;
        numPoints = 10000;
        instrumentGaussianFWHM = 0.03;
        instrumentLorentzianFWHM = 0;
        
        % Handles
        figureHandle
        axesHandle
        plotHandle
    end
    
    methods
        function this = spectrumsimulationbrowser(ParentObject)
            this.Parent = ParentObject;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
            else
                this.figureHandle = figure('Name',sprintf('%s Simulation',this.Parent.name),'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.plotHandle = this.imagePlot();
            this.updateImagePlot();
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
        end
        function Update(this)
            this.updateImagePlot(this.plotHandle,round(get(this.sliderHandle,'Value')));
        end
        
        % Internal Functions
        function hp = imagePlot(obj)
            x = linspace(obj.wavenumMin,obj.wavenumMax,obj.numPoints);
            y = obj.Parent.createSpectrum(x,...
                'instrumentLorentzianFWHM',obj.instrumentLorentzianFWHM,...
                'instrumentGaussianFWHM',obj.instrumentLorentzianFWHM);
            hp = plot(x,y,'Parent',obj.axesHandle);
        end
        function updateImagePlot(obj)
            x = linspace(obj.wavenumMin,obj.wavenumMax,obj.numPoints);
            y = obj.Parent.createSpectrum(x,...
                'instrumentLorentzianFWHM',obj.instrumentLorentzianFWHM,...
                'instrumentGaussianFWHM',obj.instrumentGaussianFWHM);
            set(obj.plotHandle,'XData',x);
            set(obj.plotHandle,'YData',y);
        end
    end
end
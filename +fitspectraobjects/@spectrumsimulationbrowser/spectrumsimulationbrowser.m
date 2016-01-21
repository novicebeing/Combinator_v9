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
        axesmenu
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

            % Add a menu for the axes
            this.axesmenu = uicontextmenu();
            uimenu('Parent',this.axesmenu,'Label','Set Simulation Range','Callback',@(s,e) this.setSimulationRange());
            set(this.axesHandle,'UIContextMenu',this.axesmenu);

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
        function setSimulationRange(this)
            data = inputdlg({'Min Wavenum','Max Wavenum','Num Points'},'Set Range',[1; 1; 1],{num2str(this.wavenumMin),num2str(this.wavenumMax),num2str(this.numPoints)});
            if ~isempty(data)
                this.wavenumMin = str2double(data{1});
                this.wavenumMax = str2double(data{2});
                this.numPoints = str2double(data{3});
                this.updateImagePlot();
            end
        end
        function hp = imagePlot(obj)
            x = linspace(obj.wavenumMin,obj.wavenumMax,obj.numPoints);
            y = obj.Parent.createSpectrum(x,...
                'instrumentLorentzianFWHM',obj.instrumentLorentzianFWHM,...
                'instrumentGaussianFWHM',obj.instrumentGaussianFWHM);
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
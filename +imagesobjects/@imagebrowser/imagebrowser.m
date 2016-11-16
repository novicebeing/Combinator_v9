classdef imagebrowser < handle
    % Line Profile Browser Class
    properties
		% Parent GUI
		ParentGUI
	
        % Parent imagesobject
        Parent
        
        % Handles
        figureHandle
        axesHandle
        plotHandle
        sliderHandle
		recordRefButton
		recordSigButton
        
        % No Image Boolean
        noImageBoolean = false
    end
    
    methods
        function this = imagebrowser(ParentObject,ParentGUI)
            this.Parent = ParentObject;
			this.ParentGUI = ParentGUI;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
            else
                this.figureHandle = figure('Name',this.Parent.name,'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);

            this.sliderHandle = uicontrol('Parent',this.figureHandle,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',1,'sliderstep',[1 1],'Visible','off');
			this.recordRefButton = uicontrol('Parent',this.figureHandle,'Style','pushbutton','Position',[81+500,10,100,23],'String','Record as Ref','Visible','off');
			this.recordSigButton = uicontrol('Parent',this.figureHandle,'Style','pushbutton','Position',[81+650,10,100,23],'String','Record as Sig','Visible','off');
            set(this.sliderHandle,'Callback',@(es,ed) this.updateImagePlot());
			set(this.recordRefButton,'Callback',@(es,ed) this.recordRef());
			set(this.recordSigButton,'Callback',@(es,ed) this.recordSig());
            this.imagePlot();
            this.Update();
			
			% Enable the "Record as" buttons if ParentGUI is set
            if ~isempty(ParentGUI)
				set(this.recordRefButton,'Visible','on');
				set(this.recordSigButton,'Visible','on');
			end
			
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
            newSliderMax = numel(this.Parent.time);
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
            ind = round(get(this.sliderHandle,'Value'));
            if ishandle(this.plotHandle)
                delete(this.plotHandle)
            end
            
            if isempty(this.Parent.time)
                this.plotHandle = imagesc(NaN,'Parent',this.axesHandle);
                this.noImageBoolean = true;
            else
                this.plotHandle = imagesc(this.Parent.images(:,:,ind),'Parent',this.axesHandle);
                this.noImageBoolean = false;
            end
        end
        function updateImagePlot(this)
            ind = round(get(this.sliderHandle,'Value'));
            if isempty(this.Parent.time)
                set(this.plotHandle,'CData',NaN);
                title(this.axesHandle,'No Image');
                this.noImageBoolean = true;
            else
                if this.noImageBoolean == true
                    this.imagePlot();
                end
                set(this.plotHandle,'CData',this.Parent.images(:,:,ind));
                title(this.axesHandle,sprintf('Image %i,T = %i',ind,this.Parent.time(ind)));
            end
        end
		function recordRef(this)
			ind = round(get(this.sliderHandle,'Value'));
			this.ParentGUI.VIPACalibrationTool.referenceImage = this.Parent.images(:,:,ind);
		end
		function recordSig(this)
			ind = round(get(this.sliderHandle,'Value'));
			this.ParentGUI.VIPACalibrationTool.calibrationgasImage = this.Parent.images(:,:,ind);
		end
    end
end
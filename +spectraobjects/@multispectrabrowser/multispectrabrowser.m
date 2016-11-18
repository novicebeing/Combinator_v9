classdef multispectrabrowser < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        ParentCellArray
        
        % Handles
        figureHandle
        dcmHandle % Datacursormode handle
        axesHandle
        plotHandle
		shadowplotHandle
        sliderHandle
        h
        herrorminus
        herrorplus
        
        noImageBoolean
    end
    
    properties (Transient = true)
        lastdatacursorposition
    end
    
    methods
        function this = multispectrabrowser(ParentObjectCellArray)
            this.ParentCellArray = ParentObjectCellArray;
            
            % Construct the figure
            %if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
                this.dcmHandle = datacursormode(this.figureHandle);
            %else
            %    this.figureHandle = figure('Name',this.Parent.name,'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
            %    this.dcmHandle = datacursormode(this.figureHandle);
            %end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.imagePlot();
            this.Update();
            set(this.dcmHandle,'UpdateFcn',@dcmupdatefcn)
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
            
            % Datacursormode update function
            function txt = dcmupdatefcn(~,event_obj)
                % Customizes text of data tips

                pos = get(event_obj,'Position');
                txt = {['Wavenum: ',num2str(pos(1))],...
                          ['A: ',num2str(pos(2))]};
                this.lastdatacursorposition = pos;
            end
        end
        function delete(obj)
            % Remove figure handles
            delete(obj.figureHandle);
        end
        function Update(this)

            this.updateImagePlot();
        end
        
        % Internal Functions
        function imagePlot(this)
            if any(ishandle(this.plotHandle))
                delete(this.plotHandle);
            end
            
			numplots = numel(this.ParentCellArray);
			
			for i = 1:numplots
				this.plotHandle(i) = plot(NaN,NaN,'Parent',this.axesHandle);
				hold(this.axesHandle,'on');
			end
			hold(this.axesHandle,'off');
        end
        function updateImagePlot(this)
			ind = 1;
			numplots = numel(this.ParentCellArray);
			
			for i = 1:numplots
				parentObj = this.ParentCellArray{i};
				if isempty(parentObj.t)
					set(this.plotHandle(i),'XData',NaN);
					set(this.plotHandle(i),'YData',NaN);
				else
					if isempty(parentObj.yavg)
						parentObj.averageSpectra();
					end

					set(this.plotHandle(i),'XData',parentObj.wavenum(:));
					set(this.plotHandle(i),'YData',reshape(parentObj.yavg(:,:,ind),[],1));
				end
			end
        end
    end
end
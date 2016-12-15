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
            
            % Construct a context menu for the axes
            c = uicontextmenu(this.figureHandle);
            this.figureHandle.UIContextMenu = c;
            topmenu = uimenu('Parent',c,'Label','Generate Movie','Callback',@generatemovie);
			
			% Generate spectra movie
            function generatemovie(src,callbackdata)
				% set the movie save path
				[filename,filepath] = uiputfile( ...
					{  '*.mp4','MPEG-4 (*.mp4)'; ...
					   '*.avi',  'AVI (*.avi)'}, ...
					   'Pick a file');

				if filepath == 0
					return
				end
				
				prompt = {'Time per frame (s)','Min spectra time (us)','Max spectra time (us)'};
				dlg_title = 'Movie Settings';
				num_lines = 1;
				defaultans = {'0.2',num2str(min(this.Parent.t)),num2str(max(this.Parent.t))};
				answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
				
				if isempty(answer)
					return
				end
				
				% get the responses
				timePerFrame = str2double(answer{1});
				minSpectraTime = str2double(answer{2});
				maxSpectraTime = str2double(answer{3});
				
				indcs = find(this.Parent.t >= minSpectraTime & this.Parent.t <= maxSpectraTime);
				
				[~,ext] = fileparts(filename);
				
				if strcmp(ext,'mp4')
					v = VideoWriter(fullfile(filepath,filename),'MPEG-4');
				else
					v = VideoWriter(fullfile(filepath,filename));
				end
				
				set(v,'FrameRate',1./timePerFrame);
				open(v);
				
				
				F(numel(indcs)) = struct('cdata',[],'colormap',[]);
				for i = 1:numel(indcs)
					set(this.sliderHandle,'Value',indcs(i));
					this.Update();
					F(i) = getframe(this.figureHandle);
					writeVideo(v,F(i));
				end
				
				% save the movie
				close(v);
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
                
                plotcolor = [0.3,0.3,0.3];
                this.plotHandle = plot(this.axesHandle,this.Parent.wavenum(:),reshape(this.Parent.y(:,:,ind),[],1),'Color',plotcolor,'LineWidth',0.5);
                hold(this.axesHandle,'on');
                co = [  1 1 1;...
                        0    0.4470    0.7410;...
                        0.8500    0.3250    0.0980;...
                        0.4940    0.1840    0.5560;...
                        0.4660-0.1    0.6740-0.1    0.1880-0.1;...
                        0.6350    0.0780    0.1840];
                set(this.axesHandle,'ColorOrder',co);
                this.simPlotHandles = [];
                for i = 1:numel(this.Parent.fitbNames)
                    indx = this.Parent.fitbNamesInd(i);
                    this.simPlotHandles(i) = plot(this.axesHandle,this.Parent.wavenum(:),this.Parent.fitM(:,indx).*this.Parent.fitb(indx,ind),'-','LineWidth',1.5);
                    hold on;
                end
                hold(this.axesHandle,'off');
                legend({'Experiment',this.Parent.fitbNames{:}},'interpreter','none');

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
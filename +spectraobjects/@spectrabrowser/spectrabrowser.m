classdef spectrabrowser < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        Parent
        
        % Handles
        figureHandle
        dcmHandle % Datacursormode handle
        axesHandle
        plotHandle
        sliderHandle
        h
        herrorminus
        herrorplus
        
        noImageBoolean
        
        options
    end
    
    properties (Transient = true)
        lastdatacursorposition
    end
    
    methods
        function this = spectrabrowser(ParentObject,options)
            this.Parent = ParentObject;
            this.options = options;
            
            % Construct the figure
            if isempty(this.Parent.name)
                this.figureHandle = figure('CloseRequestFcn',@figCloseFunction);
                this.dcmHandle = datacursormode(this.figureHandle);
            else
                this.figureHandle = figure('Name',this.Parent.name,'NumberTitle','off','CloseRequestFcn',@figCloseFunction);
                this.dcmHandle = datacursormode(this.figureHandle);
            end
            
            if isempty(this.Parent.yavg)
                this.Parent.averageSpectra();
            end
            
            % Construct the plot and axes
            this.axesHandle = axes('Parent',this.figureHandle,'position',[0.13 0.20 0.79 0.72]);
            this.sliderHandle = uicontrol('Parent',this.figureHandle,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',1,'sliderstep',[1 1]);
            this.imagePlot();
            this.Update();
            set(this.sliderHandle,'Callback',@(es,ed) this.updateImagePlot());
            set(this.dcmHandle,'UpdateFcn',@dcmupdatefcn)
            
            % Construct a context menu for the axes
            c = uicontextmenu(this.figureHandle);
            this.figureHandle.UIContextMenu = c;
            topmenu = uimenu('Parent',c,'Label','Change Color','Callback',@singlepixeltimeplot);
            
            function singlepixeltimeplot(src,callbackdata)
                pos = this.lastdatacursorposition;
                [~,idx] = min(abs(this.Parent.wavenum(:) - pos(1)));
                
                [ii,jj] = ind2sub([size(this.Parent.yavg,1) size(this.Parent.yavg,2)],idx);
                figure;scatter(this.Parent.tavg,reshape(this.Parent.yavg(ii,jj,:),1,[]));
            end
            
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
            % Save the previous value
            oldSliderValue = round(get(this.sliderHandle,'Value'));
            oldSliderMax = this.sliderHandle.Max;

            % Reset the slider bounds
            newSliderMax = numel(this.Parent.tavg);
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
                if isempty(this.Parent.yavg)
                    this.Parent.averageSpectra();
                end
                plotcolor = [0,0,0];
                errorcolor = [0,0,0]+0.90;
                %h = plot(ax,obj.wavenum,reshape(obj.yavg(:,:,ind),[],1),'Color',plotcolor); hold(ax,'on');
                this.herrorplus = plot(this.axesHandle,this.Parent.wavenum(:),reshape(this.Parent.yavg(:,:,ind)+this.Parent.ystderror(:,:,ind),[],1),'Color',errorcolor);hold(this.axesHandle,'on');
                this.herrorminus = plot(this.axesHandle,this.Parent.wavenum(:),reshape(this.Parent.yavg(:,:,ind)-this.Parent.ystderror(:,:,ind),[],1),'Color',errorcolor);
                this.h = plot(this.axesHandle,this.Parent.wavenum(:),reshape(this.Parent.yavg(:,:,ind),[],1),'Color',plotcolor);
                hold(this.axesHandle,'off');

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
            
            if isempty(this.Parent.t)
                set(this.plotHandle,'XData',NaN);
                set(this.plotHandle,'YData',NaN);
                title(this.axesHandle,'No Spectra');
                this.noImageBoolean = true;
            else
                if this.noImageBoolean == true
                    this.imagePlot();
                elseif isempty(this.Parent.yavg)
                    this.Parent.averageSpectra();
                end
                
                if isempty(this.options)
                    set(this.h,'XData',this.Parent.wavenum(:));
                    set(this.h,'YData',reshape(this.Parent.yavg(:,:,ind),[],1));
                    set(this.herrorplus,'XData',this.Parent.wavenum(:));
                    set(this.herrorplus,'YData',reshape(this.Parent.yavg(:,:,ind)+this.Parent.ystderror(:,:,ind),[],1));
                    set(this.herrorminus,'XData',this.Parent.wavenum(:));
                    set(this.herrorminus,'YData',reshape(this.Parent.yavg(:,:,ind)-this.Parent.ystderror(:,:,ind),[],1));
                elseif strcmp(this.options,'fft')
                    gridx = linspace(min(this.Parent.wavenum(:)),max(this.Parent.wavenum(:)),10000);
                    ynonnan = reshape(this.Parent.yavg(:,:,ind),[],1);
                    ynonnan(isnan(ynonnan)) = 0;
                    gridy = interp1(this.Parent.wavenum(:),ynonnan,gridx);
                    yfft = abs(fft(gridy));
                    yfft = yfft(1:numel(yfft)/2);
                    Lmax = 1/4/(gridx(2)-gridx(1));
                    xfft = linspace(0,Lmax,5000);
                    set(this.h,'XData',xfft);
                    set(this.h,'YData',yfft);
                    set(this.herrorplus,'XData',[]);
                    set(this.herrorplus,'YData',[]);
                    set(this.herrorminus,'XData',[]);
                    set(this.herrorminus,'YData',[]);
                elseif strcmp(this.options,'interp')
                    gridx = linspace(min(this.Parent.wavenum(:)),max(this.Parent.wavenum(:)),10000);
                    ynonnan = reshape(this.Parent.yavg(:,:,ind),[],1);
                    ynonnan(isnan(ynonnan)) = 0;
                    gridy = interp1(this.Parent.wavenum(:),ynonnan,gridx);
                    set(this.h,'XData',gridx);
                    set(this.h,'YData',gridy);
                    set(this.herrorplus,'XData',[]);
                    set(this.herrorplus,'YData',[]);
                    set(this.herrorminus,'XData',[]);
                    set(this.herrorminus,'YData',[]);
                end
                title(this.axesHandle,sprintf('T = %i us',this.Parent.tavg(ind)));
            end
        end
    end
end
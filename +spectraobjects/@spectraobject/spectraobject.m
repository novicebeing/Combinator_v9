classdef spectraobject < handle
    %kineticsobject
    
    properties
        name;
        
        % DOCO-specific constants
        integrationTime;
        DOCOtemplateNames;
        DOCOtemplateAvg;
        DOCOtemplateError;
        fPhot;
        O3conc;
        D2conc;
        COconc;
        Heconc;
        N2conc;
        
        % Raw spectrum input
            t;
            wavenum;
            ysum; % Sum of y/sigma^2
            wsum; % Sum of 1/sigma^2
            ybaseline;
            deltay;
            
        % Template Spectra
            templateNames;
            templateAvg;
            templateError;
        
        yWavenumRef;
        lognames;
        logvalues;
        
        % Spectrum average parameters
            tavg;
            yavg;
            ystderror;
        
        datatipPosition;
        datatipPositions;
        
        gaussianTemplatePosition;
        gaussianTemplateFWHM;
        
        gaussianTemplateParams;
    end
    
    methods
        function obj = spectraobject(varargin)
            if nargin > 0
                filename = varargin{1};
            else
                filename = [];
            end
            if ischar(filename)
                if strcmp(filename,'gui')
                    [filename,filepath] = uigetfile;
                    data = load(fullfile(filepath,filename),'-mat');
                else
                    data = load(filename,'-mat');
                end
                obj.wavenum = data.wavenum;
                obj.ysum = data.ysum;
                obj.wsum = data.wsum;
                obj.deltay = zeros(size(data.ysum));
                obj.t = data.t;
                obj.yWavenumRef = [];
                obj.lognames = {};
                obj.logvalues = [];
                return
            end
            obj.wavenum = [];
            obj.ysum = [];
            obj.wsum = [];
            obj.yWavenumRef = [];
            obj.t = [];
            obj.lognames = {};
            obj.logvalues = [];
        end
        function obj = addSpectrum(obj,specWavenum,specY,t)
            if ndims(specWavenum) > 2 || ndims(specY) > 2
               error('Too many dimensions'); 
            end
            if isempty(obj.wavenum)
                obj.wavenum = specWavenum;
            elseif obj.wavenum ~= specWavenum
                error();
            end
            if isempty(obj.y)
                obj.y = specY;
            else
                obj.y(:,:,end+1) = specY;
            end
            obj.t(end+1) = t;
        end
        function obj = averageSpectra(obj)
            %# unique values in B, and their indices
            [obj.tavg,~,subs] = unique(obj.t);
            
%             if size(subs,1) == 1
%                 subscell = {};
%                 for i = 1:numel(obj.t)
%                     subscell{i} = i;
%                 end
%             else
                subscell = accumarray(reshape(subs,[],1), reshape(1:numel(obj.t),[],1), [], @(x) {x});
%             end
            
            obj.yavg = zeros(size(obj.ysum,1),size(obj.ysum,2),numel(obj.tavg));
            for i = 1:numel(subscell)
                sub = subscell{i};
                ysum = zeros([size(obj.ysum,1) size(obj.ysum,2)]);
                wsum = zeros([size(obj.ysum,1) size(obj.ysum,2)]);
                for j = 1:numel(sub)
                	ysum = ysum + obj.ysum(:,:,sub(j));
                    wsum = wsum + obj.wsum(:,:,sub(j));
                end
                obj.yavg(:,:,i) = ysum./wsum;
                obj.ystderror(:,:,i) = sqrt(1./wsum);
            end
        end
        function [h,herrorplus,herrorminus] = plot(obj,ax,ind,options)
            if isempty(obj.yavg)
                obj.averageSpectra();
            end
            plotcolor = [0,0,0];
            errorcolor = [0,0,0]+0.90;
            %h = plot(ax,obj.wavenum,reshape(obj.yavg(:,:,ind),[],1),'Color',plotcolor); hold(ax,'on');
            herrorplus = plot(ax,obj.wavenum(:),reshape(obj.yavg(:,:,ind)+obj.ystderror(:,:,ind),[],1),'Color',errorcolor);hold(ax,'on');
            herrorminus = plot(ax,obj.wavenum(:),reshape(obj.yavg(:,:,ind)-obj.ystderror(:,:,ind),[],1),'Color',errorcolor);
            h = plot(ax,obj.wavenum(:),reshape(obj.yavg(:,:,ind),[],1),'Color',plotcolor);
            hold(ax,'off');
            
            if strcmp(options,'fft')
                xlabel(ax,'Etalon Length [cm]');
                ylabel(ax,'FFT Amplitude');
            else
                xlabel(ax,'Wavenumber [1/cm]');
                ylabel(ax,'Absorbance');
            end
        end
        function [h,herrorplus,herrorminus] = plotall(obj,ax,ind)
            h = plot(ax,obj.wavenum(:),reshape(obj.ysum(:,:,ind)./obj.wsum(:,:,ind),[],1)); hold(ax,'on');
            herrorplus = plot(ax,obj.wavenum(:),reshape(obj.ysum(:,:,ind)./obj.wsum(:,:,ind)+1./sqrt(obj.wsum(:,:,ind)),[],1));
            herrorminus = plot(ax,obj.wavenum(:),reshape(obj.ysum(:,:,ind)./obj.wsum(:,:,ind)-1./sqrt(obj.wsum(:,:,ind)),[],1));
            hold(ax,'off');
        end
        function h = updatePlot(obj,ax,h,herrorplus,herrorminus,ind,options)
            if isempty(obj.yavg)
                obj.averageSpectra();
            end
            if isempty(options)
                set(h,'XData',obj.wavenum(:));
                set(h,'YData',reshape(obj.yavg(:,:,ind),[],1));
                set(herrorplus,'XData',obj.wavenum(:));
                set(herrorplus,'YData',reshape(obj.yavg(:,:,ind)+obj.ystderror(:,:,ind),[],1));
                set(herrorminus,'XData',obj.wavenum(:));
                set(herrorminus,'YData',reshape(obj.yavg(:,:,ind)-obj.ystderror(:,:,ind),[],1));
            elseif strcmp(options,'fft')
                gridx = linspace(min(obj.wavenum),max(obj.wavenum),10000);
                ynonnan = reshape(obj.yavg(:,:,ind),[],1);
                ynonnan(isnan(ynonnan)) = 0;
                gridy = interp1(obj.wavenum,ynonnan,gridx);
                yfft = abs(fft(gridy));
                yfft = yfft(1:numel(yfft)/2);
                Lmax = 1/4/(gridx(2)-gridx(1));
                xfft = linspace(0,Lmax,5000);
                set(h,'XData',xfft);
                set(h,'YData',yfft);
                set(herrorplus,'XData',[]);
                set(herrorplus,'YData',[]);
                set(herrorminus,'XData',[]);
                set(herrorminus,'YData',[]);
            elseif strcmp(options,'interp')
                gridx = linspace(min(obj.wavenum),max(obj.wavenum),10000);
                ynonnan = reshape(obj.yavg(:,:,ind),[],1);
                ynonnan(isnan(ynonnan)) = 0;
                gridy = interp1(obj.wavenum,ynonnan,gridx);
                set(h,'XData',gridx);
                set(h,'YData',gridy);
                set(herrorplus,'XData',[]);
                set(herrorplus,'YData',[]);
                set(herrorminus,'XData',[]);
                set(herrorminus,'YData',[]);
            end
            title(ax,sprintf('T = %i us',obj.tavg(ind)));
        end
        function h = updatePlotAll(obj,ax,h,herrorplus,herrorminus,ind)
            set(h,'XData',obj.wavenum);
            set(h,'YData',reshape(obj.ysum(:,:,ind)./obj.wsum(:,:,ind),[],1));
            set(herrorplus,'XData',obj.wavenum);
            set(herrorplus,'YData',reshape(obj.ysum(:,:,ind)./obj.wsum(:,:,ind)+1./sqrt(obj.wsum(:,:,ind)),[],1));
            set(herrorminus,'XData',obj.wavenum);
            set(herrorminus,'YData',reshape(obj.ysum(:,:,ind)./obj.wsum(:,:,ind)-1./sqrt(obj.wsum(:,:,ind)),[],1));
            title(ax,sprintf('Spectrum Number %i',ind));
        end
        function h = plotbrowserall(obj)
            if isempty(obj.name)
                hf = figure;
            else
                hf = figure('Name',obj.name,'NumberTitle','off');
            end
            cursorMode = datacursormode(hf);
            set(cursorMode,'UpdateFcn',@(o,e) obj.datatipUpdateFunction(o,e));
            ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
            axmenu = uicontextmenu(hf);
            ax.UIContextMenu = axmenu;
            
            [hp,hplus,hminus] = obj.plotall(ax,1);
            obj.updatePlotAll(ax,hp,hplus,hminus,round(1))
            b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(obj.t),'sliderstep',[1/numel(obj.t) 10/numel(obj.t)]);
            b.Callback = @(es,ed) obj.updatePlotAll(ax,hp,hplus,hminus,round(es.Value));
            %uimenu('Parent',axmenu,'Label','Plot Data Cursor Peak','Callback',@(s,e) obj.plotDataCursorPeak());
            %uimenu('Parent',axmenu,'Label','Fit Gaussian Template to Cursor Peak','Callback',@(s,e) obj.plotDataCursorPeakGaussian(ax,b));
            %uimenu('Parent',axmenu,'Label','Fit All Using Template','Callback',@(s,e) obj.fitAllUsingTemplate(ax));
        end
        function hf = plotbrowser(obj,varargin)
            if isempty(obj.name)
                hf = figure;
            else
                hf = figure('Name',obj.name,'NumberTitle','off');
            end
            cursorMode = datacursormode(hf);
            set(cursorMode,'UpdateFcn',@(o,e) obj.datatipUpdateFunction(o,e));
            ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
            axmenu = uicontextmenu();
            set(ax,'UIContextMenu',axmenu);
            
            % Set plot options
            if nargin == 2
                options = varargin{1};
            else
                options = '';
            end
            
            [hp,hplus,hminus] = obj.plot(ax,1,options);
            obj.updatePlot(ax,hp,hplus,hminus,round(1),options);
            b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(obj.tavg),'sliderstep',[1/numel(obj.tavg) 10/numel(obj.tavg)]);
            set(b,'Callback',@(es,ed) obj.updatePlot(ax,hp,hplus,hminus,round(get(es,'Value')),options));
            if strcmp(options,'fft')
                uimenu('Parent',axmenu,'Label','Zero Brushed Etalons','Callback',@(s,e) obj.zeroBrushedEtalons(ax,hp,hplus,hminus,b,options));
                uimenu('Parent',axmenu,'Label','Reset Spectra','Callback',@(s,e) obj.resetSpectra(ax,hp,hplus,hminus,b,options));
                uimenu('Parent',axmenu,'Label','Plot Browser','Callback',@(s,e) obj.plotbrowser());
            else
                uimenu('Parent',axmenu,'Label','Save As...','Callback',@(s,e) obj.savegui());
                uimenu('Parent',axmenu,'Label','Generate DOCO Experiment Report','Callback',@(s,e) obj.performDOCOTemplateFit());
                uimenu('Parent',axmenu,'Label','Copy Current Spectrum to Clipboard','Callback',@(s,e) obj.copyCurrentSpectrum(hp,b));
                uimenu('Parent',axmenu,'Label','Add Template Spectrum from Clipboard','Callback',@(s,e) obj.addTemplateSpectrumFromClipboard());
                uimenu('Parent',axmenu,'Label','FFT Plot Browser','Callback',@(s,e) obj.plotbrowser('fft'));
                uimenu('Parent',axmenu,'Label','Add This Spectrum as Template','Callback',@(s,e) obj.addTemplateSpectrumFromPlotBrowser(b));
                uimenu('Parent',axmenu,'Label','Clear Spectrum Templates','Callback',@(s,e) obj.clearSpectrumTemplatesFromPlotBrowser());
                uimenu('Parent',axmenu,'Label','Perform Template Fit','Callback',@(s,e) obj.performTemplateFit());
                uimenu('Parent',axmenu,'Label','Plot Data Cursor Peak','Callback',@(s,e) obj.plotDataCursorPeak());
                uimenu('Parent',axmenu,'Label','Fit Gaussian Template to Cursor Peak','Callback',@(s,e) obj.plotDataCursorPeakGaussian(ax,b));
                uimenu('Parent',axmenu,'Label','Fit All Using Template','Callback',@(s,e) obj.fitAllUsingTemplate(ax));
                uimenu('Parent',axmenu,'Label','Add Datatip Position','Callback',@(s,e) obj.addDatatipPosition());
                uimenu('Parent',axmenu,'Label','Reset Datatip Positions','Callback',@(s,e) obj.resetDatatipPositions());
                uimenu('Parent',axmenu,'Label','Fit Gaussian Template to Cursor Peaks','Callback',@(s,e) obj.plotDataCursorPeakGaussians(ax,b));
                uimenu('Parent',axmenu,'Label','Fit All Using Template Peaks','Callback',@(s,e) obj.fitAllUsingTemplatePeaks(ax));
            end
            
            % Force figure menubar
            set( hf, 'menubar', 'figure' );
        end
        function savegui(obj)
            % Get save path
            [filename,filepath] = uiputfile('*.mat','Save Spectra As...');
            
            if ~isequal(filename,0) && ~isequal(filepath,0)
                obj.savedata(fullfile(filepath,filename));
            end
        end
        function zeroBrushedEtalons(obj,ax,hp,hplus,hminus,sliderobj,options)
            % Extract the brushed data
            brusheddata = get(hp,'BrushData');
            brushedIdcs = find(brusheddata);
            x = get(hp,'XData');
            
            % Create etalon windows
            etalonmin = reshape(x(brushedIdcs)-0.005,[],1);
            etalonmax = reshape(x(brushedIdcs)+0.005,[],1);
            
            % Zero the etalons
            obj.etalonRemove([etalonmin etalonmax]);
            
            % Update the plot
            obj.updatePlot(ax,hp,hplus,hminus,round(get(sliderobj,'Value')),options)
        end
        function copyCurrentSpectrum(obj,hp,sliderobj)
            % Idx
            idx = round(get(sliderobj,'Value'));
            
            x = reshape(obj.wavenum,size(obj.yavg,1),size(obj.yavg,2));
            y = obj.yavg(:,:,idx);
            deltay = obj.ystderror(:,:,idx);
            
            % Extract the brushed data
            brusheddata = get(hp,'BrushData');
            if ~isempty(brusheddata) && nansum(brusheddata)>0
                brushedIdcs = find(brusheddata);
                y(~brusheddata) = NaN;
                deltay(~brusheddata) = NaN;
            end
            
            % Assign to 'clipboardContents' in base workspace
            assignin('base', 'clipboardContents', cat(3,x,y,deltay));
        end
        function pasteSpectrumAtTime(obj,sliderobj)
            x = reshape(obj.wavenum,[],1);
            y = reshape(obj.yavg(:,:,idx),[],1);
            deltay = reshape(obj.ystderror(:,:,idx),[],1);
            clipboard('copy',cat(2,x,y,deltay));
        end
        function resetSpectra(obj,ax,hp,hplus,hminus,sliderobj,options)
            % Re-average the spectra
            obj.averageSpectra();
            
            % Update the plot
            obj.updatePlot(ax,hp,hplus,hminus,round(get(sliderobj,'Value')),options)
        end
        function addDatatipPosition(obj)
            nPositions = size(obj.datatipPositions,2);
            obj.datatipPositions(:,nPositions+1) = obj.datatipPosition;
        end
        function resetDatatipPositions(obj)
            obj.datatipPositions = [];
        end
        function output_txt = datatipUpdateFunction(obj,evobj,event_obj)
            % Display the position of the data cursor
            % obj          Currently not used (empty)
            % event_obj    Handle to event object
            % output_txt   Data cursor text string (string or cell array of strings).

            pos = get(event_obj,'Position');
            output_txt = {['X: ',num2str(pos(1),8)],...
                ['Y: ',num2str(pos(2),8)]};

            % If there is a Z-coordinate in the position, display it as well
            if length(pos) > 2
                output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
            end
            
            obj.datatipPosition = pos;
        end
        function plotDataCursorPeak(obj)
            if isempty(obj.datatipPosition)
                return
            end
            idx = find(obj.wavenum == obj.datatipPosition(1));
            
            [i,j] = ind2sub([size(obj.y,1) size(obj.y,2)],idx(1));
            figure;errorbar(obj.tavg,reshape(obj.yavg(i,j,:),[],1),reshape(obj.ystderror(i,j,:),[],1),'k.');
        end
        function fitAllUsingTemplate(obj,ax)
            idx = find(obj.wavenum == obj.datatipPosition(1));
            
            peakValues = zeros(size(obj.tavg));
            peakValueErrors = zeros(size(obj.tavg));
            for i = 1:size(obj.yavg,3)
                xlimits = get(ax,'XLim');
                fitIdx = obj.wavenum > min(xlimits) & obj.wavenum < max(xlimits);
                xs = obj.wavenum(fitIdx);
                yy = reshape(obj.yavg(:,:,i),[],1);
                ys = yy(fitIdx);
                
                G = @(FWHM,x0,x) exp(-(x-x0).^2/(FWHM/sqrt(2*log(2))/2)^2/2)/(FWHM/sqrt(2*log(2))/2)/sqrt(2*pi);
                fun = @(params,x) params(1)*G(obj.gaussianTemplateFWHM,obj.gaussianTemplatePosition,x-params(7)) + params(2) + params(3)*(x-min(x))./(max(x)-min(x)) + params(4)*((x-min(x))./(max(x)-min(x))).^2 + params(5)*((x-min(x))./(max(x)-min(x))).^3 + params(6)*((x-min(x))./(max(x)-min(x))).^4;
                params0 = [max(ys)/30 0 0 0 0 0 0];
                if sum(isnan(ys)) > 0.5*numel(ys)
                    peakValues(i) = NaN;
                    peakValueErrors(i) = NaN;
                else
                    [params,R,J] = nlinfit(xs,ys,fun,params0);
                    peakValues(i) = params(1);
                    ci = nlparci(params,R,'jacobian',J);
                    peakValueErrors(i) = (ci(1,1)-ci(1,2))/2;
                end
            end
            
            figure;errorbar(obj.tavg,peakValues,peakValueErrors,'k.');
            xlabel('Time [\mus]');
            ylabel('Integrated Absorbance');
            title(sprintf('Single Peak Fit: [%g]',round(obj.gaussianTemplatePosition*100)/100));
        end
        function fitAllUsingTemplatePeaks(obj,ax)
            
            peakValues = zeros(size(obj.tavg));
            peakValueErrors = zeros(size(obj.tavg));
            for i = 1:size(obj.yavg,3)
                xlimits = get(ax,'XLim');
                fitIdx = obj.wavenum > min(xlimits) & obj.wavenum < max(xlimits);
                xs = obj.wavenum(fitIdx);
                yy = reshape(obj.yavg(:,:,i),[],1);
                ys = yy(fitIdx);
                
                npeaks = numel(obj.gaussianTemplateParams)/3;
                templateParams = obj.gaussianTemplateParams;
                templateArray = obj.multiGaussian(templateParams(1:npeaks),templateParams((npeaks+1):(2*npeaks)),templateParams((2*npeaks+1):(3*npeaks)),xs)./sum(templateParams(1:npeaks));
                fun = @(params,x) params(1)*templateArray + params(2) + params(3)*(x-min(x))./(max(x)-min(x)) + params(4)*((x-min(x))./(max(x)-min(x))).^2 + params(5)*((x-min(x))./(max(x)-min(x))).^3 + params(6)*((x-min(x))./(max(x)-min(x))).^4;
                params0 = [1 0 0 0 0 0];
                params = nlinfit(xs,ys,fun,params0);
                if sum(isnan(ys)) > 0.5*numel(ys)
                    peakValues(i) = NaN;
                    peakValueErrors(i) = NaN;
                else
                    [params,R,J] = nlinfit(xs,ys,fun,params0);
                    peakValues(i) = params(1);
                    ci = nlparci(params,R,'jacobian',J);
                    peakValueErrors(i) = (ci(1,1)-ci(1,2))/2;
                end
            end
            
            figure;errorbar(obj.tavg,peakValues,peakValueErrors,'k.');
            xlabel('Time [\mus]');
            ylabel('Integrated Absorbance');
            title(sprintf('Multi Peak Fit: [%s]',sprintf('%g ',round(templateParams((npeaks+1):(2*npeaks))*100)/100)));
        end
        
        function obj = etalonRemove(obj,etalonWindows)
            for i = 1:size(obj.yavg,3)
                obj.etalonRemoveOneSpec(etalonWindows,i);
            end
        end
        function obj = etalonRemoveOneSpec(obj,etalonWindows,ind)
            if size(etalonWindows,2) ~= 2
                error('improper dimensions');
            end
            gridx = linspace(min(obj.wavenum),max(obj.wavenum),10000);
            ynonnan = reshape(obj.yavg(:,:,ind),[],1);
            ynonnan(isnan(ynonnan)) = 0;
            gridy = interp1(obj.wavenum,ynonnan,gridx);
            yfft = fft(gridy);
            Lmax = 1/4/(gridx(2)-gridx(1));
            xfft = linspace(0,Lmax,5000);
            
            % Set the etalons to zero
            yetalonsfft = zeros(size(yfft));
            for i = 1:size(etalonWindows,1)
                ind2 = find(xfft > etalonWindows(i,1) & xfft < etalonWindows(i,2));
                yetalonsfft([ind2 numel(yfft)-ind2+1]) = yfft([ind2 numel(yfft)-ind2+1]);
            end
            
            % Get the etalons
            yetalons = ifft(yetalonsfft);
            yetalonsinterp = interp1(gridx,real(yetalons),obj.wavenum);
            yetalonsinterp = reshape(yetalonsinterp,size(obj.yavg,1),size(obj.yavg,2));
            
            % Subtract the etalons
            obj.yavg(:,:,ind) = obj.yavg(:,:,ind) - yetalonsinterp;
        end
        function plotDataCursorPeakGaussian(obj,ax,sliderobj)
            if isempty(obj.datatipPosition)
                return
            end
            specnum = round(get(sliderobj,'Value'));
            xlimits = get(ax,'XLim');
            fitIdx = obj.wavenum > min(xlimits) & obj.wavenum < max(xlimits);
            xs = obj.wavenum(fitIdx);
            yy = reshape(obj.yavg(:,:,specnum),[],1);
            ys = yy(fitIdx);
            
            figure;plot(xs,ys);hold on;
            
            G = @(FWHM,x0,x) exp(-(x-x0).^2/(FWHM/sqrt(2*log(2))/2)^2/2)/(FWHM/sqrt(2*log(2))/2)/sqrt(2*pi);
            fun = @(params,x) params(1)*G(params(3),params(2),x) + params(4) + params(5)*(x-min(x))./(max(x)-min(x)) + params(6)*((x-min(x))./(max(x)-min(x))).^2 + params(7)*((x-min(x))./(max(x)-min(x))).^3 + params(8)*((x-min(x))./(max(x)-min(x))).^4;
            params0 = [max(ys)/30 obj.datatipPosition(1) (max(xs)-min(xs))/10 0 0 0 0 0];

            params = nlinfit(xs,ys,fun,params0);
            plot(xs,fun(params,xs),'g');
            obj.gaussianTemplatePosition = params(2);
            obj.gaussianTemplateFWHM = params(3);
        end
        function plotDataCursorPeakGaussians(obj,ax,sliderobj)
            if isempty(obj.datatipPositions)
                return
            else
                obj.datatipPositions
            end
            specnum = round(get(sliderobj,'Value'));
            xlimits = get(ax,'XLim');
            fitIdx = obj.wavenum > min(xlimits) & obj.wavenum < max(xlimits);
            xs = obj.wavenum(fitIdx);
            yy = reshape(obj.yavg(:,:,specnum),[],1);
            ys = yy(fitIdx);
            
            figure;plot(xs,ys);hold on;
            
            npeaks = size(obj.datatipPositions,2);
            fun = @(params,x) obj.multiGaussian(params(1:npeaks),params((npeaks+1):(2*npeaks)),params((2*npeaks+1):(3*npeaks)),x) + params(3*npeaks+1) + params(3*npeaks+2)*(x-min(x))./(max(x)-min(x)) + params(3*npeaks+3)*((x-min(x))./(max(x)-min(x))).^2 + params(3*npeaks+4)*((x-min(x))./(max(x)-min(x))).^3 + params(3*npeaks+5)*((x-min(x))./(max(x)-min(x))).^4;
            params0 = [repmat(max(ys)/30,1,npeaks) reshape(obj.datatipPositions(1,:),1,[]) repmat((max(xs)-min(xs))/10,1,npeaks) 0 0 0 0 0];

            params = nlinfit(xs,ys,fun,params0);
            plot(xs,fun(params,xs),'g');
            hold on; plot(xs,fun(params0,xs),'r');
            obj.gaussianTemplateParams = params(1:(3*npeaks));
        end
        
        function y = multiGaussian(~,as,x0s,FWHMs,x)
            G = @(FWHM,x0,x) exp(-(x-x0).^2/(FWHM/sqrt(2*log(2))/2)^2/2)/(FWHM/sqrt(2*log(2))/2)/sqrt(2*pi);
            y = zeros(size(x));
            for i = 1:numel(x0s)
                y = y + as(i)*G(FWHMs(i),x0s(i),x);
            end
        end
        
        function savedata(obj,filename)
            wavenum = obj.wavenum;
            ysum = obj.ysum;
            wsum = obj.wsum;
            t = obj.t;
            save(filename,'wavenum','ysum','wsum','t');
        end
    end
end


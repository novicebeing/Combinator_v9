classdef VIPAxaxis < handle
    %kineticsobject
    
    properties
        % 
        title;

		% Plot axes
		axExp;
		hExp;
		
        % Spectrum Parameters
        yIn;

        % Line Paramters
        linePositions;
        lineHeights;

        % Selected Line Parameters
        linePositionsSim;
        lineHeightsSim;
        
        % Fitted Parameters
        xaxisParams; % Struct containing wavenum parameters
        

        % Simulation Parameters
        wavenumSim;
        crossSectionSim;
    end
    
    methods
        function obj = VIPAxaxis(centerWavenum,vertPoly,horizPoly,yIn)
            obj.xaxisParams = struct();
            obj.xaxisParams.centerWavenum = centerWavenum;
            obj.xaxisParams.vertPoly = vertPoly;
            obj.xaxisParams.horizPoly = horizPoly;
            obj.yIn = yIn;
        end

        function obj = setSimulationSpectrum(obj,wavenum,crossSection)
            obj.wavenumSim = wavenum;
            obj.crossSectionSim = crossSection;
        end

        function hf = fitbrowser(obj,varargin)
            if isempty(obj.title)
                hf = figure;
            else
                hf = figure('Name',obj.title,'NumberTitle','off');
            end
            cursorMode = datacursormode(hf);
            set(cursorMode,'UpdateFcn',@(o,e) obj.datatipUpdateFunction(o,e));
            axExp = subplot(2,1,1);
            axSim = subplot(2,1,2);
            linkaxes([axExp,axSim],'x');
            axmenu = uicontextmenu();
            set(axExp,'UIContextMenu',axmenu);
			
            hSim = obj.plotSim(axSim);
            obj.updatePlotSim(axSim,hSim);

            hold(axSim,'on');
            hSimSelect = obj.plotSimSelect(axSim);hold(axSim,'off');
            obj.updatePlotSimSelect(axSim,hSimSelect);

            hExpStem = obj.plotExpStem(axExp);
            obj.updatePlotExpStem(axExp,hExpStem);

            hold(axExp,'on');
            hExp = obj.plotExp(axExp);hold(axExp,'off');
            obj.updatePlotExp(axExp,hExp);
			
            % Set axes and stuff
			obj.axExp = axExp;
			obj.hExp = hExp;
            
            uimenu('Parent',axmenu,'Label','Weighted Mean of Brushed Points','Callback',@(s,e) obj.weightedMeanOfBrushedPoints(axExp,hExp,hExpStem));
            uimenu('Parent',axmenu,'Label','Auto Select Peaks','Callback',@(s,e) obj.autoSelectPeaksGUI(axExp,hExp,hExpStem));
            uimenu('Parent',axmenu,'Label','Find Corresponding Peaks','Callback',@(s,e) obj.findCorrespondingPeaksGUI(axSim,hSimSelect));
            uimenu('Parent',axmenu,'Label','Fit the Peaks','Callback',@(s,e) obj.fitYaxisGUI(axExp,hExp,hExpStem));
            uimenu('Parent',axmenu,'Label','Fit the Lineshape','Callback',@(s,e) obj.fitLineshape(axExp,hExp,hExpStem));

			% Load icons
			load(cat(2,fileparts(which('spectraobjects.VIPAxaxis')),'\Icons.mat'));
			
			ht = uitoolbar(hf);
			uipushtool(ht,'CData',icons.leftIcon,...
					 'TooltipString','Shift Frequency Left',...
					 'ClickedCallback',...
					 @obj.fitFrequencyAxisFigureShiftLeft);
			uipushtool(ht,'CData',icons.setWavelengthIcon,...
					 'TooltipString','Set Reference Wavelength',...
					 'ClickedCallback',...
					 @obj.fitFrequencyAxisFigureShiftSet);
			uipushtool(ht,'CData',icons.rightIcon,...
					 'TooltipString','Shift Frequency Right',...
					 'ClickedCallback',...
					 @obj.fitFrequencyAxisFigureShiftRight);
			uipushtool(ht,'CData',icons.peakPickIcon,...
					 'TooltipString','Start Peak Picker',...
					 'ClickedCallback',...
					 @obj.pickPeak);
			uipushtool(ht,'CData',icons.peakPickIcon,...
					 'TooltipString','Clear Picked Peaks',...
					 'ClickedCallback',...
					 @obj.clearPeaks);
			
            % Force figure menubar
            set( hf, 'menubar', 'figure' );
        end
		function fitFrequencyAxisFigureShiftSet(self,hObject,eventdata)
            x = inputdlg({'Enter spectrum center wavenumber [cm-1]:','Enter Horiz span [cm-1]:','Enter Vert span [cm-1]:'}, 'Set Spectrum Center Wavenumber', [1 50],...
                {num2str(self.xaxisParams.centerWavenum),num2str(self.xaxisParams.horizPoly(1)),num2str(self.xaxisParams.vertPoly(1))});
            self.xaxisParams.centerWavenum = str2double(x{1});
			self.xaxisParams.horizPoly(:) = 0;
			self.xaxisParams.vertPoly(:) = 0;
			self.xaxisParams.horizPoly(1) = str2double(x{2});
			self.xaxisParams.vertPoly(1) = str2double(x{3});
            self.updatePlotExp(self.axExp, self.hExp);
		end
        function fitLineshape(obj,axExp,hExp,hExpStem)
            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            y = obj.yIn;
            xx = interp1(1:numel(x),x(:),obj.linePositions);

            betas = zeros(4,numel(obj.linePositions));
            for i = 1:numel(obj.linePositions)
                fitx = x(abs(x-xx(i))<0.15)-xx(i);
                fity = y(abs(x-xx(i))<0.15);
                
                fitfun = @(beta,x) beta(1).*real(areaNormVoigt(x,0.0001,abs(beta(2))).*exp(1i.*beta(3)))+beta(4);
                beta0 = [1,0.02,0,0];
                [beta,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(fitx,fity,fitfun,beta0);
                betas(:,i) = beta;

                figure;plot(fitx,fity);
                hold on; plot(fitx,fitfun(beta,fitx));
            end
            figure;plot(abs(betas'));
            mean(betas(2,:),2)
            legend({'A','FWHM L','Phase','Offset'})
        end
        function autoSelectPeaks(obj)
            % Construct x axis
            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            minx = min(x(:));
            maxx = max(x(:));
            
            % Find candidate peaks
            peaksInWindow = obj.wavenumSim > minx & obj.wavenumSim < maxx;
            maxCrossSectionInWindow = max(obj.crossSectionSim(peaksInWindow));
            
            candidatePeakLocations = obj.wavenumSim(obj.crossSectionSim>maxCrossSectionInWindow/4 &...
                peaksInWindow);
            
            % Find the peaks and add them
            for i = 1:numel(candidatePeakLocations)
                % Find the max of the data within a 0.2 wavenum interval
                ind = find(abs(x - candidatePeakLocations(i)) < 0.20);
                y = reshape(obj.yIn,[],1);
                [~,indMaxRel] = max(y(ind));
                
                maxWavenum = x(ind(indMaxRel));
                
                brushedIdcs = find(abs(reshape(x,[],1) - maxWavenum) < 0.02);
                
                % Find the centroid of the peaks
                centroid = sum(brushedIdcs.*y(brushedIdcs))/sum(y(brushedIdcs));
                obj.linePositions(end+1) = centroid;
                obj.lineHeights(end+1) = interp1(brushedIdcs,y(brushedIdcs),centroid);
            end
        end
        function autoSelectPeaksGUI(obj,axExp,hExp,hExpStem)
            % Auto Select Peaks
            obj.autoSelectPeaks();
            
            % Update the plot
            obj.updatePlotExpStem(axExp,hExpStem);
        end
        function findCorrespondingPeaks(obj)
            obj.linePositionsSim = zeros(size(obj.linePositions));
            obj.lineHeightsSim = zeros(size(obj.linePositions));

            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            xx = interp1(1:numel(x),x(:),obj.linePositions);

            for i = 1:numel(obj.linePositions)
                ind = find(abs(obj.wavenumSim - xx(i))<0.05);
                if ~isempty(ind)
                    [~,indmax] = max(obj.crossSectionSim(ind));
                    obj.linePositionsSim(i) = obj.wavenumSim(ind(indmax));
                    obj.lineHeightsSim(i) = obj.crossSectionSim(ind(indmax));
                else
                    obj.linePositionsSim(i) = NaN;
                    obj.lineHeightsSim(i) = NaN;
                end
            end
        end
        function findCorrespondingPeaksGUI(obj,axSim,hSimSelect)
            % Find Corresponding Peaks
            obj.findCorrespondingPeaks();
        
            % Update plot
            obj.updatePlotSimSelect(axSim,hSimSelect);
        end
        function weightedMeanOfBrushedPoints(obj,axExp,hExp,hExpStem)
            % Extract the brushed data
            brusheddata = get(hExp,'BrushData');
            brushedIdcs = find(brusheddata);
            y = get(hExp,'YData');
            centroid = sum(brushedIdcs.*y(brushedIdcs))/sum(y(brushedIdcs));
            obj.linePositions(end+1) = centroid;
            obj.lineHeights(end+1) = interp1(brushedIdcs,y(brushedIdcs),centroid);
            
            % Update the plot
            obj.updatePlotExpStem(axExp,hExpStem);
        end
        function hExp = plotExp(obj, axExp)
            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            hExp = plot(axExp,reshape(x,[],1),reshape(obj.yIn,[],1));
            set(axExp,'XLim',[min(x(:)), max(x(:))]);
        end
        function hExpStem = plotExpStem(obj, axExp)
            hExpStem = stem(axExp,NaN,NaN,'Marker','none','Color','r','LineWidth',3,'ShowBaseline','off');
        end
        function hExp = updatePlotExp(obj, axExp, hExp)
            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            set(hExp,'XData',reshape(x,[],1));
            set(hExp,'YData',reshape(obj.yIn,[],1));
			xlim(axExp,[min(x(:)) max(x(:))])
        end
        function hExpStem = updatePlotExpStem(obj, axExp, hExpStem)
            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            xx = interp1(1:numel(x),x(:),obj.linePositions);
            yy = obj.lineHeights;
            if isempty(xx)
                xx = NaN;
                yy = NaN;
            end
            set(hExpStem,'XData',xx);
            set(hExpStem,'YData',yy);
        end
        function hSim  = plotSim(obj, axSim)
            hSim = stem(axSim,obj.wavenumSim,obj.crossSectionSim,'Marker','none');
        end
        function hSim  = updatePlotSim(obj, axSim, hSim)
            set(hSim,'XData',obj.wavenumSim);
            set(hSim,'YData',obj.crossSectionSim);
        end
        function hSimSelect  = plotSimSelect(obj, axSim)
            hSimSelect = stem(axSim,NaN,NaN,'Marker','none','Color','g','LineWidth',3);
        end
        function hSimSelect = updatePlotSimSelect(obj, axSim, hSimSelect)
            xx = obj.linePositionsSim;
            yy = obj.lineHeightsSim;
            if isempty(xx)
                xx = NaN;
                yy = NaN;
            end
            set(hSimSelect,'XData',xx);
            set(hSimSelect,'YData',yy);
        end
        function fitYaxis(obj)
            wavenumFun = @(b,x) interp1(1:numel(obj.yIn),reshape(obj.createWavenumAxis( b(1),b(2),b(3),size(obj.yIn)),[],1),x);
            
            beta0 = [obj.xaxisParams.centerWavenum obj.xaxisParams.vertPoly(1) obj.xaxisParams.horizPoly(1)];
            opts = statset('nlinfit');
            [beta,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(obj.linePositions,obj.linePositionsSim,wavenumFun,beta0,opts);

            % Set the relevant parameters
            obj.xaxisParams.centerWavenum = beta(1);
            obj.xaxisParams.vertPoly = beta(2);
            obj.xaxisParams.horizPoly = beta(3);
        end
        function [simPeaks,expPeaks] = compareSimExpPeaks(obj)
            x = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
            
            expPeaks = interp1(1:numel(x),reshape(x,[],1),obj.linePositions);
            simPeaks = obj.linePositionsSim;
        end
        function fitYaxisGUI(obj,axExp,hExp,hExpStem)
            % Fit Y axis
            obj.fitYaxis();

            % Update the plot
            obj.updatePlotExp(axExp, hExp);
            obj.updatePlotExpStem(axExp, hExpStem);
            %figure;scatter(1:numel(linePositions),wavenumFun(linePositions))
        end
        function wavenum = getWavenum(obj)
            wavenum = obj.createWavenumAxis( obj.xaxisParams.centerWavenum, obj.xaxisParams.vertPoly, obj.xaxisParams.horizPoly, size(obj.yIn) );
        end
    end
end


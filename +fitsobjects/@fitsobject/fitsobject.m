classdef fitsobject < handle
    %kineticsobject
    
    properties
        name;
        
        % Kinetics Fit Parameters
        wavenum;
        t;
        y;
        yError;
        fitM;
        fitb;
        fitbError;
        fitbNames;
        fitbNamesInd;
        
        % Kinetics Initial Conditions
        initialConditionsNames;
        initialConditionsValues;
    end
    properties (Transient = true, Hidden)
        plotHandles;
    end
    
    methods
        function obj = fitsobject(varargin)
%             if nargin > 0
%                 filename = varargin{1};
%             else
%                 filename = [];
%             end
%             if ischar(filename)
%                 if strcmp(filename,'gui')
%                     [filename,filepath] = uigetfile;
%                     data = load(fullfile(filepath,filename),'-mat');
%                 else
%                     data = load(filename,'-mat');
%                 end
%                 obj.wavenum = data.wavenum;
%                 obj.ysum = data.ysum;
%                 obj.wsum = data.wsum;
%                 obj.deltay = zeros(size(data.ysum));
%                 obj.t = data.t;
%                 obj.yWavenumRef = [];
%                 obj.lognames = {};
%                 obj.logvalues = [];
%                 [a,b] = fileparts(filename);
%                 obj.name = b;
%                 return
%             end
            obj.wavenum = [];
            obj.y = [];
            obj.yError = [];
            obj.t = [];
            obj.fitb = [];
            obj.fitbError = [];
            obj.fitbNames = {};
            obj.initialConditionsNames = {};
            obj.initialConditionsValues = [];
        end
        function delete(obj)
            % Remove deleted plot handles
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            
            for i = 1:numel(obj.plotHandles)
                delete(obj.plotHandles{i});
            end
        end
        function updatePlots(obj)
            % Remove deleted plot handles
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            
            for i = 1:numel(obj.plotHandles)
                obj.plotHandles{i}.Update();
            end
        end
        
        
        function [h,hfit,hresid] = plot(obj,ax,axbottom,ind,options)
            plotcolor = [0,0,0];
            fitcolor = 'r';
            h = plot(ax,obj.wavenum(:),reshape(obj.y(:,:,ind),[],1),'Color',plotcolor); hold(ax,'on');
            hfit = plot(ax,obj.wavenum(:),reshape(obj.fitM*obj.fitb(:,ind),[],1),'Color',fitcolor);hold(ax,'on');
            hold(ax,'off');
            
            if strcmp(options.plotMode,'fits+residuals')
                hresid = plot(axbottom,obj.wavenum(:),reshape(obj.y(:,:,ind),[],1)-reshape(obj.fitM*obj.fitb(:,ind),[],1));
                set(ax,'XTickLabel','');
                xlabel(axbottom,'Wavenumber [1/cm]');
                ylabel(ax,'Absorbance');
            else
                hresid = [];
                xlabel(ax,'Wavenumber [1/cm]');
                ylabel(ax,'Absorbance');
            end
        end
        function h = updatePlot(obj,ax,axbottom,h,hfit,hresid,ind,options)
            if ~isempty(h)
                set(h,'XData',obj.wavenum(:));
                set(h,'YData',reshape(obj.y(:,:,ind),[],1));
            end
            if ~isempty(hfit)
                set(hfit,'XData',obj.wavenum(:));
                set(hfit,'YData',reshape(obj.fitM*obj.fitb(:,ind),[],1));
            end
            if ~isempty(hresid)
                set(hresid,'XData',obj.wavenum(:));
                set(hresid,'YData',reshape(obj.y(:,:,ind),[],1)-reshape(obj.fitM*obj.fitb(:,ind),[],1));
            end
            title(ax,sprintf('T = %i us',obj.t(ind)));
        end
        
        function hf = plotbrowser(obj,varargin)
            if isempty(obj.name)
                hf = figure;
            else
                hf = figure('Name',obj.name,'NumberTitle','off');
            end
            cursorMode = datacursormode(hf);
            set(cursorMode,'UpdateFcn',@(o,e) obj.datatipUpdateFunction(o,e));
            
            % Check options input
            options = struct();
            if numel(varargin)>0
                options.plotMode = varargin{1};
            else
                options.plotMode = '';
            end
            
            if strcmp(options.plotMode,'fits+residuals')
                axbottom = axes('Parent',hf,'position',[0.13 0.20 0.79 0.36]);
                ax = axes('Parent',hf,'position',[0.13 0.60 0.79 0.36]);
            else
                ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
                axbottom = [];
            end
            axmenu = uicontextmenu();
            set(ax,'UIContextMenu',axmenu);
            
            [hp,hfit,hresid] = obj.plot(ax,axbottom,1,options);
            if strcmp(options.plotMode,'fits+residuals')
                linkaxes([ax,axbottom],'xy');
            end
            obj.updatePlot(ax,axbottom,hp,hfit,hresid,round(1),options);
            b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(obj.t),'sliderstep',[1/numel(obj.t) 10/numel(obj.t)]);
            set(b,'Callback',@(es,ed) obj.updatePlot(ax,axbottom,hp,hfit,hresid,round(get(es,'Value')),options));
            
            % Add Zoom, pan tools to the menu
            figmenu = uicontextmenu();
            set(b,'UIContextMenu',figmenu);
            toolsmenu = uimenu('Parent',figmenu,'Label','Tools');
            uimenu('Parent',toolsmenu,'Label','None','Callback',@(s,e) figuretoolsoff(hf));
            uimenu('Parent',toolsmenu,'Label','Zoom','Callback',@(s,e) zoom(hf,'on'));
            uimenu('Parent',toolsmenu,'Label','Pan','Callback',@(s,e) pan(hf,'on'));
            
            function figuretoolsoff(hf)
                zoom(hf,'off');
                pan(hf,'off');
            end
        end
%         function h = plotfitcoefficients(obj)
%             if isempty(obj.name)
%                 h = figure;
%             else
%                 h = figure('Name',obj.name,'NumberTitle','off');
%             end
%             for i = 1:numel(obj.fitbNames)
%                 ind = obj.fitbNamesInd(i);
%                 %errorbar(obj.t,obj.fitb(ind,:),obj.fitbError(ind,:),'o');
%                 plot(obj.t,obj.fitb(ind,:),'.-');
%                 hold on;
%             end
%             xlabel('Time [\mus]');
%             ylabel('Fit Coefficient');
%             %title(sprintf('Multi Peak Fit: [%s]',sprintf('%g ',round(templateParams((npeaks+1):(2*npeaks))*100)/100)));    
%             legend(obj.fitbNames);
%         end
        function hf = plotfitcoefficients(obj,varargin)
            % Set plot options
            if nargin == 2
                options = varargin{1};
            else
                options = '';
            end
            
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = fitsobjects.fitcoefficientsbrowser(obj,options);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {fitsobjects.fitcoefficientsbrowser(obj,options)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end
        function hf = openfitbrowserwithcolors(obj,varargin)
            % Set plot options
            if nargin == 2
                options = varargin{1};
            else
                options = '';
            end
            
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            if ~isempty(obj.plotHandles)
                n = numel(obj.plotHandles);
                obj.plotHandles{n+1} = fitsobjects.fitbrowserwithcolors(obj,options);
                hf = obj.plotHandles{n+1}.figureHandle;
            else
                obj.plotHandles = {fitsobjects.fitbrowserwithcolors(obj,options)};
                hf = obj.plotHandles{1}.figureHandle;
            end
        end
        function exportDOCOglobals(obj)
            global DOCOmodel_time
            global DOCOmodel_MoleculeConcs
            global DOCOmodel_MoleculeNames
            DOCOmodel_time = obj.t;
            DOCOmodel_MoleculeConcs = obj.fitb(obj.fitbNamesInd,:);
            DOCOmodel_MoleculeNames = obj.fitbNames;
        end
        function t = getTable(obj,groupID,pathlength)
            % Check the input arguments
            if ~isscalar(pathlength)
                error('Pathlength argument must be scalar');
            end
            if ~isscalar(groupID)
                error('groupID argument must be scalar');
            end
            
            % Get initial conditions
            tableDose = zeros(numel(obj.t),numel(obj.initialConditionsValues));
            tableDose(:) = NaN;
            zeroInd = find(obj.t == 0);
            if isempty(zeroInd)
                error('Need to handle no t=0 case...');
            end
            tableDose(zeroInd,:) = obj.initialConditionsValues(:);
            
            varNames1 = vipadesktop.makeVariableName(obj.fitbNames);
            varNames2 = vipadesktop.makeVariableName(obj.initialConditionsNames);
            varUnits = {};
            for i = 1:(numel(varNames1)+numel(varNames2))
                varUnits{end+1} = 'molecule';
            end
            
            % Construct a table with the values from the fits
            t = array2table([groupID.*ones(size(obj.t(:))) obj.t(:) obj.fitb(obj.fitbNamesInd,:)'/pathlength tableDose],'VariableNames',{'ID','time',varNames1{:},varNames2{:}});
            t.Properties.VariableUnits = {'','microsecond',varUnits{:}};
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
    end
end
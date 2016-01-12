classdef pgopherspectrumobject < handle
    % PGOPHER Spectrum object
    
    properties
        name;
        
        % PGOPHER Parameters
        pgopherfilepath;
    end
    
    methods
        function obj = kineticsfitobject(varargin)
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
        end
        function [h,hfit] = plot(obj,ax,ind,options)
            plotcolor = [0,0,0];
            fitcolor = 'r';
            h = plot(ax,obj.wavenum,reshape(obj.y(:,:,ind),[],1),'Color',plotcolor); hold(ax,'on');
            hfit = plot(ax,obj.wavenum,reshape(obj.fitM*obj.fitb(:,ind),[],1),'Color',fitcolor);hold(ax,'on');
            hold(ax,'off');
            
            xlabel(ax,'Wavenumber [1/cm]');
            ylabel(ax,'Absorbance');
        end
        function h = updatePlot(obj,ax,h,hfit,ind,options)
            set(h,'XData',obj.wavenum);
            set(h,'YData',reshape(obj.y(:,:,ind),[],1));
            set(hfit,'XData',obj.wavenum);
            set(hfit,'YData',reshape(obj.fitM*obj.fitb(:,ind),[],1));
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
            ax = axes('Parent',hf,'position',[0.13 0.20 0.79 0.72]);
            axmenu = uicontextmenu();
            set(ax,'UIContextMenu',axmenu);
            
            % Set plot options
            if nargin == 2
                options = varargin{1};
            else
                options = '';
            end
            
            [hp,hfit] = obj.plot(ax,1,options);
            obj.updatePlot(ax,hp,hfit,round(1),options);
            b = uicontrol('Parent',hf,'Style','slider','Position',[81,10,419,23],...
              'value',1, 'min',1, 'max',numel(obj.t),'sliderstep',[1/numel(obj.t) 10/numel(obj.t)]);
            set(b,'Callback',@(es,ed) obj.updatePlot(ax,hp,hfit,round(get(es,'Value')),options));
            
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
    end
end


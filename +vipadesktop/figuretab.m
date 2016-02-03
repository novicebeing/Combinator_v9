classdef figuretab < handle
   properties 
       vipadesktop
       TPComponent
       Panel
       MenuAndToolbarsSection
   end
   events
       OpenButtonPressed
   end
   methods
       function this = figuretab(vipadesktopobj)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceFigureTab', 'Figure');
            
            % Add Toolbar Section
            this.MenuAndToolbarsSection = toolpack.desktop.ToolSection('menuandtoolbars','Menu and Toolbars');
            panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow,2dlu,p:grow,2dlu,p:grow,2dlu,p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
            this.MenuAndToolbarsSection.add(panel);
            
            zoomInButton = vipadesktop.TSButton('Cursor',toolpack.component.Icon.SELECT_16);
            addlistener(zoomInButton,'ActionPerformed',@(~,~) cursorallplots());
            panel.add(zoomInButton,'xy(1,2)');
            zoomInButton = vipadesktop.TSButton('Zoom In',toolpack.component.Icon.ZOOM_IN_16);
            addlistener(zoomInButton,'ActionPerformed',@(~,~) zoomallplots());
            panel.add(zoomInButton,'xy(3,2)');
            zoomInButton = vipadesktop.TSButton('Zoom Out',toolpack.component.Icon.ZOOM_OUT_16);
            addlistener(zoomInButton,'ActionPerformed',@(~,~) zoomallplots());
            panel.add(zoomInButton,'xy(5,2)');
            panButton = vipadesktop.TSButton('Pan',toolpack.component.Icon.PAN_16);
            addlistener(panButton,'ActionPerformed',@(~,~) panallplots());
            panel.add(panButton,'xy(7,2)');
            datatipButton = vipadesktop.TSButton('Data Cursor',toolpack.component.Icon.EDIT);
            addlistener(datatipButton,'ActionPerformed',@(~,~) datacursormode);
            panel.add(datatipButton,'xy(9,2)');
            linkxaxesButton = vipadesktop.TSButton('Link X Axes',toolpack.component.Icon.EDIT);
            addlistener(linkxaxesButton,'ActionPerformed',@(~,~) linkxaxes());
            panel.add(linkxaxesButton,'xy(11,2)');
            
            % Add File Section
            this.TPComponent.add(this.MenuAndToolbarsSection);
            
            %this.TPComponent = toolpack.desktop.ToolSection('Plant',pidtool.utPIDgetStrings('cst','strPlant'));
            this.vipadesktop = vipadesktopobj;
            %this.layout();
       end
        function layout(this)
            %LAYOUT
            
            panel = toolpack.component.TSPanel('7px, f:p, 7px','5px, 12px, 2px, 20px, 4px, 22px');
            plantLabel = toolpack.component.TSLabel([pidtool.utPIDgetStrings('cst','strPlant') ':']);
            panel.add(plantLabel,'xywh(2,2,1,1)');
            %panel.add(this.PlantSelector.ButtonTPComponent,'xywh(2,4,1,1)');
            this.InspectPlantButton = toolpack.component.TSButton(pidtool.utPIDgetStrings('cst','strInspect'),toolpack.component.Icon.SEARCH_16);
            panel.add(this.InspectPlantButton,'xywh(2,6,1,1)');
            this.TPComponent.add(panel);
            this.Panel = panel;
        end
        function val = getPanelWidth(this)
            val = this.Panel.Peer.getPreferredSize.getWidth;
        end
        function setPanelWidth(this, val)
            this.Panel.Peer.setPreferredSize(java.awt.Dimension(val,79));
        end
   end
end

function linkxaxes()
    hs = get(0,'Children');
    has = [];
    for i = 1:numel(hs)
        hasa = get(hs(i),'Children');
        for j = 1:numel(hasa)
            if strcmp(get(hasa(j),'Type'),'axes')
                if isempty(has)
                    has = hasa(j);
                else
                    has(end+1) = hasa(j);
                end
            end
        end
    end
    linkaxes(has,'x');
end

function cursorallplots()
    hs = get(0,'Children');
    has = [];
    for i = 1:numel(hs)
        hasa = get(hs(i),'Children');
        for j = 1:numel(hasa)
            if strcmp(get(hasa(j),'Type'),'axes')
                zoom(hasa(j),'off');
                pan(hasa(j),'off');
            end
        end
    end
end

function zoomallplots()
    hs = get(0,'Children');
    has = [];
    for i = 1:numel(hs)
        hasa = get(hs(i),'Children');
        for j = 1:numel(hasa)
            if strcmp(get(hasa(j),'Type'),'axes')
                zoom(hasa(j),'on');
            end
        end
    end
end

function panallplots()
    hs = get(0,'Children');
    has = [];
    for i = 1:numel(hs)
        hasa = get(hs(i),'Children');
        for j = 1:numel(hasa)
            if strcmp(get(hasa(j),'Type'),'axes')
                pan(hasa(j),'on');
            end
        end
    end
end
classdef fittingtab < handle
   properties 
       vipadesktop
       TPComponent
       Panel
       OpenButton
       OpenButtonKineticsObject
       FileSection
   end
   events
       OpenButtonPressed
   end
   methods
       function this = fittingtab(vipadesktop)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceFittingTab', 'Fitting');
            
            % Add open button
            this.FileSection = toolpack.desktop.ToolSection('File','File');
            this.OpenButton = toolpack.component.TSButton('Open',toolpack.component.Icon.OPEN_24);
            addlistener(this.OpenButton,'ActionPerformed',@(~,~) notify(this,'OpenButtonPressed'));
            this.FileSection.add(this.OpenButton);
            
            % Add File Section
            this.TPComponent.add(this.FileSection);
            
            %this.TPComponent = toolpack.desktop.ToolSection('Plant',pidtool.utPIDgetStrings('cst','strPlant'));
            this.vipadesktop = vipadesktop;
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
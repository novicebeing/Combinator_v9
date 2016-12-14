classdef hometab < handle
   properties 
       vipadesktop
       TPComponent
       Panel
       
       % Buttons
       NewButton
       OpenButton
       OpenButtonKineticsObject
       SaveAllButton
       FileSection
       FileSection2
   end
   events
       NewButtonPressed
       OpenButtonPressed
       OpenButtonKineticsObjectPressed
       SaveAllButtonPressed
   end
   methods
       function this = hometab(vipadesktop)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceHomeTab', 'Home');
            
            % Add File Section
            this.FileSection = toolpack.desktop.ToolSection('File','File');
            this.TPComponent.add(this.FileSection);
            
            % Add New/Open Buttons
            panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow,2dlu,p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
            this.FileSection.add(panel);
            this.NewButton = toolpack.component.TSButton('New',toolpack.component.Icon.NEW_24);
            panel.add( this.NewButton, 'xy(1,2)' );
            addlistener(this.NewButton,'ActionPerformed',@(~,~) notify(this,'NewButtonPressed'));
            this.OpenButton = toolpack.component.TSButton('Open',toolpack.component.Icon.OPEN_24);
            panel.add( this.OpenButton, 'xy(3,2)' );
            addlistener(this.OpenButton,'ActionPerformed',@(~,~) notify(this,'OpenButtonPressed'));
            this.OpenButtonKineticsObject = toolpack.component.TSButton('Open KO',toolpack.component.Icon.OPEN_24);
            panel.add( this.OpenButtonKineticsObject, 'xy(5,2)' );
            addlistener(this.OpenButtonKineticsObject,'ActionPerformed',@(~,~) notify(this,'OpenButtonKineticsObjectPressed'));
            this.SaveAllButton = toolpack.component.TSButton('Save All',toolpack.component.Icon.SAVE_24);
            panel.add( this.SaveAllButton, 'xy(7,2)' );
            addlistener(this.SaveAllButton,'ActionPerformed',@(~,~) notify(this,'SaveAllButtonPressed'));
            
            % Add Notes Section
            notesSection = toolpack.desktop.ToolSection('Notes','Notes');
            this.TPComponent.add(notesSection);
            panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
            notesSection.add(panel);
            button = toolpack.component.TSButton('Notes',toolpack.component.Icon.PROPERTIES_24);
            panel.add( button, 'xy(1,2)' );
            addlistener(button,'ActionPerformed',@(~,~) vipaworkspacenotes);
			
            % Add Notes Section
            gitSection = toolpack.desktop.ToolSection('Git','Git');
            this.TPComponent.add(gitSection);
            panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
            gitSection.add(panel);
            button = toolpack.component.TSButton('Git Shell',toolpack.component.Icon.PROPERTIES_24);
            panel.add( button, 'xy(1,2)' );
            addlistener(button,'ActionPerformed',@(~,~) vipaworkspacegitshell);
            
%             % Add open button
%             this.FileSection = toolpack.desktop.ToolSection('File','File');
%             panel = toolpack.component.TSPanel('7px, f:p, 7px','5px, 12px, 2px, 20px, 4px, 22px');
%             this.FileSection2 = toolpack.desktop.ToolSection('File2','File2');
%             this.OpenButton = toolpack.component.TSButton('Open',toolpack.component.Icon.OPEN_24);
%             addlistener(this.OpenButton,'ActionPerformed',@(~,~) notify(this,'OpenButtonPressed'));
%             this.FileSection.add(this.OpenButton,);
%             this.OpenButtonKineticsObject = toolpack.component.TSButton('Open KO',toolpack.component.Icon.OPEN_24);
%             addlistener(this.OpenButtonKineticsObject,'ActionPerformed',@(~,~) notify(this,'OpenButtonKineticsObjectPressed'));
%             this.FileSection2.add(this.OpenButtonKineticsObject);
            
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
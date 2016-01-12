classdef fitanalysistab < handle
   properties 
       vipadesktop
       TPComponent
       Panel
       OpenButton
       FileSection
       
       % Sections
       CameraSection
       AcquireSection
       AcquireDestinationSection
       
       % Buttons
       AcquireButton
       StopAcquireButton
       
       % Combo Boxes
       singleImageComboBox
       kineticsImagesComboBox
       imageDestComboBox
       calibrationComboBox
       spectraDestComboBox
   end
   events
       OpenButtonPressed
   end
   methods
       function this = fitanalysistab(vipadesktop,fitAnalysisFunctions)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceFitAnalysisTab', 'Fit Analysis');
            
            % Convert the functions to strings
            fitAnalysisFunctionStrings = {};
            for i = 1:numel(fitAnalysisFunctions)
                a = strsplit(func2str(fitAnalysisFunctions{i}),'.');
                fitAnalysisFunctionStrings{end+1} = char(a(end));
            end
            
            % Add Camera Section
            this.CameraSection = toolpack.desktop.ToolSection('camera','Camera');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.CameraSection.add(panel);
            singleImageFunctionLabel = toolpack.component.TSLabel('Fit Analysis Function');
            panel.add(singleImageFunctionLabel,'xy(2,2,''r,c'')');
            kineticsImagesFunctionLabel = toolpack.component.TSLabel('Kinetics Images');
            panel.add(kineticsImagesFunctionLabel,'xy(2,4,''r,c'')');
            this.singleImageComboBox = toolpack.component.TSComboBox(fitAnalysisFunctionStrings);
            panel.add(this.singleImageComboBox,'xywh(4,2,1,1)');
%             this.kineticsImagesComboBox = toolpack.component.TSComboBox(kineticsImagesAcquireFunctionStrings);
%             panel.add(this.kineticsImagesComboBox,'xywh(4,4,1,1)');
            this.TPComponent.add(this.CameraSection);
            
%             % Add Acquire Section
%             this.AcquireSection = toolpack.desktop.ToolSection('acquire','Acquire');
%              panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
%              this.AcquireSection.add(panel);
%             panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
%             this.AcquireSection.add(panel);
%             this.AcquireButton = toolpack.component.TSButton('Acquire',toolpack.component.Icon.RUN_24);
%             panel.add( this.AcquireButton, 'xy(1,2)' );
%             addlistener(this.AcquireButton,'ActionPerformed',@(~,~) notify(this,'AcquireButtonPressed'));
%             this.StopAcquireButton = toolpack.component.TSButton('Stop',toolpack.component.Icon.END_24);
%             panel.add( this.StopAcquireButton, 'xy(3,2)' );
%             addlistener(this.StopAcquireButton,'ActionPerformed',@(~,~) notify(this,'StopAcquireButtonPressed'));
%             this.TPComponent.add(this.AcquireSection);
            
%             % Add Acquire Destination Section
%             this.AcquireDestinationSection = toolpack.desktop.ToolSection('acquiredestination','Acquire Destination');
%             panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
%             this.AcquireDestinationSection.add(panel);
%             l = toolpack.component.TSLabel('Image Dest.');
%             panel.add(l,'xy(2,2,''r,c'')');
%             l = toolpack.component.TSLabel('Calibration');
%             panel.add(l,'xy(2,4,''r,c'')');
%             l = toolpack.component.TSLabel('Spectra Dest.');
%             panel.add(l,'xy(2,6,''r,c'')');
%             this.imageDestComboBox = toolpack.component.TSComboBox({'none'});
%             panel.add(this.imageDestComboBox,'xywh(4,2,1,1)');
%             this.calibrationComboBox = toolpack.component.TSComboBox({'none'});
%             panel.add(this.calibrationComboBox,'xywh(4,4,1,1)');
%             this.spectraDestComboBox = toolpack.component.TSComboBox({'none'});
%             panel.add(this.spectraDestComboBox,'xywh(4,6,1,1)');
%             this.TPComponent.add(this.AcquireDestinationSection);
            
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
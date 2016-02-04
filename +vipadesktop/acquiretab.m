classdef acquiretab < handle
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
       AcquireDestinationSection2
       
       % Buttons
       AcquireButton
       StopAcquireButton
       
       % Combo Boxes
       acquireFunctionComboBox
       singleImageComboBox
       kineticsImagesComboBox
       imageDestTextField
       calibrationTextField
       spectraDestTextField
       acquireOperationComboBox
   end
   events
       OpenButtonPressed
       AcquireButtonPressed
       StopAcquireButtonPressed
       AcquireFunctionBoxAction
       AcquireOperationBoxAction
   end
   methods
       function this = acquiretab(vipadesktop,acquireFunctions,singleImageAcquireFunctions,kineticsImagesAcquireFunctions)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceAcquireTab', 'Acquire');
            
            % Convert the functions to strings
            acquireFunctionStrings = {};
            for i = 1:numel(acquireFunctions)
                a = strsplit(func2str(acquireFunctions{i}),'.');
                acquireFunctionStrings{end+1} = char(a(end));
            end
            singleImageAcquireFunctionStrings = {};
            for i = 1:numel(singleImageAcquireFunctions)
                a = strsplit(func2str(singleImageAcquireFunctions{i}),'.');
                singleImageAcquireFunctionStrings{end+1} = char(a(end));
            end
            kineticsImagesAcquireFunctionStrings = {};
            for i = 1:numel(kineticsImagesAcquireFunctions)
                a = strsplit(func2str(kineticsImagesAcquireFunctions{i}),'.');
                kineticsImagesAcquireFunctionStrings{end+1} = char(a(end));
            end
            
            % Add Camera Section
            this.CameraSection = toolpack.desktop.ToolSection('camera','Camera');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.CameraSection.add(panel);
            singleImageFunctionLabel = toolpack.component.TSLabel('Acquire Function');
            panel.add(singleImageFunctionLabel,'xy(2,2,''r,c'')');
             singleImageFunctionLabel = toolpack.component.TSLabel('Acquire Operation');
             panel.add(singleImageFunctionLabel,'xy(2,4,''r,c'')');
%             kineticsImagesFunctionLabel = toolpack.component.TSLabel('Kinetics Images');
%             panel.add(kineticsImagesFunctionLabel,'xy(2,6,''r,c'')');
            this.acquireFunctionComboBox = toolpack.component.TSComboBox(acquireFunctionStrings);
            panel.add(this.acquireFunctionComboBox,'xywh(4,2,1,1)');
            addlistener(this.acquireFunctionComboBox,'ActionPerformed',@(~,~) notify(this,'AcquireFunctionBoxAction'));
             this.acquireOperationComboBox = toolpack.component.TSComboBox({'replace','add','average','averageWithRestart'});
             panel.add(this.acquireOperationComboBox,'xywh(4,4,1,1)');
             addlistener(this.acquireOperationComboBox,'ActionPerformed',@(~,~) notify(this,'AcquireOperationBoxAction'));
%             this.kineticsImagesComboBox = toolpack.component.TSComboBox(kineticsImagesAcquireFunctionStrings);
%             panel.add(this.kineticsImagesComboBox,'xywh(4,6,1,1)');
            this.TPComponent.add(this.CameraSection);
            
            % Add Acquire Section
            this.AcquireSection = toolpack.desktop.ToolSection('acquire','Acquire');
             panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
             this.AcquireSection.add(panel);
            panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
            this.AcquireSection.add(panel);
            this.AcquireButton = toolpack.component.TSButton('Acquire',toolpack.component.Icon.RUN_24);
            panel.add( this.AcquireButton, 'xy(1,2)' );
            addlistener(this.AcquireButton,'ActionPerformed',@(~,~) notify(this,'AcquireButtonPressed'));
            this.StopAcquireButton = toolpack.component.TSButton('Stop',toolpack.component.Icon.END_24);
            this.StopAcquireButton.Enabled = false;
            panel.add( this.StopAcquireButton, 'xy(3,2)' );
            addlistener(this.StopAcquireButton,'ActionPerformed',@(~,~) notify(this,'StopAcquireButtonPressed'));
            this.TPComponent.add(this.AcquireSection);
            
            % Add Acquire Destination Section
            this.AcquireDestinationSection = toolpack.desktop.ToolSection('acquiredestination','Acquire Destination');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.AcquireDestinationSection.add(panel);
            l = toolpack.component.TSLabel('Image Dest.');
            panel.add(l,'xy(2,2,''r,c'')');
            l = toolpack.component.TSLabel('Calibration');
            panel.add(l,'xy(2,4,''r,c'')');
            l = toolpack.component.TSLabel('Spectra Dest.');
            panel.add(l,'xy(2,6,''r,c'')');
            this.imageDestTextField = toolpack.component.TSTextField('none',15);
            this.imageDestTextField.Editable = false;
            addlistener(this.imageDestTextField,'ActionPerformed',@(~,~) setTextFieldText(this.imageDestTextField,'none'));
            panel.add(this.imageDestTextField,'xywh(4,2,1,1)');
            this.calibrationTextField = toolpack.component.TSTextField('none',15);
            this.calibrationTextField.Editable = false;
            addlistener(this.calibrationTextField,'ActionPerformed',@(~,~) setTextFieldText(this.calibrationTextField,'none'));
            panel.add(this.calibrationTextField,'xywh(4,4,1,1)');
            this.spectraDestTextField = toolpack.component.TSTextField('none',15);
            this.spectraDestTextField.Editable = false;
            addlistener(this.spectraDestTextField,'ActionPerformed',@(~,~) setTextFieldText(this.spectraDestTextField,'none'));
            panel.add(this.spectraDestTextField,'xywh(4,6,1,1)');
            this.TPComponent.add(this.AcquireDestinationSection);
            
%             % Add Acquire Destination Section
%             this.AcquireDestinationSection2 = toolpack.desktop.ToolSection('acquiredestination','Acquire Destination');
%             panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
%             this.AcquireDestinationSection.add(panel);
%             l = toolpack.component.TSLabel('Image Dest.');
%             panel.add(l,'xy(2,2,''r,c'')');
%             l = toolpack.component.TSLabel('Calibration');
%             panel.add(l,'xy(2,4,''r,c'')');
%             l = toolpack.component.TSLabel('Spectra Dest.');
%             panel.add(l,'xy(2,6,''r,c'')');
%             this.imageDestTextField = toolpack.component.TSTextField('none',15);
%             this.imageDestTextField.Editable = false;
%             addlistener(this.imageDestTextField,'ActionPerformed',@(~,~) setTextFieldText(this.imageDestTextField,'none'));
%             panel.add(this.imageDestTextField,'xywh(4,2,1,1)');
%             this.calibrationTextField = toolpack.component.TSTextField('none',15);
%             this.calibrationTextField.Editable = false;
%             addlistener(this.calibrationTextField,'ActionPerformed',@(~,~) setTextFieldText(this.calibrationTextField,'none'));
%             panel.add(this.calibrationTextField,'xywh(4,4,1,1)');
%             this.spectraDestTextField = toolpack.component.TSTextField('none',15);
%             this.spectraDestTextField.Editable = false;
%             addlistener(this.spectraDestTextField,'ActionPerformed',@(~,~) setTextFieldText(this.spectraDestTextField,'none'));
%             panel.add(this.spectraDestTextField,'xywh(4,6,1,1)');
%             this.TPComponent.add(this.AcquireDestinationSection);
            
            
            
            %this.TPComponent = toolpack.desktop.ToolSection('Plant',pidtool.utPIDgetStrings('cst','strPlant'));
            this.vipadesktop = vipadesktop;
            %this.layout();
            
           function setTextFieldText(obj,text)
               obj.Text = text;
           end
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
classdef calibrationtab < handle
   properties 
       vipadesktop
       TPComponent
       Panel
       OpenButton
       FileSection
       
	   % Calibration Images Section
	   CalibrationImagesSection
	   referenceImageButton
	   signalImageButton
	   referenceImageDeleteButton
	   signalImageDeleteButton
	   
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
       function this = calibrationtab(vipadesktop)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceCalibrationTab', 'Calibration');
            
            % Add the Calibration Images Panel
            this.CalibrationImagesSection = toolpack.desktop.ToolSection('calibrationimages','Cal. Images');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.CalibrationImagesSection.add(panel);
			
				% Add the signal and reference image buttons to the panel
				this.referenceImageButton = toolpack.component.TSButton('Reference Image');
				this.referenceImageButton.Enabled = false;
				panel.add(this.referenceImageButton,'xy(2,2,''r,c'')');
				this.signalImageButton = toolpack.component.TSButton('Signal Image');
				this.signalImageButton.Enabled = false;
				panel.add(this.singleImageFunctionLabel,'xy(2,4,''r,c'')');
				this.referenceImageDeleteButton = toolpack.component.TSButton('Delete');
				panel.add(this.referenceImageDeleteButton,'xywh(4,2,1,1)');
				this.signalImageDeleteButton = toolpack.component.TSButton('Delete');
				panel.add(this.signalImageDeleteButton,'xywh(4,4,1,1)');
				
				% Add Event Handlers
				addlistener(this.referenceImageButton,'ActionPerformed',@(~,~) notify(this,'openReferenceImageFigure'));
				addlistener(this.referenceImageDeleteButton,'ActionPerformed',@(~,~) notify(this,'deleteReferenceImage'));
				addlistener(this.signalImageButton,'ActionPerformed',@(~,~) notify(this,'openSignalImageFigure'));
				addlistener(this.signalImageDeleteButton,'ActionPerformed',@(~,~) notify(this,'deleteSignalImage'));
				
			this.TPComponent.add(this.CalibrationImagesSection);
            
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
classdef VIPACalibrationTool < handle
	%% Public Properties, Events, Methods
	properties (Access = public)
		tooltab
		referenceImage
		calibrationgasImage
	end

	%% Private Properties, Events, Methods
   properties (Access = private)
       vipadesktop
       Panel
       OpenButton
       FileSection
       
	   % Calibration Images Section
	   CalibrationImagesSection
		referenceImageButton
		signalImageButton
		referenceImageDeleteButton
		signalImageDeleteButton
		
	   % Calibration Section
	   CalibrationSection
		ClearAllButton
		CollectFringesButton
		CalibrateWavenumberButton
		
	   % Status Section
	   StatusSection
	    fringesStatus
		wavenumberStatus
	    
	   % Fringe Collection
	   fringeX
	   fringeY
	   fringeImageSize
	   
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
       function this = VIPACalibrationTool(vipadesktop)
            % Add home tab
            this.tooltab = toolpack.desktop.ToolTab('VIPAworkspaceCalibrationTab', 'Calibration');
            
            % Add the Calibration Images Panel
            this.CalibrationImagesSection = toolpack.desktop.ToolSection('calibrationimages','Cal. Images');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.CalibrationImagesSection.add(panel);
			
				% Add the signal and reference image buttons to the panel
				this.referenceImageButton = toolpack.component.TSButton('Reference Image');
				this.referenceImageButton.Enabled = false;
				panel.add(this.referenceImageButton,'xy(2,2,''r,c'')');
				this.signalImageButton = toolpack.component.TSButton('Cal. Gas Image');
				this.signalImageButton.Enabled = false;
				panel.add(this.signalImageButton,'xy(2,4,''r,c'')');
				this.referenceImageDeleteButton = toolpack.component.TSButton('',toolpack.component.Icon.CLOSE_16);
				this.referenceImageDeleteButton.Enabled = false;
				panel.add(this.referenceImageDeleteButton,'xywh(4,2,1,1)');
				this.signalImageDeleteButton = toolpack.component.TSButton('',toolpack.component.Icon.CLOSE_16);
				this.signalImageDeleteButton.Enabled = false;
				panel.add(this.signalImageDeleteButton,'xywh(4,4,1,1)');
				
				% Add Event Handlers
				addlistener(this.referenceImageButton,'ActionPerformed',@(~,~) this.openReferenceImageFigure());
				addlistener(this.referenceImageDeleteButton,'ActionPerformed',@(~,~) this.deleteReferenceImage());
				addlistener(this.signalImageButton,'ActionPerformed',@(~,~) this.openSignalImageFigure());
				addlistener(this.signalImageDeleteButton,'ActionPerformed',@(~,~) this.deleteSignalImage());
				
			this.tooltab.add(this.CalibrationImagesSection);
            
			% Add the Calibration section
            this.CalibrationSection = toolpack.desktop.ToolSection('Calibration','Calibration');
			panel = toolpack.component.TSPanel('p:grow,2dlu,p:grow,2dlu,p:grow', '2dlu,fill:p:grow,2dlu');
            this.CalibrationSection.add(panel);
			
				% Add calibration operations
				this.ClearAllButton = toolpack.component.TSButton('Clear All',toolpack.component.Icon.CLOSE_24);
				this.ClearAllButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
				panel.add( this.ClearAllButton, 'xy(1,2)' );
				this.CollectFringesButton = toolpack.component.TSButton(sprintf('Collect\nFringes'),toolpack.component.Icon.PLAY_24);
				this.CollectFringesButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
				this.CollectFringesButton.Enabled = false;
				panel.add( this.CollectFringesButton, 'xy(3,2)' );
				this.CalibrateWavenumberButton = toolpack.component.TSButton(sprintf('Calibrate\nWavenumber'),toolpack.component.Icon.PLAY_24);
				this.CalibrateWavenumberButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
				this.CalibrateWavenumberButton.Enabled = false;
				panel.add( this.CalibrateWavenumberButton, 'xy(5,2)' );
				
				% Add Event Handlers
				addlistener(this.ClearAllButton,'ActionPerformed',@(~,~) this.clearAll());
				addlistener(this.CollectFringesButton,'ActionPerformed',@(~,~) this.collectFringes());
				addlistener(this.CalibrateWavenumberButton,'ActionPerformed',@(~,~) this.calibrateWavenumber());
				
			this.tooltab.add(this.CalibrationSection);
			
			% Add the Status section
            this.StatusSection = toolpack.desktop.ToolSection('Status','Status');
			panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.StatusSection.add(panel);
			
				% Add status boxes
				l = toolpack.component.TSLabel('Fringes');
				panel.add(l,'xy(2,2,''r,c'')');
				l = toolpack.component.TSLabel('Wavenumber');
				panel.add(l,'xy(2,4,''r,c'')');
				l = toolpack.component.TSLabel('Other');
				panel.add(l,'xy(2,6,''r,c'')');
				this.fringesStatus = toolpack.component.TSLabel('',toolpack.component.Icon.CLOSE_16);
				panel.add(this.fringesStatus,'xy(4,2,''r,c'')');
				this.wavenumberStatus = toolpack.component.TSLabel('',toolpack.component.Icon.CLOSE_16);
				panel.add(this.wavenumberStatus,'xy(4,4,''r,c'')');
				l = toolpack.component.TSLabel('',toolpack.component.Icon.CLOSE_16);
				panel.add(l,'xy(4,6,''r,c'')');
				
			this.tooltab.add(this.StatusSection);

            this.vipadesktop = vipadesktop;
            
       end
	   
        %function val = getPanelWidth(this)
        %    val = this.Panel.Peer.getPreferredSize.getWidth;
        %end
        %function setPanelWidth(this, val)
        %    this.Panel.Peer.setPreferredSize(java.awt.Dimension(val,79));
        %end
		function spectrum = image2spectrum(this,theImage)
			spectrum = vipadesktop.VIPACalibrationTool.image2spectrumStatic(this.fringeX,this.fringeY,theImage,2);
		end
		
		% Calibration Functions
		function this = set.referenceImage(this,refImageIn)
			this.referenceImage = refImageIn;
            if isempty(this.referenceImage)
                this.referenceImageButton.Enabled = false;
                this.referenceImageDeleteButton.Enabled = false;
            else
                this.referenceImageButton.Enabled = true;
                this.referenceImageDeleteButton.Enabled = true;
				this.CollectFringesButton.Enabled = true;
            end
		end
		function this = set.calibrationgasImage(this,calgasImageIn)
			this.calibrationgasImage = calgasImageIn;
            if isempty(this.calibrationgasImage)
                this.signalImageButton.Enabled = false;
				this.signalImageDeleteButton.Enabled = false;
            else
                this.signalImageButton.Enabled = true;
				this.signalImageDeleteButton.Enabled = true;
            end
		end
	end
	methods (Access = private)
		[fringeX,fringeY,fringeImageSize] = collectFringesFunction(this,fringeImage);
		calibrateWavenumberFunction(this,spectrum);
		function this = deleteReferenceImage(this)
			this.referenceImage = [];
			this.referenceImageButton.Enabled = false;
			this.referenceImageDeleteButton.Enabled = false;
			this.CollectFringesButton.Enabled = false;
		end
		function this = deleteSignalImage(this)
			this.calibrationgasImage = [];
			this.signalImageButton.Enabled = false;
			this.signalImageDeleteButton.Enabled = false;
		end
		function openReferenceImageFigure(this)
			h = figure('Name','Reference Image');
			imagesc(this.referenceImage);
		end
		function openSignalImageFigure(this)
			h = figure('Name','Signal Image');
			imagesc(this.calibrationgasImage);
		end
		function clearAll(this)
			this.referenceImage = [];
			this.calibrationgasImage = [];
			this.referenceImageButton.Enabled = false;
			this.referenceImageDeleteButton.Enabled = false;
			this.signalImageButton.Enabled = false;
			this.signalImageDeleteButton.Enabled = false;
			this.CollectFringesButton.Enabled = false;
			this.CalibrateWavenumberButton.Enabled = false;
			this.fringesStatus.Icon = toolpack.component.Icon.CLOSE_16;
		end
		function collectFringes(this)
			[this.fringeX,this.fringeY,this.fringeImageSize] = this.collectFringesFunction(this.referenceImage);
			this.CalibrateWavenumberButton.Enabled = true;
			this.fringesStatus.Icon = toolpack.component.Icon.CONFIRM_16;
		end
		function calibrateWavenumber(this)
			refSpectrum = this.image2spectrum(this.referenceImage);
			calgasSpectrum = this.image2spectrum(this.calibrationgasImage);
			%figure;plot(reshape(log(refSpectrum./calgasSpectrum),[],1));
			this.calibrateWavenumberFunction(log(refSpectrum./calgasSpectrum));
		end
	end
	methods (Static)
		function spectrum = image2spectrumStatic(fringeX,fringeY,theImage,columnsToSum)
			indcsX = round(fringeX);
			indcsY = round(fringeY);
			nonnanindcs = ~isnan(indcsX);
			spectrum = zeros(size(indcsX));
			spectrum(~nonnanindcs) = NaN;
			for i = -columnsToSum:columnsToSum
				spectrum(nonnanindcs) = spectrum(nonnanindcs) + theImage(sub2ind(size(theImage),indcsY(nonnanindcs),indcsX(nonnanindcs)+i));
			end
		end
   end
end
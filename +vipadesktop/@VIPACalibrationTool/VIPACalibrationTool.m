classdef VIPACalibrationTool < handle
	%% Public Properties, Events, Methods
	properties (Access = public)
		tooltab
		referenceImage
		calibrationgasImage
		wavenum
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
	    
	   % Save Section
	   SaveLoadSection
	    SaveButton
		LoadButton
		
	   % Fringe Collection
	   fringeX
	   fringeY
	   fringeImageSize
	   
   end
   events
   
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
			
            % Add the Calibration Images Panel
            this.SaveLoadSection = toolpack.desktop.ToolSection('saveload','Save/Load');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.SaveLoadSection.add(panel);
			
				% Add the signal and reference image buttons to the panel
				this.SaveButton = toolpack.component.TSButton('Save');
				% this.SaveButton.Enabled = false;
				panel.add(this.SaveButton,'xy(2,2,''r,c'')');
				this.LoadButton = toolpack.component.TSButton('Load');
				% this.LoadButton.Enabled = false;
				panel.add(this.LoadButton,'xy(2,4,''r,c'')');
				% this.referenceImageDeleteButton = toolpack.component.TSButton('',toolpack.component.Icon.CLOSE_16);
				% this.referenceImageDeleteButton.Enabled = false;
				% panel.add(this.referenceImageDeleteButton,'xywh(4,2,1,1)');
				% this.signalImageDeleteButton = toolpack.component.TSButton('',toolpack.component.Icon.CLOSE_16);
				% this.signalImageDeleteButton.Enabled = false;
				% panel.add(this.signalImageDeleteButton,'xywh(4,4,1,1)');
				
				% Add Event Handlers
				addlistener(this.SaveButton,'ActionPerformed',@(~,~) this.saveCalibrationData());
				addlistener(this.LoadButton,'ActionPerformed',@(~,~) this.loadCalibrationData());
				
			this.tooltab.add(this.SaveLoadSection);

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
		calibrateWavenumberFunction2(this,spectrum);
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
			this.wavenum = [];
			this.fringeX = [];
			this.fringeY = [];
			this.fringeImageSize = [];
			this.refreshGUI();
			% this.referenceImageButton.Enabled = false;
			% this.referenceImageDeleteButton.Enabled = false;
			% this.signalImageButton.Enabled = false;
			% this.signalImageDeleteButton.Enabled = false;
			% this.CollectFringesButton.Enabled = false;
			% this.CalibrateWavenumberButton.Enabled = false;
			% this.fringesStatus.Icon = toolpack.component.Icon.CLOSE_16;
			% this.wavenumberStatus.Icon = toolpack.component.Icon.CLOSE_16;
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
			this.wavenumberStatus.Icon = toolpack.component.Icon.CONFIRM_16;
		end
		function saveCalibrationData(this)
			[filename,filepath] = uiputfile( ...
				{  '*.VIPACalibration','MAT-files (*.VIPACalibration)'}, ...
				   'Pick a file');
				   
			if filepath == 0
					return
			end
       
			[~,fname,ext] = fileparts(filename);
			
			s = struct();
			s.referenceImage = this.referenceImage;
			s.calibrationgasImage = this.calibrationgasImage;
			s.fringeX = this.fringeX;
			s.fringeY = this.fringeY;
			s.fringeImageSize = this.fringeImageSize;
			s.wavenum = this.wavenum;
			
			save(fullfile(filepath,filename),'-struct','s');
		end
		function loadCalibrationData(obj)
			[filename,filepath] = uigetfile( ...
				{  '*.VIPACalibration','VIPA Calibration (*.VIPACalibration)'}, ...
				   'Pick a file', ...
				   'MultiSelect', 'off');
				   
			if filepath == 0
				return
			end
			
			this = load(fullfile(filepath,filename),'-mat');
			obj.referenceImage = this.referenceImage;
			obj.calibrationgasImage = this.calibrationgasImage;
			obj.fringeX = this.fringeX;
			obj.fringeY = this.fringeY;
			obj.fringeImageSize = this.fringeImageSize;
			obj.wavenum = this.wavenum;
			obj.refreshGUI();
		end
		function refreshGUI(this)
			if isempty(this.referenceImage)
                this.referenceImageButton.Enabled = false;
				this.referenceImageDeleteButton.Enabled = false;
				this.CollectFringesButton.Enabled = false;
			else
                this.referenceImageButton.Enabled = true;
				this.referenceImageDeleteButton.Enabled = true;
				this.CollectFringesButton.Enabled = true;
			end
			if isempty(this.calibrationgasImage)
                this.signalImageButton.Enabled = false;
				this.signalImageDeleteButton.Enabled = false;
			else
                this.signalImageButton.Enabled = true;
				this.signalImageDeleteButton.Enabled = true;
			end
			if isempty(this.fringeX) | isempty(this.fringeX) | isempty(this.fringeImageSize)
				this.CalibrateWavenumberButton.Enabled = false;
				this.fringesStatus.Icon = toolpack.component.Icon.CLOSE_16;
			else
				this.CalibrateWavenumberButton.Enabled = true;
				this.fringesStatus.Icon = toolpack.component.Icon.CONFIRM_16;
			end
			if isempty(this.wavenum)
				this.wavenumberStatus.Icon = toolpack.component.Icon.CLOSE_16;
			else
				this.wavenumberStatus.Icon = toolpack.component.Icon.CONFIRM_16;
			end
		end
	end
	methods (Static)
		function spectrumOut = image2spectrumStatic(fringeX,fringeY,theImages,columnsToSum)
			indcsX = round(fringeX);
			indcsY = round(fringeY);
			nonnanindcs = ~isnan(indcsX);
			spectrumOut = zeros(size(indcsX,1),size(indcsX,2),size(theImages,3));
			%spectrumOut(repmat(~nonnanindcs,1,1,size(spectrum,3))) = NaN;
			for j = 1:size(theImages,3)
				spectrum = zeros(size(indcsX));
				spectrum(~nonnanindcs) = NaN;
				for i = -columnsToSum:columnsToSum
					spectrum(nonnanindcs) = spectrum(nonnanindcs) + theImages(sub2ind(size(theImages),indcsY(nonnanindcs),indcsX(nonnanindcs)+i,j.*ones(sum(sum(nonnanindcs)),1)));
				end
				spectrumOut(:,:,j) = spectrum;
			end
		end
   end
end
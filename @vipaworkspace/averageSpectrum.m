function averageSpectrum(obj)

	% Check to see if there is a valid wavelength calibration
	if isempty(obj.VIPACalibrationTool.wavenum) | ...
	   isempty(obj.VIPACalibrationTool.fringeX) | ...
	   isempty(obj.VIPACalibrationTool.fringeY)
		errordlg('Wavelength calibration is not set.','Acquire Error','modal');
		return
	end

    % Check to see if there are any acquire destinations set
    if strcmp(obj.acquiretab.imageDestTextField.Text,'none') && ...
            strcmp(obj.acquiretab.calibrationTextField.Text,'none') && ...
            strcmp(obj.acquiretab.spectraDestTextField.Text,'none')
        errordlg('No acquire destination is set...','Acquire Error','modal');
        return
    end

    % Set acquire buttons
    obj.acquiretab.AcquireButton.Enabled = false;
    obj.acquiretab.AcquireSpectrumButton.Enabled = false;
    obj.acquiretab.StopAcquireButton.Enabled = true;
    
    %try % to collect a spectrum
    
	% Create the acquire object
		acquireObject = obj.acquireFunction();
		acquireObject.referenceImage = obj.VIPACalibrationTool.referenceImage;
		acquireObject.fringeX = obj.VIPACalibrationTool.fringeX;
		acquireObject.fringeY = obj.VIPACalibrationTool.fringeY;
		acquireObject.wavenum = obj.VIPACalibrationTool.wavenum;
		acquireObject.averaging = true;
		acquireObject.startSpectrumAcquire();
	
        n = 0;
        lastAcquire = now;
        while ~obj.stopAcquireBoolean
            [spectra,time] = acquireObject.getSpectra();

            acqTimeDiff = now - lastAcquire;
            lastAcquire = now;

			% Send the image to the appropriate spectra object
			if ~strcmp(obj.acquiretab.spectraDestTextField.Text,'none')
				spectraobjid = {obj.acquiretab.spectraDestTextField.Text};
				obj.SpectraList.setSpectra(spectraobjid,acquireObject.wavenum,spectra,[],time);
			end

            pause(0.1);
    %         if ishandle(h)
    %             h.Children(2).Children.String = sprintf('Acquired %i Spectra, %.1f Hz...',n,1/(acqTimeDiff*24*3600));
    %         end
            statusString = sprintf('Acquired %i Spectra, %.1f Hz...',n,1/(acqTimeDiff*24*3600));
            obj.StatusBar.setText(statusString,[],'west');
            n = n+1;
        end
		
		acquireObject.stopAcquire();
		delete(acquireObject)
    
    %catch err
    %end
    
    % Reset the status
    statusString = sprintf('');
    obj.StatusBar.setText(statusString,[],'west');
    
    % Reset the acquire buttons
    obj.stopAcquireBoolean = false;
    obj.acquiretab.AcquireButton.Enabled = true;
    obj.acquiretab.AcquireSpectrumButton.Enabled = true;
    obj.acquiretab.StopAcquireButton.Enabled = false;
end
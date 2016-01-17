function acquire(obj)

    % Check to see if there are any acquire destinations set
    if strcmp(obj.acquiretab.imageDestTextField.Text,'none') && ...
            strcmp(obj.acquiretab.calibrationTextField.Text,'none') && ...
            strcmp(obj.acquiretab.spectraDestTextField.Text,'none')
        errordlg('No acquire destination is set...','Acquire Error','modal');
        return
    end

    % Set acquire buttons
    obj.acquiretab.AcquireButton.Enabled = false;
    obj.acquiretab.StopAcquireButton.Enabled = true;
    
    n = 0;
    lastAcquire = now;
    while ~obj.stopAcquireBoolean
        [images,time,acquireType,refImagesBoolean] = obj.acquireFunction();
        
        % Check the output
        numImages = size(images,3);
        if ~isvector(time) || ...
                numel(time) ~= numImages || ...
                ~islogical(refImagesBoolean) || ...
                ~isvector(refImagesBoolean) || ...
                numel(refImagesBoolean) ~= numImages || ...
                ~strcmp(acquireType,'image')
            errordlg('Acquire function output is poorly formatted','Acquire Error','modal');
            break
        end
        
        acqTimeDiff = now - lastAcquire;
        lastAcquire = now;
        
        % Send the image to the appropriate image object
        if ~strcmp(obj.acquiretab.imageDestTextField.Text,'none')
            imageobjid = {obj.acquiretab.imageDestTextField.Text};
            if ~strcmp(imageobjid,'none')
                switch obj.acquireOperation
                    case 'add'
                        obj.ImagesList.addImages(imageobjid,images,time,refImagesBoolean);
                    case 'replace'
                        obj.ImagesList.setImages(imageobjid,images,time,refImagesBoolean);
                    case 'average'
                        obj.ImagesList.averageImages(imageobjid,images,time,refImagesBoolean);
                    case 'averageWithRestart'
                        if n == 0
                            obj.ImagesList.clearImages(imageobjid);
                        end
                        obj.ImagesList.averageImages(imageobjid,images,time,refImagesBoolean);
                    otherwise
                        error('Acquire Operation Not Defined')
                end
            end
        end
        
        if ~strcmp(obj.acquiretab.calibrationTextField.Text,'none')
            % Pass the image through the appropriate calibration object
            [wavenum,spectra,spectraTime] = obj.CalibrationList.createSpectra(1,images,time,refImagesBoolean);
            if isempty(wavenum) && isempty(spectra) && isempty(spectraTime)
                break
            end

            % Send the image to the appropriate spectra object
            if ~strcmp(obj.acquiretab.spectraDestTextField.Text,'none')
                spectraobjid = {obj.acquiretab.spectraDestTextField.Text};
                switch obj.acquireOperation
                    case 'add'
                        obj.SpectraList.addSpectra(spectraobjid,wavenum,spectra,[],spectraTime);
                    case 'replace'
                        obj.SpectraList.setSpectra(spectraobjid,wavenum,spectra,[],spectraTime);
                    case 'average'
                        obj.SpectraList.averageSpectra(spectraobjid,wavenum,spectra,[],spectraTime);
                    case 'averageWithRestart'
                        if n == 0
                            obj.SpectraList.clearSpectra(spectraobjid);
                        end
                        obj.SpectraList.averageSpectra(spectraobjid,wavenum,spectra,[],spectraTime);
                    otherwise
                        error('Acquire Operation Not Defined')
                end
            end
        end
        
        pause(0.1);
%         if ishandle(h)
%             h.Children(2).Children.String = sprintf('Acquired %i Spectra, %.1f Hz...',n,1/(acqTimeDiff*24*3600));
%         end
        statusString = sprintf('Acquired %i Spectra, %.1f Hz...',n,1/(acqTimeDiff*24*3600));
        obj.StatusBar.setText(statusString,[],'west');
        n = n+1;
    end
    
    % Reset the status
    statusString = sprintf('');
    obj.StatusBar.setText(statusString,[],'west');
    
    % Reset the acquire buttons
    obj.stopAcquireBoolean = false;
    obj.acquiretab.AcquireButton.Enabled = true;
    obj.acquiretab.StopAcquireButton.Enabled = false;
end
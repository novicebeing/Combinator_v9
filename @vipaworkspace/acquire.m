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
    obj.acquiretab.AcquireSpectrumButton.Enabled = false;
    obj.acquiretab.StopAcquireButton.Enabled = true;
    
    try % to acquire an image
    
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
                    obj.ImagesList.setImages(imageobjid,images,time,refImagesBoolean);
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
    
    catch err
        uiwait(errordlg('Could not acquire an image.','Acquire Error'));
    end
    
    % Reset the status
    statusString = sprintf('');
    obj.StatusBar.setText(statusString,[],'west');
    
    % Reset the acquire buttons
    obj.stopAcquireBoolean = false;
    obj.acquiretab.AcquireButton.Enabled = true;
    obj.acquiretab.StopAcquireButton.Enabled = false;
end
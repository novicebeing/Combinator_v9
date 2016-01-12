function acquire(obj)
    h = msgbox('Acquiring Spectra','Acquiring...');%,'modal');
    
    n = 0;
    while ishandle(h)
        [images,time,acquireType] = obj.acquireFunction();
        
        % Send the image to the appropriate image object
        imageobjid = {obj.acquiretab.imageDestTextField.Text};
        if ~strcmp(imageobjid,'none')
            switch obj.acquireOperation
                case 'add'
                    obj.ImagesList.addImages(imageobjid,images,time);
                case 'replace'
                    obj.ImagesList.setImages(imageobjid,images,time);
                case 'average'
                    obj.ImagesList.averageImages(imageobjid,images,time);
                case 'averageWithRestart'
                    if n == 0
                        obj.ImagesList.clearImages(imageobjid,images,time);
                    end
                    obj.ImagesList.averageImages(imageobjid,images,time);
                otherwise
                    error('Acquire Operation Not Defined')
            end
        end
        
%         % Pass the image through the appropriate calibration object
%         [wavenum,spectra] = obj.CalibrationList.calibrateImages(1,images);
%         
%         % Send the calibrated spectrum to the appropriate spectra object
%         switch obj.acquireOperation
%             case 'add'
%                 obj.SpectraList.addSpectra(1,wavenum,spectra,time);
%             case 'replace'
%                 obj.SpectraList.setSpectra(1,wavenum,spectra,time);
%             case 'average'
%                 obj.SpectraList.averageSpectra(1,wavenum,spectra,time);
%             case 'averageWithRestart'
%                 if n == 0
%                     obj.SpectraList.clearSpectra(1,wavenum,spectra,time);
%                 end
%                 obj.SpectraList.averageSpectra(1,wavenum,spectra,time);
%             otherwise
%                 error('Acquire Operation Not Defined')
%         end
        
        pause(0.1);
        disp(n);
        n = n+1;
    end
end
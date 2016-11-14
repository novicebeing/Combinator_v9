function self = callback_AcquireButton(self,hObject,eventdata)

        global allanploty;
        allanploty = [];

        averaging = 1;
        
        customScan = false;
        if (hObject == self.continuousAcquireButton)
            % Set save file if needed
            [filename,filepath] = uiputfile('*.m','Save Spectra As...',self.lastSaveLoadDirectory);
            if ~isequal(filename,0) && ~isequal(filepath,0)
               [~,filename,~] = fileparts(filename);
               saveFilename = fullfile(filepath,filename);
               fileCounter = 0;
               self.lastSaveLoadDirectory = filepath;
               
               prompt = {'Scan Variable (photolysisTimeOffsetUs/chemInfo.*/spectrumInfo.*):','Scan Range:','Number of Averages:'};
               dlg_title = 'Input';
               num_lines = 1;
               def = {'photolysisTimeOffsetUs','[-50 -25 0 10 20 30 40 50 75 100 125 150 200 250 300 400 500 750 1000 1500 2000 2500 3000]','30'};
               answer = inputdlg(prompt,dlg_title,num_lines,def);
               if ~isempty(answer)
                  customScan = true;
                  if strcmp(answer{1},'photolysisTimeOffsetUs')
                     customScanVar = 'photolysisTimeOffsetUs';
                     customScanRange = str2num(answer{2});
                     customScanRange = reshape(repmat(reshape(customScanRange,[],1),1,str2double(answer{3})),[],1);
                     customScanRange = customScanRange(randperm(length(customScanRange))); % Randomize the scan
                     customScanNumAvgs = 1;%str2double(answer{3});
                     customScanRangeCounter = 1;
                     customScanAvgCounter = 0;
                  else
                      error('The scan variable must be an accepted input');
                  end 
               end
            else
               saveFilename = [];
               fileCounter = 0;
            end
        else
        end
        
        kobj = kineticsobject();
        
        specY = [];
        avgCleared = 0;
        lastAcquire = 0;
        lastDisplay = 0;
        while (get(self.continuousAcquireButton, 'Value') == 1)
            
            % Ask the user to set the scan variable to what is appropriate
            if customScan == true
                customScanAvgCounter = customScanAvgCounter+1;
                if customScanAvgCounter > customScanNumAvgs
                    customScanRangeCounter = customScanRangeCounter+1;
                    customScanAvgCounter = 1;
                    if customScanRangeCounter > numel(customScanRange)
                        disp('Done with Custom Scan')
                       break;
                    end
                end
                
                if (customScanAvgCounter == 1)
                    if strcmp(customScanVar,'photolysisTimeOffsetUs')
                        % Create a GPIB object.
                        obj1 = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 4, 'Tag', '');

                        % Create the GPIB object if it does not exist
                        % otherwise use the object that was found.
                        if isempty(obj1)
                            obj1 = gpib('NI', 0, 4);
                        else
                            fclose(obj1);
                            obj1 = obj1(1);
                        end

                        % Connect to instrument object, obj1.
                        fopen(obj1);

                        % Communicating with instrument object, obj1.
                        timeDelaySetting = 197e-6 + customScanRange(customScanRangeCounter)*1e-6;
                        fwrite(obj1, sprintf('DT 2,1,%f\r\n',timeDelaySetting));

                        % Disconnect from instrument object, obj1.
                        fclose(obj1);

                        % Clean up all objects.
                        delete(obj1);
                    else
                        msgboxText = sprintf('Set %s to %f',customScanVar,customScanRange(customScanRangeCounter));
                        uiwait(msgbox(msgboxText)); 
                    end
                    avgCleared = 0;
                end
                
                % Set the custom scan variable
                if strcmp(customScanVar,'photolysisTimeOffsetUs')
                    self.photolysisTimeOffsetUs = customScanRange(customScanRangeCounter);
                end
            end
            
            % Wait the appropriate amount of time
            minTimeBetweenAcquisitions_inDays = self.minTimeBetweenAcquisitions/(3600*24);
            
            drawnow;
            while ((now - lastAcquire) < minTimeBetweenAcquisitions_inDays) &&...
                    (get(self.continuousAcquireButton, 'Value') == 1)
               drawnow
            end
            if (get(self.continuousAcquireButton, 'Value') ~= 1)
               break; 
            end
            fprintf('Effective Rate: %f Hz\n',size(specY,3)/15./(now-lastAcquire)/(3600*24));
            lastAcquire = now;
            
            % Acquire the spectra
             [acqSpectra,acqImages,fringeIndices,timestamp] = self.dependencyHandles.MOD_VIPA.acquirePhotolysisSpectra(75);
%              assignin('base','acqImages',acqImages);
%              assignin('base','timestamp',timestamp);
             [specY,timeDelay,bkgSpectra,sigSpectra] = makespectrafromtimestamp(acqSpectra,double(timestamp).*480e-6/4,4000,self.photolysisTimeOffsetUs);
             
             spectrumWavenumber = self.dependencyHandles.MOD_VIPA.public_getWavenumberAxis();
             spectrumWavenumber = reshape(spectrumWavenumber,[],1);
             
             for i = 1:numel(timeDelay)
                kobj.averageSpectrum(spectrumWavenumber,specY(:,:,i),[],timeDelay(i));
             end
             
             % Display a bar plot if necessary (every 2 seconds)
             if (now - lastDisplay)*24*3600 > 2
                 lastDisplay = now;
                 %kobj.displayAveragingBarChart(20,2640,2645);
                 %kobj.displayAveragingBarChart(20,2592,2596);
                 kobj.displayAveragingBarChart(20,2680,2685);
             end
        end
        
        if ~isempty(saveFilename)
            fprintf('Saving...');
            kobj.savedata(fullfile(filepath,filename));
            fprintf('done\n');
        end
        kobj.plotbrowser();
        %figure;plot(kobj.wavenum,reshape(kobj.ysum(:,:,1)./kobj.wsum(:,:,1),[],1));
end
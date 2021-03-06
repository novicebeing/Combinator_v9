function self = collectFringes(self)
%CALLBACK_COLLECTFRINGESBUTTON Summary of this function goes here
%   Detailed explanation goes here
        
        % Get image from screen
        fringeImage = self.fringeImage;
        
        % Bad Pixel Locations
        badPixelKernel = [1 1 1; 1 0 1; 1 1 1]/8;
        fringeImageConv = fringeImage;
        fringeImageConv(isnan(fringeImageConv)) = 0;
        badPixelReplace = conv2(fringeImageConv,badPixelKernel,'same');
        fringeImage(isnan(fringeImage)) = badPixelReplace(isnan(fringeImage));
        fringeImage = fringeImage';
        %figure;imagesc(fringeImage');
        
        % Identify the zero crossings of the image
        windowSize = 30;
        %fringeImageBase = repmat(mean(fringeImage,1),size(fringeImage,1),1);
        fringeImageBase = filter(ones(1,windowSize)/windowSize,1,fringeImage,[],1);
        fringeImageNorm = fringeImage - fringeImageBase;
        
        %figure;imagesc(fringeImageNorm');
        %error
        
        fringeImageNorm1 = fringeImageNorm(1:end-1,:);
        fringeImageNorm2 = fringeImageNorm(2:end,:);
        idx = find(sign(fringeImageNorm1)-sign(fringeImageNorm2));
        [idxX,idxY] = ind2sub(size(fringeImageNorm1),idx);
        %figure;imagesc(fringeImageNorm');hold on;scatter(idxX,idxY,'.k');
        isPeak = (-sign(fringeImageNorm1(idx(1:end-1)))+1)/2;
        m = (fringeImageNorm2(idx)-fringeImageNorm1(idx));
        b = fringeImageNorm1(idx)-m.*idxX;
        idxX = -b./m;
        %figure;imagesc(fringeImageNorm');hold on;scatter(idxX,idxY,'.k');
        
        % Identify the peaks for each row of the image
        thePeaksAndValleysX = (idxX(1:end-1)+idxX(2:end))/2;
        thePeaksAndValleysY = idxY(1:end-1);
        deltaY = idxY(1:end-1)-idxY(2:end);
        thePeaksX = thePeaksAndValleysX((isPeak == 1) & (deltaY == 0));
        thePeaksY = thePeaksAndValleysY((isPeak == 1) & (deltaY == 0));
        %thePeaks = thePeaks(:,2:end-1);
        %figure;imagesc(fringeImageNorm');hold on;scatter(thePeaksX,thePeaksY,'.k');
        
        % Group the rows (and sort them)
        [uniqueRows,ia,ic] = unique(thePeaksY);
        
        % Iterate over the uniqe rows, selecting peaks and adding them to
        % a fringe
        fringesX = {};
        fringesY = {};
        for i = 1:length(uniqueRows)

            idx = find(thePeaksY == uniqueRows(i));
            for j = 1:length(idx)
                if i == 1
                   fringesX{i,j} = thePeaksX(idx(j));
                   fringesY{i,j} = thePeaksY(idx(j));
                else
                    fringeMatchIdx = [];
                    for k = 1:size(fringesX,2)
                        if ~isempty(fringesX{i-1,k}) & (abs(fringesX{i-1,k} - thePeaksX(idx(j))) < 1)
                            fringeMatchIdx = k;
                            break;
                        end
                    end
                    
                   %fringeMatchIdx = find(abs([fringesX{i-1,:}] - thePeaksX(idx(j))) < 1);
                   if isempty(fringeMatchIdx)
                    fringesX{i,end+1} = thePeaksX(idx(j));
                    fringesY{i,end+1} = thePeaksY(idx(j));
                   else
                    fringesX{i,fringeMatchIdx} = thePeaksX(idx(j));
                    fringesY{i,fringeMatchIdx} = thePeaksY(idx(j));
                   end
                   
                end
            end
        end
        %figure;imagesc(fringeImageNorm');hold on;
        %scatter([fringesX{:}],[fringesY{:}],'.k');
        
        % Save the fringes to be used laser
        for i = 1:numel(fringesX);
           if isempty(fringesX{i})
               fringesX{i} = NaN;
           end
           if isempty(fringesY{i})
               fringesY{i} = NaN;
           end
        end
        fringesXmat = cell2mat(fringesX);
        fringesYmat = cell2mat(fringesY);
        
        % Get the minimum x element from each fringe
        fringesStartX = min(fringesXmat,[],1);
        [~,idx] = sort(fringesStartX);

        % Sort the fringes by fringesStartX
        fringesXmatSorted = fringesXmat(:,idx);
        fringesYmatSorted = fringesYmat(:,idx);

        % Remove fringes that do not cover at least half of the screen and
        % that do not have at least 100 points
        newFringesX = [];
        newFringesY = [];
        fringeHighThresh = 0*size(fringeImage',1);
        fringeLowThresh = 1*size(fringeImage',1);
        for i = 1:size(fringesXmatSorted,2)
           if sum(~isnan(fringesXmatSorted(:,i))) > 50 && ...
                   max(fringesYmatSorted(:,i)) > fringeHighThresh && ...
                   min(fringesYmatSorted(:,i)) < fringeLowThresh
               newFringesX(:,end+1) = fringesXmatSorted(:,i);
               newFringesY(:,end+1) = fringesYmatSorted(:,i);
           end
        end
        
        % Save the fringes to be used later
        self.fringeX = newFringesX;
        self.fringeY = newFringesY;
        self.fringeImageSize = size(fringeImage');
        
        % Save other parameters
%         self.fringeXcrop = self.fringeX;
%         self.fringeYcrop = self.fringeY;
        self.spectrumIndcs = sub2ind(size(fringeImage),...
            self.fringeX,...
            self.fringeY);
        
        % Flipping indices
        %warning('Careful Here - I am flipping the indices!!!');
        self.spectrumIndcs = flipud(self.spectrumIndcs);
        self.fringeX = flipud(self.fringeX);
        self.fringeY = flipud(self.fringeY);
        
        self.xAxis_wavenumber = 1:numel(self.spectrumIndcs);
%         self.spectrumX = reshape(1e4./(1:numel(self.spectrumIdcs)),size(self.spectrumIdcs));
        
%         self.spectrumX = zeros(size(self.spectrumIdcs));
%         reflambda = 3.725;
%         fsr = 55;
%         for k = 1:size(self.spectrumIdcs,2)
%             deltaLambda = fsr * 1e9 * ((reflambda/10^6)^2)/3e8 * 1e6;
%             self.spectrumX(:,k) = reflambda + deltaLambda*(k-1) + ...
%                 deltaLambda/size(self.spectrumIdcs,1)*((1:size(self.spectrumIdcs,1))-1);
%         end
        
        % Plot the fringes for the user
        figure;imagesc(fringeImageNorm');hold on;
        fringesOddX = newFringesX(:,1:2:end);
        fringesOddY = newFringesY(:,1:2:end);
        fringesEvenX = newFringesX(:,2:2:end);
        fringesEvenY = newFringesY(:,2:2:end);
        scatter(fringesOddX(:),fringesOddY(:),'.k');
        scatter(fringesEvenX(:),fringesEvenY(:),'.r');
        
        % Set the calibration status
        self.fringesCalibrated = true;
        self.xaxisCalibrated = false;
        self.yaxisCalibrated = false;
end


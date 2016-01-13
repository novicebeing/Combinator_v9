function [t,averageError,averageStdMean] = averageError(obj,wavenumMin,wavenumMax)
    averageError = zeros(size(obj.t));
    averageStdMean = zeros(size(obj.t));
    t = obj.t;
    ind = find(obj.wavenum>wavenumMin & obj.wavenum<wavenumMax);
    
    wsumtemp = obj.wsum;
    wsumtemp(wsumtemp == 0) = NaN;
    for i = 1:numel(obj.t)
        idcs = ind+(i-1)*size(obj.wsum,1)*size(obj.wsum,2);
        %averageError(i) = nanmean(reshape(sqrt(1./wsumtemp(ind+(i-1)*size(obj.wsum,1)*size(obj.wsum,2))),[],1));
        averageError(i) = nanstd(reshape(obj.ysum(idcs)./wsumtemp(idcs),[],1));
        averageStdMean(i) = nanmean(reshape(sqrt(1./wsumtemp(idcs)),[],1));
    end

%     averageError = zeros(size(obj.tavg));
%     t = obj.tavg;
%     ind = find(obj.wavenum>wavenumMin & obj.wavenum<wavenumMax);
%     
%     for i = 1:numel(obj.tavg)
%         averageError(i) = mean(reshape(obj.ystderror(ind+(i-1)*size(ystderror,3)),[],1));
%     end
end
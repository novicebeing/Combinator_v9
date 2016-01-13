function obj = assignyerrors(obj)
    obj.deltay = zeros(size(obj.y));
    obj.ybaseline = zeros(size(obj.y));
    ytemp = reshape(obj.y,size(obj.y,1)*size(obj.y,2),1,size(obj.y,3));
    for i = 1:numel(obj.wavenum)
        ind = find(abs(obj.wavenum-obj.wavenum(i)) < 0.4);
        [ii,jj] = ind2sub([size(obj.y,1) size(obj.y,2)],i);
        %[iii,jjj] = ind2sub([size(obj.y,1) size(obj.y,2)],ind);
        %thestd = std(ytemp(ind,:),[],1);
        obj.deltay(ii,jj,:) = nanstd(ytemp(ind,:),[],1);
        obj.ybaseline(ii,jj,:) = nanmean(ytemp(ind,:),1);
    end
    %obj.deltay(obj.deltay == 0) = NaN;
end
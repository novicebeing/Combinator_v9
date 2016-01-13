function obj = displayAveragingBarChart(obj,hfig,wavenumMin,wavenumMax)
        global allanplotx;
        global allanploty;

        % Gather the errors
        [tplot,averageErrorPlot,averageStdMean] = obj.averageError(wavenumMin,wavenumMax);
        
        % Sort t,averageError
        [~,isort] = sort(tplot);
        
        % Display the bar chart
        figure(hfig); hold off;
        bar(1./averageStdMean(isort),'k'); hold on;
        bar(1./averageErrorPlot(isort));
        %ylim([0 1000]);
        
%         % Display an "Allan" Plot
%         allanplotx = tplot(isort);
%         if size(allanploty,1) ~= numel(isort)
%             allanploty = [];
%         end
%         n = size(allanploty,2)*(~isempty(allanploty));
%         allanploty(:,n+1) = reshape(averageErrorPlot(isort),[],1);
%         
%         h = figure(21);
%         hold off
%         for i = 1:size(allanploty,1)
%             loglog(1:size(allanploty,2),allanploty(i,:)'); hold on;
%         end
%         ylim([1e-4 1e-2]);
end
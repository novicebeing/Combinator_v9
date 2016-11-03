function DOCO_v7_COfigure(fitobjnames,fitobjs)
    
    % Define the variants
    variants = sbiovariant('fvariant');
    addcontent(variants, {'parameter', 'f', 'value', 0.164});
    addcontent(variants, {'parameter', 'ODscale', 'value', 1});
    addcontent(variants, {'parameter', 'DOCOscale', 'value', 1});
    addcontent(variants, {'parameter', 'D2Oscale', 'value', 1});
    addcontent(variants, {'parameter', 'tpump', 'value', 25000});
    addcontent(variants, {'parameter', 'HOCO_LOSS.k', 'value', 0});

    intTimes = zeros(size(fitobjs));
    x = ezeros(size(fitobjs));
    y = ezeros(size(fitobjs));
    xxsim = zeros(size(fitobjs));
    yysim = zeros(size(fitobjs));
    hwait = waitbar(0,'Running Simulations...', 'WindowStyle', 'modal');
    for ii = 1:numel(fitobjs)
        fitobject = fitobjs{ii};
        
        CO = fitobject.initialConditionsTable.CO;
        
        try
            intBox = fitobject.initialConditionsTable.intWindow;
        catch ee
            intBox = 50;
        end
        
        % Evaluate a slope for the first two OD points
        ODidx = find(strcmp('OD',fitobject.fitbNames));
        DOCOidx = find(strcmp('trans-DOCO',fitobject.fitbNames));
        time = fitobject.t;
        ODtrace = fitobject.fitb(fitobject.fitbNamesInd(ODidx),:)/14700;
        ODtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(ODidx),:)/14700;
        DOCOtrace = fitobject.fitb(fitobject.fitbNamesInd(DOCOidx),:)/14700;
        DOCOtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(DOCOidx),:)/14700;

        % Find the first two time points
        time2 = time;
        time2(time < 0) = NaN;
        [~,firstidx] = nanmin(time2);
        time3 = time2;
        time3(firstidx) = NaN;
        [~,secondidx] = nanmin(time3);
        dt = (time(secondidx) - time(firstidx))/1e6;

        % Calculate the simulated data
        %data = runsimbiologyscanincurrentworkspace(fitobject.getTable(1,14700),variants);
        %[t,ysim,names] = getdata(data(1));
        t=time;
        ysim = zeros(numel(time),2);
        names = {'ODscaled','DOCOscaled'};
        %t = t-50;
        
        ysimbox = zeros(size(ysim));
        for i = 1:numel(names)
            yyy = ysim(:,i);
            [~,ind,~] = unique(t);
            xint = linspace(nanmin(t),nanmax(t),2e5);
            yint = interp1(t(ind),yyy(ind),xint);
            windowSize = round(50/(xint(2)-xint(1)));
            yintbox = filter((1/windowSize)*ones(1,windowSize),1,yint);
            ysimbox(:,i) = interp1(xint,yintbox,t);
            %set(gca,'FontSize',14);
            %xlabel('Time (\mus)');
            %ylabel('DOCO Concentration (mlc cm^{-3})');
        end
        
        % Get the proper indices for the data
        odsimInd = find(strcmp(names,'ODscaled'));
        docosimInd = find(strcmp(names,'DOCOscaled'));
        
        [~,ind,~] = unique(t);
        DOCOsim1 = interp1(t(ind),ysimbox(ind,docosimInd),-25);
        DOCOsim2 = interp1(t(ind),ysimbox(ind,docosimInd),0);
        dDOCOdtsim = (interp1(t(ind),ysimbox(ind,docosimInd),time(secondidx))-interp1(t(ind),ysimbox(ind,docosimInd),time(firstidx)))/dt;
        dDOCOdt2sim = (1/(50e-6)^2*DOCOsim2+1/(25e-6)^2*DOCOsim1)*100e-6/2;
        
        ODsim1 = interp1(t(ind),ysimbox(ind,odsimInd),time(firstidx));
        ODsim2 = interp1(t(ind),ysimbox(ind,odsimInd),time(secondidx));
        ODmeansim = (ODsim1+ODsim2)/2;
        
        
        % Calculate and print the DOCO slope
        dDOCOdt = (edouble(DOCOtrace(4),DOCOtraceErr(4))-edouble(DOCOtrace(3),DOCOtraceErr(3)))/(time(4)-time(3))*1e6;
        dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
        n = 2; ind3 = 3:7; p = polyfit(time(ind3)*1e-6,DOCOtrace(ind3),n);
        
        [xData, yData] = prepareCurveData( time(ind3),DOCOtrace(ind3)/1e12 );
        % Set up fittype and options.
        ft = fittype( 'b*(x+delta/2)+c*(x^2+delta*x+delta^2/3)', 'independent', 'x', 'dependent', 'y','problem','delta' );
        %ft = fittype( 'a+b*x+c*x^2+delta*0', 'independent', 'x', 'dependent', 'y','problem','delta' );
        %ft = fittype( 'b*(x+delta/2)+delta*0', 'independent', 'x', 'dependent', 'y','problem','delta' );
        opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        opts.weights = 1./(DOCOtraceErr(ind3)/1e12).^2;
%         [fitresult, gof, output] = fit( xData, yData, ft, opts,'problem',intBox );
%         ci = confint(fitresult,0.68);
%         output.Jacobian
%         %gof
%         return
%         rmse = sqrt(gof.sse/gof.dfe);
%         dDOCOdt3 = edouble(fitresult.b,(ci(1)-fitresult.b)/rmse)*1e12*1e6;
        
        % Fit the data in a different manner
        M = [(xData+intBox/2) (xData.^2+intBox.*xData+intBox.^2/3)];
        [b,stdb,mse] = lscov(M,DOCOtrace(ind3)'/1e12,1./(DOCOtraceErr(ind3)/1e12).^2);
        
        dDOCOdt3 = edouble(b(1),stdb(1))*1e12*1e6;
        %dDOCOdt3 = (DOCOtrace(ind3(2))-DOCOtrace(ind3(1)))/(time(ind3(2))-time(ind3(1)))*1e6;
        %dDOCOdt3 = (edouble(DOCOtrace(ind3(2)),DOCOtraceErr(ind3(2)))-edouble(DOCOtrace(ind3(1)),DOCOtraceErr(ind3(1))))/(time(ind3(2))-time(ind3(1)))*1e6;
        %dDOCOdt3 = dDOCOdt3.value(:);
        
        if ii == 1
            figh = 400;
            figw = 600;
            smallplotlinewidth = 1;
            figure('Position', [100, 100, figw,figh]); 
            subplot(2,1,1); htop = gca;
            subplot(2,1,2); hbottom = gca;
            set(htop,'Position',[0.157094594594595 0.583837209302326 0.814189189189189 0.341162790697675]);
            set(hbottom,'Position',[0.157094594594595 0.2 0.812500000000001 0.341162790697674]);
        end
%         if strcmp(fitobjnames{ii},'v_20160210_CO_1')
%             % Plot DOCO
%             xxxsim = linspace(min(time(ind3)),max(time(ind3)),100)';
%             Mxxx = [(xxxsim+intBox/2) (xxxsim.^2+intBox.*xxxsim+intBox.^2/3)];
%             indxxx = find(time<100 & time>=0);
%             axes(htop); errorbar(time(indxxx),DOCOtrace(indxxx)/1e12,DOCOtraceErr(indxxx)/1e12,'.','LineWidth',smallplotlinewidth,'DisplayName','50 \mus','Color',[0 0.447 0.741]); hold on;
%             plot(xxxsim,(b')*(Mxxx'),'LineWidth',smallplotlinewidth,'DisplayName','50 \mus fit','Color',[0 0.447 0.741]);
%             xlim([-5 80]);
%             ylim([-0.02 0.45]);
%             set(gca,'FontSize',12);
%             set(gca,'XTickLabel',[]);
%             % Plot OD
%             axes(hbottom); errorbar(time(indxxx),ODtrace(indxxx)/1e12,ODtraceErr(indxxx)/1e12,'.','LineWidth',smallplotlinewidth,'Color',[0 0.447 0.741]); hold on;
%             xlim([-5 80]);
%             ylim([0 4]);
%             set(gca,'FontSize',12);
%             linkaxes([htop hbottom],'x');
%         end
        
        if strcmp(fitobjnames{ii},'v_20160315_ShortInt1')
            % Plot DOCO
            xxxsim = linspace(min(time(ind3)),max(time(ind3)),100)';
            Mxxx = [(xxxsim+intBox/2) (xxxsim.^2+intBox.*xxxsim+intBox.^2/3)];
            indxxx = find(time<100 & time>=-25);
            axes(htop); errorbar(time(indxxx),DOCOtrace(indxxx)/1e12,DOCOtraceErr(indxxx)/1e12,'.','LineWidth',smallplotlinewidth,'DisplayName','10 \mus','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]); hold on;
            plot(xxxsim,(b')*(Mxxx'),'LineWidth',smallplotlinewidth,'DisplayName','10 \mus fit','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            xlim([-30 80]);
            ylim([0 0.45]);
            set(gca,'FontSize',12);
            set(gca,'XTickLabel',[]);
            ylabel({'[DOCO]\times10^{-12}','(mlc cm{-3})'});
            legend1 = legend(htop,'show');
            set(legend1,...
                'Position',[0.315867121915692 0.59672838996836 0.62837837012233 0.0617283936635947],...
                'Orientation','horizontal',...
                'EdgeColor',[1 1 1]);
            % Plot OD
            axes(hbottom); errorbar(time(indxxx),ODtrace(indxxx)/1e12,ODtraceErr(indxxx)/1e12,'.','LineWidth',smallplotlinewidth,'Color',[0.850980392156863 0.325490196078431 0.0980392156862745]); hold on;
            xlim([-30 80]);
            ylim([0 4]);
            set(gca,'FontSize',12);
            xlabel('Time (\mus)');
            ylabel({'[OD]\times10^{-12}';'(mlc cm{-3})'});
            annotation(gcf,'rectangle',[0.261000000000001 0.3875 0.169 0.125],'LineStyle','--');
        end
        
        i = 1;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;

        ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
        
         xxsim(ii) = CO;
         yysim(ii) = dDOCOdtsim/ODmeansim;
         y(ii) = dDOCOdt3/ODmean*edouble(1,0.01);
         x(ii) = edouble(1,0)*CO;%ExtraRxns/ODmean/CO;
         intTimes(ii) = intBox;
         
         waitbar(ii/numel(fitobjs),hwait);
    end
    close(hwait);
    
    % Fit
    [xData, yData, weights] = prepareCurveData( x.value(:), y.value(:), 1./y.errorbar(:).^2 );

    % Set up fittype and options.
    ft = fittype( 'poly2' );
    opts = fitoptions( 'Method', 'LinearLeastSquares' );
    opts.Lower = [-inf -inf 0];
    opts.Upper = [inf inf 0];
    %opts.Lower = [-inf -inf 0];
    %opts.Upper = [inf inf 0];
    opts.Weights = weights;

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
    fitresult
    bs = coeffvalues(fitresult);
    dbs = coeffstderrors(fitresult,gof);
    bout = edouble(bs,dbs);
    bout(1)
    bout(2)
%     % Fit the data in a different manner
%     M = [xData xData.^2];
%     [b,stdb,mse] = lscov(M,yData',weights);
    
    % Generate the fit line
    xmin = min(x.value(:));
    xrange = max(x.value(:))-min(x.value(:));
    xfit = linspace(0,xmin+1.1*xrange,1000);
    yfit = feval(fitresult,xfit);
    ci = predint(fitresult,xfit);
    
    figure;plot(x(intTimes==50),y(intTimes==50),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('CO Concentration (mlc cm^{-3})');
    ylabel('DOCO Rate Relative to OD (s^{-1})');
    hold on;
    plot(x(intTimes==10),y(intTimes==10),'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    plot(x(intTimes==25),y(intTimes==25),'go','MarkerFaceColor','g','MarkerEdgeColor','g');
    plot(xfit,yfit,'Color','r','LineWidth',2);
    plot(xfit,ci(:,1),'r--','LineWidth',1);
    plot(xfit,ci(:,2),'r--','LineWidth',1);
   
    scatter(xxsim,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
end


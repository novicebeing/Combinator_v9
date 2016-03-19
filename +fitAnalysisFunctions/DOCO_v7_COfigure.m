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
        [fitresult, gof] = fit( xData, yData, ft, opts,'problem',intBox );
        
        dDOCOdt3 = fitresult.b*1e12*1e6;
        %dDOCOdt3 = (DOCOtrace(ind3(2))-DOCOtrace(ind3(1)))/(time(ind3(2))-time(ind3(1)))*1e6;
        %dDOCOdt3 = (edouble(DOCOtrace(ind3(2)),DOCOtraceErr(ind3(2)))-edouble(DOCOtrace(ind3(1)),DOCOtraceErr(ind3(1))))/(time(ind3(2))-time(ind3(1)))*1e6;
        %dDOCOdt3 = dDOCOdt3.value(:);
        
        xxxsim = linspace(min(time(ind3)),max(time(ind3)),100);
        figure; plot(time,DOCOtrace/1e12); hold on;
        plot(xxxsim,feval(fitresult,xxxsim));
        xlim([-25 60]);
        
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
    opts.Lower = [-Inf -inf 0];
    opts.Upper = [Inf inf 0];
    opts.Weights = weights;

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
    fitresult
    
    % Generate the fit line
    xmin = min(x.value(:));
    xrange = max(x.value(:))-min(x.value(:));
    xfit = linspace(xmin-0.1*xrange,xmin+1.1*xrange,1000);
    yfit = feval(fitresult,xfit);
    ci = predint(fitresult,xfit);
    
    figure;plot(x(intTimes==50),y(intTimes==50),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('CO Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(x(intTimes==10),y(intTimes==10),'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    plot(xfit,yfit,'Color','r','LineWidth',2);
    plot(xfit,ci(:,1),'r--','LineWidth',1);
    plot(xfit,ci(:,2),'r--','LineWidth',1);
   
    scatter(xxsim,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
end


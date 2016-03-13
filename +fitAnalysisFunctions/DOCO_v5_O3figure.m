function DOCO_v5_O3figure(fitobjnames,fitobjs)
    
    % Define the variants
    variants = sbiovariant('fvariant');
    addcontent(variants, {'parameter', 'f', 'value', 0.164});
    addcontent(variants, {'parameter', 'ODscale', 'value', 1});
    addcontent(variants, {'parameter', 'DOCOscale', 'value', 1});
    addcontent(variants, {'parameter', 'D2Oscale', 'value', 1});
    addcontent(variants, {'parameter', 'tpump', 'value', 25000});
    addcontent(variants, {'parameter', 'HOCO_LOSS.k', 'value', 0});

    x = ezeros(size(fitobjs));
    y = ezeros(size(fitobjs));
    xxsim = zeros(size(fitobjs));
    yysim = zeros(size(fitobjs));
    hwait = waitbar(0,'Running Simulations...', 'WindowStyle', 'modal');
    for ii = 1:numel(fitobjs)
        fitobject = fitobjs{ii};
        
        O3 = fitobject.initialConditionsTable.O3;
        CO = fitobject.initialConditionsTable.CO;
        D2 = fitobject.initialConditionsTable.D2;
        N2 = fitobject.initialConditionsTable.N2;
        
        % Evaluate a slope for the first two OD points
        ODidx = find(strcmp('OD',fitobject.fitbNames));
        DOCOidx = find(strcmp('trans-DOCO',fitobject.fitbNames));
        time = fitobject.t;
        ODtrace = fitobject.fitb(fitobject.fitbNamesInd(ODidx),:)/14700;
        ODtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(ODidx),:)/14700;
        DOCOtrace = fitobject.fitb(fitobject.fitbNamesInd(DOCOidx),:)/14700;
        DOCOtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(DOCOidx),:)/14700;

        % Find the first two time points
        time(time < 0) = NaN;
        [~,firstidx] = nanmin(time);
        time2 = time;
        time2(firstidx) = NaN;
        [~,secondidx] = nanmin(time2);
        dt = (time(secondidx) - time(firstidx))/1e6;

        % Calculate the simulated data
        data = runsimbiologyscanincurrentworkspace(fitobject.getTable(1,14700),variants);
        [t,ysim,names] = getdata(data(1));
        t = t-50;
        
        ysimbox = zeros(size(ysim));
        for i = 1:numel(names)
            yyy = ysim(:,i);
            [~,ind,~] = unique(t);
            xint = linspace(min(t),max(t),1e6);
            yint = interp1(t(ind),yyy(ind),xint);
            windowSize = round(50/(xint(2)-xint(1)));
            yintbox = filter((1/windowSize)*ones(1,windowSize),1,yint);
            ysimbox(:,i) = interp1(xint,yintbox,t);
        end
        
        % Get the proper indices for the data
        odsimInd = find(strcmp(names,'ODscaled'));
        docosimInd = find(strcmp(names,'DOCOscaled'));
        
        [~,ind,~] = unique(t);
        DOCOsim1 = interp1(t(ind),ysimbox(ind,docosimInd),25);
        DOCOsim2 = interp1(t(ind),ysimbox(ind,docosimInd),50);
        dDOCOdt2sim = (1/(50e-6)^2*DOCOsim2+1/(25e-6)^2*DOCOsim1)*100e-6/2;
        ODsim1 = interp1(t(ind),ysimbox(ind,odsimInd),time(firstidx));
        ODsim2 = interp1(t(ind),ysimbox(ind,odsimInd),0);
        ODmeansim = ODsim2;
        
        
        % Calculate and print the DOCO slope
        dDOCOdt = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))-edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/dt;
        dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
        
        i = 0;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;

        ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
        
         xxsim(ii) = O3;
         yysim(ii) = dDOCOdt2sim/ODmeansim;
         y(ii) = dDOCOdt2/ODmean;
         x(ii) = edouble(1,0)*O3;%ExtraRxns/ODmean/CO;
         
         waitbar(ii/numel(fitobjs),hwait);
    end
    close(hwait);
    
    % Fit
    [xData, yData, weights] = prepareCurveData( x.value(:), y.value(:), 1./y.errorbar(:).^2 );

    % Set up fittype and options.
    ft = fittype( 'poly1' );
    opts = fitoptions( 'Method', 'LinearLeastSquares' );
    opts.Weights = weights;

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
    
    % Generate the fit line
    xmin = min(x.value(:));
    xrange = max(x.value(:))-min(x.value(:));
    xfit = linspace(xmin-0.1*xrange,xmin+1.1*xrange,1000);
    yfit = feval(fitresult,xfit);
    ci = predint(fitresult,xfit);
    
    figure;plot(x,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('O_3 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xfit,yfit,'Color','r','LineWidth',2);
    plot(xfit,ci(:,1),'r--','LineWidth',1);
    plot(xfit,ci(:,2),'r--','LineWidth',1);
   
    scatter(xxsim,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
end


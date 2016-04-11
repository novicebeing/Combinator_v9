function DOCO_v5_N2figure(fitobjnames,fitobjs)
    
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
        
        N2 = fitobject.initialConditionsTable.N2;
        if isfield(fitobject.initialConditionsTable,'intWindow')
            intBox = fitobject.initialConditionsTable.intWindow;
        else
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
        time(time < 0) = NaN;
        [~,firstidx] = nanmin(time);
        time2 = time;
        time2(firstidx) = NaN;
        [~,secondidx] = nanmin(time2);
        secondidx = secondidx+1;
        dt = (time(secondidx) - time(firstidx))/1e6;

        % Calculate the simulated data
        data = runsimbiologyscanincurrentworkspace(fitobject.getTable(1,14700),variants);
        [t,ysim,names] = getdata(data(1));
        t = t-intBox;
        
        ysimbox = zeros(size(ysim));
        %intBox = 10;
        for i = 1:numel(names)
            yyy = ysim(:,i);
            [~,ind,~] = unique(t);
            xint = linspace(min(t),max(t),1e6);
            yint = interp1(t(ind),yyy(ind),xint);
            windowSize = round(intBox/(xint(2)-xint(1)));
            yintbox = filter((1/windowSize)*ones(1,windowSize),1,yint);
            ysimbox(:,i) = interp1(xint,yintbox,t);
        end
        
        % Get the proper indices for the data
        odsimInd = find(strcmp(names,'ODscaled'));
        docosimInd = find(strcmp(names,'DOCOscaled'));
        
        [~,ind,~] = unique(t);
        DOCOsim1 = interp1(t(ind),ysimbox(ind,docosimInd),-25);
        DOCOsim2 = interp1(t(ind),ysimbox(ind,docosimInd),0);
        
        indcs = [firstidx secondidx secondidx+1];
        [xData, yData] = prepareCurveData( time(indcs), interp1(t(ind),ysimbox(ind,docosimInd),time(indcs)));
        ft = fittype( 'poly1' );
        opts = fitoptions( 'Method', 'LinearLeastSquares' );
        %opts.Weights = weights;
        
        [fitresult, gof] = fit( xData, yData, ft, opts );
        
        dDOCOdtsim = fitresult.p1*1e6;
        %dDOCOdtsim = (interp1(t(ind),ysimbox(ind,docosimInd),time(secondidx))-interp1(t(ind),ysimbox(ind,docosimInd),time(firstidx)))/dt
        dDOCOdt2sim = (1/(50e-6)^2*DOCOsim2+1/(25e-6)^2*DOCOsim1)*100e-6/2;
        ODsim1 = interp1(t(ind),ysimbox(ind,odsimInd),time(firstidx));
        ODsim2 = interp1(t(ind),ysimbox(ind,odsimInd),time(secondidx));
        ODsim3 = interp1(t(ind),ysimbox(ind,odsimInd),time(secondidx+1));
        ODmeansim = (ODsim1+ODsim2+ODsim3)/2;
        
        
        % Calculate and print the DOCO slope
        dDOCOdt = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))-edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/dt;
        % Fit
        indcs = [firstidx secondidx secondidx+1];
        [xData, yData, weights] = prepareCurveData( time(indcs), DOCOtrace(indcs), 1./DOCOtraceErr(indcs).^2 );

        % Set up fittype and options.
        ft = fittype( 'poly1' );
        opts = fitoptions( 'Method', 'LinearLeastSquares' );
        opts.Weights = weights;
        
        [fitresult, gof] = fit( xData, yData, ft, opts );
        ci = confint(fitresult);
        dDOCOdt = edouble(fitresult.p1,0)*1e6
        
        dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
        
        i = 0;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;

        ODmean = (edouble(ODtrace(secondidx+1),ODtraceErr(secondidx+1))+edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/3;
        %ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
        
         xxsim(ii) = N2;
         yysim(ii) = dDOCOdtsim/ODmeansim;
         y(ii) = dDOCOdt/ODmean;
         x(ii) = edouble(1,0)*N2;%ExtraRxns/ODmean/CO;
         
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
    
    fitresult
    
    % Generate the fit line
    xmin = min(x.value(:));
    xrange = max(x.value(:))-min(x.value(:));
    xfit = linspace(xmin-0.1*xrange,xmin+1.1*xrange,1000);
    yfit = feval(fitresult,xfit);
    ci = predint(fitresult,xfit);
    
    figure;
    for i =1:numel(x)
        plot(x(i),y(i),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
        hold on;
    end
    xlabel('N_2 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xfit,yfit,'Color','r','LineWidth',2);
    plot(xfit,ci(:,1),'r--','LineWidth',1);
    plot(xfit,ci(:,2),'r--','LineWidth',1);
   
    scatter(xxsim,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
end


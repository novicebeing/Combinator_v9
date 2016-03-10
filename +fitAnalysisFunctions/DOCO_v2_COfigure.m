function DOCO_v2_COfigure(fitobjnames,fitobjs)
    

    x = ezeros(size(fitobjs));
    y = ezeros(size(fitobjs));
    for ii = 1:numel(fitobjs)
        fitobject = fitobjs{ii};

        CO = fitobject.initialConditionsTable.CO;
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

        % Calculate and print the DOCO slope
        dDOCOdt = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))-edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/dt;
        dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
        i = 0;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;

        ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;

         y(ii) = dDOCOdt2/ODmean;
         x(ii) = edouble(1,0)*CO;%ExtraRxns/ODmean/CO;
    end
    
    % Fit
    [xData, yData, weights] = prepareCurveData( x.value(:), y.value(:), 1./y.errorbar(:).^2 );

    % Set up fittype and options.
    ft = fittype( 'poly2' );
    opts = fitoptions( 'Method', 'LinearLeastSquares' );
    opts.Lower = [-Inf -Inf 0];
    opts.Upper = [Inf Inf 0];
    opts.Weights = weights;

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
    
    % Generate the fit line
    xmin = min(x.value(:));
    xrange = max(x.value(:))-min(x.value(:));
    xfit = linspace(0,xmin+1.1*xrange,1000);
    yfit = feval(fitresult,xfit);
    ci = predint(fitresult,xfit);
    
    figure;plot(x,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('CO Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xfit,yfit,'Color','r','LineWidth',2);
    plot(xfit,ci(:,1),'r--','LineWidth',1);
    plot(xfit,ci(:,2),'r--','LineWidth',1);
    set(gca,'FontSize',14);
    
    assignin('base','x',x);
    assignin('base','y',y);
end
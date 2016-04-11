function DOCO_v6_COfigure(fitobjnames,fitobjs)
    
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
    
    % Define the fit data
    pathlength = 14700;
    for i = 1:length(fitobjs)
        if i == 1
            dataToFit = fitobjs{i}.getTable(1,pathlength);
        else
            dataToFit = union(dataToFit,fitobjs{i}.getTable(i,pathlength));
        end
        %plants{i}.exportDOCOglobals();
    end
    data = runsimbiologyscanincurrentworkspace(dataToFit,variants);
    hwait = waitbar(0,'Running Analysis...', 'WindowStyle', 'modal');
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

        % Calculate the simulated data
        %data = runsimbiologyscanincurrentworkspace(fitobject.getTable(1,14700),variants);
        [t,ysim,names] = getdata(data(ii));
        t = t-50;
        
        ysimbox = zeros(size(ysim));
        for i = 1:numel(names)
            yyy = ysim(:,i);
            [~,ind,~] = unique(t);
            xint = linspace(min(t),max(t),2e5);
            yint = interp1(t(ind),yyy(ind),xint);
            windowSize = round(50/(xint(2)-xint(1)));
            yintbox = filter((1/windowSize)*ones(1,windowSize),1,yint);
            ysimbox(:,i) = interp1(xint,yintbox,t);
        end
        
        % Get the proper indices for the data
        odsimInd = find(strcmp(names,'ODscaled'));
        docosimInd = find(strcmp(names,'DOCOscaled'));
        
        [~,ind,~] = unique(t);
        point1=1;  point2=20;
        ODmean4sim = interp1(t(ind)+50,ysim(ind,odsimInd),(point1+point2)/2);
        dDOCOdt4sim = (interp1(t(ind)+50,ysim(ind,docosimInd),point2)-interp1(t(ind)+50,ysim(ind,docosimInd),point1))/1e-6/(point2-point1);
        DOCOsim1 = interp1(t(ind),ysimbox(ind,docosimInd),-25);
        DOCOsim2 = interp1(t(ind),ysimbox(ind,docosimInd),0);
        dDOCOdtsim = (interp1(t(ind),ysimbox(ind,docosimInd),time(secondidx))-interp1(t(ind),ysimbox(ind,docosimInd),time(firstidx)))/dt;
        dDOCOdt2sim = (1/(50e-6)^2*DOCOsim2+1/(25e-6)^2*DOCOsim1)*100e-6/2;
        %dDOCOdt3sim = (interp1(t(ind),ysimbox(ind,docosimInd),time(secondidx))/(time(secondidx)+50/2) + ...
        %    interp1(t(ind),ysimbox(ind,docosimInd),time(firstidx))/(time(firstidx)+50/2))/2;
        
        %%
        
        ODsim1 = interp1(t(ind),ysimbox(ind,odsimInd),time(firstidx));
        ODsim2 = interp1(t(ind),ysimbox(ind,odsimInd),time(secondidx));
        ODmeansim = (ODsim1+ODsim2)/2;
        ODmeansim2 = interp1(t(ind)+50,ysim(ind,odsimInd),1.5);
        
        
        % Calculate and print the DOCO slope
        dDOCOdt = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))-edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/dt;
        dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
        dDOCOdt2 = (edouble(DOCOtrace(3),DOCOtraceErr(3))/(time(3)+50/2) + ...
            edouble(DOCOtrace(4),DOCOtraceErr(4))/(time(4)+50/2))/2/1e-6;
        
        %% Fit: 'untitled fit 5'.
        yfit = DOCOtrace(2:5)/1e12;
        yfitErr = DOCOtraceErr(2:5)/1e12;
        [xData, yData, weights] = prepareCurveData( fitobject.t(2:5),yfit,1./yfitErr.^2 );
        [~,ind,~] = unique(t);
        [xDataSim,yDataSim] = prepareCurveData( fitobject.t(2:5),interp1(t(ind),ysimbox(ind,docosimInd),fitobject.t(2:5))/1e12);

        % Set up fittype and options.
        ft = fittype( 'a/b*(ebox(x,0,50)-ebox(x,b,50))', 'independent', 'x', 'dependent', 'y' );
        opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        opts.StartPoint = [0.152248002862074 0.759041680363263];
        opts.Lower = [0 0];
        opts.Upper = [Inf Inf];

        % Fit model to data.
        [fitresult, gof] = fit( xData, yData, ft, opts );
        fitresult
        %figure;plot(fitobject.t,DOCOtrace/1e12,'o'); hold on;
        %tsim = linspace(min(fitobject.t),1000,10000);
        %plot(tsim,feval(fitresult,tsim));
        pram = confint(fitresult,0.68);
        dDOCOdt3 = edouble(fitresult.a,pram(1)-fitresult.a)*1e12*1e6;
        [fitresult, gof] = fit( xDataSim, yDataSim, ft, opts );
        dDOCOdt3sim = fitresult.a*1e12*1e6;
%         figure;plot(fitobject.t,interp1(t(ind),ysimbox(ind,docosimInd),fitobject.t)/1e12,'o'); hold on;
%         tsim = linspace(min(fitobject.t),1000,10000);
%         plot(tsim,feval(fitresult,tsim));
        
        %%
        
        i = 0;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;

        ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
        
         xxsim(ii) = CO;
         yysim(ii) = dDOCOdt4sim/ODmean4sim;
         y(ii) = dDOCOdt3/ODmean;
         x(ii) = edouble(1,0)*CO;%ExtraRxns/ODmean/CO;
         
         waitbar(ii/numel(fitobjs),hwait);
    end
    close(hwait);
    
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
    fitresult
    gof
    
    Chi2 = sum((yData-fitresult(xData)).^2.*weights)/(numel(xData)-2-1)
    
    
    % Generate the fit line
    xmin = min(x.value(:));
    xrange = max(x.value(:))-min(x.value(:));
    xfit = linspace(xmin-0.1*xrange,xmin+1.1*xrange,1000);
    yfit = feval(fitresult,xfit);
    ci = predint(fitresult,xfit);
    
    figure;plot(x,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('CO Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xfit,yfit,'Color','r','LineWidth',2);
    plot(xfit,ci(:,1),'r--','LineWidth',1);
    plot(xfit,ci(:,2),'r--','LineWidth',1);
   
    scatter(xxsim,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
end


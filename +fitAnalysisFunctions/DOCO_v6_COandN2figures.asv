function DOCO_v6_COandN2figures(fitobjnames,fitobjs)
    
    % Define the variants
    variants = sbiovariant('fvariant');
    addcontent(variants, {'parameter', 'f', 'value', 0.164});
    addcontent(variants, {'parameter', 'ODscale', 'value', 1});
    addcontent(variants, {'parameter', 'DOCOscale', 'value', 1});
    addcontent(variants, {'parameter', 'D2Oscale', 'value', 1});
    addcontent(variants, {'parameter', 'tpump', 'value', 25000});
    addcontent(variants, {'parameter', 'HOCO_LOSS.k', 'value', 0});

    intTimes = zeros(size(fitobjs));
    xCO = ezeros(size(fitobjs));
    xN2 = ezeros(size(fitobjs));
    xO3 = ezeros(size(fitobjs));
    xD2 = ezeros(size(fitobjs));
    y = ezeros(size(fitobjs));
    xxsim = zeros(size(fitobjs));
    yysim = zeros(size(fitobjs));
    yDOCO_O3 = zeros(size(fitobjs));
    yDOCO_LOSS = ezeros(size(fitobjs));
    
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
    %data = runsimbiologyscanincurrentworkspace(dataToFit,variants);
    hwait = waitbar(0,'Running Analysis...', 'WindowStyle', 'modal');
    for ii = 1:numel(fitobjs)
        fitobject = fitobjs{ii};
        
        CO = fitobject.initialConditionsTable.CO;
        N2 = fitobject.initialConditionsTable.N2;
        O3 = fitobject.initialConditionsTable.O3;
        D2 = fitobject.initialConditionsTable.D2;
        
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
        %[t,ysim,names] = getdata(data(ii));
        t=time;
        ysim = zeros(numel(time),2);
        names = {'ODscaled','DOCOscaled'};
        %t = t-50;
        
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
        DOCOsim1 = interp1(t(ind),ysimbox(ind,docosimInd),-25);
        DOCOsim2 = interp1(t(ind),ysimbox(ind,docosimInd),0);
        dDOCOdtsim = (interp1(t(ind),ysimbox(ind,docosimInd),time(secondidx))-interp1(t(ind),ysimbox(ind,docosimInd),time(firstidx)))/dt;
        dDOCOdt2sim = (1/(50e-6)^2*DOCOsim2+1/(25e-6)^2*DOCOsim1)*100e-6/2;
        ODsim1 = interp1(t(ind),ysimbox(ind,odsimInd),time(firstidx));
        ODsim2 = interp1(t(ind),ysimbox(ind,odsimInd),time(secondidx));
        ODmeansim = (ODsim1+ODsim2)/2;
        
        
        % Calculate and print the DOCO slope
        dDOCOdt = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))-edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/dt;
        dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
        n = 2; ind3 = 3:7; p = polyfit(time(ind3)*1e-6,DOCOtrace(ind3),n);
        
        [xData, yData] = prepareCurveData( time(ind3),DOCOtrace(ind3)/1e12 );
         % Set up fittype and options.
         %ft = fittype( 'a/b+a/b^2/delta*exp(-b*(x+delta))-a/b^2/delta*exp(b*delta-b*(x+delta))', 'independent', 'x', 'dependent', 'y','problem','delta' );
         %ft = fittype( 'a+b*x+c*x^2+delta*0', 'independent', 'x', 'dependent', 'y','problem','delta' );
         %ft = fittype( 'b*(x+delta/2)+delta*0', 'independent', 'x', 'dependent', 'y','problem','delta' );
         %opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
         %[fitresult, gof] = fit( xData, yData, ft, opts,'problem',intBox );
        
        M = [(xData+intBox/2) (xData.^2+intBox.*xData+intBox.^2/3)];
        [b,stdb,mse] = lscov(M,DOCOtrace(ind3)'/1e12,1./(DOCOtraceErr(ind3)/1e12).^2);
        
        dDOCOdt3 = edouble(b(1),stdb(1)*sqrt(1/mse))*1e12*1e6;
        
        i = 1;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;
        DOCOmean = DOCOmean.value;
        ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
        
         xxsim(ii) = CO;
         yysim(ii) = (dDOCOdt2sim*2 + 0*dDOCOdtsim)/2/ODmeansim;
         y(ii) = dDOCOdt3/ODmean;
         %y(ii) = DOCOmean;
         xCO(ii) = edouble(1,0)*CO;
         xN2(ii) = edouble(1,0)*N2;
         xO3(ii) = edouble(1,0)*O3;
         xD2(ii) = edouble(1,0)*D2;
         yDOCO_O3(ii) = DOCOmean.*O3/ODmean.value(:);
         yDOCO_LOSS(ii) = DOCOmean/ODmean;
         intTimes(ii) = intBox;
         
         waitbar(ii/numel(fitobjs),hwait);
    end
    close(hwait);
    
    % Fit
    %[xData, yData, weights] = prepareCurveData( x.value(:), y.value(:), 1./y.errorbar(:).^2 );

    % Set up fittype and options.
    X = [xCO.value(:).^2 xCO.value(:).*xN2.value(:) xCO.value(:).*xO3.value(:) xCO.value(:).*1e32./xO3.value(:)];% yDOCO_LOSS*1e16];
    Xplot = [xCO.value(:) xCO.value(:)];
    [b,bstd,mse] = lscov(X,y.value(:),1./y.errorbar(:).^2);
    %b(3) = 5e-11/1e16;
    
    fprintf('b = \n');
    for i=1:numel(b)
        fprintf('%g +- %g\n',b(i),bstd(i)/sqrt(mse));
    end

    ysim = b'*X';
    
    %ft = fittype( 'poly2' );
    %opts = fitoptions( 'Method', 'LinearLeastSquares' );
    %opts.Lower = [-Inf 4.2e-15 0];
    %opts.Upper = [Inf 4.2e-15 0];
    %opts.Weights = weights;

    % Fit model to data.
    %[fitresult, gof] = fit( xData, yData, ft, opts );
    %fitresult
    
    % Generate the fit line
    %xmin = min(x.value(:));
    %xrange = max(x.value(:))-min(x.value(:));
    %xfit = linspace(xmin-0.1*xrange,xmin+1.1*xrange,1000);
    %yfit = feval(fitresult,xfit);
    %ci = predint(fitresult,xfit);
    
    figure;plot(xCO,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('CO Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xCO,ysim,'ro');
    %plot(xCOfit,yCOfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xCO,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate N2 Plot
    figure;plot(xN2,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('N2 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xN2,ysim,'ro');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %plot(xN2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate O3 Plot
    figure;plot(xO3,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('O3 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xO3,ysim,'ro');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %plot(xO3,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate D2 Plot
    figure;plot(xD2,y,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('D2 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(xD2,ysim,'ro');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate another N2 Plot with only N2 scans
    N2dataNames = {...
        'v_20160307_N2_1',...
        'v_20160307_N2_2',...
        'v_20160307_N2_3',...
        'v_20160307_N2_4',...
        'v_20160307_N2_5',...
        'v_20160307_N2_6',...
        'v_20160307_N2_7',...
        'v_20160307_N2_8',...
        'v_20160322_HighN2_1',...
        'v_20160322_HighN2_2',...
        'v_20160322_HighN2_3',...
        };
    N2dataIndcs = [];
    for i = 1:numel(N2dataNames)
        tempind = find(strcmp(N2dataNames{i},fitobjnames));
        if ~isempty(tempind)
            N2dataIndcs(end+1) = tempind(1);
        end
    end
    
    N2linex = linspace(min(xN2.value(N2dataIndcs)),max(xN2.value(N2dataIndcs)),100);
    COval = mean(xCO.value(N2dataIndcs));
    N2liney = b(1)*COval.^2 + b(2)*N2linex*COval + b(3)*mean(xO3.value(N2dataIndcs));

    figure;plot(xN2(N2dataIndcs),y(N2dataIndcs),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('N2 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    hold on;
    plot(N2linex,N2liney,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate another CO Plot with only CO scans
    COdataNames = {...
        'v_20160210_CO_1',...
        'v_20160210_CO_2',...
        'v_20160210_CO_3',...
        'v_20160210_CO_4',...
        'v_20160210_CO_5',...
        'v_20160210_CO_6',...
        'v_20160209_CO_1',...
        'v_20160209_CO_2',...
        'v_20160209_CO_3',...
        'v_20160209_CO_4',...
        'v_20160209_CO_5',...
        'v_20160318_ShortInt1',...
        'v_20160318_ShortInt2',...
        'v_20160318_ShortInt3',...
        'v_20160317_ShortInt1',...
        'v_20160317_ShortInt2',...
        'v_20160317_ShortInt3',...
        'v_20160315_ShortInt1',...
        'v_20160315_ShortInt3',...
        };
    COdataIndcs = [];
    for i = 1:numel(COdataNames)
        tempind = find(strcmp(COdataNames{i},fitobjnames));
        if ~isempty(tempind)
            COdataIndcs(end+1) = tempind(1);
        end
    end
    
    COlinex = linspace(min(xCO.value(COdataIndcs)),max(xCO.value(COdataIndcs)),100);
    N2val = mean(xN2.value(COdataIndcs));
    COliney = b(1)*COlinex.^2 + b(2)*COlinex*N2val + b(3)*mean(xO3.value(N2dataIndcs));
    
    indcs50 = COdataIndcs(intTimes(COdataIndcs)==50);
    indcs25 = COdataIndcs(intTimes(COdataIndcs)==25);
    indcs10 = COdataIndcs(intTimes(COdataIndcs)==10);
    
    figure;
    plot(xCO(indcs50),y(indcs50),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    hold on;
    plot(xCO(indcs10),y(indcs10),'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    xlabel('N2 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    plot(COlinex,COliney,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate another O3 Plot with only O3 scans
    O3dataNames = {...
        'v_20160216_O3_1',...
        'v_20160216_O3_2',...
        'v_20160216_O3_3',...
        'v_20160216_O3_4',...
        'v_20160216_O3_5',...
        };
    O3dataIndcs = [];
    for i = 1:numel(O3dataNames)
        tempind = find(strcmp(O3dataNames{i},fitobjnames));
        if ~isempty(tempind)
            O3dataIndcs(end+1) = tempind(1);
        end
    end
    
    O3linex = linspace(min(xO3.value(O3dataIndcs)),max(xO3.value(O3dataIndcs)),100);
    N2val = mean(xN2.value(O3dataIndcs));
    COval = mean(xCO.value(O3dataIndcs));
    O3liney = b(1)*COval.^2 + b(2)*COval*N2val + b(3)*O3linex*COval + 1e32*COval*b(4)./O3linex;
    
    indcs50 = O3dataIndcs(intTimes(O3dataIndcs)==50);
    indcs25 = O3dataIndcs(intTimes(O3dataIndcs)==25);
    indcs10 = O3dataIndcs(intTimes(O3dataIndcs)==10);
    
    figure;
    plot(xO3(indcs50),y(indcs50),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    hold on;
    plot(xO3(indcs10),y(indcs10),'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    xlabel('O3 Concentration [mlc cm^{-3}]');
    ylabel('DOCO Rate Relative to OD [s^{-1}]');
    plot(O3linex,O3liney,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% D2 Analysis
    
    v_20160212_D2_1
    v_20160212_D2_2
    v_20160212_D2_3
    v_20160212_D2_4
    v_20160212_D2_5

end


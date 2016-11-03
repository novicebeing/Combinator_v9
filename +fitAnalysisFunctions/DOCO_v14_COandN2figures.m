function DOCO_v14_COandN2figures(fitobjnames,fitobjs)
    
    % Define the variants
    variants = sbiovariant('fvariant');
    addcontent(variants, {'parameter', 'f', 'value', 0.164});
    addcontent(variants, {'parameter', 'ODscale', 'value', 0.2131});
    addcontent(variants, {'parameter', 'DOCOscale', 'value', 0.2131});
    addcontent(variants, {'parameter', 'D2Oscale', 'value', 1});
    addcontent(variants, {'parameter', 'tpump', 'value', 25000});
    addcontent(variants, {'parameter', 'HOCO_LOSS.k', 'value', 0});
    addcontent(variants, {'parameter', 'HOCO_O3_OH_CO_O3.k_HOCO_O3_OH_CO_O3','value',0});
    
    % Define the reaction rates
    k1aN2 = 6.54588e-33;
    k1aCO = 1.61386e-32;
    addcontent(variants, {'parameter', 'k1aN2', 'value', k1aN2});
    addcontent(variants, {'parameter', 'k1aCO', 'value', k1aCO});

    intTimes = zeros(size(fitobjs));
    xCO = ezeros(size(fitobjs));
    xN2 = ezeros(size(fitobjs));
    xO3 = ezeros(size(fitobjs));
    xD2 = ezeros(size(fitobjs));
    y = ezeros(size(fitobjs));
    xxsim = zeros(size(fitobjs));
    yysim = zeros(size(fitobjs));
    yysimExpRatio = zeros(size(fitobjs));
    yysimExpDOCORatio = zeros(size(fitobjs));
    yysimExpODRatio = zeros(size(fitobjs));
    yysimSensRatio = zeros(size(fitobjs));
    yDOCO_O3 = zeros(size(fitobjs));
    yDOCO_LOSS = ezeros(size(fitobjs));

    % VALUES OF d([DOCO])/dt
    dDOCOdt_CUBIC = ezeros(size(fitobjs));
    dDOCOdt_QUADRATIC = ezeros(size(fitobjs));
    dDOCOdt_LINEAR = ezeros(size(fitobjs));
    dDOCOdt_EXPONENTIAL = ezeros(size(fitobjs));
    dDOCOdt_EXPCONV = ezeros(size(fitobjs));
    dDOCOdt_EXPCONV_TOFFSET = ezeros(size(fitobjs));
    dDOCOdtsim_CUBIC = zeros(size(fitobjs));
    dDOCOdtsim_QUADRATIC = zeros(size(fitobjs));
    dDOCOdtsim_LINEAR = zeros(size(fitobjs));
    dDOCOdtsim_EXPONENTIAL = zeros(size(fitobjs));
    
    % VALUES OF OD
    OD_MEAN = ezeros(size(fitobjs));
    
    % Define the fit data
    pathlength = 5348;
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
        ODtrace = fitobject.fitb(fitobject.fitbNamesInd(ODidx),:)/5348;
        ODtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(ODidx),:)/5348;
        DOCOtrace = fitobject.fitb(fitobject.fitbNamesInd(DOCOidx),:)/5348;
        DOCOtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(DOCOidx),:)/5348;

        % Find the first two time points
        time2 = time;
        time2(time < 0) = NaN;
        [~,firstidx] = nanmin(time2);
        time3 = time2;
        time3(firstidx) = NaN;
        [~,secondidx] = nanmin(time3);
        dt = (time(secondidx) - time(firstidx))/1e6;

        % Calculate the simulated data
        data = runsimbiologyscanincurrentworkspace(fitobject.getTable(1,5348),variants);
        [t,ysim,names] = getdata(data(1));
        %t=time;
        %ysim = zeros(numel(time),2);
        %names = {'ODscaled','DOCOscaled'};
        %t = t-50;
        
        ysimbox = zeros(numel(time),size(ysim,2));
        for i = 1:numel(names)
            yyy = ysim(:,i);
            [~,ind,~] = unique(t);
            xint = linspace(min(t),max(t),2e5);
            yint = interp1(t(ind),yyy(ind),xint);
            windowSize = round(50/(xint(2)-xint(1)));
            yintbox = filter((1/windowSize)*ones(1,windowSize),1,yint);
            ysimbox(:,i) = interp1(xint,yintbox,time+intBox);
        end
        
        % Get the proper indices for the data
        odsimInd = find(strcmp(names,'ODscaled'));
        docosimInd = find(strcmp(names,'DOCOscaled'));
        
        docoRealSlope = (interp1(t(ind),ysim(ind,docosimInd),2)-interp1(t(ind),ysim(ind,docosimInd),1))/1e-6;
        odReal = interp1(t(ind),ysim(ind,odsimInd),1.5);
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  %% CALCULATE THE DOCO SLOPE USING DIFFERENT FUNCTIONS %%
        %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % ALL FITS
            DOCOfitIndcs = 3:7;
            DOCOscalefactor = 1e12;
            [xData, yData, weights] = prepareCurveData( time(DOCOfitIndcs),DOCOtrace(DOCOfitIndcs)'/DOCOscalefactor,1./(DOCOtraceErr(DOCOfitIndcs)'/DOCOscalefactor).^2 );
            [xData, yDataSim] = prepareCurveData( time(DOCOfitIndcs),ysimbox(DOCOfitIndcs,docosimInd)/DOCOscalefactor );
            
            
            % LINEAR
            M_LINEAR = [(xData+intBox/2)];
            [b_LINEAR,stdb_LINEAR,mse_LINEAR] = lscov(M_LINEAR,yData,weights);
            bsim_LINEAR = lscov(M_LINEAR,yDataSim);
            dDOCOdt_LINEAR(ii) = edouble(b_LINEAR(1),stdb_LINEAR(1)/min(1,sqrt(mse_LINEAR)))*DOCOscalefactor*1e6;
            dDOCOdtsim_LINEAR(ii) = bsim_LINEAR(1)*DOCOscalefactor*1e6;
            
            % QUADRATIC
            M_QUADRATIC = [(xData+intBox/2) (xData.^2+intBox.*xData+intBox.^2/3)];
            [b_QUADRATIC,stdb_QUADRATIC,mse_QUADRATIC] = lscov(M_QUADRATIC,yData,weights);
            bsim_QUADRATIC = lscov(M_QUADRATIC,yDataSim);
            dDOCOdt_QUADRATIC(ii) = edouble(b_QUADRATIC(1),stdb_QUADRATIC(1)/min(1,sqrt(mse_QUADRATIC)))*DOCOscalefactor*1e6;
            dDOCOdtsim_QUADRATIC(ii) = bsim_QUADRATIC(1)*DOCOscalefactor*1e6;
            
            % QUADRATIC
            M_CUBIC = [(xData+intBox/2) (xData.^2+intBox.*xData+intBox.^2/3) (xData.^3+3/2*intBox.*xData.^2+intBox.^2*xData+intBox.^3/4)];
            [b_CUBIC,stdb_CUBIC,mse_CUBIC] = lscov(M_CUBIC,yData,weights);
            bsim_CUBIC = lscov(M_CUBIC,yDataSim);
            dDOCOdt_CUBIC(ii) = edouble(b_CUBIC(1),stdb_CUBIC(1)/min(1,sqrt(mse_CUBIC)))*DOCOscalefactor*1e6;
            dDOCOdtsim_CUBIC(ii) = bsim_CUBIC(1)*DOCOscalefactor*1e6;
        
            % EXPONENTIAL
            ft_EXPONENTIAL = fittype( 'a/b*(1-exp(-b*x)*(1-exp(-b*delta))/b/delta)', 'independent', 'x', 'dependent', 'y','problem','delta' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares',...
                'Lower',[0,0],...
                'Upper',[Inf,Inf],...
                'StartPoint',[1000 1000]);
            opts.weights = weights;
            [fitresult_EXPONENTIAL, gof, output] = fit( xData, yData, ft_EXPONENTIAL, opts,'problem',intBox );
            ci = diff(confint(fitresult_EXPONENTIAL,0.68),[],1)/2;
            dDOCOdt_EXPONENTIAL(ii) = edouble(fitresult_EXPONENTIAL.a,ci(1))*DOCOscalefactor*1e6;
            
            % ALL FITS
            DOCOfitIndcs2 = 1:9;
            DOCOscalefactor = 1e12;
            [xData2, yData2, weights2] = prepareCurveData( time(DOCOfitIndcs2),DOCOtrace(DOCOfitIndcs2)'/DOCOscalefactor,1./(DOCOtraceErr(DOCOfitIndcs2)'/DOCOscalefactor).^2 );
            %[xData, yDataSim] = prepareCurveData( time(DOCOfitIndcs),ysimbox(DOCOfitIndcs,docosimInd)/DOCOscalefactor );
            
            % EXPONENTIAL CONV
            ft_EXPCONV = fittype( 'a/b*(ebox(x,0,delta)-ebox(x,b,delta))', 'independent', 'x', 'dependent', 'y','problem','delta' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares',...
                'Lower',[-Inf,0],...
                'Upper',[Inf,Inf],...
                'StartPoint',[max(xData2)*0.1 0.1]);
            opts.weights = weights2;
            [fitresult, gof, output] = fit( xData2, yData2, ft_EXPCONV, opts,'problem',intBox );
            ci = diff(confint(fitresult,0.68),[],1)/2;
            dDOCOdt_EXPCONV(ii) = edouble(fitresult.a,ci(1))*DOCOscalefactor*1e6;
            
            % EXPONENTIAL
            ft_EXPCONV_TOFFSET = fittype( 'a/b*(ebox(x-tau,0,delta)-ebox(x-tau,b,delta))', 'independent', 'x', 'dependent', 'y','problem','delta' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares',...
                'Lower',[-Inf,0,-Inf],...
                'Upper',[Inf,Inf,Inf],...
                'StartPoint',[max(xData2)*0.05 0.05 5]);
            opts.weights = weights2;
            [fitresult, gof, output] = fit( xData2, yData2, ft_EXPCONV_TOFFSET, opts,'problem',intBox );
            ci = diff(confint(fitresult,0.68),[],1)/2;
            dDOCOdt_EXPCONV_TOFFSET(ii) = edouble(fitresult.a,ci(1))*DOCOscalefactor*1e6;
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  %% CALCULATE THE OD VALUE USING DIFFERENT FUNCTIONS %%
        %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        ind3od = 4:7;
        xDataod = time(ind3od)';
        MOD3 = [ones(size(xDataod)) xDataod];
        [bOD,stdbOD,mseOD] = lscov(MOD3,(ODtrace(ind3od))'/1e12,1./(ODtraceErr(ind3od)/1e12).^2);
        bODsim = lscov(MOD3,(ysimbox(ind3od,odsimInd))/1e12);
        %chisqr = sum((DOCOtrace(ind3)/1e12-b'*M').^2./(ODtraceErr(ind3)/1e12).^2)/(5-2-1)
        ODmean3 = edouble(bOD(1),stdbOD(1)/min(1,sqrt(mseOD)))*1e12;
        ODmean3sim = bODsim(1)*1e12;
        
        if ii == 1
            figh = 400;
            figw = 600;
            figure('Position', [100, 100, figw,figh]); 
            smallplotlinewidth = 1;
            subplot(2,1,1); htop = gca;
            subplot(2,1,2); hbottom = gca;
            set(htop,'Position',[0.157094594594595 0.583837209302326 0.814189189189189 0.341162790697675]);
            set(hbottom,'Position',[0.157094594594595 0.2 0.812500000000001 0.341162790697674]);
        end
        
        if strcmp(fitobjnames{ii},'v_20160315_ShortInt1')
            ind3 = DOCOfitIndcs;
            % Plot DOCO
            xxxsim = linspace(min(xData),max(xData),100)';
            Mxxx = [(xxxsim+intBox/2) (xxxsim.^2+intBox.*xxxsim+intBox.^2/3)];
            indxxx = find(time<100 & time>=-25);
            axes(htop); errorbar(time(indxxx),DOCOtrace(indxxx)/1e12,DOCOtraceErr(indxxx)/1e12,'.','LineWidth',smallplotlinewidth,'DisplayName','Exp','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]); hold on;
            plot(xxxsim,(b_QUADRATIC')*(Mxxx'),'LineWidth',smallplotlinewidth,'DisplayName','Exp Fit','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            %plot(time(indxxx),ysimbox(indxxx,docosimInd)/1e12,'.','LineWidth',smallplotlinewidth,'DisplayName','Sim','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            %plot(xxxsim,(bsim')*(Mxxx'),'LineWidth',smallplotlinewidth,'DisplayName','Sim Fit','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            %plot(xxxsim,fitresult(xxxsim),'-','LineWidth',smallplotlinewidth,'DisplayName','Exp Fit','Color','b');
            xlim([-30 80]);
            %ylim([0 0.45]);
            set(gca,'FontSize',12);
            set(gca,'XTickLabel',[]);
            ylabel({'[DOCO]\times10^{-12}','(mlc cm{-3})'});
            %legend1 = legend(htop,'show');
            %set(legend1,...
            %    'Position',[0.315867121915692 0.59672838996836 0.62837837012233 0.0617283936635947],...
            %    'Orientation','horizontal',...
            %    'EdgeColor',[1 1 1]);
            % Plot OD
            MxxxOD = [ones(size(xxxsim)) xxxsim];
            axes(hbottom); errorbar(time(indxxx),ODtrace(indxxx)/1e12,ODtraceErr(indxxx)/1e12,'.','LineWidth',smallplotlinewidth,'DisplayName','Exp','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]); hold on;
            %plot(xxxsim,(bOD')*(MxxxOD'),'LineWidth',smallplotlinewidth,'DisplayName','Exp Fit','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            %plot(time(indxxx),ysimbox(indxxx,odsimInd)/1e12,'.','LineWidth',smallplotlinewidth,'Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            %plot(xxxsim,(bODsim')*(MxxxOD'),'LineWidth',smallplotlinewidth,'DisplayName','Sim Fit','Color',[0.850980392156863 0.325490196078431 0.0980392156862745]);
            xlim([-30 80]);
            %ylim([0 4]);
            set(gca,'FontSize',12);
            xlabel('Time (\mus)');
            ylabel({'[OD]\times10^{-12}';'(mlc cm{-3})'});
            %annotation(gcf,'rectangle',[0.261000000000001 0.3875 0.169 0.125],'LineStyle','--');
        end
        
        i = 1;
        dt = (time(secondidx+i) - time(firstidx+i))/1e6;
        
        dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
        dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
        DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;
        DOCOmean = DOCOmean.value;
        ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
        OD_MEAN(ii) = ODmean;
        ODmeansim = (ysimbox(secondidx+i,odsimInd)+ysimbox(firstidx+i,odsimInd))/2;
        
         xxsim(ii) = CO;
         yysimExpDOCORatio(ii) = dDOCOdtsim_QUADRATIC(ii)/docoRealSlope;
         yysimExpODRatio(ii) = ODmeansim/odReal;
         yysimExpRatio(ii) = (dDOCOdtsim_QUADRATIC(ii)/ODmeansim)/(docoRealSlope/odReal);
         yysimSensRatio(ii) = (docoRealSlope/odReal)/(k1aN2*N2+k1aCO*CO)/CO;
         yysim(ii) = (dDOCOdtsim_QUADRATIC(ii)/ODmeansim);
         y(ii) = dDOCOdt_QUADRATIC(ii)/ODmean;
         %y(ii) = DOCOmean;
         xCO(ii) = edouble(1,0)*CO;
         xN2(ii) = edouble(1,0)*N2;
         xO3(ii) = edouble(1,0)*O3;
         xD2(ii) = edouble(1,0)*D2;
         yDOCO_O3(ii) = 1e-11*DOCOmean.*O3/ODmean.value(:)/CO;
         yDOCO_LOSS(ii) = DOCOmean;
         intTimes(ii) = intBox;
         
         waitbar(ii/numel(fitobjs),hwait);
    end
    close(hwait);
    
    % Fit
    %[xData, yData, weights] = prepareCurveData( x.value(:), y.value(:), 1./y.errorbar(:).^2 );

    % Set up fittype and options.
    X = [xCO.value(:).^2 xCO.value(:).*xN2.value(:)];% yDOCO_LOSS*1e16];
    Xplot = [xCO.value(:) xCO.value(:)];
    [b,bstd,mse] = lscov(X,y.value(:),1./y.errorbar(:).^2);
    %yyyyy = dDOCOdt_EXPONENTIAL./OD_MEAN;
    %[b,bstd,mse] = lscov(X,yyyyy.value(:),1./yyyyy.errorbar(:).^2);
    
    fprintf('b = \n');
    for i=1:numel(b)
        fprintf('%g +- %g\n',b(i),bstd(i));
    end
    fprintf('mse = %g\n',sqrt(mse));
    
    ysim = b'*X';
    b(3) = 0;
    bstd(3) = 0;
    b(4) = 0;
    bstd(4) = 0;
    
    redChiSqr = sum((y.value(:)'-ysim).^2./y.errorbar(:)'.^2)/(numel(y)-2-1)
    
    % GENERATE SIMULATION SENSITIVITY PLOTS
        %% Generate N2 sim plot
        figure;plot(xN2,yysimExpDOCORatio,'o');hold on;
        plot(xN2,yysimExpODRatio,'s');
        plot(xN2,yysimExpDOCORatio./yysimExpODRatio,'.');
        plot(xN2,yysimSensRatio,'x');
        ylim([0 1.5]);
        %% Generate CO sim plot
        figure;plot(xCO,yysimExpDOCORatio,'o');hold on;
        plot(xCO,yysimExpODRatio,'s');
        plot(xCO,yysimExpDOCORatio./yysimExpODRatio,'.');hold on;
        plot(xCO,yysimSensRatio,'x');
        ylim([0 1.5]);
        %% Generate O3 sim plot
        figure;%plot(xO3,yysimExpDOCORatio,'o');hold on;
        %plot(xO3,yysimExpODRatio,'s');
        plot(xO3,yysimExpDOCORatio./yysimExpODRatio,'.'); hold on;
        %plot(xO3,yysimSensRatio,'x');
        ylim([0 1.5]);
        %% Generate D2 sim plot
        figure;plot(xD2,yysimExpDOCORatio,'o');hold on;
        plot(xD2,yysimExpODRatio,'s');
        plot(xD2,yysimExpDOCORatio./yysimExpODRatio,'.');
        plot(xD2,yysimSensRatio,'x');
        ylim([0 1.5]); 
    
    %return
    
   %% CHOOSE DATA FOR PLOTS
    O3dataNames = {...
        'v_20160216_O3_1',...
        'v_20160216_O3_2',...
        'v_20160216_O3_3',...
        'v_20160216_O3_4',...
        'v_20160216_O3_5',...
        'v_20160224_O3_1',...
        'v_20160224_O3_2',...
        'v_20160224_O3_3',...
        'v_20160224_O3_4',...
        'v_20160224_O3_5',...
        'v_20160224_O3_6',...
        };
    D2dataNames = {...
        'v_20160212_D2_1',...
        'v_20160212_D2_2',...
        'v_20160212_D2_3',...
        'v_20160212_D2_4',...
        'v_20160212_D2_5',...
        };
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
    MdataNames = {...
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
    O3dataIndcs = [];
    for i = 1:numel(O3dataNames)
        tempind = find(strcmp(O3dataNames{i},fitobjnames));
        if ~isempty(tempind)
            O3dataIndcs(end+1) = tempind(1);
        end
    end
    D2dataIndcs = [];
    for i = 1:numel(D2dataNames)
        tempind = find(strcmp(D2dataNames{i},fitobjnames));
        if ~isempty(tempind)
            D2dataIndcs(end+1) = tempind(1);
        end
    end
    N2dataIndcs = [];
    for i = 1:numel(N2dataNames)
        tempind = find(strcmp(N2dataNames{i},fitobjnames));
        if ~isempty(tempind)
            N2dataIndcs(end+1) = tempind(1);
        end
    end
    COdataIndcs = [];
    for i = 1:numel(COdataNames)
        tempind = find(strcmp(COdataNames{i},fitobjnames));
        if ~isempty(tempind)
            COdataIndcs(end+1) = tempind(1);
        end
    end
    MdataIndcs = [];
    for i = 1:numel(MdataNames)
        tempind = find(strcmp(MdataNames{i},fitobjnames));
        if ~isempty(tempind)
            MdataIndcs(end+1) = tempind(1);
        end
    end
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  %%  DOCOdot FUNCTIONAL FORM PLOT       %%
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure;plot(xCO(COdataIndcs),dDOCOdt_QUADRATIC(COdataIndcs),'ko','DisplayName','Quadratic','MarkerFaceColor','k','MarkerEdgeColor','k');hold on;
        plot(xCO(COdataIndcs),dDOCOdt_LINEAR(COdataIndcs),'rs','DisplayName','Linear','MarkerFaceColor','r','MarkerEdgeColor','r');
        plot(xCO(COdataIndcs),dDOCOdt_CUBIC(COdataIndcs),'gx','DisplayName','Cubic','MarkerFaceColor','g','MarkerEdgeColor','g');
        plot(xCO(COdataIndcs),dDOCOdt_EXPONENTIAL(COdataIndcs),'bd','DisplayName','Exponential','MarkerFaceColor','b','MarkerEdgeColor','b');
        plot(xCO(COdataIndcs),dDOCOdt_EXPCONV(COdataIndcs),'md','DisplayName','Exp Conv','MarkerFaceColor','m','MarkerEdgeColor','m');
        plot(xCO(COdataIndcs),dDOCOdt_EXPCONV_TOFFSET(COdataIndcs),'kd','DisplayName','Exp Conv + Toffset','MarkerFaceColor','k','MarkerEdgeColor','k');
        xlabel('CO Concentration (molecule cm^{-3})');
        ylabel('d[DOCO]/dt (molecule cm^{-3} s^{-1})');
        legend;
        set(gca,'FontSize',15);
        return

        figure;plot(xN2(N2dataIndcs),dDOCOdt_QUADRATIC(N2dataIndcs),'ko','DisplayName','Quadratic','MarkerFaceColor','k','MarkerEdgeColor','k');hold on;
        plot(xN2(N2dataIndcs),dDOCOdt_LINEAR(N2dataIndcs),'rs','DisplayName','Linear','MarkerFaceColor','r','MarkerEdgeColor','r');
        plot(xN2(N2dataIndcs),dDOCOdt_CUBIC(N2dataIndcs),'gx','DisplayName','Cubic','MarkerFaceColor','g','MarkerEdgeColor','g');
        plot(xN2(N2dataIndcs),dDOCOdt_EXPONENTIAL(N2dataIndcs),'bd','DisplayName','Exponential','MarkerFaceColor','b','MarkerEdgeColor','b');
        xlabel('N2 Concentration (molecule cm^{-3})');
        ylabel('d[DOCO]/dt (molecule cm^{-3} s^{-1})');
        legend;
        set(gca,'FontSize',15);

        figure;plot(xD2(D2dataIndcs),dDOCOdt_QUADRATIC(D2dataIndcs),'ko','DisplayName','Quadratic','MarkerFaceColor','k','MarkerEdgeColor','k');hold on;
        plot(xD2(D2dataIndcs),dDOCOdt_LINEAR(D2dataIndcs),'rs','DisplayName','Linear','MarkerFaceColor','r','MarkerEdgeColor','r');
        plot(xD2(D2dataIndcs),dDOCOdt_CUBIC(D2dataIndcs),'gx','DisplayName','Cubic','MarkerFaceColor','g','MarkerEdgeColor','g');
        plot(xD2(D2dataIndcs),dDOCOdt_EXPONENTIAL(D2dataIndcs),'bd','DisplayName','Exponential','MarkerFaceColor','b','MarkerEdgeColor','b');
        xlabel('D2 Concentration (molecule cm^{-3})');
        ylabel('d[DOCO]/dt (molecule cm^{-3} s^{-1})');
        legend;
        set(gca,'FontSize',15);

        figure;plot(xO3(O3dataIndcs),dDOCOdt_QUADRATIC(O3dataIndcs),'ko','DisplayName','Quadratic','MarkerFaceColor','k','MarkerEdgeColor','k');hold on;
        plot(xO3(O3dataIndcs),dDOCOdt_LINEAR(O3dataIndcs),'rs','DisplayName','Linear','MarkerFaceColor','r','MarkerEdgeColor','r');
        plot(xO3(O3dataIndcs),dDOCOdt_CUBIC(O3dataIndcs),'gx','DisplayName','Cubic','MarkerFaceColor','g','MarkerEdgeColor','g');
        plot(xO3(O3dataIndcs),dDOCOdt_EXPONENTIAL(O3dataIndcs),'bd','DisplayName','Exponential','MarkerFaceColor','b','MarkerEdgeColor','b');
        xlabel('O3 Concentration (molecule cm^{-3})');
        ylabel('d[DOCO]/dt (molecule cm^{-3} s^{-1})');
        legend;
        set(gca,'FontSize',15);

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  %% RANDOM CO PLOT       %%
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
    figure;
    plot(xCO(COdataIndcs),dDOCOdt_QUADRATIC(COdataIndcs),'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);hold on;
    set(gca,'FontSize',15);
    
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  %% CO SCAN PLOTS (DIV BY CO)       %%
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    COlinex = linspace(0,max(xCO.value(COdataIndcs)),100);
    N2val = mean(xN2.value(COdataIndcs));
    COliney = b(1)*COlinex.^2 + b(2)*COlinex*N2val + b(3)*mean(xO3.value(N2dataIndcs));
    
    indcs50 = COdataIndcs(intTimes(COdataIndcs)==50);
    indcs25 = COdataIndcs(intTimes(COdataIndcs)==25);
    indcs10 = COdataIndcs(intTimes(COdataIndcs)==10);
    
    figure;
    plot(xCO(indcs50)./1e17,dDOCOdt_QUADRATIC(indcs50)./OD_MEAN(indcs50).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);hold on;
    plot(xCO(indcs10)./1e17,dDOCOdt_QUADRATIC(indcs10)./OD_MEAN(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y_q*CO \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    plot(COlinex./1e17,COliney./COlinex.*1e14,'r');
    set(gca,'FontSize',15);
    
    figure;
    plot(xCO(indcs50)./1e17,dDOCOdt_EXPONENTIAL(indcs50)./OD_MEAN(indcs50).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);hold on;
    plot(xCO(indcs10)./1e17,dDOCOdt_EXPONENTIAL(indcs10)./OD_MEAN(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y_e*CO \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    %plot(COlinex./1e17,COliney./COlinex.*1e14,'r');
    set(gca,'FontSize',15);
        
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  %% CO SCAN PLOTS (DIV BY CO)       %%
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    COlinex = linspace(0,max(xCO.value(COdataIndcs)),100);
    N2val = mean(xN2.value(COdataIndcs));
    COliney = b(1)*COlinex.^2 + b(2)*COlinex*N2val + b(3)*mean(xO3.value(N2dataIndcs));
    
    indcs50 = COdataIndcs(intTimes(COdataIndcs)==50);
    indcs25 = COdataIndcs(intTimes(COdataIndcs)==25);
    indcs10 = COdataIndcs(intTimes(COdataIndcs)==10);
    
    figure;
    plot(xCO(indcs50)./1e17,dDOCOdt_QUADRATIC(indcs50)./OD_MEAN(indcs50)./xCO(indcs50).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);hold on;
    plot(xCO(indcs10)./1e17,dDOCOdt_QUADRATIC(indcs10)./OD_MEAN(indcs10)./xCO(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y_q \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    plot(COlinex./1e17,COliney./COlinex.*1e14,'r');
    set(gca,'FontSize',15);
    
    figure;
    plot(xCO(indcs50)./1e17,dDOCOdt_EXPONENTIAL(indcs50)./OD_MEAN(indcs50)./xCO(indcs50).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);hold on;
    plot(xCO(indcs10)./1e17,dDOCOdt_EXPONENTIAL(indcs10)./OD_MEAN(indcs10)./xCO(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y_e \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    %plot(COlinex./1e17,COliney./COlinex.*1e14,'r');
    set(gca,'FontSize',15);
    
    return
    
    
    %% Generate another O3 Plot
    COval = mean(xCO.value(O3dataIndcs));
    figure;plot(xO3(O3dataIndcs),y(O3dataIndcs),'ko','MarkerFaceColor','k','MarkerEdgeColor','k'); hold on;
    %plot(xO3(O3dataIndcs),yysim(O3dataIndcs)./COval.*1e14,'go','MarkerFaceColor','g','MarkerEdgeColor','g');
    xlabel('O3 Concentration (molecule cm^{-3})');
    ylabel('DOCOdot \times 10^{14} (molecule^{-1} cm^3 s^{-1})');
    set(gca,'FontSize',15);

    figure;plot(xO3(O3dataIndcs),y(O3dataIndcs)./COval.*1e14,'ko','MarkerFaceColor','k','MarkerEdgeColor','k'); hold on;
    plot(xO3(O3dataIndcs),yysim(O3dataIndcs)./COval.*1e14,'go','MarkerFaceColor','g','MarkerEdgeColor','g');
    xlabel('O3 Concentration (molecule cm^{-3})');
    ylabel('y \times 10^{14} (molecule^{-1} cm^3 s^{-1})');
    set(gca,'FontSize',15);
    figure;plot(xO3(O3dataIndcs),yDOCO_O3(O3dataIndcs),'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('O3 Concentration (molecule cm^{-3})');
    ylabel('yDOCOLOSS \times 10^{14} (molecule^{-1} cm^3 s^{-1})');
    set(gca,'FontSize',15);
    figure;plot(xO3(O3dataIndcs).*yDOCO_LOSS(O3dataIndcs)./COval,y(O3dataIndcs)./COval,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('O3 Concentration (molecule cm^{-3})');
    ylabel('yyy (molecule^{-1} cm^3 s^{-1})');
    set(gca,'FontSize',15);
    
    %% Generate another D2 Plot
    COval = mean(xCO.value(D2dataIndcs));
    figure;plot(xD2(D2dataIndcs),y(D2dataIndcs)./COval.*1e14,'ko','MarkerFaceColor','k','MarkerEdgeColor','k');
    xlabel('D2 Concentration (molecule cm^{-3})');
    ylabel('y \times 10^{14} (molecule^{-1} cm^3 s^{-1})');
    %hold on;
    %plot(xD2,ysim,'ro');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate another N2 Plot with only N2 scans
    
    N2linex = linspace(0,max(xN2.value(N2dataIndcs)),100);
    COval = mean(xCO.value(N2dataIndcs));
    N2liney = b(1)*COval.^2 + b(2)*N2linex*COval + b(3)*mean(xO3.value(N2dataIndcs));

    figure;plot(xN2(N2dataIndcs)./1e17,y(N2dataIndcs)./1e4,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);
    xlabel('[N2] \times 10^{-17} (molecule cm^{-3})');
    ylabel('(d[DOCO]_0/dt)/[OD]_0 \times 10^{-4} (s^{-1})');
    hold on;
    plot(N2linex./1e17,N2liney./1e4,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate another N2 Plot with only N2 scans
    
    N2linex = linspace(0,max(xN2.value(N2dataIndcs)),100);
    COval = mean(xCO.value(N2dataIndcs));
    N2liney = b(1)*COval.^2 + b(2)*N2linex*COval + b(3)*mean(xO3.value(N2dataIndcs));

    figure;plot(xN2(N2dataIndcs)./1e17,y(N2dataIndcs)./xCO(N2dataIndcs).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);
    xlabel('[N2] \times 10^{-17} (molecule cm^{-3})');
    ylabel('y \times 10^{14} (molecule^{-1} cm^3 s^{-1})');
    hold on;
    plot(N2linex./1e17,N2liney./COval.*1e14,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);

    
    %% Generate another CO Plot with only CO scans
    COlinex = linspace(0,max(xCO.value(COdataIndcs)),100);
    N2val = mean(xN2.value(COdataIndcs));
    COliney = b(1)*COlinex.^2 + b(2)*COlinex*N2val + b(3)*mean(xO3.value(N2dataIndcs));
    
    indcs50 = COdataIndcs(intTimes(COdataIndcs)==50);
    indcs25 = COdataIndcs(intTimes(COdataIndcs)==25);
    indcs10 = COdataIndcs(intTimes(COdataIndcs)==10);
    
    figure;
    plot(xCO(indcs50)./1e17,dDOCOdt_QUADRATIC(indcs50)/OD_MEAN(indcs50)./1e4,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);
    hold on;
    plot(xCO(indcs10)./1e17,dDOCOdt_QUADRATIC(indcs10)/OD_MEAN(indcs10)./1e4,'bo','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecule cm^{-3})');
    ylabel('(d[DOCO]_0/dt)/[OD]_0 \times 10^{-4} (s^{-1})');
    plot(COlinex./1e17,COliney./1e4,'r');
    set(gca,'FontSize',14);

    %% Generate another CO Plot with only CO scans
    COlinex = linspace(0,max(xCO.value(COdataIndcs)),100);
    N2val = mean(xN2.value(COdataIndcs));
    COliney = b(1)*COlinex.^2 + b(2)*COlinex*N2val + b(3)*mean(xO3.value(N2dataIndcs));
    
    indcs50 = COdataIndcs(intTimes(COdataIndcs)==50);
    indcs25 = COdataIndcs(intTimes(COdataIndcs)==25);
    indcs10 = COdataIndcs(intTimes(COdataIndcs)==10);
    
    figure;
    plot(xCO(indcs50)./1e17,dDOCOdt_QUADRATIC(indcs50)/OD_MEAN(indcs50)./xCO(indcs50).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);
    hold on;
    plot(xCO(indcs10)./1e17,dDOCOdt_QUADRATIC(indcs10)/OD_MEAN(indcs10)./xCO(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    plot(COlinex./1e17,COliney./COlinex.*1e14,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    return
    
    %% Generate another SYSTEMATIC CO Plot with only CO scans
    COlinex = linspace(0,max(xCO.value(COdataIndcs)),100);
    N2val = mean(xN2.value(COdataIndcs));
    COliney = b(1)*COlinex.^2 + b(2)*COlinex*N2val + b(3)*mean(xO3.value(N2dataIndcs));
    
    indcs50 = COdataIndcs(intTimes(COdataIndcs)==50);
    indcs25 = COdataIndcs(intTimes(COdataIndcs)==25);
    indcs10 = COdataIndcs(intTimes(COdataIndcs)==10);
    
    indcs50div = [];
    indcs10div = [];
    for i = 1:numel(indcs50)
        for j = 1:numel(indcs10)
            if xCO.value(indcs50(i)) == xCO.value(indcs10(j))
                indcs50div(end+1) = indcs50(i);
                indcs10div(end+1) = indcs10(j);
            end
        end
    end
    
    figure;
    plot(xCO(indcs50div)./1e17,y(indcs50div)./y(indcs10div),'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);
    %hold on;
    %plot(xCO(indcs10)./1e17,y(indcs10)./xCO(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[CO] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    %plot(COlinex./1e17,COliney./COlinex.*1e14,'r');
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    set(gca,'FontSize',14);
    
    %% Generate another plot with all scans
    rVal = (b(1)/b(2));
    Mlinex = linspace(0,max(rVal.*xCO.value(MdataIndcs)+xN2.value(MdataIndcs)),100);
    N2val = mean(xN2.value(MdataIndcs));
    Mliney = b(2)*Mlinex;
    
    indcs50 = dataIndcs(intTimes(MdataIndcs)==50);
    indcs25 = dataIndcs(intTimes(MdataIndcs)==25);
    indcs10 = dataIndcs(intTimes(MdataIndcs)==10);
    
    figure;
    %yyaxis left
    plot((rVal.*xCO(indcs50)+xN2(indcs50))./1e17,y(indcs50)./xCO(indcs50).*1e14,'ko','MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',1);
    hold on;
    plot((rVal.*xCO(indcs10)+xN2(indcs10))./1e17,y(indcs10)./xCO(indcs10).*1e14,'bs','MarkerFaceColor','none','MarkerEdgeColor','b','LineWidth',1);
    xlabel('[M_{eff}] \times 10^{-17} (molecules cm^{-3})');
    ylabel('y \times 10^{14} (molecules^{-1} cm^3 s^{-1})');
    plot(Mlinex./1e17,Mliney.*1e14,'r');
    % Create second Y axes on the right.
    a1 = gca;
    a2 = axes('YAxisLocation', 'Right');
    % Hide second plot.
    set(a1,'box','off')
    set(a2,'box','off')
    set(a2, 'color', 'none');
    set(a2, 'XTick', []);
    % Set scala for second Y.
    set(a2, 'YLim', [min(get(a1,'YLim')) max(get(a1,'YLim'))].*1e-14./7.5e-14.*100);
    set(a1,'FontSize',14);
    set(a2,'FontSize',14);
    set(a2, 'Position', get(a1,'Position'));
 
    ylabel('DOCO Yield (%)');
    
    %plot(xfit,yfit,'Color','r','LineWidth',2);
    %plot(xfit,ci(:,1),'r--','LineWidth',1);
    %plot(xfit,ci(:,2),'r--','LineWidth',1);
    %scatter(xD2,yysim,'bo','MarkerFaceColor','b','MarkerEdgeColor','b');
    
    return
    %% Generate another O3 Plot with only O3 scans
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

end


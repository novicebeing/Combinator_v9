function performDOCOTemplateFit( obj )
    
    % Check that integration time is set
    if isempty(obj.integrationTime)
        uiwait(msgbox('Defaulting to 50 us integration time...'));
        obj.integrationTime = 50;
        %error('Integration time parameter is not set');
    end
    
    % Start Reporting
    import mlreportgen.dom.*;
    DOCOreport = Document('DOCO Report');
    reportimagenum = 1;
    
    % Correct wavenumber axis
    if ~isempty(DOCOreport)
        h = Heading(1,'X Axis Correction');
        append(DOCOreport,h);
    end
    obj.correctDOCOwavenumAxis(DOCOreport);
    
    % Load template spectra
    obj.loadDOCOtemplates(DOCOreport);

    % Construct the fitting matrix
    %   Fitting matrix should be of size (x size,number of fitting
    %   elements)
    fitMatrix = reshape(obj.DOCOtemplateAvg,size(obj.DOCOtemplateAvg,1)*size(obj.DOCOtemplateAvg,2),size(obj.DOCOtemplateAvg,3));
    fitMatrix(isnan(fitMatrix)) = 0;
    
    % Normalize the stdev if necessary
    stdNormFactor = nanstd(fitMatrix,0,1);
    stdNormFactor(isnan(stdNormFactor)) = 1;
    stdNormFactor(stdNormFactor == 0) = 1;
    
    % Check
    obj.averageSpectra();
    
    % Fit each spectrum
    beta = zeros([size(fitMatrix,2) size(obj.yavg,3)]);
    betaError = zeros([size(fitMatrix,2) size(obj.yavg,3)]);
    for i = 1:size(obj.yavg,3)
        % Get the data
        dataY = reshape(obj.yavg(:,:,i),size(obj.yavg,1)*size(obj.yavg,2),1);
        
        % Remove the NaN Values
        nonnanvals = ~isnan(dataY) & ~isnan(sum(fitMatrix,2));
        dataYnonnan = dataY(nonnanvals);
        nonnanvalsFitMatrix = repmat(reshape(nonnanvals,[],1),1,size(fitMatrix,2));
        fitMatrixnonnan = reshape(fitMatrix(nonnanvalsFitMatrix),[],size(fitMatrix,2));

        % Perform the matrix division
        %beta(:,i) = mldivide(fitMatrixnonnan./repmat(stdNormFactor,size(fitMatrixnonnan,1),1),(dataYnonnan/std(dataYnonnan))).*std(dataYnonnan)./stdNormFactor';
        Y = dataYnonnan;
        M = fitMatrixnonnan;
        alpha = 0.05;
        [b,bError] = regress(Y,M./repmat(nanmean(fitMatrixnonnan,1),size(fitMatrixnonnan,1),1),alpha);
        beta(:,i) = b./reshape(nanmean(fitMatrixnonnan,1),[],1);
        betaError(:,i) = (bError(:,2)-bError(:,1))/2./reshape(nanmean(fitMatrixnonnan,1),[],1);
    end
    
    % Plot the results
    hf=figure;
    for i = 1:numel(obj.DOCOtemplateNames)
        shadederrorbar(obj.tavg,beta(i,:),betaError(i,:),'.'); hold on;
    end
    xlabel('Time [\mus]');
    ylabel('Concentration [mlc/cc] x Path Length [cm]');
    
    if ~isempty(DOCOreport)
        h = Heading(1,'Fit Results');
        append(DOCOreport,h);
        
        print(hf,'-dpng',sprintf('test%i',reportimagenum));
        testimg = Image(sprintf('test%i.png',reportimagenum));
        testimg.Height = '3.75in';
        testimg.Width = '5in';
        append(DOCOreport, testimg);
        reportimagenum = reportimagenum+1;
        
        xlim(gca,[-100 500]);
        print(hf,'-dpng',sprintf('test%i',reportimagenum));
        testimg = Image(sprintf('test%i.png',reportimagenum));
        testimg.Height = '3.75in';
        testimg.Width = '5in';
        append(DOCOreport, testimg);
        reportimagenum = reportimagenum+1;
        
        close(hf);
    end
    %title(sprintf('Multi Peak Fit: [%s]',sprintf('%g ',round(templateParams((npeaks+1):(2*npeaks))*100)/100)));    
    %legend(obj.DOCOtemplateNames);
    
    % Construct the residuals
    yfit = fitMatrixnonnan*beta;
    yresiduals = obj.yavg;
    yresidualsError = obj.ystderror;
    nonnanvalsResiduals = repmat(reshape(nonnanvals,size(obj.yavg,1),size(obj.yavg,2)),[1 1 size(obj.yavg,3)]);
    yresiduals(nonnanvalsResiduals) = yresiduals(nonnanvalsResiduals) - yfit(:);
    
    % Display the residuals
    kobj = kineticsobject();
    kobj.name = 'Residuals';
    kobj.ysum = yresiduals./yresidualsError.^2;
    kobj.wsum = 1./yresidualsError.^2;
    kobj.t = obj.tavg;
    kobj.wavenum = obj.wavenum;
    %kobj.plotbrowser;
    
    % Fit each of the results if desired, to the correct function
    D2Oindex = 0;
    ODindex = 0;
    DOCOindex = 0;
    for i = 1:numel(obj.DOCOtemplateNames)
        if strcmp(obj.DOCOtemplateNames{i},'D2O')
            D2Oindex = i;
        elseif strcmp(obj.DOCOtemplateNames{i},'OD')
            ODindex = i;
        elseif strcmp(obj.DOCOtemplateNames{i},'DOCO')
            DOCOindex = i;
        end
    end
    
    k1avals = struct();
    
    if D2Oindex > 0
        % Add the D2O heading to the report
        if ~isempty(DOCOreport)
            h = Heading(1,'D2O Analysis');
            append(DOCOreport,h);
        end
        
        % Fit the D2O data
        x = obj.tavg;
        y = beta(D2Oindex,:);
        yError = betaError(D2Oindex,:);
        
        % Scale the data
        fitx = x;
        scalefactor = max(y);
        fity = y/scalefactor;
        fityError = yError/scalefactor;
        
        % Set the integration time
        W = obj.integrationTime;
        
        %% FIRST D2O Fit FUNCTION
        %D2OfitFun = @(A,Aa,bRisea,bRiseb,bPump,t) A*(ebox(t,0,W)-Aa.*ebox(t,bRisea,W)-(1-Aa).*ebox(t,bRiseb,W)).*exp(-bPump.^2.*t.^2);
        D2OfitFun = @(A,bRise,bPump,t) A.*(ebox(t,0,W)-ebox(t,bRise,W)).*exp(-bPump.^2.*t.^2);
        D2Ofittype = fittype(D2OfitFun,...
            'independent','t',...
            'coefficients',{'A','bRise','bPump'});
        
        % Set some initial parameters
        A0 = max(fity);
        Aa = 0.5;
        bRise0 = 0.0005;
        bRiseb0 = 0.0001;
        bPump0 = 0.00001;
        
        % Perform the fit
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),D2Ofittype, ...
                'StartPoint', [A0,bRise0,bPump0], ...
                'Lower', [0, 0, 0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.bRise = edouble(fitobj.bRise,cint(2));
        fitVals.bPump = edouble(fitobj.bPump,cint(3));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor);
        title('D2O Concentration Fit');
        xlabel('Time [\mus]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 1');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\n\tD2O = D2O_0 (1-exp(-r t)) exp(-rPump^2 t^2),\n convolved with integration window.'));
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'D2O_0: %s mlc cm/cc\n' ...
                'r: %s 1/s\n' ...
                'rPump: %s 1/s\n'], ...
                fitVals.A.string(),...
                fitVals.bRise.string(),...
                fitVals.bPump.string()...
                ));            
            
            
            
            close(hf);
        end
        
        %% SECOND D2O Fit FUNCTION
        D2OfitFun = @(A,aa,bRisea,bRiseb,bPump,t) A*(ebox(t,0,W)-aa.*ebox(t,bRisea,W)-(1-aa).*ebox(t,bRiseb,W)).*exp(-bPump.^2.*t.^2);
        D2Ofittype = fittype(D2OfitFun,...
            'independent','t',...
            'coefficients',{'A','aa','bRisea','bRiseb','bPump'});
        
        % Set some initial parameters
        A0 = max(fity);
        aa = 0.5;
        bRisea0 = 0.0005;
        bRiseb0 = 0.0001;
        bPump0 = 0.00001;
        
        % Perform the fit
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),D2Ofittype, ...
                'StartPoint', [A0,aa,bRisea0,bRiseb0,bPump0], ...
                'Lower', [0, 0, 0, 0, 0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.aa = edouble(fitobj.aa,cint(2));
        fitVals.bRisea = edouble(fitobj.bRisea,cint(3));
        fitVals.bRiseb = edouble(fitobj.bRiseb,cint(4));
        fitVals.bPump = edouble(fitobj.bPump,cint(5));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor);
        title('D2O Concentration Fit');
        xlabel('Time [\mus]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 2');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\n\tD2O = D2O_0 (1-a*exp(-r1 t)-(1-a)*exp(-r2 t)) exp(-rPump^2 t^2),\n convolved with integration window.'));
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'D2O_0: %s mlc cm/cc\n' ...
                'a: %s\n' ...
                'r1: %s 1/s\n' ...
                'r2: %s 1/s\n' ...
                'rPump: %s 1/s\n'], ...
                fitVals.A.string(),...
                fitVals.aa.string(),...
                fitVals.bRisea.string(),...
                fitVals.bRisea.string(),...
                fitVals.bPump.string()...
                ));
            close(hf);
        end
        
        %% THIRD D2O Fit FUNCTION
        D2OfitFun = @(A,bRise,bPump,t) A.*t./(1/bRise+t).*exp(-bPump.^2.*t.^2);
        D2Ofittype = fittype(D2OfitFun,...
            'independent','t',...
            'coefficients',{'A','bRise','bPump'});
        
        % Set some initial parameters
        A0 = max(fity);
        bRise0 = 0.0005;
        bPump0 = 0.00001;
        
        % Perform the fit
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),D2Ofittype, ...
                'StartPoint', [A0,bRise0,bPump0], ...
                'Lower', [0, 0, 0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.bRise = edouble(fitobj.bRise,cint(2));
        fitVals.bPump = edouble(fitobj.bPump,cint(3));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor);
        title('D2O Concentration Fit');
        xlabel('Time [\mus]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 3');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\n\tD2O = D2O_0 t/(1/r+t) exp(-rPump^2 t^2),\n convolved with integration window.'));
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'D2O_0: %s mlc cm/cc\n' ...
                'r1: %s 1/s\n' ...
                'rPump: %s 1/s\n'], ...
                fitVals.A.string(),...
                fitVals.bRise.string(),...
                fitVals.bPump.string()...
                ));
            close(hf);
        end
    end
    
    if ODindex > 0
        % Fit the D2O data
        x = obj.tavg;
        y = beta(ODindex,:);
        yError = betaError(ODindex,:);

        % Linear DOCO fitting
        linfitind = find(x>0 & x<60);
        if ~isempty(linfitind)
            [minODval,minODidx] = min(y(linfitind));
            minODerror = yError(linfitind(minODidx));
            minODt = x(linfitind(minODidx));
            minOD = edouble(minODval,minODerror);
        else
            minODval = 0;
            minODerror = 0;
            minODt = 0;
            minOD = edouble(minODval,minODerror);
        end
        
        if ~isempty(DOCOreport)
            h = Heading(1,'OD Analysis');
            append(DOCOreport,h);
            h = Heading(2,'Linear OD Concentration Fit');
            append(DOCOreport,h);
            hf = figure;shadederrorbar(x,y,yError,'.');hold on;
            errorbar(minODt,minOD.value(),minOD.errorbar(),'ro');
            xlim(gca,[-20 100]);
            xlabel('Time [\mus]');
            ylabel('Concentration [mlc/cc] x Path Length [cm]');
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
             append(DOCOreport,sprintf('OD Min (0,60 us): %s mlc cm/cc',minOD.string()));
            close(hf);
        end
        
        % Scale the data
        fitx = x(x>50);
        scalefactor = max(y);
        fity = y(x>50)/scalefactor;
        fityError = yError(x>50)/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*exp(-t*bFalla)+Ab*exp(-t*bFallb)-(1-Aa).*exp(-t*(bRise+bFalla))+(1-Ab).*exp(-t*(bRise+bFallb)));
        ODfitFun = @(A,b,c,t) A./(1+b.*t)+c;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*ebox(t,bFalla,W)+Ab*ebox(t,bFallb,W)-(1-Aa).*ebox(t,bRise+bFalla,W)+(1-Ab).*ebox(t,bRise+bFallb,W));
        %ODfitFun = @(A,Aa,bFalla,bFallb,c,t) A*expRiseDecayBoxConvolve( t,obj.integrationTime,bFall,bRise )
        ODfittype = fittype(ODfitFun,...
            'independent','t',...
            'coefficients',{'A','b','c'});
        
        % Set some initial parameters
        A0 = max(fity);
        b0 = 0.1;
        c0 = 0;
        Aa0 = 0.3;
        Ab0 = 0.3;
        bRise0 = 0.1;
        bFalla0 = 0.01;
        bFallb0 = 0.001;
        c0 = 0;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),ODfittype, ...
                'StartPoint', [A0,b0,c0], ...
                'Lower', [0, 0, 0],...
                'Upper', [inf, 1, 1]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.b = edouble(fitobj.b,cint(2));
        fitVals.c = edouble(fitobj.c,cint(3));
        
        k1avals.OD_A = fitVals.A;

        fprintf('OD A: %s\n',...
            fitVals.A.string());%,...
%             edouble(fitobj.bFalla,(cint(2,5)-cint(1,5))/2).string,...
%             edouble(fitobj.bFallb,(cint(2,6)-cint(1,6))/2).string);
        
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor);
        title('OD Concentration Fit');
        xlabel('Time [\mus]');
        ylabel('OD Conc. [mlc cm/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'OD Fit 1');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\nOD = OD_0/(1+r.*t)+c.'));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            r = fitVals.b*1e6;
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'OD_0: %s mlc cm/cc\n' ...
                'r: %s 1/s\n' ...
                'c: %s mlc cm/cc\n'], ...
                fitVals.A.string(),...
                r.string(),...
                fitVals.c.string()...
                ));
            close(hf);
        end
    end
    
    if DOCOindex > 0
        % Get the DOCO data
        x = obj.tavg;
        y = beta(DOCOindex,:);
        yError = betaError(DOCOindex,:);
        
        % Linear DOCO concentration fit
        xlinearfit = x(x>0 & x<60);
        ylinearfit = y(x>0 & x<60);
        yErrorlinearfit = yError(x>0 & x<60);
        [A,Bdoco] = weightedLinearLeastSquares(xlinearfit,ylinearfit,yErrorlinearfit);

        if ~isempty(DOCOreport)
            h = Heading(1,'DOCO Analysis');
            append(DOCOreport,h);
            h = Heading(2,'Linear DOCO Concentration Fit');
            append(DOCOreport,h);
            hf = figure;shadederrorbar(x,y,yError,'.');hold on;
            xx = -100:500;
            yy = A.value() + Bdoco.value()*xx;
            plot(xx,yy);
            xlim(gca,[-20 100]);
            xlabel('Time [\mus]');
            ylabel('Concentration [mlc/cc] x Path Length [cm]');
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf('DOCO Slope: %s mlc cm/cc/s',Bdoco.string()));
            close(hf);
        end
        
        % Scale the data
        fitx = x;
        scalefactor = max(y);
        fity = y/scalefactor;
        fityError = yError/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        DOCOfitFun = @(A,bRise,bFall,t0,t) A.*(ebox(t-t0,bFall,W)-ebox(t-t0,(bRise+bFall),W));
        DOCOfittype = fittype(DOCOfitFun,...
            'independent','t',...
            'coefficients',{'A','bRise','bFall','t0'});
        
        % Set some initial parameters
        A0 = max(fity);
        aa0 = 0.5;
        bRise0 = 0.01;
        bFall0 = 0.001;
        c0 = 0;
        
        % 
        fitobj = fit( reshape(fitx(fitx<4000),[],1),reshape(fity(fitx<4000),[],1),DOCOfittype, ...
                'StartPoint', [A0,bRise0,bFall0,0], ...
                'Lower', [0, 0, 0,0]);
        cint = confint(fitobj,0.95);
            
        A = edouble(fitobj.A.*scalefactor,(cint(2,1)-cint(1,1))/2.*scalefactor);
        k1avals.DOCO_A = A;
        bRise = edouble(fitobj.bRise,(cint(2,2)-cint(1,2))/2);
        k1avals.DOCO_bRise = bRise;

%         fprintf('DOCO A: %s Rise: %s Fall: %s 1/s\n',...
%             A.string,...
%             bRise.string,...
%             edouble(fitobj.bFall,(cint(2,3)-cint(1,3))/2).string);
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor);
        title('DOCO Concentration Fit');
        xlabel('Time [\mus]');
        ylabel('DOCO Conc. [mlc/cc]');
        close(hf);
    end

    % k1a Analysis
    if ~isempty(DOCOreport)
        h = Heading(1,'k1a Analysis');
        append(DOCOreport,h);
        h = Heading(2,'k1a From Linear Fitting');
        append(DOCOreport,h);
        append(DOCOreport,sprintf('Using dDOCO/dt = %s mlc cm/cc/s and OD = %s mlc cm/cc, we have k1a CO > %s 1/s',...
            Bdoco.string(),...
            minOD.string(),...
            string(Bdoco/minOD)));
    end
    
    % View the report
    close(DOCOreport);
    rptview(DOCOreport.OutputPath);
end


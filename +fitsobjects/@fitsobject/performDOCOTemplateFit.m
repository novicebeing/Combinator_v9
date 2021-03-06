function [xM,M,Mreal,beta,betaError,fitOutput] = performDOCOTemplateFit( obj, varargin )
    global kobjxaxis

    % Check that integration time is set
    if isempty(obj.integrationTime)
        %uiwait(msgbox('Defaulting to 50 us integration time...'));
        obj.integrationTime = 50;
        %error('Integration time parameter is not set');
    end
    
    % Set fitOutput variable
    fitOutput = struct([]);
    
    % Start Reporting
    import mlreportgen.dom.*;
    if nargin > 1
        if isempty(varargin{1})
            DOCOreport = [];
        else
            DOCOreport = Document(varargin{1},'html-file');
        end
    else
        DOCOreport = Document('DOCO Report');
    end
    reportimagenum = 1;
    
    % Correct wavenumber axis
    if ~isempty(DOCOreport)
        h = Heading(1,'X Axis Correction');
        append(DOCOreport,h);
    end
    
    if isempty(kobjxaxis)
        [simPeaks,expPeaks] = obj.correctDOCOwavenumAxis(DOCOreport);

        hf = figure();
        scatter(expPeaks,expPeaks-simPeaks);
        xlabel('Wavenumber');
        ylabel('Frequency Error [cm^{-1}]');
        if ~isempty(DOCOreport)
            h = Heading(1,'X Axis Fitting Residuals');
            append(DOCOreport,h);

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;

            close(hf);
        end
        kobjxaxis = obj.wavenum;
    else
        obj.wavenum = kobjxaxis;
    end
    
    % Load template spectra
    Mreal = obj.loadDOCOtemplates(DOCOreport);

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
    xM = obj.wavenum;
    M = fitMatrix;
    %return
    % Plot the results
    hf=figure;
    for i = 1:numel(obj.DOCOtemplateNames)
        if strcmp(obj.DOCOtemplateNames{i},'DOCO')
            shadederrorbar(obj.tavg,20*beta(i,:),20*betaError(i,:),'.'); hold on;
        else
            shadederrorbar(obj.tavg,beta(i,:),betaError(i,:),'.'); hold on;
        end
    end
    scalexaxis(1e-6);
    xlabel('Time [s]');
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
        
        xlim(gca,[-100 500]/1e6);
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
    kobj.plotbrowser;
    
    yfit = fitMatrixnonnan(:,1:3)*beta(1:3,:);
    yfit2 = zeros(size(yresiduals));
    yfit2(nonnanvalsResiduals) = yfit(:);
    % Display the residuals
    kobj2 = kineticsobject();
    kobj2.name = 'Fit';
    kobj2.ysum = yfit2./yresidualsError.^2;
    kobj2.wsum = 1./yresidualsError.^2;
    kobj2.t = obj.tavg;
    kobj2.wavenum = obj.wavenum;
    kobj2.plotbrowser;
    
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
    
    % Perform OD,D2O Simultaneous fits
    if D2Oindex > 0 && ODindex >0
        
        % Add the D2O heading to the report
        if ~isempty(DOCOreport)
            h = Heading(1,'D2O&OD Analysis');
            append(DOCOreport,h);
        end
        
        % Fit the D2O data
        x = obj.tavg;
        yD2O = beta(D2Oindex,:);
        yD2OError = betaError(D2Oindex,:);
        yOD = beta(ODindex,:);
        yODError = betaError(ODindex,:);
        
        % Scale the data
        fitx = x(x>100);
        scalefactorD2O = max(yD2O(x>100));
        fityD2O = yD2O(x>100)/scalefactorD2O;
        fityD2OError = yD2OError(x>100)/scalefactorD2O;
        scalefactorOD = max(yOD(x>100));
        fityOD = yOD(x>100)/scalefactorD2O;
        fityODError = yODError(x>100)/scalefactorOD;
        
        
        %% FIRST OD, D2O Simultaneous Fit
        ODfitFun = @(A1,A2,b1,b2,t) A1.*exp(-b1.*t)+A2.*exp(-b2.*t);
        D2OfitFun = @(A,aa,b1,b2,bPump,t) A*(1-aa.*exp(-b1*t)-(1-aa).*exp(-b2*t)).*exp(-bPump.^2.*t.^2);
        TotalFitFun = @(aOD1,aOD2,aD2O1,b1,b2,bPump,t) (t>0).*ODfitFun(aOD1,aOD2,b1,b2,t.*(t>0))+(t<0).*D2OfitFun(aD2O1,aOD2.*b2./(aOD1.*b1+aOD2.*b2),b1,b2,bPump,-t.*(t<0));
        TotalFitType = fittype(TotalFitFun,...
            'independent','t',...
            'coefficients',{'aOD1','aOD2','aD2O1','b1','b2','bPump'});
        
        % Set some initial parameters
        aOD10 = max(fityOD)/2;
        aOD20 = max(fityOD)/2;
        aD2O10 = max(fityD2O);
        aD2O20 = 0.5;
        b10 = 0.001;
        b20 = 0.0001;
        bPump0 = 0.00003;
        
        % Perform the fit
        fitobj = fit( reshape([fitx(:) -fitx(:)],[],1),reshape([fityOD(:) fityD2O(:)],[],1),TotalFitType, ...
                'StartPoint', [aOD10,aOD20,aD2O10,b10,b20,bPump0], ...
                'Lower', [0, 0, 0, 0, 0, 0],...
                'Upper', [inf,inf,inf,1,inf,inf]);
            
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.aOD1 = edouble(fitobj.aOD2,cint(1))*scalefactorOD;
        fitVals.aOD2 = edouble(fitobj.aOD1,cint(2))*scalefactorOD;
        fitVals.aD2O1 = edouble(fitobj.aD2O1,cint(3))*scalefactorD2O;
        fitVals.aD2O2 = edouble(0,0);%edouble(fitobj.aD2O2,cint(4));
        fitVals.b1 = edouble(fitobj.b1,cint(4));
        fitVals.b2 = edouble(fitobj.b2,cint(5));
        fitVals.bPump = edouble(fitobj.bPump,cint(6));
            
        hfOD = figure;shadederrorbar(fitx,fityOD.*scalefactorOD,fityODError.*scalefactorOD);hold on;
        plot(100:0.1:60000,feval(fitobj,100:0.1:60000).*scalefactorOD,'r');
        scalexaxis(1e-6);
        title('OD Concentration Fit');
        xlabel('Time [s]');
        ylabel('OD Conc. [mlc/cc]');
        
        hfD2O = figure;shadederrorbar(fitx,fityD2O.*scalefactorD2O,fityD2OError.*scalefactorD2O);hold on;
        plot(100:0.1:60000,feval(fitobj,-(100:0.1:60000)).*scalefactorD2O,'r');
        scalexaxis(1e-6);
        title('D2O Concentration Fit');
        xlabel('Time [s]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 2');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting OD to: %s\n',func2str(ODfitFun)));
            append(DOCOreport,sprintf('Fiting D2O to: %s\n',func2str(D2OfitFun)));
            
            print(hfOD,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            print(hfD2O,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'aOD1: %s\n',...
                'aOD2: %s\n',...
                'aD2O1: %s\n',...
                'aD2O2: %s\n',...
                'b1: %s\n',...
                'b2: %s\n',...
                'bPump: %s\n'], ...
                fitVals.aOD1.string(),...
                fitVals.aOD2.string(),...
                fitVals.aD2O1.string(),...
                fitVals.aD2O2.string(),...
                fitVals.b1.string(),...
                fitVals.b2.string(),...
                fitVals.bPump.string()...
                ));
            
            append(DOCOreport,sprintf(['Calculations:\n' ...
                'b1+b2: %s\n' ...
                'k[D2] = D2Omax*b1*b2/(A1*b1+A2*b2): %s'],...
                string(fitVals.b1+fitVals.b2),...
                string(fitVals.aD2O1*fitVals.b1*fitVals.b2/(fitVals.aOD1*fitVals.b1+fitVals.aOD2*fitVals.b2))...
                ));
            close(hfD2O);
            close(hfOD);
        end

    end
    
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
        bRise0 = 0.0008;
        bRiseb0 = 0.0001;
        bPump0 = 0.000038;
        
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
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('D2O Concentration Fit');
        xlabel('Time [s]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 1');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to: %s\n',func2str(D2OfitFun)));
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
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('D2O Concentration Fit');
        xlabel('Time [s]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 2');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to: %s\n',func2str(D2OfitFun)));
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
                fitVals.bRiseb.string(),...
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
        bRise0 = 0.001;
        bPump0 = 0.00001;
        
        % Perform the fit
        fitobj = fit( reshape(fitx(x>50),[],1),reshape(fity(x>50),[],1),D2Ofittype, ...
                'StartPoint', [A0,bRise0,bPump0], ...
                'Lower', [0, 0, 0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.bRise = edouble(fitobj.bRise,cint(2));
        fitVals.bPump = edouble(fitobj.bPump,cint(3));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(0:0.1:60000,feval(fitobj,0:0.1:60000).*scalefactor);
        scalexaxis(1e-6);
        title('D2O Concentration Fit');
        xlabel('Time [s]');
        ylabel('D2O Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            % First fit
            h = Heading(2,'D2O Fit 3');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to: %s\n',func2str(D2OfitFun)));
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

        %% Linear DOCO fitting
        linfitind = find(x>=0 & x<40);
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
            scalexaxis(1e-6);
            xlim(gca,[-20 100]/1e6);
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
        
        %% FIRST OD FIT
        fitx = x(x>50);
        scalefactor = max(y);
        fity = y(x>50)/scalefactor;
        fityError = yError(x>50)/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*exp(-t*bFalla)+Ab*exp(-t*bFallb)-(1-Aa).*exp(-t*(bRise+bFalla))+(1-Ab).*exp(-t*(bRise+bFallb)));
        ODfitFun = @(A,b,t) A./(1+b.*t);
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*ebox(t,bFalla,W)+Ab*ebox(t,bFallb,W)-(1-Aa).*ebox(t,bRise+bFalla,W)+(1-Ab).*ebox(t,bRise+bFallb,W));
        %ODfitFun = @(A,Aa,bFalla,bFallb,c,t) A*expRiseDecayBoxConvolve( t,obj.integrationTime,bFall,bRise )
        ODfittype = fittype(ODfitFun,...
            'independent','t',...
            'coefficients',{'A','b'});
        
        % Set some initial parameters
        A0 = max(fity);
        b0 = 0.1;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),ODfittype, ...
                'StartPoint', [A0,b0], ...
                'Lower', [0, 0],...
                'Upper', [inf, 1]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.b = edouble(fitobj.b,cint(2));
        
        k1avals.OD_A = fitVals.A;
        
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(0:0.1:60000,feval(fitobj,0:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('OD Concentration Fit');
        xlabel('Time [s]');
        ylabel('OD Conc. [mlc cm/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'OD Fit 1');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\nOD = OD_0/(1+r.*t).'));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'OD_0: %s mlc cm/cc\n' ...
                'r: %s 1/us\n'], ...
                fitVals.A.string(),...
                fitVals.b.string()...
                ));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'OD Fit 1';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A = fitVals.A;
            fitOutput(n+1).b = fitVals.b;
            close(hf);
        end
        %% SECOND OD FIT
        fitx = x(x>100);
        scalefactor = max(y);
        fity = y(x>100)/scalefactor;
        fityError = yError(x>100)/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*exp(-t*bFalla)+Ab*exp(-t*bFallb)-(1-Aa).*exp(-t*(bRise+bFalla))+(1-Ab).*exp(-t*(bRise+bFallb)));
        ODfitFun = @(A,b,c,t) A.*exp(-b.*t)+c;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*ebox(t,bFalla,W)+Ab*ebox(t,bFallb,W)-(1-Aa).*ebox(t,bRise+bFalla,W)+(1-Ab).*ebox(t,bRise+bFallb,W));
        %ODfitFun = @(A,Aa,bFalla,bFallb,c,t) A*expRiseDecayBoxConvolve( t,obj.integrationTime,bFall,bRise )
        ODfittype = fittype(ODfitFun,...
            'independent','t',...
            'coefficients',{'A','b','c'});
        
        % Set some initial parameters
        A0 = max(fity);
        b0 = 0.0005;
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

        fprintf('OD A: %s\n',...
            fitVals.A.string());%,...
%             edouble(fitobj.bFalla,(cint(2,5)-cint(1,5))/2).string,...
%             edouble(fitobj.bFallb,(cint(2,6)-cint(1,6))/2).string);
        
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(0:0.1:60000,feval(fitobj,0:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('OD Concentration Fit');
        xlabel('Time [s]');
        ylabel('OD Conc. [mlc cm/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'OD Fit 2');
            append(DOCOreport,h);
             append(DOCOreport,sprintf('Fiting to:\n%s.',func2str(ODfitFun)));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'OD_0: %s mlc cm/cc\n' ...
                'r: %s 1/us\n' ...
                'c: %s mlc cm/cc\n'], ...
                fitVals.A.string(),...
                fitVals.b.string(),...
                fitVals.c.string()...
                ));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'OD Fit 2';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A = fitVals.A;
            fitOutput(n+1).b = fitVals.b;
            fitOutput(n+1).c = fitVals.c;
            close(hf);
        end

        %% THIRD OD FIT
        fitx = x;
        scalefactor = max(y);
        fity = y/scalefactor;
        fityError = yError/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*exp(-t*bFalla)+Ab*exp(-t*bFallb)-(1-Aa).*exp(-t*(bRise+bFalla))+(1-Ab).*exp(-t*(bRise+bFallb)));
        %ODfitFun = @(A,b,c,t) A.*exp(-b.*t)+c;
        ODfitFun = @(A,B,bRise,bFall,t) A.*(ebox(t,bFall,W)-ebox(t,bRise+bFall,W))+B.*ebox(t,bFall,W);
        %ODfitFun = @(A,Aa,bFalla,bFallb,c,t) A*expRiseDecayBoxConvolve( t,obj.integrationTime,bFall,bRise )
        ODfittype = fittype(ODfitFun,...
            'independent','t',...
            'coefficients',{'A','B','bRise','bFall'});
        
        % Set some initial parameters
        A0 = 0.25*max(fity);
        B0 = 0.75*max(fity);
        bRise0 = 0.1;
        bFall0 = 0.001;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),ODfittype, ...
                'StartPoint', [A0,B0,bRise0,bFall0], ...
                'Lower', [0, 0, 0,0],...
                'Upper', [inf, inf, 1,1]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.B = edouble(fitobj.B,cint(2))*scalefactor;
        fitVals.bRise = edouble(fitobj.bRise,cint(3));
        fitVals.bFall = edouble(fitobj.bFall,cint(4));
        
        ODinitialConc3 = fitVals.B;
        
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('OD Concentration Fit');
        xlabel('Time [s]');
        ylabel('OD Conc. [mlc cm/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'OD Fit 3');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\n%s.',func2str(ODfitFun)));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            xlim(gca,[-50 200]/1e6);
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'A: %s mlc cm/cc\n' ...
                'B: %s mlc cm/cc\n' ...
                'rRise: %s 1/us\n' ...
                'rFall: %s 1/us\n'], ...
                fitVals.A.string(),...
                fitVals.B.string(),...
                fitVals.bRise.string(),...
                fitVals.bFall.string()...
                ));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'OD Fit 3';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A = fitVals.A;
            fitOutput(n+1).B = fitVals.B;
            fitOutput(n+1).bRise = fitVals.bRise;
            fitOutput(n+1).bFall = fitVals.bFall;
            close(hf);
        end

        %% FOURTH OD FIT
        fitx = x(x>100);
        scalefactor = max(y(x>100));
        fity = y(x>100)/scalefactor;
        fityError = yError(x>100)/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*exp(-t*bFalla)+Ab*exp(-t*bFallb)-(1-Aa).*exp(-t*(bRise+bFalla))+(1-Ab).*exp(-t*(bRise+bFallb)));
        ODfitFun = @(A1,A2,b1,b2,t) A1.*exp(-b1.*t)+A2.*exp(-b2.*t);
        %ODfitFun = @(A,B,bRise,bFall,t) A.*(ebox(t,bFall,W)-ebox(t,bRise+bFall,W))+B.*ebox(t,bFall,W);
        %ODfitFun = @(A,Aa,bFalla,bFallb,c,t) A*expRiseDecayBoxConvolve( t,obj.integrationTime,bFall,bRise )
        ODfittype = fittype(ODfitFun,...
            'independent','t',...
            'coefficients',{'A1','A2','b1','b2'});
        
        % Set some initial parameters
        A10 = 0.5*max(fity);
        A20 = 0.5*max(fity);
        b10 = 0.001;
        b20 = 0.0001;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),ODfittype, ...
                'StartPoint', [A10,A20,b20,b10], ...
                'Lower', [0, 0, 0,0],...
                'Upper', [inf, inf, 1,1]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A1 = edouble(fitobj.A1,cint(1))*scalefactor;
        fitVals.A2 = edouble(fitobj.A2,cint(2))*scalefactor;
        fitVals.b1 = edouble(fitobj.b1,cint(3));
        fitVals.b2 = edouble(fitobj.b2,cint(4));
        
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('OD Concentration Fit');
        xlabel('Time [s]');
        ylabel('OD Conc. [mlc cm/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'OD Fit 4');
            append(DOCOreport,h);
             append(DOCOreport,sprintf('Fiting to:\n%s.',func2str(ODfitFun)));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            xlim(gca,[-50 200]/1e6);
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'A1: %s mlc cm/cc\n' ...
                'A2: %s mlc cm/cc\n' ...
                'r1: %s 1/us\n' ...
                'r2: %s 1/us\n'], ...
                fitVals.A1.string(),...
                fitVals.A2.string(),...
                fitVals.b1.string(),...
                fitVals.b2.string()...
                ));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'OD Fit 4';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A1 = fitVals.A1;
            fitOutput(n+1).A2 = fitVals.A2;
            fitOutput(n+1).b1 = fitVals.b1;
            fitOutput(n+1).b2 = fitVals.b2;
            close(hf);
        end
        
        %% FIFTH OD FIT
        fitx = x;
        scalefactor = max(y);
        fity = y/scalefactor;
        fityError = yError/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        %ODfitFun = @(A,Aa,Ab,bRise,bFalla,bFallb,t) A*(Aa*exp(-t*bFalla)+Ab*exp(-t*bFallb)-(1-Aa).*exp(-t*(bRise+bFalla))+(1-Ab).*exp(-t*(bRise+bFallb)));
        ODfitFun = @(A1,b1,b2,t) A1.*exp(-b1.*t)./(1+b2./b1.*(1-exp(-b1.*t)));
        %ODfitFun = @(A,B,bRise,bFall,t) A.*(ebox(t,bFall,W)-ebox(t,bRise+bFall,W))+B.*ebox(t,bFall,W);
        %ODfitFun = @(A,Aa,bFalla,bFallb,c,t) A*expRiseDecayBoxConvolve( t,obj.integrationTime,bFall,bRise )
        ODfittype = fittype(ODfitFun,...
            'independent','t',...
            'coefficients',{'A1','b1','b2'});
        
        % Set some initial parameters
        A10 = max(fity);
        b10 = 0.001;
        b20 = 0.0001;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),ODfittype, ...
                'StartPoint', [A10,b20,b10], ...
                'Lower', [0, 0,0],...
                'Upper', [inf, 1,1]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A1 = edouble(fitobj.A1,cint(1))*scalefactor;
        fitVals.b1 = edouble(fitobj.b1,cint(2));
        fitVals.b2 = edouble(fitobj.b2,cint(3));
        
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(0:0.1:60000,feval(fitobj,0:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('OD Concentration Fit');
        xlabel('Time [s]');
        ylabel('OD Conc. [mlc cm/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'OD Fit 5');
            append(DOCOreport,h);
             append(DOCOreport,sprintf('Fiting to:\n%s.',func2str(ODfitFun)));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            xlim(gca,[-50 200]/1e6);
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'A1: %s mlc cm/cc\n' ...
                'r1: %s 1/us\n' ...
                'r2: %s 1/us\n'], ...
                fitVals.A1.string(),...
                fitVals.b1.string(),fitVals.b2.string()));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'OD Fit 5';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A1 = fitVals.A1;
            fitOutput(n+1).r1 = fitVals.b1;
            fitOutput(n+1).r2 = fitVals.b2;
            close(hf);
        end
    end
    
    if DOCOindex > 0
        % Get the DOCO data
        x = obj.tavg;
        y = beta(DOCOindex,:);
        yError = betaError(DOCOindex,:);
        
        %% Linear DOCO concentration fit
        xlinearfit = x(x>=0 & x<40);
        ylinearfit = y(x>=0 & x<40);
        yErrorlinearfit = yError(x>=0 & x<40);
        [A,Bdoco] = weightedLinearLeastSquares(xlinearfit,ylinearfit,yErrorlinearfit);
        if numel(ylinearfit) < 2
            xlinearfit = [NaN NaN];
            ylinearfit = [NaN NaN];
            yErrorlinearfit = [NaN NaN];
        end
        DOCOfirstpoint = edouble(ylinearfit(1),yErrorlinearfit(1));
        DOCOsecondpoint = edouble(ylinearfit(2),yErrorlinearfit(2));
        
        if ~isempty(DOCOreport)
            h = Heading(1,'DOCO Analysis');
            append(DOCOreport,h);
            h = Heading(2,'Linear DOCO Concentration Fit');
            append(DOCOreport,h);
            hf = figure;shadederrorbar(x,y,yError,'.');hold on;
            xx = -100:500;
            yy = A.value() + Bdoco.value()*xx;
            plot(xx,yy);
            scalexaxis(1e-6);
            xlim(gca,[-20 100]);
            xlabel('Time [s]');
            ylabel('Concentration [mlc/cc] x Path Length [cm]');
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            append(DOCOreport,sprintf('DOCO First Point(%d us): %s mlc cm/cc',xlinearfit(1),DOCOfirstpoint.string()));
            append(DOCOreport,sprintf('DOCO Second Point(%d us): %s mlc cm/cc',xlinearfit(2),DOCOsecondpoint.string()));
            append(DOCOreport,sprintf('DOCO Average: %s mlc cm/cc',string(0.5*DOCOfirstpoint+0.5*DOCOsecondpoint)));
            append(DOCOreport,sprintf('DOCO Slope: %s mlc cm/cc/us',Bdoco.string()));
            close(hf);
        end
        
        %% FIRST DOCO FIT
        fitx = x;
        scalefactor = max(y);
        fity = y/scalefactor;
        fityError = yError/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        DOCOfitFun = @(A,bRise,bFall,t) A.*(ebox(t,bFall,W)-ebox(t,(bRise+bFall),W));
        DOCOfittype = fittype(DOCOfitFun,...
            'independent','t',...
            'coefficients',{'A','bRise','bFall'});
        
        % Set some initial parameters
        A0 = max(fity);
        bRise0 = 0.1;
        bFall0 = 0.001;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),DOCOfittype, ...
                'StartPoint', [A0,bRise0,bFall0], ...
                'Lower', [0, 0, 0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.bRise = edouble(fitobj.bRise,cint(2));
        fitVals.bFall = edouble(fitobj.bFall,cint(3));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('DOCO Concentration Fit');
        xlabel('Time [s]');
        ylabel('DOCO Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'DOCO Fit 1');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\nDOCO = A.*(ebox(t,bFall,W)-ebox(t,(bRise+bFall),W)).'));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            xlim(gca,[-100 500]/1e6);
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
        
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'DOCO_0: %s mlc cm/cc\n' ...
                'bRise: %s 1/us\n' ...
                'bFall: %s 1/us\n'], ...
                fitVals.A.string(),...
                fitVals.bRise.string(),...
                fitVals.bFall.string()));
            DOCOmaxSlope = fitVals.A*fitVals.bRise;
            append(DOCOreport,sprintf(['Max slope from fit:\n' ...
                'A*bRise = %s mlc cm/cc/us\n'],...
                DOCOmaxSlope.string()));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'DOCO Fit 1';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A = fitVals.A;
            fitOutput(n+1).bRise = fitVals.bRise;
            fitOutput(n+1).bFall = fitVals.bFall;
            close(hf);
        end
        %% SECOND DOCO FIT
        fitx = x(x>200);
        scalefactor = max(y(x>200));
        fity = y(x>200)/scalefactor;
        fityError = yError(x>200)/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        DOCOfitFun = @(A,bFall,t) A.*exp(-t.*bFall);
        DOCOfittype = fittype(DOCOfitFun,...
            'independent','t',...
            'coefficients',{'A','bFall'});
        
        % Set some initial parameters
        A0 = max(fity);
        bRise0 = 0.1;
        bFall0 = 0.001;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),DOCOfittype, ...
                'StartPoint', [A0,bFall0], ...
                'Lower', [0, 0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        %fitVals.bRise = edouble(fitobj.bRise,cint(2));
        fitVals.bFall = edouble(fitobj.bFall,cint(2));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('DOCO Concentration Fit');
        xlabel('Time [s]');
        ylabel('DOCO Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'DOCO Fit 2');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\n%s.',func2str(DOCOfitFun)));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            xlim(gca,[-100 500]/1e6);
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
        
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'DOCO_0: %s mlc cm/cc\n' ...
                'bFall: %s 1/us\n'], ...
                fitVals.A.string(),...
                fitVals.bFall.string()));
            %DOCOmaxSlope = fitVals.A*fitVals.bRise;
%             append(DOCOreport,sprintf(['Max slope from fit:\n' ...
%                 'A*bRise = %s mlc cm/cc/us\n'],...
%                 DOCOmaxSlope.string()));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'DOCO Fit 2';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A = fitVals.A;
            fitOutput(n+1).bFall = fitVals.bFall;
            close(hf);
        end

        %% THIRD DOCO FIT
        fitx = x(x>=200);
        scalefactor = max(y(x>=200));
        fity = y(x>=200)/scalefactor;
        fityError = yError(x>=200)/scalefactor;
        
        % Set the fit function
        W = obj.integrationTime;
        DOCOfitFun = @(A,a,bFall1,bFall2,t) A.*(a.*exp(-t.*bFall1)+(1-a).*exp(-t.*bFall2));
        DOCOfittype = fittype(DOCOfitFun,...
            'independent','t',...
            'coefficients',{'A','a','bFall1','bFall2'});
        
        % Set some initial parameters
        A0 = max(fity);
        a = 0.5;
        bFall10 = 0.001;
        bFall20 = 0.0001;
        
        % 
        fitobj = fit( reshape(fitx,[],1),reshape(fity,[],1),DOCOfittype, ...
                'StartPoint', [A0,a,bFall10,bFall20], ...
                'Lower', [0, 0,0,0]);
        cint = diff(confint(fitobj,0.95),1)/2;
        fitVals = struct();
        fitVals.A = edouble(fitobj.A,cint(1))*scalefactor;
        fitVals.a = edouble(fitobj.a,cint(2));
        fitVals.bFall1 = edouble(fitobj.bFall1,cint(3));
        fitVals.bFall2 = edouble(fitobj.bFall2,cint(4));
            
        hf = figure;shadederrorbar(fitx,fity.*scalefactor,fityError.*scalefactor);hold on;
        plot(-100:0.1:60000,feval(fitobj,-100:0.1:60000).*scalefactor,'r');
        scalexaxis(1e-6);
        title('DOCO Concentration Fit');
        xlabel('Time [s]');
        ylabel('DOCO Conc. [mlc/cc]');
        
        if ~isempty(DOCOreport)
            h = Heading(2,'DOCO Fit 2');
            append(DOCOreport,h);
            append(DOCOreport,sprintf('Fiting to:\n%s.',func2str(DOCOfitFun)));

            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
            
            xlim(gca,[-100 500]/1e6);
            print(hf,'-dpng',sprintf('test%i',reportimagenum));
            testimg = Image(sprintf('test%i.png',reportimagenum));
            testimg.Height = '3.75in';
            testimg.Width = '5in';
            append(DOCOreport, testimg);
            reportimagenum = reportimagenum+1;
        
            append(DOCOreport,sprintf(['Parameter Estimates:\n' ...
                'DOCO_0: %s mlc cm/cc\n' ...
                'a: %s' ...
                'bFall1: %s 1/us\n' ...
                'bFall2: %s 1/us\n'], ...
                fitVals.A.string(),...
                fitVals.a.string(),...
                fitVals.bFall1.string(),...
                fitVals.bFall2.string()));
            %DOCOmaxSlope = fitVals.A*fitVals.bRise;
            append(DOCOreport,sprintf(['Early (t=0) slope from fit:\n' ...
                'a*b1+(1-a)*b2 = %s mlc cm/cc/us\n'],...
                string(fitVals.a*fitVals.bFall1+(1-fitVals.a)*fitVals.bFall2)));
            n = numel(fitOutput);
            fitOutput(n+1).name = 'DOCO Fit 3';
            fitOutput(n+1).fitFunction = func2str(ODfitFun);
            fitOutput(n+1).A = fitVals.A;
            fitOutput(n+1).a = fitVals.a;
            fitOutput(n+1).bFall1 = fitVals.bFall1;
            fitOutput(n+1).bFall2 = fitVals.bFall2;
            close(hf);
        end
        
    end

    % k1a Analysis
    if ~isempty(DOCOreport)
        h = Heading(1,'k1a Analysis');
        append(DOCOreport,h);
        h = Heading(2,'k1a From Linear Fitting');
        append(DOCOreport,h);
        append(DOCOreport,sprintf('Using dDOCO/dt = %s mlc cm/cc/us and OD = %s mlc cm/cc, we have k1a CO > %s 1/s',...
            Bdoco.string(),...
            minOD.string(),...
            string(Bdoco/minOD*1e6)));
        h = Heading(2,'k1a From OD First Point and DOCO exp fit');
        append(DOCOreport,h);
        append(DOCOreport,sprintf('Using dDOCO/dt = %s mlc cm/cc/us and OD = %s mlc cm/cc, we have k1a CO > %s 1/s',...
            DOCOmaxSlope.string(),...
            minOD.string(),...
            string(DOCOmaxSlope/minOD*1e6)));
        h = Heading(2,'k1a From OD ebox fit and DOCO exp fit');
        append(DOCOreport,h);
        append(DOCOreport,sprintf('Using dDOCO/dt = %s mlc cm/cc/us and OD = %s mlc cm/cc, we have k1a CO > %s 1/s',...
            DOCOmaxSlope.string(),...
            ODinitialConc3.string(),...
            string(DOCOmaxSlope/ODinitialConc3*1e6)));
    end
    
    % View the report
    if ~isempty(DOCOreport)
        close(DOCOreport);
        rptview(DOCOreport.OutputPath);
    end
end


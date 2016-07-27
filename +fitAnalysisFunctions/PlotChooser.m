function PlotChooser(fitobjnames,fitobjs)
	
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  %%  PREALLOCATE VARIABLES              %%
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    d = dialog('Position',[300 300 250 150],'Name','Select One');
    txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 80 210 40],...
           'String','Select a color');
       
    popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[75 70 100 25],...
           'String',{'Red';'Green';'Blue'},...
           'Callback',@popup_callback);
       
    popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[75 70 100 25],...
           'String',{'Red';'Green';'Blue'},...
           'Callback',@popup_callback);
       
    btn = uicontrol('Parent',d,...
           'Position',[89 20 70 25],...
           'String','Close',...
           'Callback','delete(gcf)');
       
    choice = 'Red';
       
    % Wait for d to close before running to completion
    uiwait(d);
   
       function popup_callback(popup,callbackdata)
          idx = popup.Value;
          popup_items = popup.String;
          % This code uses dot notation to get properties.
          % Dot notation runs in R2014b and later.
          % For R2014a and earlier:
          % idx = get(popup,'Value');
          % popup_items = get(popup,'String');
          choice = char(popup_items(idx,:));
       end
   
   
    pathlength = 5700;
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  %%  PREALLOCATE VARIABLES              %%
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    intTimes = zeros(size(fitobjs));
    xCO = ezeros(size(fitobjs));
    xN2 = ezeros(size(fitobjs));
    xO3 = ezeros(size(fitobjs));
    xD2 = ezeros(size(fitobjs));

    % VALUES OF d([DOCO])/dt
    dDOCOdt_CUBIC = ezeros(size(fitobjs));
    dDOCOdt_QUADRATIC = ezeros(size(fitobjs));
    dDOCOdt_QUADRATIC_RELAX = ezeros(size(fitobjs));
    dDOCOdt_LINEAR = ezeros(size(fitobjs));
    dDOCOdt_EXPONENTIAL = ezeros(size(fitobjs));
    dDOCOdtsim_CUBIC = zeros(size(fitobjs));
    dDOCOdtsim_QUADRATIC = zeros(size(fitobjs));
    dDOCOdtsim_LINEAR = zeros(size(fitobjs));
    
    % VALUES OF OD
    OD_MEAN = ezeros(size(fitobjs));
    
    % Define the fit data
    for i = 1:length(fitobjs)
        if i == 1
            dataToFit = fitobjs{i}.getTable(1,5700);
        else
            dataToFit = union(dataToFit,fitobjs{i}.getTable(i,5700));
        end
        %plants{i}.exportDOCOglobals();
    end
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
        ODtrace = fitobject.fitb(fitobject.fitbNamesInd(ODidx),:)/pathlength;
        ODtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(ODidx),:)/pathlength;
        DOCOtrace = fitobject.fitb(fitobject.fitbNamesInd(DOCOidx),:)/pathlength;
        DOCOtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(DOCOidx),:)/pathlength;

        % Find the first two time points
        time2 = time;
        time2(time < 0) = NaN;
        [~,firstidx] = nanmin(time2);
        time3 = time2;
        time3(firstidx) = NaN;
        [~,secondidx] = nanmin(time3);
        dt = (time(secondidx) - time(firstidx))/1e6;
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  %% CALCULATE THE DOCO SLOPE USING DIFFERENT FUNCTIONS %%
        %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % ALL FITS
            DOCOfitIndcs = 3:7;
            DOCOscalefactor = 1e12;
            [xData, yData, weights] = prepareCurveData( time(DOCOfitIndcs)',DOCOtrace(DOCOfitIndcs)'/DOCOscalefactor,1./(DOCOtraceErr(DOCOfitIndcs)'/DOCOscalefactor).^2 );
            
            
            % LINEAR
            M_LINEAR = [(xData+intBox/2)];
            [b_LINEAR,stdb_LINEAR,mse_LINEAR] = lscov(M_LINEAR,yData,weights);
            dDOCOdt_LINEAR(ii) = edouble(b_LINEAR(1),stdb_LINEAR(1)/min(1,sqrt(mse_LINEAR)))*DOCOscalefactor*1e6;
            
            % QUADRATIC
            M_QUADRATIC = [(xData+intBox/2) (xData.^2+intBox.*xData+intBox.^2/3)];
            [b_QUADRATIC,stdb_QUADRATIC,mse_QUADRATIC] = lscov(M_QUADRATIC,yData,weights);
            dDOCOdt_QUADRATIC(ii) = edouble(b_QUADRATIC(1),stdb_QUADRATIC(1)/min(1,sqrt(mse_QUADRATIC)))*DOCOscalefactor*1e6;
            
            figure;plot(xData,yData,'o'); hold on;
            xFit = linspace(min(xData),max(xData),100);
            plot(xFit,[(xFit+intBox/2); (xFit.^2+intBox.*xFit+intBox.^2/3)]'*b_QUADRATIC,'r');
            title(sprintf('%s,%g',fitobjnames{ii},N2));
            
            % CUBIC
            M_CUBIC = [(xData+intBox/2) (xData.^2+intBox.*xData+intBox.^2/3) (xData.^3+3/2*intBox.*xData.^2+intBox.^2*xData+intBox.^3/4)];
            [b_CUBIC,stdb_CUBIC,mse_CUBIC] = lscov(M_CUBIC,yData,weights);
            dDOCOdt_CUBIC(ii) = edouble(b_CUBIC(1),stdb_CUBIC(1)/min(1,sqrt(mse_CUBIC)))*DOCOscalefactor*1e6;
        
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


        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  %% CALCULATE THE OD VALUE USING DIFFERENT FUNCTIONS %%
        %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        idxoffset = 0;
        OD_MEAN(ii) = (edouble(ODtrace(secondidx+idxoffset),ODtraceErr(secondidx+idxoffset))+edouble(ODtrace(firstidx+idxoffset),ODtraceErr(firstidx+idxoffset)))/2;
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  %%  SAVE SOME VALUES FOR LATER         %%
        %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         xCO(ii) = edouble(1,0)*CO;
         xN2(ii) = edouble(1,0)*N2;
         xO3(ii) = edouble(1,0)*O3;
         xD2(ii) = edouble(1,0)*D2;
         intTimes(ii) = intBox;
         
        %% Update the waitbar
         waitbar(ii/numel(fitobjs),hwait);
    end
    close(hwait);
    
    figure;plot(xN2,dDOCOdt_QUADRATIC./OD_MEAN,'o')

end
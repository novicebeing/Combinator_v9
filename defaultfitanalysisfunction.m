function [x,y,ODmean,DOCOmean,O3,CO,D2] = defaultfitanalysisfunction(name,fitobject)
    
    O3 = fitobject.initialConditionsTable.O3;
    CO = fitobject.initialConditionsTable.CO;
    D2 = fitobject.initialConditionsTable.D2*7e16/50;

    % Evaluate a slope for the first two OD points
    ODidx = find(strcmp('OD',fitobject.fitbNames));
    DOCOidx = find(strcmp('trans-DOCO',fitobject.fitbNames));
    time = fitobject.t;
    ODtrace = fitobject.fitb(fitobject.fitbNamesInd(ODidx),:)/14700;
    DOCOtrace = fitobject.fitb(fitobject.fitbNamesInd(DOCOidx),:)/14700;
    
    % Print the filename
    disp(name);
    
    % Find the first two time points
    time(time < 0) = NaN;
    [~,firstidx] = nanmin(time);
    time2 = time;
    time2(firstidx) = NaN;
    [~,secondidx] = nanmin(time2);
    dt = (time(secondidx) - time(firstidx))/1e6;
    
    % Calculate and print the DOCO slope
    dDOCOdt = (DOCOtrace(secondidx)-DOCOtrace(firstidx))/dt;
    DOCOmean = (DOCOtrace(secondidx)+DOCOtrace(firstidx))/2;
    fprintf('   DOCO Slope: %g mlc/cc/sec\n',dDOCOdt);
    fprintf('   DOCO Mean: %g mlc/cc\n',DOCOmean);
    
    % Calculate and print the DOCO slope
    ODmean = (ODtrace(secondidx)+ODtrace(firstidx))/2;
    fprintf('   OD Mean: %g mlc/cc\n',ODmean);
    
    % Calculate and print the DOCO slope
    fprintf('   DOCOslope/ODmean: %g 1/sec\n',dDOCOdt/ODmean);
    fprintf('   DOCOmean/ODmean: %g 1/sec\n',DOCOmean/ODmean);
     
    H = O3;
    ExtraRxns = DOCOmean*D2;
    
     y = dDOCOdt/ODmean/CO;
     x = ExtraRxns/ODmean/CO;
    %y = dDOCOdt/DOCOmean;
    %x = O3;
end
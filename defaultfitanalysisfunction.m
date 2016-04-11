function [x,y,ODmean,DOCOmean,O3,CO,D2] = defaultfitanalysisfunction(name,fitobject)
    
    O3 = fitobject.initialConditionsTable.O3;
    CO = fitobject.initialConditionsTable.CO;
    D2 = fitobject.initialConditionsTable.D2;%*7e16/50;

    % Evaluate a slope for the first two OD points
    ODidx = find(strcmp('OD',fitobject.fitbNames));
    DOCOidx = find(strcmp('trans-DOCO',fitobject.fitbNames));
    time = fitobject.t;
    ODtrace = fitobject.fitb(fitobject.fitbNamesInd(ODidx),:)/14700;
    ODtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(ODidx),:)/14700;
    DOCOtrace = fitobject.fitb(fitobject.fitbNamesInd(DOCOidx),:)/14700;
    DOCOtraceErr = fitobject.fitbError(fitobject.fitbNamesInd(DOCOidx),:)/14700;
    
    % Print the filename
    disp(name);
    
    % Find the first two time points
    time(time < 0) = NaN;
    [~,firstidx] = nanmin(time);
    time2 = time;
    time2(firstidx) = NaN;
    [~,secondidx] = nanmin(time2);
    dt = (time(secondidx) - time(firstidx))/1e6;
    
    size(DOCOtrace)
    % Calculate and print the DOCO slope
    dDOCOdt = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))-edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/dt;
    dDOCOdt2 = (1/(50e-6)^2*edouble(DOCOtrace(3),DOCOtraceErr(3))+1/(25e-6)^2*edouble(DOCOtrace(2),DOCOtraceErr(2)))*100e-6/2;
    i = 0;
    dt = (time(secondidx+i) - time(firstidx+i))/1e6;
    dODdt = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))-edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/dt;
    dODdt2 = (1/(50e-6)^2*edouble(ODtrace(3),ODtraceErr(3))+1/(25e-6)^2*edouble(ODtrace(2),ODtraceErr(2)))*100e-6/2;
    DOCOmean = (edouble(DOCOtrace(secondidx),DOCOtraceErr(secondidx))+edouble(DOCOtrace(firstidx),DOCOtraceErr(firstidx)))/2;
    fprintf('   DOCO Slope: %g mlc/cc/sec\n',dDOCOdt.value);
    fprintf('   DOCO Slope2: %g mlc/cc/sec\n',dDOCOdt2.value);
    fprintf('   DOCO Mean: %g mlc/cc\n',DOCOmean.value);
    
    % Calculate and print the DOCO slope
    ODmean = (edouble(ODtrace(secondidx+i),ODtraceErr(secondidx+i))+edouble(ODtrace(firstidx+i),ODtraceErr(firstidx+i)))/2;
%     fprintf('   OD Mean: %g mlc/cc\n',ODmean);
    
    % Calculate and print the DOCO slope
%     fprintf('   DOCOslope/ODmean: %g 1/sec\n',value(dDOCOdt/ODmean));
%     fprintf('   DOCOmean/ODmean: %g 1/sec\n',value(DOCOmean/ODmean));
     
    H = O3;
    ExtraRxns = DOCOmean*O3;
    
     y = dDOCOdt2/ODmean;%/ODmean/CO;
     x = edouble(1,0)*D2;%ExtraRxns/ODmean/CO;
    %y = dDOCOdt/DOCOmean;
    %x = O3;
end
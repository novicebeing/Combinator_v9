function addTemplateSpectrumFromPlotBrowser( obj,sliderobj )
    specnum = round(get(sliderobj,'Value'));
    
    % Get the spectrum
    y = obj.yavg(:,:,specnum);
    yerr = obj.ystderror(:,:,specnum);
    
    
    
    % Assign a name to the spectrum
    prompt = {'Template Spectrum Name:'};
    dlg_title = 'Add Template Spectrum';
    num_lines = 1;
    defaultans = {sprintf('Template %i',size(obj.templateAvg,3)*(~isempty(obj.templateAvg))+1)};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    if isempty(answer)
        return
    else
        templateName = answer{1};
    end
    
    % Save the template
    if isempty(obj.templateAvg)
        obj.templateAvg = y;
        obj.templateError = yerr;
        obj.templateNames = {templateName};
    else
        n = size(obj.templateAvg,3)+1;
        obj.templateAvg(:,:,n) = y;
        obj.templateError(:,:,n) = yerr;
        obj.templateNames{n} = templateName;
    end


end


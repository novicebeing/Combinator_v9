function addTemplateSpectrumFromClipboard( obj)
    % Get the spectrum
    data = evalin('base','clipboardContents','');
    if isempty(data)
        return
    end
    x = data(:,:,1);
    y = data(:,:,2);
    yerr = data(:,:,3);
    
    if reshape(x,[],1) ~= reshape(obj.wavenum,[],1);
       error('The x axis must be the same')
    end
    
    y = reshape(y,size(obj.yavg,1),size(obj.yavg,2));
    yerr = reshape(yerr,size(obj.yavg,1),size(obj.yavg,2));
    
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


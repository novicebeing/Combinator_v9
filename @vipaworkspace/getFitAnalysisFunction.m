function getFitAnalysisFunction(obj)
    % Check to see if there are any acquire destinations set
    if strcmp(obj.acquiretab.imageDestTextField.Text,'none') && ...
            strcmp(obj.acquiretab.calibrationTextField.Text,'none') && ...
            strcmp(obj.acquiretab.spectraDestTextField.Text,'none')
        errordlg('No acquire destination is set...','Acquire Error','modal');
        return
    end
end
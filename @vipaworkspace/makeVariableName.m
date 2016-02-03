function outString = makeVariableName(this,inString)
    
    % Check the input
    if ~ischar(inString)
        error('Invalid Input')
    end

    outString = inString;

    % Add an underscore if the first character is a number
    if any(strcmp(inString(1),{'0','1','2','3','4','5','6','7','8','9'}))
        outString = ['v_' outString];
    end
    
    outString = strrep(outString,' ','_');
	outString = strrep(outString,'(','_');
	outString = strrep(outString,')','_');
    outString = strrep(outString,'-','_');
end
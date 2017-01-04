function mfiles = getpackagemfiles(packageString)
	packageStruct = what(strrep(packageString,'.','/'));
	mfiles = {};
	if isempty(packageStruct)
		return
	end
	for i = 1:numel(packageStruct.m)
		[~,b,~] = fileparts(packageStruct.m{i});
		mfiles{end+1} = sprintf('%s.%s',packageString,b);
	end
end
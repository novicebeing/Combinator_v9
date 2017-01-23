classdef inspect
	properties (Constant = true)
		menuitemName = 'inspect';
		menuitemText = 'Inspect';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			WorkspaceList = Parent.SpectraList;
			
			WorkspaceList.Inspect(SelectedItems.Variables);
		end
	end
end
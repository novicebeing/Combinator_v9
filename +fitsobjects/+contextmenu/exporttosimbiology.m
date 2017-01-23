classdef exporttosimbiology
	properties (Constant = true)
		menuitemName = 'exporttosimbiology';
		menuitemText = 'Export to SimBiology';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			Parent.FitsList.exportToSimBiology(SelectedItems.Variables);
		end
	end
end
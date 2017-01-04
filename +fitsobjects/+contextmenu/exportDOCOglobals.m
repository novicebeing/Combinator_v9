classdef exportDOCOglobals
	properties (Constant = true)
		menuitemName = 'exportDOCOglobals';
		menuitemText = 'Export DOCO Globals';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			Parent.FitsList.exportDOCOglobals(SelectedItems.Variables);
		end
	end
end
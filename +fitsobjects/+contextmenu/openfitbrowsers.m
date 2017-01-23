classdef openfitbrowsers
	properties (Constant = true)
		menuitemName = 'openfitbrowsers';
		menuitemText = 'Open Fit Browser(s)';
		menuitemMultiSelection = false;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			h = Parent.FitsList.openFitBrowsers(SelectedItems.Variables);
			Parent.TPComponent.addFigure(h);
		end
	end
end
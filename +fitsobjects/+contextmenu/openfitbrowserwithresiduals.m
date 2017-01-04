classdef openfitbrowserwithresiduals
	properties (Constant = true)
		menuitemName = 'openfitbrowserwithresiduals';
		menuitemText = 'Open Fit Browser with Residuals';
		menuitemMultiSelection = false;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			h = Parent.FitsList.openFitBrowsersWithResiduals(SelectedItems.Variables);
			Parent.TPComponent.addFigure(h);
		end
	end
end
classdef plotgroupedfitcoefficients
	properties (Constant = true)
		menuitemName = 'plotgroupedfitcoefficients';
		menuitemText = 'Plot Grouped Fit Coefficients';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			hs = Parent.FitsList.plotGroupedFitCoefficients(SelectedItems.Variables);
			for h = hs
			   Parent.TPComponent.addFigure(h);
			end
		end
	end
end
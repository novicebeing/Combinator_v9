classdef plotfitcoefficients
	properties (Constant = true)
		menuitemName = 'plotfitcoefficients';
		menuitemText = 'Plot Fit Coefficients';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			hwait = waitbar(0,'Plotting Fit Coefficients...', 'WindowStyle', 'modal');
			for i = 1:numel(SelectedItems.Variables)
				h = Parent.FitsList.plotFitCoefficients(SelectedItems.Variables(i));
				Parent.TPComponent.addFigure(h);
				waitbar(i/numel(SelectedItems.Variables),hwait);
			end
			close(hwait);
		end
	end
end
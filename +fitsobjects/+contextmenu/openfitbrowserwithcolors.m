classdef openfitbrowserwithcolors
	properties (Constant = true)
		menuitemName = 'openfitbrowserwithcolors';
		menuitemText = 'Open Fit Browser with Colors';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			hwait = waitbar(0,'Opening Plot Browsers...', 'WindowStyle', 'modal');
			for i = 1:numel(SelectedItems.Variables)
				h = Parent.FitsList.openfitbrowserwithcolors(SelectedItems.Variables(i));
				Parent.TPComponent.addFigure(h);
				waitbar(i/numel(SelectedItems.Variables),hwait);
			end
			close(hwait);
		end
	end
end
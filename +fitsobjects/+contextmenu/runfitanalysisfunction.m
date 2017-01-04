classdef runfitanalysisfunction
	properties (Constant = true)
		menuitemName = 'runfitanalysisfunction';
		menuitemText = 'Run Fit Analysis Function';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			Parent.FitsList.setInitialConcentrations(SelectedItems.Variables);
		end
	end
end
classdef setinitialconditions
	properties (Constant = true)
		menuitemName = 'setinitionalconditions';
		menuitemText = 'Set Initial Conditions';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			Parent.FitsList.setInitialConcentrations(SelectedItems.Variables);
		end
	end
end
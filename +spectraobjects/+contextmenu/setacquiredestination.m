classdef setacquiredestination
	properties (Constant = true)
		menuitemName = 'setacquiredestination';
		menuitemText = 'Set Acquire Destination';
		menuitemMultiSelection = false;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			WorkspaceList = Parent.SpectraList;

			itemNames = WorkspaceList.getItemNames(SelectedItems.Variables);
			Parent.acquiretab.spectraDestTextField.Text = itemNames{1};
		end
	end
end
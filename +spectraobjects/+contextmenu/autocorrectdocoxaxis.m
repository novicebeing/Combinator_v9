classdef autocorrectdocoxaxis
	properties (Constant = true)
		menuitemName = 'autocorrectdocoxaxis';
		menuitemText = 'Autocorrect DOCO X Axis';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			hwait = waitbar(0,'Correcting DOCO X Axis...', 'WindowStyle', 'modal');
			for i = 1:numel(SelectedItems.Variables)
				Parent.SpectraList.autocorrectdocoxaxis(SelectedItems.Variables(i));
				waitbar(i/numel(SelectedItems.Variables),hwait);
			end
			close(hwait);
		end
	end
end
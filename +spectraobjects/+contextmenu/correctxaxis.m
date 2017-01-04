classdef correctxaxis
	properties (Constant = true)
		menuitemName = 'correctxaxis';
		menuitemText = 'Correct X Axis';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			for i = 1:numel(SelectedItems.Variables)
				Parent.SpectraList.correctxaxis(SelectedItems.Variables(i));
			end
		end
	end
end
classdef usexaxisforallspectra
	properties (Constant = true)
		menuitemName = 'usexaxisforallspectra';
		menuitemText = 'Use X Axis for All Spectra';
		menuitemMultiSelection = false;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			Parent.SpectraList.usexaxisforallspectra(SelectedItems.Variables);
		end
	end
end
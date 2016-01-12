function y = areaNormVoigt(x,FWHMg,FWHMl)
% FWHMg: Gaussian FWHM
% FWHMl: lorentzian FWHM

    z = sqrt(log(2)).*complex(x,FWHMl./2)./(FWHMg./2);
    y = sqrt(log(2)).*cef(z,1000)./sqrt(pi)./(FWHMg./2);
	
end
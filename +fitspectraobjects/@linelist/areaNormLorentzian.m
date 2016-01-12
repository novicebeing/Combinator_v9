function y = areaNormLorentzian(x,FWHM)
% FWHM: Lorentzian FWHM

    y = FWHM./2./pi./(x.^2+FWHM.^2./4);
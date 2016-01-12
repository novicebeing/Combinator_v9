function y = areaNormGaussian(x,FWHM)
% FWHM: Gaussian FWHM

    y = exp(-x.^2./(FWHM./sqrt(2.*log(2))./2).^2./2)./(FWHM./sqrt(2.*log(2))./2)./sqrt(2.*pi);
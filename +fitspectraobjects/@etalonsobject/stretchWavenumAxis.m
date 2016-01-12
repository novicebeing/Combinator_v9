function wavenumOut = stretchWavenumAxis( obj,wavenumIn,vertPoly, fringeSize )
    
    stretchMatrix = repmat(reshape(linspace(-0.01,0.01,fringeSize(1)),[],1),1,fringeSize(2));

    wavenumShift = zeros(size(fringeSize));
    for i = 1:numel(vertPoly)
        wavenumShift = wavenumShift + vertPoly(i).*stretchMatrix.^(i-1);
    end

    wavenumOut = wavenumIn + reshape(vertPoly,size(wavenumIn,1),size(wavenumIn,2));
end


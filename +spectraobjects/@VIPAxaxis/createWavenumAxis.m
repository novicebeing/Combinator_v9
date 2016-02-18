function wavenumOut = createWavenumAxis( obj, centerWavenum, vertPoly, horizPoly, fringeSize )
    vertStretchMatrix = repmat(reshape(linspace(-0.5,0.5,fringeSize(1)),[],1),1,fringeSize(2));
    horizStretchMatrix = repmat(reshape(linspace(-0.5,0.5,fringeSize(2)),1,[]),fringeSize(1),1);

    wavenumShift = centerWavenum.*ones(fringeSize);
    for i = 1:numel(vertPoly)
        wavenumShift = wavenumShift + vertPoly(i).*vertStretchMatrix.^i;
    end
    for i = 1:numel(horizPoly)
        wavenumShift = wavenumShift + horizPoly(i).*horizStretchMatrix.^i;
    end

    wavenumOut = wavenumShift;
end
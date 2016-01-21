function correctedImages = imageColumnCorrect(images)
    % Get the crossing points
    a = diff(round(h.fringeX),1,1);
    a = a(~isnan(a));

end
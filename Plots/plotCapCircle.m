function [] = plotCapCircle(X,r)
    th = 0:pi/50:2*pi;
    xunit = r * cos(th) + X(1);
    yunit = r * sin(th) + X(2);
    plot(xunit, yunit, '-k');
end
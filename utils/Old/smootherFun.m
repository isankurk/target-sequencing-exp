function [smooVar] = smootherFun(var, AVwindow)
    for iter = 1: size(var, 1)-AVwindow
       tmp2 = zeros(1,size(var, 2));
       for AViter = iter : (iter-1)+AVwindow
           tmp2 = tmp2 +  var(AViter, :);
       end
       smooVar(iter, :) = tmp2./AVwindow;
    end
end
function [Phi, Synergies] = calibration_syn(glovedata)

    [l,s,g]=pca(glovedata);
    
    [~,~,latent] = pca(s);
    scaling = sqrt(latent);
    
    C    = -[l(:,1)'/scaling(1)*2.5; l(:,2)'/scaling(2)*2.5];
    p0   = -C * mean(glovedata)' + [2.5;2.5];
    
    Phi = -[l(:,1)'/scaling(1)*2.5; l(:,2)'/scaling(2)*2.5; l(:,3)'/scaling(3)*2.5; l(:,4)'/scaling(4)*2.5];

    for i = 1:size(l,2)
        Synergies(i,:) = -l(:,i)'/scaling(i)*2.5;
    end
end
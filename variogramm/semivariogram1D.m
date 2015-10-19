function gamma=semivariogram1D(h,c0,range,model,n)

H= h./range;

switch model
    case 'sph'
        gamma = c0*ones(size(H));
        gamma(H<1) = c0*( 3/2*H(H<1) - 1/2*H(H<1).^3);
    case 'exp'
        gamma = c0 *( 1 - exp(-3*H));
    case 'gaus'
        gamma = c0 *( 1 - exp(-3*H.^2));
end

% nugget effect
gamma(H~=0) = n + gamma(H~=0);
end

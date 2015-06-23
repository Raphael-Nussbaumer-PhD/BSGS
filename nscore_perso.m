%% NSCORE_PERSO
% This function is computing the Normal zscore transform of the input 
% vector the function return two fonction handle : one for the normal transform 
% and the other one for the back-transform. The function use the inputed 
% vector to create the normal transform. Then using interpolation, the 
% function handle are created.
%
% INPUT:
% * X           : Input vector
%
% OUTPUT:
% * NscoreT     : 
% * NscoreTinv  : 
%
% * *Author:* Raphael Nussbaumer (raphael.nussbaumer@unil.ch)
% * *Date:* 29.01.2015

function [NscoreT_fx,NscoreTinv_fx,Dist_NsTinv_fx]=nscore_perso(X,method,kernel)

% Compute the empirical cdf of the value
[f,x] = ecdf(X);

% Modify the step-like cdf to a linear one. tail extrapolation : eps to
% avoid 0 and 1 that norminv() doesn't like...
x = x(2:end); 
f = (f(1:end-1)+f(2:end))/2;
x = [kernel.y(1)-1 ; x(1)-f(1)*(x(2)-x(1))/((f(2)-f(1)));  x;  x(end)+(1-f(end))*((x(end)-x(end-1))/(f(end)-f(end-1))) ; kernel.y(end)+1];
f = [0+eps; 0+2*eps; f; 1-2*eps; 1-eps];

NscoreT_F = griddedInterpolant(x,f,method);
NscoreTinv_F = griddedInterpolant(f,x,method);

% Function of Normal Score Transform
NscoreT_fx    = @(y) norminv(NscoreT_F(y));
NscoreTinv_fx = @(y) NscoreTinv_F(normcdf(y));


% Kriging generate a mean and standard deviation in the std normal space.
% We want to transform this std normal distribution in the original space.
% The final distribution is on the grid of kernel.y. Therefore we compute
% the nscore transform of the kernel.y cell and compute the probability
% corresponding of the normal distribution generated by kriging (mu, sigma)
% ncty = NscoreT_fx([kernel.y(1)-kernel.dy/2 ; kernel.y+kernel.dy/2]);

% Dist_NsTinv_fx = @(mu,sigma) max(normcdf(ncty(2:end),mu,sigma)-normcdf(ncty(1:end-1),mu,sigma),0);
Dist_NsTinv_fx = @(mu,sigma) normpdf(NscoreT_fx(kernel.y),mu,sigma)/sum(normpdf(NscoreT_fx(kernel.y),mu,sigma));
return

mu= 0.4210
sigma=1.0044
hold on
plot(kernel.y,Dist_NsTinv_fx(mu,sigma))
plot(kernel.y,normpdf(NscoreT_fx(kernel.y),mu,sigma))
plot()

%% NOTE:
% Here are 6 Method to compute the transform and back transform
% A:  input vector
% B: Normal z-score of A
% b: point of a std normal distribution
% a: the back transform of b

hold on;

% Method 1: Inital script from Paolo
B=nscoretool(A);
nt=length(A);
zmin=min(b);
zmax=max(b);
ltail=2;
ltpar=2;
utail=1;
utpar=2;
a=backtrtool_pr(b,nt,A,B,zmin,zmax,ltail,ltpar,utail,utpar);

plot(A,B,'o')



% Method 2: mGstat toolbox
% w1,dmin : Extrapolation options for lower tail. w1=1 -> linear interpolation, w1>1 -> Gradual power interpolation
% w2,dmax : Extrapolation options for lower tail. w1=1 -> linear interpolation, w1<1 -> Gradual power interpolation
% DoPlot : plot
% d_nscore : normal score transform of input data
% o_nscore : normal socre object containing information needed to perform normal score backtransform.
[B,o_nscore]=nscore(A,w1,w2,dmin,dmax);
a=inscore(b,o_nscore);



% Method 3. ECDF
CDF_inv=norminv(ecdf(A));
B = CDF_inv(tiedrank(A));
a=quantile(A,normcdf(b));



% Method 4. TieRank
B = norminv( tiedrank(A)/(numel(A)+1));
a=quantile(A,normcdf(b));



% Method 5. http://ch.mathworks.com/help/stats/examples/nonparametric-estimates-of-cumulative-distribution-functions-and-their-inverses.html#zmw57dd0e1074
[Bi,xi] = ecdf(A);
n=numel(A);
xj = xi(2:end);
Bj = (Bi(1:end-1)+Bi(2:end))/2;
xj = [xj(1)-Bj(1)*(xj(2)-xj(1))/((Bj(2)-Bj(1)));  xj;  xj(n)+(1-Bj(n))*((xj(n)-xj(n-1))/(Bj(n)-Bj(n-1)))];
Bj = [0; Bj; 1];

F    = @(y) norminv(interp1(xj,Bj,y,'linear','extrap'));
Finv = @(u) normcdf(interp1(Bj,xj,u,'linear','extrap'));

B=norminv(F(A));
a=Finv(normcdf(b));




% Method 6. http://ch.mathworks.com/help/stats/examples/nonparametric-estimates-of-cumulative-distribution-functions-and-their-inverses.html#zmw57dd0e1147
Fy = ksdensity(A, A, 'function','cdf', 'width',.35);
Finv = @(u) interp1(Fy,y,u,'linear','extrap');

B=norminv(Fy);
a=Finv(normcdf(b));

end
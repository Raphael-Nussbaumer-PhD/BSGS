%% SCRIPT_BSS.m
% This file contain the script which can run the entire algorithm. It is
% where the main options/parameters are set and the main fonctions are
% lauch. Refere to the manual for more information of the Algorithm
%
% # DATA CREATION : Data are created either by reading mat file or
% generated with physical relationship. see description below
% # FIRST STEP : First Baysian Sequential Simulation on rho and Rho
% # SECOND STEP : Second Baysian Sequential Simulation on gG and K
% # FLOW : Measure the flow in the field.
% # PLOTTHEM : Graphical visualisation of data
%
%
% Variable naming convension:
% * rho     : Electrical resisitivity [\omega.m]
% * sigma   : Electrical conductivity = 1/rho [mS/m]
% * phi     : Porosity [-]
% * K       : Hydraulic conductivity [m/s]
%
% * *Author:* Raphael Nussbaumer (raphael.nussbaumer@unil.ch)
% * *Date:* 19.10.2015

 % Add folder and sub-folder to path
clc; % clear all;


%% DATA CREATION
% This section gather all possible way to create the data. |gen| struct
% store the parameter and |data_generation.m| compute everything

% Grid size
gen.xmax = 300; %total length in unit [m]
gen.ymax = 20; %total hight in unit [m]

% Scale define the subdivision of the grid (multigrid). At each scale, the
% grid size is $(2^gen.scale.x(i)+1) \times (2^gen.scale.y(i)+1)$ 
gen.sx = 10;
gen.sy = 7;

% Generation Method.
gen.method              = 'fromRho';% 'Normal-Random';% 'fromRho';   
% 'Paolo':              load paolo initial model and fit it to the created grid
% 'fromK':              genreate with FFTMA a field and log transform it with the parameter defined below 
% 'fromRho':            idem

% Generation parameter
gen.samp                = 1;                     % Method of sampling of K and g | 1: borehole, 2:random. For fromK or from Rho only
gen.samp_n              = 3;          % number of well or number of point
gen.covar.modele        = [4 100 10 0; 1 1 1 0]; % covariance structure
gen.covar.c             = [0.99; 0.01]; 
gen.mu                  = .40; % parameter of the first field. 
gen.std                 = .04;
gen.Rho.method          = 'R2'; % 'Paolo' (default for gen.method Paolo), 'noise', 'RESINV3D'

% Electrical inversion
gen.Rho.grid.nx           = 200;
gen.Rho.grid.ny           = 15; % log-spaced grid.
gen.Rho.elec.spacing      = 2; % in grid spacing unit.
gen.Rho.elec.config_max   = 6000; % number of configuration of electrode maximal 
gen.Rho.dmin.res_matrix   = 1; % resolution matrix: 1-'sensitivity' matrix, 2-true resolution matrix or 0-none
gen.Rho.dmin.tolerance    = 10;

% Other parameter
gen.plotit              = false;      % display graphic or not (you can still display later with |script_plot.m|)
gen.saveit              = true;       % save the generated file or not, this will be turn off if mehod Paolo or filename are selected
gen.name                = 'SimilarToPaolo2';
gen.seed                = 123456;

% Run the function
data_generation(gen);
%[fieldname, grid_gen, K_true, phi_true, sigma_true, K, sigma, Sigma, gen] = data_generation(gen);



%% BSGS
% Generation of the high resolution electrical conductivity (sSigma) from
% scarse electrical  data (sigma) and large scale inverted ERt (Sigma).
parm.gen            = gen;

parm.n_realisation  = 10;
% parm.scale          = numel(grid);
parm.likelihood     = 1;
parm.lik_weight     = 1;
parm.name           = 'SimilarPaolo_real10_lik1.0';
% 
% parm.fitvar         = 0;
% 
% parm.seed           = rand();
% parm.neigh          = true;
% parm.cstk           = false;
% parm.nscore         = true;
% parm.unit           = 'Electrical Conductivitiy';
% 
% % Saving
% parm.saveit         = true;
% parm.name           = gen.name;
% 
% % Ploting
% parm.plot.bsgs      = 0;
% parm.plot.ns        = 0;
% parm.plot.sb        = 0;
% parm.plot.kernel    = 0;
% parm.plot.fitvar    = 0;
% parm.plot.krig      = 0;
% 
% parm.k.range.min = [min(sigma.d(:))-2 min(Sigma.d(:))-2];
% parm.k.range.max = [max(sigma.d(:))+2 max(Sigma.d(:))+2];

BSGS(sigma,Sigma,sigma_true,grid_gen,parm);









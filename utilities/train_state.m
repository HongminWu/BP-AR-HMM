%@Hongmin Wu 11-08, 2016
%@Hongmin Wu 05-23, 2017
function train_state (nState, trialID, TrainedModelPath)
tic;
global ROOT_PATH DATA_PATH
global METHOD STATE DATASET PLOT_ON
global TRAIN_TIMES  INERATIVE_TIMES  AUTOREGRESSIVE_ORDER         %parameters

%% Load/preprocess the data
cellData    = {};  
R_State     = {};
data_struct = struct;
[cellData, R_State, FOLDERS_NAME]= load_data(strcat(DATA_PATH, '/', DATASET), trialID);   
cd (ROOT_PATH);
[cellData, meanSigma] = data_preprocessing(cellData);
for i=1: length(cellData)
    data_struct(i).obs         = cellData{i}(:, R_State{i}(nState): R_State{i}(nState + 1));
    data_struct(i).true_labels = ones(1, length(data_struct(i).obs)); % initial 
end

% for i=1: length(cellData) 
%     data_struct(i).true_labels = ones(1, length(cellData{i})); % initial 
%     for j = 1:(length(R_State{i}) - 1)
%         data_struct(i).true_labels(:, R_State{i}(j): R_State{i}(j + 1)) = j * ones(1, R_State{i}(j + 1) - R_State{i}(j) + 1);
%     end
%     s = strcat( 'savedStats/','Parse',num2str(i),'.txt');
%     data_struct(i).savepath = s;
% end
%----display----
figure('Name', 'Data Preprocessing: Original -> time alignment -> mean = 0, variance = 1'); 
for n = 1:length(data_struct)
    subplot(length(data_struct),2, 2*n -1); plot(cellData{n}');
    title(FOLDERS_NAME{n});
    subplot(length(data_struct),2, 2*n); plot(data_struct(n).obs');
    title(char(STATE(nState)));
end    
drawnow;

%% Parameters setting
[dims,len] = size(data_struct(1).obs);
d = dims;  % dimension of each time series
r = AUTOREGRESSIVE_ORDER;  % autoregressive order for each time series
m = d*r;
K = inv(diag([1*ones(1,m)]));  % matrix normal hyperparameter (affects covariance of matrix)
M = zeros(d,m); % matrix normal hyperparameter (mean matrix)
clear model settings
nu = d+2;  % default d+2,  inverse Wishart degrees of freedom, If oversegmenting, try d+6

%Don't change these
obsModelType = 'AR';%AR
priorType = 'MNIW';

%Set hyperprior settings for Dirichlet and IBP
%Don't ever changes these
% Sticky HDP-HMM hyperparameters settings:

% Gamma(1,0.01)prior on the (alpha0 + kappa0), alpha0_p_kappa0 = a_alpha / b_alpha;
% affects \pi_z
a_alpha = 1;     %default: 1
b_alpha = 1;  %default: 1
var_alpha = 1;   %default: 1

a_kappa = 100;   %default: 100
b_kappa = 1;     %default: 1
var_kappa = 100; %default: 100

% Gamma(1,0.01)prior on the concertration parapeters :gamma0 = a_gamma / b_gamma;    
% G0 concentration parameter
a_gamma = 1;   %default: 0.1
b_gamma = 1;     %default: 1

% The 'getModel' function takes the settings above and creates the
% necessary 'model' structure.
getModel

% Setting for inference:
settings.Ks         = 1;  % legacy parameter setting from previous code.  Do not change.
settings.Niter      = INERATIVE_TIMES;  % Number of iterations of the MCMC sampler. Some data may need much much more than this.  
settings.storeEvery = 500;  % default: 100 How often to store MCMC statistics
settings.saveEvery  = 500;  %default:100 How often to save (to disk) structure containing MCMC sample statistics
settings.ploton     = PLOT_ON;  % Whether or not to plot the mode sequences and feature matrix while running sampler
settings.plotEvery  = 20;  %default:20  How frequently plots are displayed
settings.plotpause  = 0;
settings.saveDir    = strcat(ROOT_PATH,'/savedStats'); % Directory to which you want statistics stored.  This directory will be created if it does not already exist:
settings.formZInit  = 1; % whether or not the sampler should be initialized with specified mode sequence.  (Experimentally, this seems to work well.)

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Run IBP Inference %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Number of initializations/chains of the MCMC sampler:
settings.nTrial       = TRAIN_TIMES;
settings.STATE        = STATE(nState);
loglikes              = zeros(1, TRAIN_TIMES);
BPARHMM_data_struct   = {};
BPARHMM_F             = {};
BPARHMM_dist_struct   = {};
BPARHMM_theta         = {};
for trial= 1 : TRAIN_TIMES
    z_max = 0;
    for seq = 1: length(data_struct)
        % Form initial mode sequences to simply block partition each
        % time series into 'Ninit' features.  Time series are given
        % non-overlapping feature labels:
        T = size(data_struct(seq).obs,2);
        Ninit = 2; %2
        init_blocksize = floor(T/Ninit);
        z_init = [];
        for i=1:Ninit
            z_init = [z_init i*ones(1,init_blocksize)];
        end
        z_init(Ninit*init_blocksize+1:T) = Ninit;
        data_struct(seq).z_init = z_init + z_max;
        z_max = max(data_struct(seq).z_init);
    end
    % Call to main function:
    % staeSeq: hidden state sequence for each demonstration
    %Ustats:
    %   Ustats.card:d
    %   Ustats.XX:
    %   Ustats.YX:
    %   Ustats.YY:
    %   Ustats.sumX:
    %   Ustats.symY:
    % F: Binary(0/1) feature matrices
    %theta: 
    %loglikes:
    [data_struct stateSeq Ustats F dist_struct theta loglikes(trial)] = IBPHMMinference(data_struct,model,settings,trial);
    BPARHMM_data_struct   = [BPARHMM_data_struct, {data_struct}];
    BPARHMM_F             = [BPARHMM_F, {F}];
    BPARHMM_dist_struct   = [BPARHMM_dist_struct, {dist_struct}];
    BPARHMM_theta         = [BPARHMM_theta, {theta}];
end     

%% Postprocess
%1.Keep the trial with largest log likelihood
[~, largest_n]        = max(loglikes);
BPARHMM_data_struct   = BPARHMM_data_struct{largest_n};
BPARHMM_F             = BPARHMM_F{largest_n};
BPARHMM_dist_struct   = BPARHMM_dist_struct{largest_n};
BPARHMM_theta         = BPARHMM_theta{largest_n};
cd (TrainedModelPath);
TrainedModelFile = strcat(METHOD, '_', num2str(TRAIN_TIMES),'_',num2str(INERATIVE_TIMES), '_',char(STATE(nState)),'.mat');
save (TrainedModelFile, 'FOLDERS_NAME','BPARHMM_data_struct','BPARHMM_F', 'BPARHMM_dist_struct', 'BPARHMM_theta');

%% for plotting
%{
%2. Find the max skill num for color scaling at the trail with the largest log likelihood
nplots = size(stateSeq,2);
max_skill_num = 1;
for i=1:nplots
    for j=1:size(stateSeq(i).z,2)
        curr = stateSeq(i).z(j);
        if curr > max_skill_num 
            max_skill_num = curr;
        end
    end
    plot(stateSeq(i).z');
    hold on;
end

figure
for i=1:nplots
    %Plot the segments and the corresponding traj below it
    subplot(2,nplots,i)
    imagesc(stateSeq(i).z,[1, max_skill_num])
    subplot(2,nplots,i+nplots)
    plot(cellData{i}')

    npts = length(stateSeq(i).z);
    xlim([0,npts]);

    %Calc the switchpoints and make lines on the traj graph
    switchpts = [];
    last = stateSeq(i).z(1);
    for j=1 : npts   % In order to improve the persistent state
        curr = stateSeq(i).z(j);
        if(curr ~= last)
            last = curr;
            switchpts = [switchpts, j];
        end
    end
    gridxy(switchpts,'Linestyle','--')

    cd ('F:\Matlab\Emily_Fox\HIRO_SA_DATA\R_State_NEW');
    fid = fopen(char(strcat(folders_name{i},'.dat')), 'wt');
    fprintf(fid,'%g\n',switchpts);
    fclose(fid);

%             fname = data_struct(i).savepath; %for each demonatration
%             f = fopen(fname,'w+');
%             p = int8(stateSeq(i).z);
%             for k=1:size(p,2)
%                 fprintf(f,'%i\n',p(k));
%             end
%             fclose(f); 
%end
%}
%%
toc;
disp(strcat('....................Finish training state: ',char(STATE(nState)),'....................'));
end
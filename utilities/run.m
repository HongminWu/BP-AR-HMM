%@Homls 2016-11-02
%before using, cd ../BPARHMMtoolbox/logs

clear ; clc  ;close all
tic;
%% Load/preprocess the data
    ndemos =2;
    cellData = {};  
    data_struct = struct;
    %'R_CartPos' 
    %'R_CartPos_Corrected'
    %'R_Torques' 
    %'R_Angles'
    dataType = {'R_CartPos_Corrected','R_Torques'};  
  %  while length(cellData) ~= ndemos
        %REAL_HIRO_ONE_SA_SUCCESS 
        %SIM_HIRO_ONE_SA_SUCCESS 
        %SIM_HIRO_ONE_SA_FAILURE
        %SIM_HIRO_ONE_SA_ERROR_CHARAC_Prob
       [cellData, folders_name]= extract_file('SIM_HIRO_ONE_SA_ERROR_CHARAC_Prob', dataType, ndemos);   
  %  end

    nbData = [];
    origData = {};
    alignData = {};
    for i=1: length(cellData)       %transport the data [dim, length]
        cellData{i} = cellData{i}';
        origData{i} = cellData{i};
        nbData = [nbData, size(cellData{i}, 2)]; % so as to find out the largest length    
    end

    for n=1:length(cellData)
        data_struct(n).obs = cellData{n};
        %data_struct(n).obs = spline(1:size(cellData{n},2), cellData{n}, linspace(1,size(cellData{n},2), max(nbData))); %Resampling
        alignData{n} = data_struct(n).obs;
        data_struct(n).true_labels = ones(1, max(nbData));
        s = strcat( 'savedStats/','Parse',num2str(n),'.txt');
        data_struct(n).savepath = s;
    end

%--------Preprocess data  mean = 0; variance = 1-----------------
%Smooth trajectory
    radius = 20;
     for i=1:length(data_struct)
         [dims,len] = size(data_struct(i).obs);
         smoothed = zeros(dims,len);
         for j=1:dims
             for k=1:len
                 low = max(1,k-radius);
                 high = min(len,k+radius);
                 smoothed(j,k) = mean(data_struct(i).obs(j,low:high));
             end
         end
         data_struct(i).obs = smoothed;
     end

    Ybig1 = [];
    for ii=1:length(data_struct)
        Ybig1 = [Ybig1 data_struct(ii).obs];
    end
    %Adjust each dim to mean 0
    mY = mean((Ybig1'));
    for i=1:length(data_struct)
        for j=1:length(mY)
            data_struct(i).obs(j,:) = data_struct(i).obs(j,:) - mY(j);
        end
    end
    Ybig2 = [];
    for ii=1:length(data_struct)
        Ybig2 = [Ybig2 data_struct(ii).obs];
    end
    %Renormalize so for each feature, the variance of the first diff is 1.0
    vY = var(diff(Ybig2'));
    for i=1:length(data_struct)
        for j=1:length(vY)
            data_struct(i).obs(j,:) = data_struct(i).obs(j,:) ./ sqrt(vY(j));
        end
    end

    Ybig3 = [];
    for ii=1:length(data_struct)
        Ybig3 = [Ybig3 data_struct(ii).obs];
    end
    meanSigma = 5.0 * cov(diff(Ybig3'));  %If bad segmentation, try values between 0.75 and 5.0
    for i=1:size(meanSigma,1)
        for j=1:size(meanSigma,2)
            if(i~=j) 
                meanSigma(i,j) = 0;
            end
        end
    end
    sig0 = meanSigma;  %Only needed for MNIW-N prior
   
%----display----
    figure('Name', 'Data Preprocessing: Original -> time alignment -> mean = 0, variance = 1'); 
    for n = 1:length(data_struct)
       %  subplot(length(data_struct)/2,2, n); plot(origTraj{n}'); grid on;
        subplot(length(data_struct),3, 3*n -2); plot(origData{n}');
        subplot(length(data_struct),3, 3*n -1); plot(alignData{n}');
        subplot(length(data_struct),3, 3*n); plot(data_struct(n).obs');
        title(folders_name{n});
    end    
    drawnow;
    
%% Parameters setting
    [dims,len] = size(data_struct(1).obs);
    d = dims;  % dimension of each time series
    r = 1;  % autoregressive order for each time series
    m = d*r;
    K = inv(diag([1*ones(1,m)]));  % matrix normal hyperparameter (affects covariance of matrix)
    M = zeros(d,m); % matrix normal hyperparameter (mean matrix)
    clear model settings
    nu = d+2;  % default d+2,  inverse Wishart degrees of freedom, If oversegmenting, try d+6
 
    %Don't change these
    obsModelType = 'AR';
    priorType = 'MNIW';

    %Set hyperprior settings for Dirichlet and IBP
    %Don't ever changes these
    a_alpha = 1;
    b_alpha = 1;
    var_alpha = 1;
    
    a_kappa = 100;
    b_kappa = 1;
    var_kappa = 100;
    
    a_gamma = 0.1;
    b_gamma = 1;

    % The 'getModel' function takes the settings above and creates the
    % necessary 'model' structure.
    getModel

    % Setting for inference:
    settings.Ks = 1;  % legacy parameter setting from previous code.  Do not change.
    settings.Niter = 200;  % Number of iterations of the MCMC sampler. Some data may need much much more than this.  
    settings.storeEvery = 100;  % default: 100 How often to store MCMC statistics
    settings.saveEvery = 100;  %default:100 How often to save (to disk) structure containing MCMC sample statistics
    settings.ploton = 1;  % Whether or not to plot the mode sequences and feature matrix while running sampler
    settings.plotEvery = 1;  %default:20  How frequently plots are displayed
    settings.plotpause = 0;
    settings.saveDir = '../savedStats/BPARHMM/'; % Directory to which you want statistics stored.  This directory will be created if it does not already exist:
    settings.formZInit = 1; % whether or not the sampler should be initialized with specified mode sequence.  (Experimentally, this seems to work well.)

    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% Run IBP Inference %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Number of initializations/chains of the MCMC sampler:
    trial_vec = [1:1];
    loglikes = zeros(size(trial_vec));
    stateSequence = {};
    for t=trial_vec;
        z_max = 0;
        for seq = 1:length(data_struct)
            % Form initial mode sequences to simply block partition each
            % time series into 'Ninit' features.  Time series are given
            % non-overlapping feature labels:
            T = size(data_struct(seq).obs,2);
            Ninit = 4; %2
            init_blocksize = floor(T/Ninit);
            z_init = [];
            for i=1:Ninit
                z_init = [z_init i*ones(1,init_blocksize)];
            end
            z_init(Ninit*init_blocksize+1:T) = Ninit;
            data_struct(seq).z_init = z_init + z_max;

            z_max = max(data_struct(seq).z_init);
        end
        settings.trial = t;
        % Call to main function:
        % staeSeq: state sequence for each demonstration
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
        [stateSeq Ustats F theta loglikes(t)] = IBPHMMinference(data_struct,model,settings);
        stateSequence{t} = stateSeq;
    end
    
%% Postprocess
%1.Keep the trial with largest log likelihood
    largest = -Inf;
    largest_n = 1;
    for t=trial_vec
        if(loglikes(t) > largest)
            largest = loglikes(t);
            largest_n = t;
        end
    end   
    stateSeq = stateSequence{largest_n};
    largest_n
    loglikes(largest_n);

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
    end
    
   % close all;  
    figure
    for i=1:nplots
        %Plot the segments and the corresponding traj below it
        subplot(2,nplots,i)
        imagesc(stateSeq(i).z,[1, max_skill_num])
        subplot(2,nplots,i+nplots)
        plot(alignData{i}')

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

        fname = data_struct(i).savepath; %for each demonatration
        f = fopen(fname,'w+');
        p = int8(stateSeq(i).z);
        for k=1:size(p,2)
            fprintf(f,'%i\n',p(k));
        end
        fclose(f);           
    end
    toc;
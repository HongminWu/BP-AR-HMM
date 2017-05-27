%*********************************************************************
%  *
%  * Software License Agreement (BSD License)
%  *
%  *  Copyright (c) 2012, Scott Niekum
%  *  Code adapted from code from Emily B. Fox at:
%  *    http://www.stat.washington.edu/~ebfox/software.html
%  *  All rights reserved.
%  *
%  *  Redistribution and use in source and binary forms, with or without
%  *  modification, are permitted provided that the following conditions
%  *  are met:
%  *
%  *   * Redistributions of source code must retain the above copyright
%  *     notice, this list of conditions and the following disclaimer.
%  *   * Redistributions in binary form must reproduce the above
%  *     copyright notice, this list of conditions and the following
%  *     disclaimer in the documentation and/or other materials provided
%  *     with the distribution.
%  *   * Neither the name of the Willow Garage nor the names of its
%  *     contributors may be used to endorse or promote products derived
%  *     from this software without specific prior written permission.
%  *
%  *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%  *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%  *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
%  *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
%  *  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
%  *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
%  *  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%  *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
%  *  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
%  *  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
%  *  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%  *  POSSIBILITY OF SUCH DAMAGE.
%  *
%  *********************************************************************/

clear
clc
close all
skill_num_offset = 0

for whicharm = 0:1  %Specific to pr2-lfd project. Set to 0:0 otherwise or get rid of.

    d = 8;  % dimension of each time series
    r = 1;  % autoregressive order for each time series
    m = d*r;
    %numTraj = 1;  %Number of trajectories to generate
    K = inv(diag([1*ones(1,m)]));  % matrix normal hyperparameter (affects covariance of matrix)
    M = zeros(d,m); % matrix normal hyperparameter (mean matrix)

    %Load the data
    data_struct = loadRobotLogs(whicharm)

    %figure
    %subplot(1,2,1)
    %plot(data_struct(1).obs')
    %subplot(1,2,2)
    %plot(data_struct(2).obs')

    %%
    clear model settings
    nu = d+2;  %If oversegmenting, try d+6

    ntraj = length(data_struct)
    origTraj = {}
    for i=1:ntraj
        origTraj{i} = data_struct(i).obs
    end

    %Preprocess data
    
    %Smooth trajextory
    radius = 10
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
    mY = mean((Ybig1'))
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
    vY = var(diff(Ybig2'))
    for i=1:length(data_struct)
        for j=1:length(vY)
            data_struct(i).obs(j,:) = data_struct(i).obs(j,:) ./ sqrt(vY(j));
        end
    end

    Ybig3 = [];
    for ii=1:length(data_struct)
        Ybig3 = [Ybig3 data_struct(ii).obs];
    end


    meanSigma = 2.0*cov(diff(Ybig3'))  %If bad segmentation, try values between 0.75 and 5.0
    for i=1:size(meanSigma,1)
        for j=1:size(meanSigma,2)
            if(i~=j) 
                meanSigma(i,j) = 0;
            end
        end
    end
    sig0 = meanSigma;  %Only needed for MNIW-N prior

    figure
    %subplot(1,4,1)
    %plot(origTraj{2}')
    %subplot(1,4,1)
    %plot(data_struct(1).obs')
    %subplot(1,4,2)
    %plot(data_struct(2).obs')
    %subplot(1,4,3)
    %plot(origTraj{1}')
    %subplot(1,4,4)
    %plot(origTraj{2}')

    %Don't change these
    obsModelType = 'AR';
    priorType = 'MNIW';

    % Set hyperprior settings for Dirichlet and IBP
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
    settings.Niter = 500;  % Number of iterations of the MCMC sampler. Some data may need much much more than this.  
    settings.storeEvery = 100;  % How often to store MCMC statistics
    settings.saveEvery = 100;  % How often to save (to disk) structure containing MCMC sample statistics
    settings.ploton = 1;  % Whether or not to plot the mode sequences and feature matrix while running sampler
    settings.plotEvery = 10;  % How frequently plots are displayed
    settings.plotpause = 0;

    %%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% Run IBP Inference %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Directory to which you want statistics stored.  This directory will be
    % created if it does not already exist:
    settings.saveDir = '../savedStats/BPARHMM/'; 

    settings.formZInit = 1; % whether or not the sampler should be initialized with specified mode sequence.  (Experimentally, this seems to work well.)

    % Number of initializations/chains of the MCMC sampler:
    trial_vec = [1:10];

    loglikes = zeros(size(trial_vec))
    seqs = {}

    for t=trial_vec;

        z_max = 0;
        for seq = 1:length(data_struct)

            % Form initial mode sequences to simply block partition each
            % time series into 'Ninit' features.  Time series are given
            % non-overlapping feature labels:
            T = size(data_struct(seq).obs,2);
            Ninit = 2;
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
        [stateSeq Ustats F theta loglikes(t)] = IBPHMMinference(data_struct,model,settings);
        seqs{t} = stateSeq;

    end

    %Keep the trial with largest log likelihood
    largest = -Inf;
    largest_n = 1;
    for t=trial_vec
        if(loglikes(t) > largest)
            largest = loglikes(t);
            largest_n = t;
        end
    end
    stateSeq = seqs{largest_n};
    largest_n
    loglikes(largest_n);

    nplots = size(stateSeq,2);

    %Find the max skill num for color scaling
    max_skill_num = 1;
    for i=1:nplots
        for j=1:size(stateSeq(i).z,2)
            curr = stateSeq(i).z(j);
            if curr > max_skill_num 
                max_skill_num = curr;
            end
        end
    end
    
    figure
    for i=1:nplots
        %Plot the segments and the corresponding traj below it
        subplot(2,nplots,i)
        imagesc(stateSeq(i).z,[1,max_skill_num])
        subplot(2,nplots,i+nplots)
        plot(origTraj{i}')

        npts = length(stateSeq(i).z);
        xlim([0,npts]);

        %Calc the switchpoints and make lines on the traj graph
        switchpts = [];
        last = stateSeq(i).z(1);
        for j=1:npts
            curr = stateSeq(i).z(j);
            if(curr ~= last)
                last = curr;
                switchpts = [switchpts, j];
            end
        end
        gridxy(switchpts,'Linestyle','--')

        fname = data_struct(i).savepath;
        f = fopen(fname,'w+');
        p = int8(stateSeq(i).z + skill_num_offset);
        for i=1:size(p,2)
            fprintf(f,'%i\n',p(i));
        end
        fclose(f);
    end
    
    %If this is the right arm, make sure to remember the max skill num
    %so that we can add that number to skill nums for the left arm
    %so that we don't get aliasing of numbers between the arms
    if(whicharm==0)
       skill_num_offset = max_skill_num; 
    end
end
%@Hongmin Wu
%Friday, April 7, 2017
% loading data
% Get Observation data from testing trials
%INPUT: trialID
%OUTPUT: data R_state

function [data, R_State, foldname] = load_one_trial(trialID, dataset_path)
global SIGNAL_TYPE WRENCH_DERIVATIVE

folder_name = dir([strcat(dataset_path,'/') '*' trialID]);
foldname    = folder_name.name;
cd(strcat(dataset_path,'/',foldname))
data = [];
raw_data = [];
for j = 1: length(SIGNAL_TYPE)
    file = dir([char(SIGNAL_TYPE(j)) '.dat*']);
    filename = strcat('/',foldname,'/',file(1).name);
    raw_data = load(filename);
    d = raw_data(:,2:end);  %delete the time column   
     if strcmp(SIGNAL_TYPE(j), 'R_Torques') & WRENCH_DERIVATIVE             
         d = [d,[d(1,:);diff(d)]];
     end
    data = [data, d];
end

data = data'; %[dim * len]

    R_State = [];
    file = dir([char('R_State') '.dat*']);
    filename = strcat('/',foldname,'/',file(1).name);
    tState = load(filename);
    for in = 1:length(tState)
        idex= find(raw_data(:,1) == tState(in));
        R_State = [R_State,idex];
    end
    R_State = [R_State,length(data)];
    %}

    %{
    %load new R_State values which detect by BP-AR-HMM method.
    cd ('F:\Matlab\Emily_Fox\HDPHMM_HDPSLDS_toolbox\HDPHMM_HDPSLDS\logs\R_State_NEW');
    files = dir('*.dat');
    for nfile = 1:length(files)
        if strcmp(files(nfile).name,strcat(foldname,'.dat'));
            R_State = load(files(nfile).name);
            R_State = [R_State',length(data)];
            break;
        end
    end
    %}
end
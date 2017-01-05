%*********************************************************************
%  @Homls 2016-11-02
%  *********************************************************************/

function [totData] = loadLogs()
    cellData = {};
    totData = struct;
    
    PATH_LOGS = './logs/';
    TXT_LOGS = dir([PATH_LOGS '*_data']); 
    if size(TXT_LOGS,1) == 0
    disp('can not load the data, maybe the wrong path');
    return;
    end
    for i = 1 : size(TXT_LOGS, 1);
         disp(['Load RobotLogs Files : ' TXT_LOGS(i).name]);
         d = load(TXT_LOGS(i).name);
         cellData = [cellData; {d}];
    end
  
    for i=1:size(cellData)
        [n,dims] = size(cellData{i}); 
        labels = ones(1,n);
        totData(i).obs = cellData{i}';
        totData(i).true_labels = labels;
    end
end



  
    
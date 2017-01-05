%*********************************************************************
%  *
%  * Software License Agreement (BSD License)
%  *
%  *  Copyright (c) 2012, Scott Niekum
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

function [totData] = loadRobotLogs()
    cellData = {};
    totData = struct;
    savelist = {};
    numlist = []
    
   basename = 'logs';
    cd(basename);
    folders = dir;
    
    for i=1:size(folders) % a folder per demonsration
        if(folders(i).isdir == 1 && ~strcmp(folders(i).name,'..') && ~strcmp(folders(i).name,'.'))
            %foldname = strcat(basename,'/',folders(i).name);
            %cd(foldname); 
            cd(folders(i).name);
            matlist = dir('Demonstration*');
           
            for j=1:size(matlist)
               % matname = strcat(foldname,'/',matlist(j).name);
                s_ind = regexp(matlist(j).name, '[0-9]') %find out the digital number 0~9
                s_num = matlist(j).name(s_ind)
                
                   % d = load(matname);
                   d = load(matlist(j).name);
                    cellData = [cellData; {d}];
                    %s = strcat(foldname,'/Parse',s_num,'.txt');
                    s = strcat('/Parse',s_num,'.txt');
                    savelist = [savelist, {s}];
            end
            cd ..
        end
    end
    
    cd ..
    
    for i=1:size(cellData)
        [n,dims] = size(cellData{i}); 
        labels = ones(1,n);
        totData(i).obs = cellData{i}';
        totData(i).true_labels = labels;
        totData(i).savepath = savelist{i};
    end
end


  
    
function [totData] = genLightChainData(numTraj)

cellData = {};
cellLabels = {};
totData = struct;

curr = [];
step = 0.25;

for rep = 1:numTraj
   
   data = [];
   labels = [];
    
   %Choose light locations
   %targ = [1 1 ; 4 9 ; 9 2];
   
%    targ(1,1) = rand * 10;
%    targ(1,2) = rand * 10;
%    targ(2,1) = rand * 10;
%    targ(2,2) = rand * 10;
%    targ(3,1) = rand * 10;
%    targ(3,2) = rand * 10;

   targ(1,1) = 0; %+ rand;
   targ(1,2) = 5; %+ rand;
   targ(2,1) = 4; %+ rand;
   targ(2,2) = 9; %+ rand;
   targ(3,1) = 9; %+ rand;
   targ(3,2) = 2; %+ rand;
   
   %Choose starting location
   %curr(1,1) = 10 * rand; 
   %curr(1,2) = 10 * rand; 
   
   curr(1,1) = 5;
   curr(1,2) = 5;
   
   %order = randperm(3);
   order = [1 2 3];
   
   for ind=1:3 
       t = order(ind);
       %curr(1,1) = 10 * rand; 
       %curr(1,2) = 10 * rand;
       
       while(norm(curr(1,:)-targ(t,:)) > 1)
          diff = targ(t,:) - curr(1,:);
          if(abs(diff(1,1)) >= step) 
              xdiff = sign(diff(1,1)) * step;
          else
              xdiff = 0;
          end
          if(abs(diff(1,2)) >= step) 
              ydiff = sign(diff(1,2)) * step;
          else
              ydiff = 0;
          end
          
          %Determine the action
          if(xdiff > 0)
            if(ydiff > 0)
                act = 1;
            elseif(ydiff < 0)
                act = 2;
            else
                act = 3;
            end
          elseif(xdiff < 0)
            if(ydiff > 0)
                act = 4;
            elseif(ydiff < 0)
                act = 5;
            else
                act = 6;
            end  
          else
              if(ydiff > 0)
                act = 7;
            elseif(ydiff < 0)
                act = 8;
            else
                act = 9;
            end  
          end

          agentSpace(1,1) = curr(1,1) - targ(1,1);
          agentSpace(2,1) = curr(1,2) - targ(1,2);
          %agentSpace(3,1) = curr(1,1) - targ(2,1);
          %agentSpace(4,1) = curr(1,2) - targ(2,2);
          %agentSpace(5,1) = curr(1,1) - targ(3,1);
          %agentSpace(6,1) = curr(1,2) - targ(3,2);
          %agentSpace(3,1) = act;
          
          data = [data agentSpace];
          %data = [data [curr]'];
          labels = [labels t];
          curr = curr + [xdiff ydiff];
       end
   end
   %cellData = [cellData ; {data}];
   %cellLabels = [cellLabels ; {labels}];
   totData(rep).obs = data;
   totData(rep).true_labels = labels;
end

%Calc duration stats
% durs = [];
% i = 1;
% while(i<=T)
%    currLabel = labels(i);
%    currDur = 1;
%    i = i+1;
%    
%    while(i<=T)
%       nextLabel = labels(i);
%       
%       if(nextLabel == currLabel)
%          i = i+1;
%          currDur = currDur + 1;
%       else    
%           break;
%       end
%    end
%    
%    durs = [durs currDur];   
% end
% mean(durs)
% var(durs)   

end

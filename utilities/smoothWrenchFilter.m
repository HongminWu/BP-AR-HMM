%@Homls 2016-11-07
%using the second order equation to filter the wrench data
%input: [n, dim] = size(wrenchVec)
function [wrenchVecF] = smoothWrenchFilter(wrenchVec)
    [n, dim] = size(wrenchVec);
    if n < 3  
        return;  end
    wrenchVecF(1:2,:) = wrenchVec(1:2,:);
    cur_data_f_ = [];
    while (size(wrenchVec, 1) >= 3)
         temp = 0.018299*wrenchVec(3, :) + 0.036598*wrenchVec(2, :) + 0.018299*wrenchVec(1, :)  +  ...
                        1.58255*wrenchVecF(2, :) - 0.65574*wrenchVecF(1, : );
         wrenchVecF = cat(1, wrenchVecF, temp); % add new row to the end 
         wrenchVec(1,:) = []; % delete the fist row
         wrenchVecF(1,:) = [];
         cur_data_f_ = cat(1, cur_data_f_, wrenchVecF(1,:));
    end
    wrenchVecF = cat(1, cur_data_f_, wrenchVecF);
end
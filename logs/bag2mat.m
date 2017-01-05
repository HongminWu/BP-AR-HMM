function [data, fields, topics] = bag2mat(inp, map_topics, array_map, do_save)
% Convert ROS Bag files into MAT files
% 
% This is really more of a wrapper for extractSingleFile. It does a little
% bit of checking to make sure we're all good, and will do whole
% directories at a time.
% 
% USAGE:
%   bag2mat('<folder_with_bag_files>')
%   bag2mat('<some_file.bag>')
%   
% INPUTS:
% 
%   inp: string with folder or file path
% 
%   array_map = {
%     {                                   <-- topic1
%       'eval_string_for_message_field1', <-- row 1
%       'eval_string_for_message_field2', <-- row 2
%       'eval_string_for_message_field3'  <-- row 3 ...
%     },
%     {                                   <-- topic2
%       'eval_string_for_message_field1',
%       'eval_string_for_message_field2',
%       'eval_string_for_message_field3'
%     }
%   }
%   -- array_map may also be empty if you're too much of a pleb to figure out
%      how to do the above
%   -- the eval string must yield a scalar number
% 
% 
% Copyright (c) 2015 Robert Cofield
% All rights reserved.
% 

if isdir(inp) % directory with bag files
  flst = dir(inp);
  for kf = 1:length(flst)
    if flst(k).isdir % make sure it's a file
      continue
    end
    [~,name,ext] = fileparts(fullfile(inp,flst(k).name));
    if ~strcmp(ext, '.bag') % make sure it's a bag file
      % cool, since we're doing a whole directory
      continue
    end
    bagf = fullfile(inp, flst(k).name);
    matf = fullfile(inp, [name '.mat']);
    [data, fields, topics] = extractSingleFile(bagf, matf, map_topics, array_map, do_save);
  end
else % single bag file
  [pathstr,name,ext] = fileparts(inp);
  if ~strcmp(ext, '.bag') % make sure it's a bag file
    warning('Is not a bag file: %s\n', inp)
    return
  end
  matf = fullfile(pathstr, [name '.mat']);
  [data, fields, topics] = extractSingleFile(inp, matf, map_topics, array_map, do_save);
end
end


function [data, fields, topics] = extractSingleFile(bagf, matf, map_topics, array_map, do_save)
% here's the function that does the magic
%

fprintf('Extracting:\n\tBag: %s\n\tMAT: %s\n',bagf,matf)
fprintf('\tOpening bag file ...')
bag = ros.Bag.load(bagf);
fprintf(' done.\n')

data = struct();
fields = cell(1,length(bag.topics)-1); % not going to put rosout messages in there.
topics = fields;
% turn the topic namespaces into nested structs
fprintf('\tReading and copying ...')
kk = 1; % index within the list of topics we actually want
for k = 1:length(bag.topics)
  if strcmp(bag.topics{k},'/rosout')
    continue
  end
  fields{kk} = bag.topics{k};
  topics{kk} = bag.topics{k};
  fields{kk}(find(fields{kk}=='/')) = '.';
  if fields{kk}(1) ~= '.'
    fields{kk} = [fields{kk} '.'];
  end
  fields{kk} = ['data' fields{kk}];  

  % decide how to empty the data. (dump directly or map to a 2D matrix from
  % the ros msg struct)
  msgs = bag.readAll({topics{kk}});
  if isempty(array_map) % dump in as is since we don't have a mapping
    eval([fields{kk},'= msgs;'])
  else % we might have a mapping
    idx = find(not(cellfun('isempty', strfind(map_topics, topics{kk}))));
    if isempty(idx) % false hope, the mapping doesn't cover this topic
      eval([fields{kk},'= msgs;']);
    else % naively assume it must be there if the search result isn't empty.
      data_ = nan(length(array_map{idx}),length(msgs));
      % populate the mapped matrix
      for kkk = 1:length(array_map{idx}) % over each message field (row)
        for kkkk = 1:length(msgs) % over each message (column)
          eval(['data_(kkk,kkkk) = msgs{kkkk}.' array_map{idx}{kkk} ';']);
        end
      end
      % put this thing in the proper field instead of a giant new nested
      % structure
      eval([fields{kk}, '= data_;'])
    end
  end
%   error('Stop here')
  kk = kk + 1;
end
if do_save
  fprintf(' done.\n\tSaving... ')
  save(matf, 'data','fields','topics', '-v7.3');
  fprintf(' done.\n')
  fprintf('\t----- Done with that file & saved -----\n')
end
end


function [pi_z pi_init pi_s] = transformDistStruct_HongminWu(dist_struct,feature_vec)
pi_z    = dist_struct.pi_z(feature_vec,feature_vec);
pi_z    = pi_z./repmat(sum(pi_z,2),[1,size(pi_z,2)]);
pi_init = dist_struct.pi_init(feature_vec);
pi_init = pi_init./sum(pi_init);
pi_s    = dist_struct.pi_s(feature_vec);
pi_s    = pi_s./repmat(sum(pi_s,2),[1,size(pi_s,2)]);
end
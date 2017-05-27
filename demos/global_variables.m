function global_variables()
global ROOT_PATH DATA_PATH TRAINED_MODEL_PATH TESTING_RESULTS_PATH%path
global METHOD ROBOT TASK STATE SIGNAL_TYPE DATASET TIME_STEP COLORS PLOT_ON PLOT_SAVE                 %general
global TRAIN_TIMES  INERATIVE_TIMES  WRENCH_DERIVATIVE  AUTOREGRESSIVE_ORDER     %parameters
global CONFUSION_MATRIX TIME_PERCENT

AUTOREGRESSIVE_ORDER = 1;
TRAIN_TIMES          = 1;
INERATIVE_TIMES      = 500;
TIME_STEP            = 0.005;
COLORS               = {'r', 'g', 'b', 'k', 'c','y'};
PLOT_ON              = false;
PLOT_SAVE            = true;
METHOD               = 'BPARHMM';
ROBOT                = 'HIRO';
TASK                 = 'SA';
WRENCH_DERIVATIVE    = true;
SIGNAL_TYPE          = {'R_Torques'};  %'R_Torques', 'R_Angles' 
MULTIMODAL           = '';
for nSignal          = 1 : length(SIGNAL_TYPE) 
    MULTIMODAL       = strcat(MULTIMODAL,'_',SIGNAL_TYPE{nSignal}); 
end
DATASET              = 'REAL_HIRO_ONE_SA_SUCCESS';
DATA_PATH            = '/media/vmrguser/DATA/Homlx/HIRO_SA_DATA';
ROOT_PATH            = '/media/vmrguser/DATA/Homlx/BPARHMM';
TRAINED_MODEL_PATH   = strcat(ROOT_PATH, '/','TrainedModels/',METHOD,'_',ROBOT,'_',TASK,'_',MULTIMODAL,'_');
TESTING_RESULTS_PATH = strcat(ROOT_PATH, '/','Results','/',METHOD,'_',ROBOT,'_',TASK,'_',MULTIMODAL);
STATE                = {'APPROACH', 'ROTATION', 'INSERTION', 'MATING'};

addpath(genpath(ROOT_PATH));
addpath(genpath(DATA_PATH));

% state classification accuracy for generating the confusion matrix and time threshold
CONFUSION_MATRIX            = zeros(length(STATE), length(STATE));
TIME_PERCENT                = zeros(1, length(STATE));
end

Data from snap assembly work in simulation with the HIRO Robot. Successful and failed trials are included. Work with belief generation through Bayesian filters and "Gradient" threshold optimization also included. This data was used in ICMA/IROS/Humanoids/ROBIO 2012. Location: Tsukuba, Japan. Dates: 2012

This data contains: (i) Manipulation data, (ii) RCBHT State estimation data, and then there are two global folders: (iii) ./Probability where probabilistic data and results are kept for a Bayesian filter, and (iv) ./gradClassFolder + ./GradientClassification folder. These 4 are detailed below:

(i) Manipulation Data
Angles: Current Joint Angles (7 DoF) Format: time th1 th2 ... th7

CartPos: EndEffector Cartesian Position Format: time x y z r p y

Torques: Wrench data wrt the tool. No gravity compensation. Format: time Fx Fy Fz Mx My Mz

State: State Transition Time Vector. Format: time

(ii) RCBHT Information

- Segments:
contains information about how the original FT data is segmented by a regression fit for all 6 FT axes. Data include: iteration, average magnitude value, maximum magnitude value, minimum magnitude value, start time, finish time, gradient value, and gradient lable.

- Composites:
contains information of how neighboring segments are combined (though affected by MC filtering rules) for all 6 FT axes. Data include iteration, MC label, avg val across segments, root-mean-square value across segments, amplitude value across segments, gradient labels for both segments, start, end, avg time for both segments.

- llBehaviors:
- contains information of how neighboring actions are combined (though affected by LLB filtering rules) for all 6 FT axes. Data is kept in file (.txt) format and also in matlab format (.mat) and include the following info: iteration, llb label, avg. val for mc1 & mc2, avg val for combination of mc1&2, same for rms value and amplitude value, mc label 1 and 2, time they start and finish respectively, and the average time for both of them.

(iii) Probability:
The data was captured manually and off-line. We ran out of time to automate the process. The excel files capture: 
- the prior probability (of LLB labels)
- The System Model (here defined as the likelihood of transitioning from one state to another based on training data)
- Measurement info (the duration of different labels for each of the 4 assembly states for each of the 6 Force axes)

(iv) gradClassFolder:
This folder records gradient treshold classification values in Fx/Fy/Fz/Mx/My/Mz.dat. It also records new limits based on the experienced gradient information. 

GradientClassificationFolder:
Holds the newly generated thresholds for the 7 categories (8 intervals) of gradient thresholds int the primitives layer: pimp/bpos/mpos/spos/sneg/mneg/bnet/nimp
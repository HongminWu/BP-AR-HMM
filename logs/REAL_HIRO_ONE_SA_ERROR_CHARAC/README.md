Data from snap assembly for specific failure cases with the HIRO Robot. Location: AIST-Tsukuba, Japan. Dates: 2014.

Each folder contains the following files and data:

i. rstate.dat (7DoF Actual Joint Angles -- yaw computed differently here)
Format: time-stamp theta1 ...  theta7
Note: code changed by another... have not looked @ difference.

ii. astate.dat (7DoF Desired Joint Angles)
Format: time-stamp theta1 ...  theta7

iii. localforce.dat (Wrench data wrt end-effector)
Format: time Fx Fy Fz Mx My Mz
Note: localforce and Torques.dat different. Code changed another... have not looke\
d @ diff.

iv. worldforce.dat (Wrench data wrt robot base)
Format: time Fx Fy Fz Mx My Mz

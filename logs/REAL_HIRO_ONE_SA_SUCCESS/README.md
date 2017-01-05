Data from snap assembly work with the HIRO Robot. Location: AIST-Tsukuba, Japan. Dates: 2012-2014.

Each folder contains the following files and data:
(Due to having w different programmers here, sometimes they created data files that record the same thing at different cycle times. The data is redundant and one can select which data set to use).

i. Angles.dat (7DoF Actual Joint Angles)
Format: time-stamp theta1 ...  theta7

- rstate.dat (7DoF Actual Joint Angles -- yaw computed differently than in Angles.dat)
Format: time-stamp theta1 ...  theta7
Note: code changed by another... have not looked @ difference.

ii. astate.dat (7DoF Desired Joint Angles)
Format: time-stamp theta1 ...  theta7

iii. CartPos.dat (xyzrpy end-effect Cartesian positions)
Format: time-stap x y z r p y

iv. State.dat (Time stamps of state transitions)
Format: time (secs)

v. Torques.dat (Actual Wrench data wrt end-effector)
Format: time Fx Fy Fz Mx My Mz

- localforce.dat (Wrench data wrt end-effector)
Format: time Fx Fy Fz Mx My Mz
Note: localforce and Torques.dat different. Code changed another... have not looked @ diff.

v. worldforce.dat (Actual Wrench data wrt world)
Format: time Fx Fy Fz Mx My Mz

- Cur.dat (Wrench data wrt world)
Format: time Fx Fy Fz Mx My Mz
Note: localforce and Torques.dat different. Code changed another... have not looked @ diff.

vi Des.dat (Desired Torques wrt world)
Format: time Fx Fy Fz Mx My Mz


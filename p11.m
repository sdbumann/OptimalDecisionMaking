%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EPFL | MGT-483: Optimal Decision Making | Group Project, Exercise 1.1 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; yalmip('clear');clc;
%% Data
% The following data is define as a struct for each generator.
% You could define it in your own way if you want, 
% like vectors: GenCost=[15; 20; 15; 20; 30; 25];

% number of generators
NGen= 6;
% time duration
T=24;
% cost
G1.cost = 15;
G2.cost = 20;
G3.cost = 15;
G4.cost = 20;
G5.cost = 30;
G6.cost = 25;
% capacity
G1.capacity = 10;
G2.capacity = 5;
G3.capacity = 10;
G4.capacity = 10;
G5.capacity = 20;
G6.capacity = 30;
% ramp-up
G1.rampup = 2;
G2.rampup = 5;
G3.rampup = 2;
G4.rampup = 5;
G5.rampup = 10;
G6.rampup = 5;
% ramp-down
G1.rampdown = 2;
G2.rampdown = 5;
G3.rampdown = 2;
G4.rampdown = 5;
G5.rampdown = 10;
G6.rampdown = 5;
% renewable energy source
r=[15.2;16.4;16.1;10.9;14.8;7.6;15.6;5.5;9.2;5.7;1.5;12.4;10.4;4.8;14.3;0.5;6.6;5.7;11.5;11.9;2.8;7.3;6.7;9.7];

% demand
d=[21.3;21.4;17.8;20.9;15.5;17.6;20.2;23.8;27.7;30.1;35.4;39.4;43.2;47.0;49.3;51.5;52.6;50.3;47.0;43.1;38.8;33.2;28.6;24.3];

%% Economic Dispatch
% three elements
% variables Initial

con=[];%constraints initial
obj=0;%objective function initial

% decision variable
g=sdpvar(T,NGen);   %power produced by the traditional generator i at time t 
                    % = array of size (number of time steps x number of generators)

% objective function
obj = sum(g,1)*[G1.cost; G2.cost; G3.cost; G4.cost; G5.cost; G6.cost];

% constraints
con = [
    sum(g,2)+r==d,
    g>=zeros(T,NGen),
    g<=repmat([G1.capacity, G2.capacity, G3.capacity, G4.capacity, G5.capacity, G6.capacity],T,1),
    diff(g)<=repmat([G1.rampup, G2.rampup, G3.rampup, G4.rampup, G5.rampup, G6.rampup],T-1,1),
    -diff(g)<=repmat([G1.rampdown, G2.rampdown, G3.rampdown, G4.rampdown, G5.rampdown, G6.rampdown],T-1,1)
]

%% define sdpsetting
ops=sdpsettings('solver','LINPROG');
sol=solvesdp(con,obj,ops);

% obtain the solutions and objective value
disp(['The value of the objective function is ',num2str(value(obj))]) %gives value of objective function

disp('The optimal value of the decision variable g is given by')
g_value=value(g)%gives optimal value of decision variable g
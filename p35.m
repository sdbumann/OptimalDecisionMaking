%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EPFL | MGT-483: Optimal Decision Making | Group Project, Exercise 3.5 %
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
% generation cost
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
% start-up cost
G1.startup = 75;
G2.startup = 100;
G3.startup = 75;
G4.startup = 100;
G5.startup = 100;
G6.startup = 125;
% shutdown cost
G1.shutdown = 7.5;
G2.shutdown = 10;
G3.shutdown = 17.5;
G4.shutdown = 10;
G5.shutdown = 10;
G6.shutdown = 12.5;
% no-load cost
G1.noload = 10;
G2.noload = 5;
G3.noload = 10;
G4.noload = 10;
G5.noload = 10;
G6.noload = 10;
% initial state of generators x_0
G1.inital = 1;
G2.inital = 0;
G3.inital = 0;
G4.inital = 0;
G5.inital = 0;
G6.inital = 0;
% minimum up-time of generators
G1.minup = 3;
G2.minup = 3;
G3.minup = 3;
G4.minup = 3;
G5.minup = 3;
G6.minup = 3;
% minimum down-time of generators
G1.mindown = 2;
G2.mindown = 2;
G3.mindown = 2;
G4.mindown = 2;
G5.mindown = 2;
G6.mindown = 2;

% renewable energy source
r_bar=[15.2;16.4;16.1;10.9;14.8;7.6;15.6;5.5;9.2;5.7;1.5;12.4;10.4;4.8;14.3;0.5;6.6;5.7;11.5;11.9;2.8;7.3;6.7;9.7];
r_hat = 0.6*ones(T,1);

% demand
d=[21.3;21.4;17.8;20.9;15.5;17.6;20.2;23.8;27.7;30.1;35.4;39.4;43.2;47.0;49.3;51.5;52.6;50.3;47.0;43.1;38.8;33.2;28.6;24.3];

%% Robust Unit Commitment
% Hints: define binary variables (vector) in yalmip:  
% a = binvar(N,M) with dimension N*M 

% three elements
%variables Initial

con=[];%constraints initial
obj=0;%objective function initial

% decision variable
x=binvar(T,NGen);   %x_i^t=1 -> generator i running at time t
                    %x_i^t=0 -> generator i not running at time t
u=binvar(T,NGen);   %u_i^t=1 -> generator i turned on at time t
                    %u_i^t=0 -> generator i not turned on at time t
v=binvar(T,NGen);   %v_i^t=1 -> generator i turned off at time t
                    %v_i^t=0 -> generator i not turned off at time t
a=sdpvar(T,NGen);   %decision variable used to approcimate the functional
                    %decisions by linear decision rules
b=sdpvar(T,NGen);   %decision variable used to approcimate the functional
                    %decisions by linear decision rules
c=sdpvar(T,NGen);   %decision variable used to approcimate the functional
                    %decisions by linear decision rules
z=sdpvar(4*T,1);    %decision variable recived by dualization
g=sdpvar(T,NGen);   %power produced by the traditional generator i at time t 
                    % = array of size (number of time steps x number of generators)
r=sdpvar(T,1)       % renewable energy source                    

% objective function
obj =   sum(x,1)*[G1.noload; G2.noload; G3.noload; G4.noload; G5.noload; G6.noload] + ...
        sum(u,1)*[G1.startup; G2.startup; G3.startup; G4.startup; G5.startup; G6.startup] + ...
        sum(v,1)*[G1.shutdown; G2.shutdown; G3.shutdown; G4.shutdown; G5.shutdown; G6.shutdown] + ...
        [-ones(1,T),ones(1,T),r_hat.'+r_bar.',r_hat.'-r_bar.']*z;


% constraints
con = [
    sum(a,2) == -ones(T,1),
    sum(b,2) == zeros(T,1),
    sum(c,2) == d,
    
    % r should not be here?
    % is the new variable after dualization x? -> do not think so.
    
    g(1,:) == a(1,:).*r(1)+c(1,:),
    g(1,:) >= zeros(1,NGen),
    g(1,:) <= x(1,:).*[G1.capacity, G2.capacity, G3.capacity, G4.capacity, G5.capacity, G6.capacity],
    g(2:end,:) == a(2:end,:).*repmat(r(2:end),1,NGen)+b(2:end,:).*repmat(r(1:end-1),1,NGen)+c(2:end,:),
    g(2:end,:) >= zeros(T-1,NGen),
    g(2:end,:) <= x(2:end,:).*repmat([G1.capacity, G2.capacity, G3.capacity, G4.capacity, G5.capacity, G6.capacity],T-1,1),
    b(end,:) == zeros(1,NGen),
    [-ones(T,T), ones(T,T), zeros(T,T), zeros(T,T); zeros(T,T), zeros(T,T), ones(T,T), -ones(T,T)]*z >= [[G1.cost; G2.cost; G3.cost; G4.cost; G5.cost; G6.cost].'*c.',[G1.cost; G2.cost; G3.cost; G4.cost; G5.cost; G6.cost].'*(a.'+b.')].',
    z >= zeros(4*T,1),
    
    -diff(x) + u(2:end,:) >= zeros(T-1,NGen),
    diff(x) + v(2:end,:) >= zeros(T-1,NGen),
    x(1,:) == [G1.inital, G2.inital, G3.inital, G4.inital, G5.inital, G6.inital],
    u(1,:) == zeros(1,NGen),
    v(1,:) == zeros(1,NGen),
%     a(:,:) >= zeros(T,NGen),
%     b(:,:) >= zeros(T,NGen),
%     c(:,:) >= zeros(T,NGen),
];

con = minup_con_generate(con, x, [G1.minup, G2.minup, G3.minup, G4.minup, G5.minup, G6.minup]);
con = mindown_con_generate(con,x,[G1.mindown, G2.mindown, G3.mindown, G4.mindown, G5.mindown, G6.mindown]);


%% define sdpsetting
ops=sdpsettings('solver','MOSEK');
sol=solvesdp(con,obj,ops);

% obtain the solutions and objective value
disp(['The value of the objective function is ',num2str(value(obj))]) %gives value of objective function

disp('The optimal value of the decision variable g is given by')
g_value=value(g)%gives optimal value of decision variable g

disp('When to run the generator and when not is given by')
x_value=value(x)

disp('Z is given by')
z_value=value(z)




%% functions
function con_ret = minup_con_generate(con,x,minup_array)
    for minup_idx=1:length(minup_array)
        for i=1:minup_array(minup_idx)
            con=[con, diff(x(1:end-1,minup_idx)) <= [x(2+i:end,minup_idx);repmat(x(end,minup_idx),i-1,1)]];
        end
    end
    con_ret=con;
end

function con_ret = mindown_con_generate(con,x,mindown_array)
    [T,NGen] = size(x);
    for mindown_idx=1:length(mindown_array)
        for i=1:mindown_array(mindown_idx)
            con=[con, -diff(x(1:end-1,mindown_idx)) <= ones(T-2,1) - [x(2+i:end,mindown_idx);repmat(x(end,mindown_idx),i-1,1)]];
        end
    end
    con_ret=con;
end
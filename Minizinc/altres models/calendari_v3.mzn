include "all_different.mzn";

% Input
% =======
int: nmachesperday;
int: nmatchesperstadium;
int: ndays;
int: nteams;
int: nstadiums;

set of int: DAY = 1..ndays;
set of int: TEAM = 1..nteams;
set of int: STADIUM = 1..nstadiums;

array[DAY, STADIUM] of set of TEAM: fixes;
array[STADIUM,STADIUM] of int: distancies;
array[TEAM] of int: tifosi;
array[STADIUM] of int: capacitats;

% Boundaries
% ==========
int: lboundDistance = min([distancies[s,s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);
int: uboundDistance = max([distancies[s,s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);

int: lboundSeguidors = 0;
int: uboundSeguidors = max(0, max(tifosi)*2 - min(capacitats));

% Variables
% =========
array[TEAM, TEAM] of var 0..ndays: dies;
array[TEAM, TEAM] of var 0..nstadiums: estadis;
array[TEAM] of var lboundDistance..uboundDistance: team_distance;
array[TEAM, TEAM] of var lboundSeguidors..uboundSeguidors: spectators_left_out;

% Constraints
% ===========

constraint forall(t in TEAM) (
    dies[t,t] = 0 /\ estadis[t,t] = 0 /\ spectators_left_out[t,t] = 0
);

constraint forall(t,t2 in TEAM where t < t2) (
    dies[t,t2] == dies[t2,t] /\ estadis[t,t2] == estadis[t2,t]
);

% Fixes for specific days and stadiums
constraint forall(d in DAY, s in STADIUM)(
    if card(fixes[d, s]) = 1 then
        let {
            var TEAM: t_fixe = fixes[d, s][1] 
        } in
            exists(t2 in TEAM where t2 != t_fixe) (
                dies[t_fixe, t2] = d /\ estadis[t_fixe, t2] = s
            )
    elseif card(fixes[d, s]) = 2 then
        let { 
            var TEAM: t1 = fixes[d, s][1], 
            var TEAM: t2 = fixes[d, s][2] 
        } in
            dies[t1, t2] = d /\ estadis[t1, t2] = s
    else true endif
);

% No repetition of days or stadiums for teams (files i columnes, no es toca)
constraint forall(t in TEAM) (
    all_different([dies[min(t, t2), max(t, t2)] | t2 in TEAM where t2 != t]) /\
    all_different([estadis[min(t, t2), max(t, t2)] | t2 in TEAM where t2 != t])
);

% all_different de les tuples generades (ja força nmachesperday i nmatchesperstadium)
constraint all_different([dies[t1,t2] * 100 + estadis[t1,t2] | t1,t2 in TEAM where t1 < t2]);

% Distance constraints
constraint forall(t in TEAM) (
    team_distance[t] = sum(d in 1..ndays-1)(
        let {
            var STADIUM: prev_stadium = max([estadis[t, t2] | t2 in TEAM where dies[t, t2] = d]),
            var STADIUM: curr_stadium = max([estadis[t, t2] | t2 in TEAM where dies[t, t2] = d + 1])

        } in
        distancies[prev_stadium, curr_stadium]
    )
);

% Spectators left out constraints
constraint forall(t1 in TEAM, t2 in TEAM where t1 < t2)(
    spectators_left_out[t1, t2] = max(tifosi[t1] + tifosi[t2] - capacitats[estadis[t1, t2]], 0)
);


% Solving queries
% ===============

%% 1. FIRST SOLUTION
%solve satisfy;

%% 2. MINIMIZE TEAM DISTANCES:
%solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([dies[t1,t2] * 100 + estadis[t1,t2] | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize sum(team_distance);

%% 3. MAXIMIZE SPECTATORS (MINIMIZING SPECTATORS LEFT OUT):
solve :: seq_search([
    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
    int_search([dies[t1,t2] * 100 + estadis[t1,t2] | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
]) minimize sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

%% 4. MAXIMIZE SPECTATORS REDUCING DISTANCES
%int: LARGE_NUMBER = 1000000; % A large value to prioritize minimizing spectators left out

%var int: combined_objective =
%    LARGE_NUMBER * sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]) +
%    sum(team_distance);

%solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([dies[t1,t2] * 100 + estadis[t1,t2] | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize combined_objective;

%% 5. MINIMIZE TEAM DISTANCES REDUCING SPECTATORS LEFT OUT
%int: LARGE_NUMBER = 1000000; % A large value to prioritize minimizing spectators left out

%var int: combined_objective =
%    LARGE_NUMBER * sum(team_distance) +
%    sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

%solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([dies[t1,t2] * 100 + estadis[t1,t2] | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize combined_objective;

%% 6. MINIMIZE TIME DISTANCES DIFFERENCES
% solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([dies[t1,t2] * 100 + estadis[t1,t2] | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize((max(team_distance) - min(team_distance) + 1)*sum(team_distance));


% Output
% ======

output
        ["MATRIU DE PARTITS (DIA, ESTADI): \n"] ++
        ["\t"] ++ ["Eq " ++ show(t1) ++ "\t" | t1 in TEAM] ++ ["\n"] ++ % primera fila d'informació
        ["--------" | t1 in 0..nteams] ++ ["\n"] ++
        [
            if t2 == 1 then "Eq " ++ show(t1) ++ "\t" else "" endif ++ "" ++ % columna d'informació
            
            if t1 == t2 then "   -"
            else "(" ++ show(dies[t1,t2]) ++ "," ++ show(estadis[t1,t2]) ++ ")" endif ++ % imprimint dia,estadi de cada equip
            
            if t2 == nteams then "\n" else "\t" endif % salt de línia o tab
            
        | t1,t2 in TEAM] ++ [ % altres dades
            "\n\n" ++
            "KMs TOTALS: " ++ show(sum(team_distance)) ++ "\n" ++
            "Repartiment d'equips: " ++ show(team_distance) ++ "\n" ++
            "SEGUIDORS FORA: " ++ show(sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2])) ++ "\n"
        ]
;
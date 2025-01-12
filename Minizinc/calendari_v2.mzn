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
array[TEAM, TEAM] of var tuple(DAY,STADIUM): tauler;
array[TEAM] of var lboundDistance..uboundDistance: team_distance;
array[TEAM, TEAM] of var lboundSeguidors..uboundSeguidors: spectators_left_out;

% Constraints
% ===========

% Fixes for specific days and stadiums
constraint forall(d in DAY, s in STADIUM)(
    if card(fixes[d,s]) == 1 then
        exists(t2 in TEAM where t2 != fixes[d,s][1])(tauler[min(fixes[d,s][1], t2), max(fixes[d,s][1], t2)] = (d,s))
    elseif card(fixes[d,s]) == 2 then
        tauler[min(fixes[d,s][1], fixes[d,s][2]), max(fixes[d,s][1], fixes[d,s][2])] = (d,s)
    else
        true
    endif
);

% No repetition of days or stadiums for teams

constraint forall(t in TEAM) (
    all_different([if t2 > t then tauler[t,t2].1 else tauler[t2,t].1 endif | t2 in TEAM where t2 != t]) /\
    all_different([if t2 > t then tauler[t,t2].2 else tauler[t2,t].2 endif | t2 in TEAM where t2 != t])
);

% all_different de les tuples generades (ja força nmachesperday i nmatchesperstadium)
constraint all_different([tauler[t1,t2].1 * 100 + tauler[t1,t2].2 | t1,t2 in TEAM where t1 < t2]);

% Distance constraints
constraint forall(t in TEAM) (
    team_distance[t] = sum(d in 1..ndays-1)(
        let {
            var STADIUM: prev_stadium;
            var STADIUM: curr_stadium;
            constraint exists(t2 in TEAM)((t < t2 /\ tauler[t, t2] = (d, prev_stadium)) \/ (t2 < t /\ tauler[t2, t] = (d, prev_stadium)));
            constraint exists(t2 in TEAM)((t < t2 /\ tauler[t, t2] = (d+1, curr_stadium)) \/ (t2 < t /\ tauler[t2, t] = (d+1, curr_stadium)));
        } in
        distancies[prev_stadium, curr_stadium]
    )
);

% Spectators left out constraints
constraint forall(t1 in TEAM, t2 in TEAM where t1 < t2)(
    spectators_left_out[t1, t2] = max(tifosi[t1] + tifosi[t2] - capacitats[tauler[t1, t2].2], 0)
);


% Solving queries
% ===============

%% 1. FIRST SOLUTION
%solve satisfy;

%% 2. MINIMIZE TEAM DISTANCES:
%solve minimize sum(team_distance);

%% 3. MAXIMIZE SPECTATORS (MINIMIZING SPECTATORS LEFT OUT):
solve minimize sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

%% 4. MAXIMIZE SPECTATORS REDUCING DISTANCES
%int: LARGE_NUMBER = 1000000; % A large value to prioritize minimizing spectators left out

%var int: combined_objective =
%    LARGE_NUMBER * sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]) +
%    sum(team_distance);

%solve minimize combined_objective;

%% 5. MINIMIZE TEAM DISTANCES REDUCING SPECTATORS LEFT OUT
%int: LARGE_NUMBER = 1000000; % A large value to prioritize minimizing spectators left out

%var int: combined_objective =
%    LARGE_NUMBER * sum(team_distance) +
%    sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

%solve minimize combined_objective;

%% 6. MINIMIZE TIME DISTANCES DIFFERENCES
% solve minimize((max(team_distance) - min(team_distance) + 1)*sum(team_distance));


% Output
% ======

output
        ["MATRIU DE PARTITS (DIA, ESTADI): \n"] ++
        ["\t"] ++ ["Eq " ++ show(t1) ++ "\t" | t1 in TEAM] ++ ["\n"] ++
        ["--------" | t1 in 0..nteams] ++ ["\n"] ++
        [
            if t2 == 1 then "Eq " ++ show(t1) ++ "\t" else "" endif ++ "" ++
            if t1 < t2 then "(" ++ show(tauler[t1,t2].1) ++ "," ++ show(tauler[t1,t2].2) ++ ")"
            elseif t1 == t2 then "   -"
            else "(" ++ show(tauler[t2,t1].1) ++ "," ++ show(tauler[t2,t1].2) ++ ")" endif ++
            if t2 == nteams then "\n" else "\t" endif
        | t1,t2 in TEAM] ++ [
            "\n\n" ++
            "KMs TOTALS: " ++ show(sum(team_distance)) ++ "\n" ++
            "Repartiment d'equips: " ++ show(team_distance) ++ "\n" ++
            "SEGUIDORS FORA: " ++ show(sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2])) ++ "\n"
        ]
;
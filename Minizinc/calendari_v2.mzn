include "all_different.mzn";

% Input
% =====
int: nmachesperday;
int: nmatchesperstadium;
int: ndays;
int: nteams;
int: nstadiums;

set of int: DAY = 1..ndays;
set of int: TEAM = 1..nteams;
set of int: STADIUM = 1..nstadiums;

array[DAY, STADIUM] of set of TEAM: fixes;
array[STADIUM, STADIUM] of int: distancies;
array[TEAM] of int: tifosi;
array[STADIUM] of int: capacitats;

% Boundaries
% ==========
int: lboundDistance = min([distancies[s, s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);
int: uboundDistance = max([distancies[s, s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);

int: lboundSeguidors = 0;
int: uboundSeguidors = max(0, max(tifosi) * 2 - min(capacitats));

% Variables
% =========
array[TEAM, TEAM] of var tuple(DAY, STADIUM): tauler;
array[TEAM] of var lboundDistance..uboundDistance: team_distance;
array[TEAM, TEAM] of var lboundSeguidors..uboundSeguidors: spectators_left_out;

% Constraints
% ===========

% Self-matches and spectators for a team playing itself
constraint forall(t in TEAM)(
    tauler[t, t] = (1, 1)
);

% Symmetry reduction for team-to-team matches
constraint forall(t, t2 in TEAM where t < t2)(
    tauler[t, t2] = tauler[t2, t]
);

% Fix matches based on pre-specified days and stadiums
constraint forall(d in DAY, s in STADIUM)(
    if card(fixes[d, s]) = 1 then
        exists(t2 in TEAM where t2 != fixes[d, s][1]) (tauler[fixes[d, s][1], t2] = (d, s))
    elseif card(fixes[d, s]) = 2 then
        tauler[fixes[d, s][1], fixes[d, s][2]] = (d, s)
    else 
        true
    endif
);

% No repetition of days or stadiums per team
constraint forall(t in TEAM)(
    all_different([tauler[t, t2].1 | t2 in TEAM where t2 != t]) /\
    all_different([tauler[t, t2].2 | t2 in TEAM where t2 != t])
);

% Ensure matches are unique by encoding (day, stadium) as a single value
constraint all_different([
    tauler[t1, t2].1 * 100 + tauler[t1, t2].2
    | t1, t2 in TEAM where t1 < t2
]);

% Distance constraints
constraint forall(t in TEAM) (
    team_distance[t] = sum(d in 1..ndays-1)(
        let {
            var STADIUM: prev_stadium;
            var STADIUM: curr_stadium;
            constraint exists(t2 in TEAM where t != t2)(tauler[t, t2] = (d, prev_stadium));
            constraint exists(t2 in TEAM where t != t2)(tauler[t, t2] = (d+1, curr_stadium));
        } in
        distancies[prev_stadium, curr_stadium]
    )
);

% Calculate spectators left out for matches
constraint forall(t1, t2 in TEAM where t1 < t2)(
    spectators_left_out[t1, t2] = max(
        tifosi[t1] + tifosi[t2] - capacitats[tauler[t1, t2].2],
        0
    )
);

% Solving queries
% ===============

%% 1. FIRST SOLUTION
%solve satisfy;

%% 2. MINIMIZE TEAM DISTANCES:
solve :: seq_search([
    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
    int_search([tauler[t1,t2].1 * 100 + tauler[t1,t2].2 | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
]) minimize sum(team_distance);

%% 3. MAXIMIZE SPECTATORS (MINIMIZING SPECTATORS LEFT OUT):
%solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([tauler[t1,t2].1 * 100 + tauler[t1,t2].2 | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

%% 4. MAXIMIZE SPECTATORS REDUCING DISTANCES
int: LARGE_NUMBER = 1000000; % A large value to prioritize minimizing spectators left out

%var int: combined_objective =
%    LARGE_NUMBER * sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]) +
%    sum(team_distance);

%solve :: seq_search([
%   int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([tauler[t1,t2].1 * 100 + tauler[t1,t2].2 | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize combined_objective;

%% 5. MINIMIZE TEAM DISTANCES REDUCING SPECTATORS LEFT OUT

%var int: combined_objective =
%    LARGE_NUMBER * sum(team_distance) +
%    sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

%solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([tauler[t1,t2].1 * 100 + tauler[t1,t2].2 | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize combined_objective;

%% 6. MINIMIZE TIME DISTANCES DIFFERENCES
%solve :: seq_search([
%    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
%    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
%    int_search([tauler[t1,t2].1 * 100 + tauler[t1,t2].2 | t1,t2 in TEAM where t1 < t2], input_order, indomain_min)
%]) minimize((max(team_distance) - min(team_distance) + 1)*sum(team_distance));

% Output
% ======
output [
    "Matches Schedule (Day, Stadium):\n"
] ++ ["\t"] ++
[
    "Team " ++ show(t1) ++ "\t" | t1 in TEAM
] ++ ["\n"] ++
[
    if t2 = 1 then "Team " ++ show(t1) ++ "\t" else "" endif ++
    if t1 < t2 then "(" ++ show(tauler[t1, t2].1) ++ "," ++ show(tauler[t1, t2].2) ++ ")"
    elseif t1 = t2 then "   -"
    else "(" ++ show(tauler[t2, t1].1) ++ "," ++ show(tauler[t2, t1].2) ++ ")"
    endif ++
    if t2 = nteams then "\n" else "\t" endif
    | t1, t2 in TEAM
] ++
[
    "\nTotal Distance: " ++ show(sum(team_distance)) ++ "\n" ++
    "Team Distances: " ++ show(team_distance) ++ "\n" ++
    "Spectators Left Out: " ++ show(sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2])) ++ "\n"
];

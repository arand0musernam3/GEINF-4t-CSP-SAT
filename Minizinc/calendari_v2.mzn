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

% Precomputed helper structures
% =============================
array[STADIUM, STADIUM] of int: precomputed_dist = distancies;

% Constraints
% ===========

% Self-matches and spectators for a team playing itself
constraint forall(t in TEAM)(
    tauler[t, t] = (1, 1) /\ spectators_left_out[t, t] = 0
);

% Symmetry reduction for team-to-team matches
constraint forall(t, t2 in TEAM where t < t2)(
    tauler[t, t2] = tauler[t2, t] /\ spectators_left_out[t, t2] = spectators_left_out[t2, t]
);

% Fix matches based on pre-specified days and stadiums
constraint forall(d in DAY, s in STADIUM)(
    if card(fixes[d, s]) = 1 then
        exists(t2 in TEAM where t2 != fixes[d, s][1]) (
            if fixes[d, s][1] < t2 then
                tauler[fixes[d, s][1], t2] = (d, s)
            else
                tauler[t2, fixes[d, s][1]] = (d, s)
            endif
        )
    elseif card(fixes[d, s]) = 2 then
        if fixes[d, s][1] < fixes[d, s][2] then
            tauler[fixes[d, s][1], fixes[d, s][2]] = (d, s)
        else
            tauler[fixes[d, s][2], fixes[d, s][1]] = (d, s)
        endif
    else true
    endif
);

% No repetition of days or stadiums per team
constraint forall(t in TEAM)(
    all_different([
        if t < t2 then tauler[t, t2].1 else tauler[t2, t].1 endif 
        | t2 in TEAM where t2 != t
    ]) /\
    all_different([
        if t < t2 then tauler[t, t2].2 else tauler[t2, t].2 endif 
        | t2 in TEAM where t2 != t
    ])
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
            constraint exists(t2 in TEAM)((t < t2 /\ tauler[t, t2] = (d, prev_stadium)) \/ (t2 < t /\ tauler[t2, t] = (d, prev_stadium)));
            constraint exists(t2 in TEAM)((t < t2 /\ tauler[t, t2] = (d+1, curr_stadium)) \/ (t2 < t /\ tauler[t2, t] = (d+1, curr_stadium)));
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

% Optimization goals
% ==================
% Solve to minimize spectators left out
solve :: seq_search([
    int_search([team_distance[t] | t in TEAM], input_order, indomain_min),
    int_search([spectators_left_out[t1, t2] | t1, t2 in TEAM where t1 < t2], input_order, indomain_min),
    int_search([tauler[t1, t2].1 * 100 + tauler[t1, t2].2 | t1, t2 in TEAM where t1 < t2], input_order, indomain_min)
]) minimize sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

% Output
% ======
output [
    "Matches Schedule (Day, Stadium):\n"
] ++
[
    "Team " ++ show(t1) ++ "\t" | t1 in TEAM
] ++
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

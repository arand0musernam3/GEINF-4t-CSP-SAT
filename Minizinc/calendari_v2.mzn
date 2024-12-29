include "globals.mzn";

% Entrada
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
int: lboundDistance = min([distancies[s,s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);
% int: lboundDistance = sum(sort([distancies[s, s2] | s, s2 in STADIUM where s != s2])[1..ndays-1]);
int: uboundDistance = max([distancies[s,s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);

% Variables (sempre afegirem la restricció t1 < t2)
% =========
array[TEAM, TEAM] of var tuple(DAY,STADIUM): tauler;
array[TEAM] of var lboundDistance..uboundDistance: team_distance;
% Calculate spectators left out for each match
array[TEAM, TEAM] of var 0..(max(tifosi)*2-min(capacitats)): spectators_left_out;

% Constraints
% ===========
% Això s'ha de poder millorar d'alguna forma...
constraint forall(d in DAY, s in STADIUM)(
    if card(fixes[d,s]) == 1 then
        exists(t2 in TEAM where t2 != fixes[d,s][1])(tauler[min(fixes[d,s][1], t2), max(fixes[d,s][1], t2)] = (d,s))
    elseif card(fixes[d,s]) == 2 then
        tauler[min(fixes[d,s][1], fixes[d,s][2]), max(fixes[d,s][1], fixes[d,s][2])] = (d,s)
    else
        true
    endif
);

% Que no es repeteixi cap dia ni estadi per equip.
constraint forall(t in TEAM) (
    all_different([tauler[t, t2].1 | t2 in TEAM where t2 > t] ++
                  [tauler[t2, t].1 | t2 in TEAM where t2 < t]) /\
    all_different([tauler[t, t2].2 | t2 in TEAM where t2 > t] ++
                  [tauler[t2, t].2 | t2 in TEAM where t2 < t])
);


% Distància (potser es pot millorar)
predicate calculate_distance(
    array[TEAM, TEAM] of var tuple(DAY, STADIUM): tauler,
    array[STADIUM, STADIUM] of int: distancies,
    array[TEAM] of var lboundDistance..uboundDistance: team_distance) = 
        forall(t in TEAM) (
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

% Espectadors fora (potser es pot millorar)
predicate calculate_spectators_left(
    array[TEAM, TEAM] of var tuple(DAY, STADIUM): tauler,
    array[TEAM] of int: tifosi,
    array[STADIUM] of int: capacitats,
    array[TEAM, TEAM] of var 0..(max(tifosi) * 2 - min(capacitats)): spectators_left_out) =
        forall(t1 in TEAM, t2 in TEAM where t1 < t2)(
            spectators_left_out[t1, t2] = max(tifosi[t1] + tifosi[t2] - capacitats[tauler[t1, t2].2], 0)
        );


constraint calculate_distance(tauler, distancies, team_distance);
constraint calculate_spectators_left(tauler, tifosi, capacitats, spectators_left_out);

% TROBAR UNA SOLUCIÓ
/*
solve satisfy;
*/

% MINIMITZAR DISTÀNCIES DELS EQUIPS:
%solve minimize sum(team_distance);


% MAXIMITZAR NOMBRE D'ESPECTADORS:
solve minimize sum(t1 in TEAM, t2 in TEAM where t1 < t2)(spectators_left_out[t1, t2]);

% MINIMITZAR DIFERÈNCIA ENTRE DISTÀNCIES EQUIPS
% solve minimize((max(team_distance) - min(team_distance))*sum(team_distance));




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
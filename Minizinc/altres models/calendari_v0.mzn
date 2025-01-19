% Viewpoint: com la solució: Matriu estadi, dia.
% A cada posició de la matriu, un set que contingui els equips que s'enfronten. Set de cardinalitat 0 o 2.
% Unió dels sets per fila ha de ser tots els equips.
% Unió dels sets per columna ha de ser tots els equips.
% No hi poden haver repetits, és clar. Potser en comptes d'un set, una array (pel tema de que la unió sigui tal sense repetits).

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

int: lboundDistance = min([distancies[s,s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);
int: uboundDistance = max([distancies[s,s2] | s, s2 in STADIUM where s != s2]) * (ndays - 1);

% Variables
% =========
array[DAY,STADIUM] of var set of TEAM: tauler;

% Constraints
% ===========

%% Establint els equips de fixes al tauler
constraint forall(d in DAY, s in STADIUM) (
    forall(t in fixes[d,s]) (t in tauler[d,s])
);

%% Forçar cardinalitat dels sets a 0 o a 2
constraint forall(d in DAY, s in STADIUM) (
    card(tauler[d,s]) in {0,2}
);

%% Filtrant nº de partits per dia.
constraint forall(d in DAY) (
    let {
        var int: num_full_sets = sum([if (card(tauler[d,s]) == 2) then 1 else 0 endif | s in STADIUM]);
    } in
    num_full_sets == nmachesperday
);

%% Filtrant nº de partits per estadi.
constraint forall(s in STADIUM) (
    let {
        var int: num_full_sets = sum([if (card(tauler[d,s]) == 2) then 1 else 0 endif | d in DAY]);
    } in
    num_full_sets == nmatchesperstadium
);

%% All_different per què no hi hagi partits repetits (equip vs equip ha de ser únic)
constraint forall(t1 in TEAM, t2 in TEAM where t1 < t2) ( 
    exists(s in STADIUM, d in DAY) ( 
        (tauler[d,s] = {t1, t2}) 
    )
);

%% Exactament una aparició de cada equip per estadi
constraint forall(d in DAY, t in TEAM) (
    sum([bool2int(t in tauler[d,s]) | s in STADIUM]) == 1
);

%% Exactament una aparició de cada equip per dia
constraint forall(s in STADIUM, t in TEAM) (
    sum([bool2int(t in tauler[d,s]) | d in DAY]) == 1
);



% ==================
%%% Trobar una solució correcta
% solve satisfy;
% ==================

% ==================
%%% Minimitzar km recorreguts per l'equip (sense seguidors)
array[TEAM] of var lboundDistance..uboundDistance: distanciesEquips;
var lboundDistance*nteams..uboundDistance*nteams: distTotal;

constraint
    forall(t in TEAM) (
        distanciesEquips[t] = sum([distancies[st1, st2] | d in 1..ndays-1, st1 in STADIUM, st2 in STADIUM
        where t in tauler[d,st1] /\ t in tauler[d+1, st2]])
    );
    
constraint distTotal = sum(distanciesEquips);
% solve :: seq_search([
%    set_search(tauler, first_fail, indomain_min),
%    int_search(distanciesEquips, first_fail, indomain_min),
%]) minimize distTotal;
% ==================

% ==================
%%% Maximitzar entrades de seguidors: (i.e. minimitzar seguidors a fora)
array[DAY, STADIUM] of var int: seguidorsFora; % buscar també lower i upper bounds !!!!
var int: seguidorsForaTotal;
constraint
    forall(d in DAY, s in STADIUM) (
    seguidorsFora[d,s] = 
        if tauler[d,s] == {} 
            then 0 
            else max(sum(t in tauler[d,s])(tifosi[t]) - capacitats[s], 0) 
        endif
);
constraint seguidorsForaTotal = sum(seguidorsFora);

solve :: seq_search([
    set_search(tauler, first_fail, indomain_min),
	int_search(seguidorsFora, first_fail, indomain_min)
]) minimize seguidorsForaTotal;
% ==================
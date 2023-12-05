%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algorithme smart grid - Affichage conséquence floue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Copyright G.POIDATZ & L.Lixfé, 2021-2022 - All rights reserved

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Affichage graphique de la conséquence floue finale 


function [Xd,CsqFinaleToPrint] = printCsqFinale(partitionCsqToPrint,CsqToPrint,figureN,titleOfFigure,legendOfFigure);

% fuzzyCsqDef est l'entrée un fuzzy system créé à la main avec des entrées 
% correspondantes aux sorties à afficher (dans notre cas : tension 
% immeuble et mesure). Les classes floues de ces sorties y sont définies.

Xd = [0:0.01:100];
outputMfd = zeros(length(partitionCsqToPrint.mf),length(Xd));
% une ligne = une classe
% une colonne = un point discrétisé
for i=1:length(partitionCsqToPrint.mf);
    for j=1:length(Xd);
        outputMfd(i,j) = trapmf(Xd(j),partitionCsqToPrint.mf(i).params);
    end;
end;

for i=1:length(partitionCsqToPrint.mf);
    for j=1:length(Xd); 
    % min troncature pour chaque classe floue
    CsqPartToPrint(i,j) = min(outputMfd(i,j),CsqToPrint(i));
    end;   
end;

% max union en tout point discrétisé (max sur les colonnes de la matrice
% CsqPartToPrint)

CsqFinaleToPrint=max(CsqPartToPrint);

% affichage

figure(figureN);
plot(Xd,CsqFinaleToPrint);
title(titleOfFigure);
legend(legendOfFigure);
axis([0 Xd(length(Xd)) 0 1]);

end
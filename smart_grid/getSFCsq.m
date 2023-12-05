%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algorithme smart grid - Algorithme de Zalila généralisé
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Copyright G.POIDATZ & L.Lixfé, 2021-2022 - All rights reserved


function outputSF = getSFCsq(SF,outputName,varargin);

nbInput = length(SF.input);
input = varargin(1:nbInput);
substituteInput = varargin(nbInput+1:length(varargin));

% fuzzification
irr = fuzzification(SF,input);
nbRuleSF = length(SF.rule); % nombre de règles
nbCsqSF = length(SF.output.mf); % nombre CF de sortie possibles

% vérification des variables sorties de précédent SF
k = 1;
for j=1:length(SF.input);
   if SF.input(j).range==[0 1];
       for i = 1:nbRuleSF;
           irr(i,j) = substituteInput{k}(SF.rule(i).antecedent(j));
       end;
       k=k+1;
   end;
end;
% Algorithme de Zalila généralisé
% T est min et co-T est max et implication modélisée par min
% (pseudo-implication).
declenchementSF = min(irr, [], 2);
outputSF = zeros(1,nbCsqSF);

% max-union de tous les degrés de déclenchement des règles pointant
% vers la même conséquence floue partielle.
for i = 1:nbRuleSF;
    outputSF(SF.rule(i).consequent) = max(outputSF(SF.rule(i).consequent),declenchementSF(i));
end;

% affichage de la conséquence floue finale du SF
csqSFTxt = strcat(outputName,' = {');
for i = 1:nbCsqSF;
    csqSFTxt = strcat(csqSFTxt,'(',SF.output.mf(i).name,';',num2str(outputSF(i)),'), ');
end;
csqSFTxt = strcat(csqSFTxt,'}');
disp(csqSFTxt);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fonction fuzzification

function irr = fuzzification(SF,inputClasses);
% initialisation des variables contenant les règles 
% matrice : 
% ligne = 1 règle
% colonne = 1 variable floue d'entrée
irr = zeros(length(SF.rule),length(SF.input));
for j=1:length(SF.input); % construction de la matrice règle/prémisse avec max/min possibilité 
    Xd = [SF.input(j).range(1):0.01:SF.input(j).range(2)]; %discrétisation
    classToFuzzy = trapmf(Xd,inputClasses{j});
    for i=1:length(SF.rule); 
        % SF.input(j).mf(SF.rule(i).antecedent(j)).params récupère les
        % paramètres de la classe de la variable j (colonne) utilisée pour
        % la règle i (ligne)
        fuzzyClassd = trapmf(Xd,SF.input(j).mf(SF.rule(i).antecedent(j)).params);
        irr(i,j)=max(min(fuzzyClassd,classToFuzzy));
    end;
end;
end
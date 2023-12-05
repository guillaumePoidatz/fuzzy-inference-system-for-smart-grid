%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algorithme smart grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Copyright G.POIDATZ & L.Lixfé, 2021-2022 - All rights reserved

clear all; % pour "vider" les variables (vide le cache)
close all; % pour fermer les figures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constantes

TRAPMF_NULL = parallel.pool.Constant([0 0 0 0]);
SF_FOLDER = parallel.pool.Constant([cd,'/fuzzy_systems/']);
WEIGHT_RATIO = parallel.pool.Constant(2);
PARTITIONNEMENT_MESURE = parallel.pool.Constant(readfis('SF_definition_Csq_floue.fis').input(2));

% chargement des systèmes flous en mémoire

SF10 = readfis([SF_FOLDER.Value,'SF10.fis']);

% caractéristiques génrales du cas d'étude (nom du dossier et nombre
% d'agents)

useCaseId = defineUseCase();

nbAgents = str2num(useCaseId{1});
useCaseFolder = useCaseId{2};

% création du dossier contenant le useCase

mkdir(useCaseFolder);

% nbAgents en intéraction définis par "algorithme_Building" : SF1-SF9
% sauvegarde les données des agents dans nbAgents fichiers

useCaseResults = defineAgent(nbAgents,useCaseFolder);

% fichier contenant les sorties du SF9

pathOfUseCase = [cd,'/',useCaseFolder,'/results_',useCaseFolder,'.bin'];
saveUseCaseResults(pathOfUseCase,useCaseResults);

% aggrégation des sorties des différents immeubles

SF9Aggregation = aggregate(nbAgents,WEIGHT_RATIO.Value,pathOfUseCase);

% SF10

inputVar = {'Capacité V2G / G2V','taux en % prix vente/achat électricité' };
def = {'5 45 55 95','50 90 110 180'};
nom = 'Algorithme Smart Grid';
taille = 1;
answer = inputdlg(inputVar,nom,taille,def);
if isempty(answer);
    disp('action annulée');
    return;
end;

% variables d'entrée floues du SF10

V2GDisponibilite = StringIFT2NumberIFT(answer{1});
prixElectricite = StringIFT2NumberIFT(answer{2});
tensionImmeubleAggregee = [SF9Aggregation-1,SF9Aggregation-1,SF9Aggregation+1,SF9Aggregation+1];

nameOfFinalCsq = 'Mesures Smart Grid'
measure = getSFCsq(SF10,nameOfFinalCsq,tensionImmeubleAggregee,V2GDisponibilite,prixElectricite);

%%% affichage conséquence SF10 %%%

% ci-dessous un nombre magique à modifier par la suite (28/12/21, guillaume
% en a marre^^)
figureNumber = 10;
legendOfFigure = ['G2V-EXP-IC  G2V-EXP  EXP  G2V / V2G  IMP  V2G-IMP  V2G-IMP-DC'];
printCsqFinale(PARTITIONNEMENT_MESURE.Value,measure,figureNumber,nameOfFinalCsq,legendOfFigure);

% msg={'mesures à prendre'};
% msgbox(msg, 'Mesures à prendre');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fonction permettant de définir le useCase

function useCaseDefinition = defineUseCase();
useCaseDefinition = {'7','a'};
questions = {"Combien voulez-vous d'immeubles ?",'Quel nom de fichier ?'};
windowName = "Cas d'étude";
while str2num(useCaseDefinition{1})>5 | exist(useCaseDefinition{2})~=0 ;
    useCaseDefinition = inputdlg(questions,windowName,2,{'',''});
    if isempty(useCaseDefinition);
        disp('action annulée');
        return;
    end;
end;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fonction permettant de définir chaque agent (immeuble)

function useCaseResults = defineAgent(nbAgents,useCaseFolder);
for k=1:nbAgents;
    buildingN = k;
    useCaseResults(k) = algorithme_Building(useCaseFolder,buildingN);
    fprintf('\n');
end;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fonction permettant d'enregistrer le useCase

function saveUseCaseResults(pathOfUseCaseFile,useCaseResults);
pathOfUseCaseFileId = fopen(pathOfUseCaseFile,'w');
fwrite(pathOfUseCaseFileId,useCaseResults,'double');
fclose(pathOfUseCaseFileId);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Méthode d'aggrégation des données - moyenne "déséquilibrée" favorisant la
% plus forte qualification

function aggregation = aggregate(nbAgents,weightRatio,pathOfUseCaseFile);

averageModifier = (weightRatio-1) / (weightRatio+1); 
denOfValueWeight = 2*averageModifier + nbAgents*(1-averageModifier);
highestValueWeight = (1+averageModifier) / denOfValueWeight;
otherValueWeight = (1-averageModifier) / denOfValueWeight;

useCaseResults = getUseCaseResults(pathOfUseCaseFile);
highestValue = max(useCaseResults);

aggregation = highestValueWeight * highestValue + otherValueWeight * (sum(useCaseResults)-highestValue);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fonction permettant de récupérer les données du cas d'étude

function useCaseResults = getUseCaseResults(pathOfUseCaseFile);
pathOfUseCaseFileId = fopen(pathOfUseCaseFile);
useCaseResults = fread(pathOfUseCaseFileId,'double');
fclose(pathOfUseCaseFileId);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algorithme smart grid - caractéristiques immeuble
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Copyright G.POIDATZ & L.Lixfé, 2021-2022 - All rights reserved

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Commentaires généraux concernant le programme
% la fonction trapmf ne prend que 4 paramètres, la hauteur est à 1, si l'on
% veut avoir une hauteur différente de 1, il va falloir modifier un peu le
% programme.
%

function tensionImmeubleNette = algorithme_Building(folder,buildingNumber);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constantes

TRAPMF_NULL = parallel.pool.Constant([0 0 0 0]);
SF_FOLDER = parallel.pool.Constant([cd,'/fuzzy_systems/']);
PARTITIONNEMENT_TENSION_IMMEUBLE = parallel.pool.Constant(readfis('SF_definition_Csq_floue.fis').input(1));

% chargement des systèmes flous en mémoire

SF1 = readfis([SF_FOLDER.Value,'SF1.fis']);
SF2 = readfis([SF_FOLDER.Value,'SF2.fis']);
SF3 = readfis([SF_FOLDER.Value,'SF3.fis']);
SF4 = readfis([SF_FOLDER.Value,'SF4.fis']);
SF5 = readfis([SF_FOLDER.Value,'SF5.fis']);
SF6 = readfis([SF_FOLDER.Value,'SF6.fis']);
SF7 = readfis([SF_FOLDER.Value,'SF7.fis']);
SF8 = readfis([SF_FOLDER.Value,'SF8.fis']);
SF9 = readfis([SF_FOLDER.Value,'SF9.fis']);

% La fonction inputdlg permet de créer une IHM
% Cela permettra certainement de modifier la valeur des variables floues 
% afin de réaliser nos différents cas d'étude

% création d'un tableau de cellules afin de stocker des noms de variables
% utilisés dans l'affichage de l'IHM
prompt = {'Confort chauffage :','Confort éclairage :','Superficie immeuble :',...
    'Densité de personnes :','Isolation thermique :',"Humidité de l'air :",...
    'Température extérieure :','Moment de la journée :','Optimisation des panneaux solaires :',...
    'Saison :','Ensoleillement :','Nombre de panneaux :','Stockage :',...
    };

% Def est la valeur par défaut de nos variable, celle ci pourra être
% mofifiée directement par l'utilisateur en cours de programme dans l'IHM.
def = {'16 19 21 22','75 100 1000 2000','400 800 1300 2500','18 25 45 75','3 3.5 5 6',...
    '30 50 50 70','-6 8 24 37', '7 8 12 13','-90 0 0 90','7 10 10 11','30 50 60 80',...
    '20 40 60 80','25 35 65 75'};


% nom de l'IHM
nom = 'Algorithme Immeuble';

% définit la dimension des cases permettant la saisit de la valeur de
% chaque variable
taille = 1;

% IHM stockée dans answer 
answer = inputdlg(prompt,nom,taille,def);

% si on appuie sur cancel => answer vide. Cela veut dire que l'on souhaite 
% annuler le programme.
if isempty(answer);
    disp('action annulée');
    return;
end;

% la fonction inputdlg sort un tableau de cellules de chaines de caractère.
% Pour faire nos calculs, il faut convertir ces tableaux en IFT
% discrétisés.
confortChauffage = StringIFT2NumberIFT(answer{1});
confortEclairage = StringIFT2NumberIFT(answer{2});
superficieImmeuble = StringIFT2NumberIFT(answer{3});
densitePersonnes = StringIFT2NumberIFT(answer{4});
isolationThermique = StringIFT2NumberIFT(answer{5});
humidite = StringIFT2NumberIFT(answer{6});
temperatureExt = StringIFT2NumberIFT(answer{7});
momentDeLaJournee = StringIFT2NumberIFT(answer{8})+2;
optimisationPanneau = StringIFT2NumberIFT(answer{9});
saison = StringIFT2NumberIFT(answer{10});
ensoleillement = StringIFT2NumberIFT(answer{11});
nombrePanneaux = StringIFT2NumberIFT(answer{12});
stockage = StringIFT2NumberIFT(answer{13});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calcul des conséquences floues finales des différents SF

% SF1
confortUtilisateur = getSFCsq(SF1,'Confort utilisateur',confortChauffage,confortEclairage);
% SF2
besoinImmeuble = getSFCsq(SF2,'Besoin immeuble',TRAPMF_NULL.Value,superficieImmeuble,densitePersonnes,confortUtilisateur);
% SF3
consoEnergetique = getSFCsq(SF3,'Consommation énergétique',TRAPMF_NULL.Value,isolationThermique,besoinImmeuble);
% SF4
conditionsMeteo = getSFCsq(SF4,'Conditions météo',temperatureExt,humidite);
% SF5
besoinElectricite = getSFCsq(SF5,'Besoin en électricité',TRAPMF_NULL.Value,TRAPMF_NULL.Value,momentDeLaJournee,...
    consoEnergetique,conditionsMeteo);
% SF6
electriciteMaxPan = getSFCsq(SF6,'Electricité maximale par panneau',optimisationPanneau,momentDeLaJournee,saison);
% SF7
prodElecSolaire = getSFCsq(SF7,"Production d'électricité solaire",TRAPMF_NULL.Value,ensoleillement,nombrePanneaux,electriciteMaxPan);
% SF8
elecDispo = getSFCsq(SF8,'électricité disponible',TRAPMF_NULL.Value,stockage,prodElecSolaire);

% SF9
% calcul Csq
nameOfSF9Csq = 'tension immeuble';
tensionImmeuble = getSFCsq(SF9,nameOfSF9Csq,TRAPMF_NULL.Value,TRAPMF_NULL.Value,besoinElectricite,elecDispo);

% affichage Csq
titleOfFigure = [nameOfSF9Csq,num2str(buildingNumber)];
legendOfFigure = 'faible moyenne élevée';
[Xd,tensionImmeublePrinted] = printCsqFinale(PARTITIONNEMENT_TENSION_IMMEUBLE.Value,tensionImmeuble,buildingNumber,...
    titleOfFigure,legendOfFigure);

% défuzzyfication modale
tensionImmeubleNette = defuzzyfication(Xd,tensionImmeublePrinted);

% enregistrement des caractéristiques immeubles
immeubleN = ['immeuble','_',num2str(buildingNumber)];
save(folder,prompt,answer,immeubleN); 

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% défuzzyfication conséquence floue finale - algorithme de Zalila - 
% régression - défuzzyfication par méthode modale car fonction non convexe

function CsqFinaleNette = defuzzyfication(Xd,CsqFinale);
hauteur = max(CsqFinale);
j=0;
CsqFinaleNette = 0;
for k=1:length(CsqFinale);
    if CsqFinale(k) == hauteur;
        CsqFinaleNette = CsqFinaleNette+Xd(k); % calcul du noyau
        j = j+1;
    end;
end;
CsqFinaleNette = CsqFinaleNette/j; % valeur moyenne du noyau
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sauvegarde des données d'entrée pour chaque agent (immeuble)

function save(folder,nameOfVar,data,agentN)
nameOfFile = ['data_',agentN,'_',folder,'.txt'];
dataUseCase = fopen([cd,'/',folder,'/',nameOfFile],'w');
for k=1:length(data);
    fprintf(dataUseCase,'%s %s \n',nameOfVar{k},data{k});
end;
fclose(dataUseCase);
end

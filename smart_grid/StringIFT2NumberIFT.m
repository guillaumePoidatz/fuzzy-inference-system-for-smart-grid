%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conversion String to IFT

function listOfNum = StringIFT2NumberIFT(StringIFT);
listOfNum=zeros(130);
k=1;
tamp='';
number=false; % cette variable permet d'éviter de faire un saut d'indice sans aucune saisit 
for i=1:strlength(StringIFT);
    if StringIFT(i)==' ' & number==true ; % remplit le tableau de nombre
        listOfNum(k)=str2double(tamp);
        tamp=''; 
        k=k+1; 
        number=false; 
    elseif StringIFT(i)~=' '; % stocke les différents nombre
        tamp=[tamp,StringIFT(i)];
        number=true;
    end;
    listOfNum(k)=str2double(tamp); % pour la dernière saisit
end;
listOfNum=listOfNum(1:k);
end
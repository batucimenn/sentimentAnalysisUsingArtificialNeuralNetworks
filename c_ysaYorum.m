%% BAŞLANGIÇ
clc;
clear;

%% SABİTLER
DosyaEgitim = 'egitimData.xlsx';
DosyaYorumSonuclar='gercekSonucData.xlsx';
Siniflar={'Pozitif','Negatif'};
DizinTest='testData';

%% VERİ OKUNMASI 
[DataYorum,DataCumle]=xlsread(DosyaEgitim);
DataYorum=DataYorum(:,end);
DataCumle=DataCumle(2:end,2);

% Eğitim girişinin "Token" olarak tanımlanması ve düzenlenmesi
TokenEgitim = tokenizedDocument(DataCumle);
TokenEgitim = lower(TokenEgitim);
TokenEgitim = erasePunctuation(TokenEgitim);     

% Eğitim girişinin sayıllaştırılması
TokenSayisal = wordEncoding(TokenEgitim);
L=max(doclength(TokenEgitim));

%% YSA EĞİTİM
fprintf('\n');
fprintf(' 1. Aşama: YSA Eğitimi gerçekleştiriliyor... \n');

xEgitim = doc2sequence(TokenSayisal,TokenEgitim,'Length',L);
xEgitim = Dosya2YSAGirisData(xEgitim);
yEgitim = Sinif2YSACikisData(Siniflar,DataYorum);

net = patternnet;
net.trainParam.showWindow=false;
net = train(net,xEgitim',yEgitim');   % YSA Eğitilmesi
yyEgitim = net(xEgitim');
[YY,sinifYY] = ysaCikis2Sinif(yyEgitim,Siniflar);

%% YSA TEST
fprintf(' 2. Aşama: YSA Testi başlatılıyor... \n\n');
[DosyaAdi,Dizin] = uigetfile(fullfile(pwd,DizinTest,'*.*'));
fid1=fopen(fullfile(Dizin,DosyaAdi));
Yorum=textscan(fid1,'%s','Delimiter','\n');
Yorum=Yorum{1};
fclose(fid1);

% Test girişinin "Token" olarak tanımlanması ve düzenlenmesi
TokenYorum = tokenizedDocument(Yorum);
TokenYorum = lower(TokenYorum);
TokenYorum = erasePunctuation(TokenYorum);     

xYorum = doc2sequence(TokenSayisal,TokenYorum,'Length',L);
xYorum = Dosya2YSAGirisData(xYorum);
yyYorum = net(xYorum');
[YYYorum,sinifYYYorum] = ysaCikis2Sinif(yyYorum,Siniflar);

% Karşılaştırma
[~,DataCumle]=xlsread(DosyaYorumSonuclar);
p=find(strcmpi(DataCumle(:,1),DosyaAdi)==true);
if isempty(p), error('Seçilen dosya bilgisine ulaşılamadı'); end

fprintf(1,'Değerlendirme Sonucu: \n');
fprintf(1,'Yorum: %s\n',Yorum{1});

fprintf(1,'YSA model sonucu: %s \n',sinifYYYorum{1});
fprintf(1,'    Gerçek sonuç: %s \n',DataCumle{p,2});

z=1;
% >>>>>>>>>>>>>>>>>>>> ANA PROGRAM SONU <<<<<<<<<<<<<<<<<<<<<<<<

function  [YY,sinifYY] = ysaCikis2Sinif(yy,Siniflar)
    YY=zeros(size(yy));
    sinifYY=cell(size(yy,2),1);
    for k=1:size(yy,2)
        
        [~,p]=max(yy(:,k));
        YY(p,k)=1;
        
        sinifYY{k,1}=Siniflar{p};
    end
end

function Y = Sinif2YSACikisData(Siniflar,SinifEgitim)
    Y = nan(size(SinifEgitim,1),length(Siniflar));
    for k = 1: length(SinifEgitim)
        if SinifEgitim(k,1)==1
            Y(k,1)=1;
            Y(k,2)=0;
        else
            Y(k,1)=0;
            Y(k,2)=1;
        end
    end
end

function X = Dosya2YSAGirisData(cellX)
    X=nan(size(cellX,1),size(cellX{1},2));
    for k=1:size(cellX,1)
        X(k,:)=cellX{k,1};
    end
end

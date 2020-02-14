% Source removing script.
% 2019.11.05 QYQ
clear
tic
%% Test
dataDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/BANDEDGE/2bands/ONE/band1';
outDataDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/BANDEDGE/2bands/ONE/band1';
srchParamDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/searchParams/2bands';
FileName = 'GWBsimDataSKASrlz1Nrlz3';
searchParamName = 'searchParams';
ext = '.mat';
bandNum = 1;
SNRcut = 50;

inputFile = strcat(dataDir,filesep,FileName,ext);

load(inputFile);
searchParams = strcat(srchParamDir,filesep,searchParamName,num2str(bandNum),ext);
load(searchParams);
Index = find(omega >= searchParams.angular_velocity(2) & ...
    omega <= searchParams.angular_velocity(1));
binsrcsnr = snr_chr(Index);
Np = simParams.Np;
N = simParams.N;
I = find(binsrcsnr < SNRcut);
ite = length(I);
%I = 33; % debug
%% calcu. timing residual
phiI = zeros(Np,1);
snr_chr2_tmp=zeros(Np,1);  % squared characteristic snr for each pulsar and source
tmp=zeros(1,N); % noiseless timing residuals from a source
timingResiduals_tmp = zeros(Np,N);
for j = 1:ite
    for i=1:1:Np  % number of pulsar
        % GW sky location in Cartesian coordinate
        k=zeros(1,3);  % unit vector pointing from SSB to source
        k(1)=cos(delta(Index(I(j))))*cos(alpha(Index(I(j))));
        k(2)=cos(delta(Index(I(j))))*sin(alpha(Index(I(j))));
        k(3)=sin(delta(Index(I(j))));
        theta=acos(k*simParams.kp(i,:)');
        phiI(i)=mod(phi0(Index(I(j)))-0.5*omega(Index(I(j)))*simParams.distP(i)*(1-cos(theta)), pi); % modulus after division, YW 04/30/14 check original def. of phiI
        
        
        tmp = FullResiduals(alpha(Index(I(j))),delta(Index(I(j))),omega(Index(I(j))),phi0(Index(I(j))),phiI(i),simParams.alphaP(i),...
            simParams.deltaP(i),Amp(Index(I(j))),iota(Index(I(j))),thetaN(Index(I(j))),theta,yr);
        
        timingResiduals_tmp(i,:) = tmp';
        snr_chr2_tmp(i,1) = dot(tmp,tmp)/simParams.sd(i)^2;
        
    end
    
    snr_chr_tmp=sqrt(sum(snr_chr2_tmp,1));  % sum of elements in each column
    
    %% substitute timing residual and SNR
    timingResiduals_tmp1 = timingResiduals - timingResiduals_tmp;
    snr_chr(Index(I(j))) = snr_chr(Index(I(j))) - snr_chr_tmp;
end

newFile = strcat(outDataDir,filesep,FileName,'_rm',ext);
copyfile(inputFile,newFile);
m = matfile(newFile,'Writable',true);
m.timingResiduals = timingResiduals_tmp1;
m.snr_chr = snr_chr;

toc
% EOF
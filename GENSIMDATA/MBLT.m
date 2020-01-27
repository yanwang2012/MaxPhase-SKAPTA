% MBLT Implementation for Multisource
% QYQ 23/11/2019
clear;
tic
%% Set up
simParamsDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/searchParams/2bands';
simParamsName = 'searchParams';
inParamsList = dir([simParamsDir,filesep,simParamsName,'*.mat']);
simDataDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/BANDEDGE/2bands';
estDataDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/BANDEDGE/2bands/MBLT/GWBsimDataSKASrlz1Nrlz3_MBLT1/Results20';
inputFileName = 'GWBsimDataSKASrlz1Nrlz3';

%%%%%%%%%%%%%%%%%%%% DON'T FOGET TO CHANGE THIS %%%%%%%%%%%%%%%%%%%%%%
outputfiles = dir([estDataDir,filesep,'*',inputFileName,'*.mat']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Npara = length(inParamsList);
NestSrc = length(outputfiles);
nFile = dir([estDataDir,filesep,inputFileName,'band1','*.mat']); % count how many iterations are used.
num_ite = length(nFile);
% Load the simulated source parameters.
load([simDataDir,filesep,inputFileName,'.mat']);
estTimRes = zeros(simParams.Np,simParams.N);

%% MBLT
[file,Index]=rassign(estDataDir,outputfiles,NestSrc,simParams,yr);
% disp(["File needs to be skipped: ",file]);
outputFilename = 'GWBsimDataSKASrlz1Nrlz3_MBLT2';
OutputDir = [simDataDir,filesep,outputFilename];
mkdir(OutputDir);
for i = 1:Npara
    for j = 1:NestSrc
        if j <= (i-1)*num_ite || j > i*num_ite
            if j == Index
                continue
            else
%                 disp("j is:"+j);
                path_estData = [estDataDir,filesep,outputfiles(j).name];
                [srcParams]=ColSrcParams(path_estData);
                [~,estTimRes_tmp] = Amp2Snr(srcParams,simParams,yr);
                estTimRes = estTimRes + estTimRes_tmp;
            end
        end
    end
    newFile = strcat(OutputDir,filesep,inputFileName,'band ',num2str(i),'.mat');
    copyfile([simDataDir,filesep,inputFileName,'.mat'],newFile);
    m = matfile(newFile,'Writable',true);
    m.timingResiduals = timingResiduals - estTimRes;
    estTimRes = zeros(simParams.Np,simParams.N);
end


toc
% END
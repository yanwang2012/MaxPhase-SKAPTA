% MBLT Implementation for Multisource
% Developed to handle multiple realizations
% QYQ 1/4/2021

clear;
tic
%% Set up
searchParamsDir = '/Users/qyq/Library/Mobile Documents/com~apple~CloudDocs/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Final/realizations/2bands/searchParams/Band_opt';
searchParamsName = 'searchParams';
simDataDir = '/Users/qyq/Library/Mobile Documents/com~apple~CloudDocs/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Final/realizations/2bands/simData';
simFileBaseName = 'GWBsimDataSKASrlz1Nrlz*'; % change here to switch between multiple and single
NsimFiles = dir([simDataDir,filesep,simFileBaseName,'.mat']);
simFileNames = sort_nat({NsimFiles.name});
[~,fileName_noExt,~] = fileparts(simFileNames);
Nrealizations = length(NsimFiles);
estDataDir = '/Users/qyq/Library/Mobile Documents/com~apple~CloudDocs/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Final/realizations/2bands/Band_opt_results';
inputFileName = 'GWBsimDataSKASrlz1Nrlz*';


% use regular expression to filter file names
FileList = dir([estDataDir,filesep,'*',inputFileName,'.mat']); % get all file names

for r = 1:4 %Nrealizations
    % select searchParams for each realization
    inParamsList = dir([searchParamsDir,filesep,fileName_noExt{r},filesep,searchParamsName,'*.mat']);
    inParamNames = sort_nat({inParamsList.name});
    exp = 'searchParams_Nyquist\d\.mat'; % regular expressions for desire file names
    inParamNames = regexp(inParamNames,exp,'match');
    inParamNames = inParamNames(~cellfun(@isempty,inParamNames)); % get rid of empty cells
    Npara = length(inParamNames);
    
    % set regexp
    FilenameList = sort_nat({FileList.name});
    exp = ['\d+_',fileName_noExt{r},'(?=_|\.mat)_?\d{0,2}.mat'];
    FilenameList = regexp(FilenameList,exp,'match');
    FilenameList = FilenameList(~cellfun(@isempty,FilenameList));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DON'T FORGET TO CHECK THE NAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % nFile = dir([estDataDir,filesep,'1_',inputFileName,num2str(r),'_*.mat']); % count how many iterations are used.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    num_ite = sum(startsWith(string(FilenameList),'1_'));
    %num_ite = length(nFile); % since iteration starts from 0
    
    % Load the simulated source parameters.
    load([simDataDir,filesep,simFileNames{r}]);
    estTimRes = zeros(simParams.Np,simParams.N);
    
    %% xMBLT
    % outputfiles = dir([estDataDir,filesep,'*',inputFileName,num2str(r),'_*.mat']);
    % NestSrc = length(outputfiles);
    % Nband1 = NestSrc/2;
    Nband1 = num_ite;
    NestSrc = Npara * num_ite;
    % outputfilenames = sort_nat({outputfiles.name});
    [file,Index]=rassign(estDataDir,FilenameList,NestSrc,Nband1,simParams,yr);
    % disp(["File needs to be skipped: ",file]);
    %     Filename = ['GWBsimDataSKASrlz1Nrlz',num2str(r)];
    OutputDir = [simDataDir,filesep,'Band_opt_xMBLT'];
    mkdir(OutputDir);
    for i = 1:Npara
        for j = 1:NestSrc
            if j <= (i-1)*num_ite || j > i*num_ite
                if ismember(j,Index) == 1
                    continue
                else
                    %                 disp("j is:"+j);
                    path_estData = [estDataDir,filesep,char(FilenameList{j})];
                    disp(['File loaded: ',char(FilenameList{j})]);
                    [srcParams]=ColSrcParams(path_estData, simParams.Np);
                    [~,estTimRes_tmp] = Amp2Snr(srcParams,simParams,yr);
                    estTimRes = estTimRes + estTimRes_tmp;
                end
            end
        end
        newFile = strcat(OutputDir,filesep,num2str(i),'_',simFileNames{r});
        copyfile([simDataDir,filesep,simFileNames{r}],newFile);
        m = matfile(newFile,'Writable',true);
        m.timingResiduals = timingResiduals - estTimRes;
        estTimRes = zeros(simParams.Np,simParams.N);
    end
end

toc
% END
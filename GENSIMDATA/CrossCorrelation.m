% Cross-Correlation Coefficients Matrix

% Author: QYQ
% 05/13/2020

clear;
tic

%% Dir settings
searchParamsDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/searchParams/2bands/superNarrow';
simdataDir = '~/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11';
estdataDir = '/Users/qyq/Research/PulsarTiming/SimDATA/MultiSource/Investigation/Test11/BANDEDGE/2bands/SuperNarrow/Union_xMBLT2/xMBLT-iMBLT-20';
Filename = 'GWBsimDataSKASrlz1Nrlz3';
ext = '.mat';

%% Files
paraFile = dir([searchParamsDir,filesep,'searchParams','*.mat']);
simFile = [simdataDir,filesep,Filename,ext];
estFile = dir([estdataDir,filesep,'*',Filename,'*',ext]);
Nestsrc = length(estFile);

paraFilename = sort_nat({paraFile.name});
exp = 'searchParams\d.mat'; % regular expressions for desire file names
paraFilename = regexp(paraFilename,exp,'match');
paraFilename = paraFilename(~cellfun(@isempty,paraFilename)); % get rid of empty cells
Nband = length(paraFilename);

estFilename = sort_nat({estFile.name});
load(simFile);

%% Seperate sources into different bands
% Ntsrc = length(alpha); % Number of true sources.
SrcSNR = {};
SrcAlpha = {};
SrcAmp = {};
SrcDelta = {};
SrcIota = {};
SrcOmega = {};
SrcPhi0 = {};
SrcThetaN = {};

for i = 1:Nband
    load([searchParamsDir,filesep,char(paraFilename{i})]);
    Indx = find(omega >= searchParams.angular_velocity(2) & ...
        omega <= searchParams.angular_velocity(1));
    
    SrcSNR{i} = snr_chr(Indx);
    SrcAlpha{i} = alpha(Indx);
    SrcDelta{i} = delta(Indx);
    SrcAmp{i} = Amp(Indx);
    SrcIota{i} = iota(Indx);
    SrcOmega{i} = omega(Indx);
    SrcPhi0{i} = phi0(Indx);
    SrcThetaN{i} = thetaN(Indx);
    
end

%% Sort sources in different bands

for j = 1:Nband
    [~,id] = sort(SrcSNR{j},'descend'); % sort true sources according to SNR value
    SrcSNR{j} = SrcSNR{j}(id);
    SrcAlpha{j} = SrcAlpha{j}(id);
    SrcDelta{j} = SrcDelta{j}(id);
    SrcAmp{j} = SrcAmp{j}(id);
    SrcIota{j} = SrcIota{j}(id);
    SrcOmega{j} = SrcOmega{j}(id);
    SrcPhi0{j} = SrcPhi0{j}(id);
    SrcThetaN{j} = SrcThetaN{j}(id);
end
simSrc = struct('SrcSNR',SrcSNR,'SrcAlpha',SrcAlpha,'SrcDelta',SrcDelta,'SrcAmp',SrcAmp,...
    'SrcIota',SrcIota,'SrcOmega',SrcOmega,'SrcPhi0',SrcPhi0,'SrcThetaN',SrcThetaN); % Simulated sources parameters

%% Get estimated sources info
estsrcBand1 = Nestsrc/Nband; % number of sources in a band.
estsrcBand2 = Nestsrc/Nband;
NestsrcBand = struct('Band1',estsrcBand1,'Band2',estsrcBand2);
EstSrc = {};
for band = 1:Nband
    for k = 1:estsrcBand1
        path_to_estimatedData = [estdataDir,filesep,char(estFilename((band - 1) * estsrcBand1 + k))];
        EstSrc{band,k} = ColSrcParams(path_to_estimatedData);
    end
end

%% Cross-Corelation

% Max Weighted CC
% [rho,rho_max,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR] = MWC(Nband,NestsrcBand,SrcAlpha,SrcDelta,SrcOmega,SrcPhi0,SrcIota,SrcThetaN,SrcAmp,SrcSNR,EstSrc,simParams,yr,'snr');

% Max Weighted Ave. CC
% [rho,rho_max,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR] = MWAC(Nband,NestsrcBand,SrcAlpha,SrcDelta,SrcOmega,SrcPhi0,SrcIota,SrcThetaN,SrcAmp,SrcSNR,EstSrc,simParams,yr,'snr');

% Max over Threshold CC
% [rho,rho_max,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR] = MTC(Nband,NestsrcBand,SrcAlpha,SrcDelta,SrcOmega,SrcPhi0,SrcIota,SrcThetaN,SrcAmp,EstSrc,simParams,yr,0.85);

% Normalized MTC
[rho,rho_max,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR] = NMTC(Nband,NestsrcBand,simSrc,EstSrc,simParams,yr,0.90);


% Minimum distance Maximum CC.
% [rho,rho_max,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR] = MinDMaxC(Nband,NestsrcBand,SrcAlpha,SrcDelta,SrcOmega,SrcPhi0,SrcIota,SrcThetaN,SrcAmp,EstSrc,simParams,yr);

%% Plotting
metric = 'NMTC';
methods = 'True vs Union-xMBLT-iMBLT';
prefix = [estdataDir,filesep,'fig',filesep,metric,'-',methods];
mkdir(prefix);

figname1 = metric;
for fig = 1:Nband
    figure
    imagesc(rho{fig});
    a = colorbar;
    xlabel('True sources')
    ylabel('Estimated sources')
    ylabel(a,'Corss-Correlation Coefficients')
    title(['Band ',num2str(fig)])
    saveas(gcf,[prefix,filesep,figname1,'Band ',num2str(fig)],'png');
    savefig([prefix,filesep,figname1,'Band ',num2str(fig)]);
end


figname2 = [metric,'-SNR'];
for fig2 = 1:Nband
    switch fig2
        case 1
            N = estsrcBand1;
        case 2
            N = estsrcBand2;
    end
    figure
    plot(estSNR(fig2,1:N),rho_max{fig2},'ob')
    xlabel('Estimated SNR')
    ylabel(metric)
    title(['Band ',num2str(fig2)])
    saveas(gcf,[prefix,filesep,figname2,'Band ',num2str(fig2)],'png');
    savefig([prefix,filesep,figname2,'Band ',num2str(fig2)]);
end

% figname3 = [metric,'identified sources'];
%
% for fig = 1:Nband
%     ifreq = arrayfun(@(x) isrc{fig,x}.omega/(2*pi*365*24*3600), 1:length(r{fig}));
%     figure
%     plot(SrcSNR{fig},SrcOmega{fig}/(2*pi*365*24*3600),'ob',estSNR(fig,r{fig}),ifreq,'sr')
%     text(SrcSNR{fig}+0.5,SrcOmega{fig}/(2*pi*365*24*3600), num2str((1:numel(SrcSNR{fig}))'), 'Color', '#0072BD')
%     text(estSNR(fig,r{fig})-2,ifreq, num2str(r{fig}), 'HorizontalAlignment','right', 'Color', '#D95319')
%     title(['Identified Sources Band ',num2str(fig)])
%     xlabel('SNR')
%     ylabel('Frequency(Hz)')
%     legend('True Source','Identified Source')
%     saveas(gcf,[prefix,filesep,figname3,'Band ',num2str(fig)],'png');
%     savefig([prefix,filesep,figname3,'Band ',num2str(fig)]);
% end

figname6 = [metric,'-freq'];

for fig = 1:Nband
    switch fig
        case 1
            N = idsrcBand1;
        case 2
            N = idsrcBand2;
    end
    figure
    plot(dif_freq_max(1:N,fig),rho_max{fig},'ob')
    xlabel('Difference of Freq. Percentage (%)')
    ylabel(metric)
    title(['Band ',num2str(fig)])
    saveas(gcf,[prefix,filesep,figname6,'Band ',num2str(fig)],'png');
    savefig([prefix,filesep,figname6,'Band ',num2str(fig)]);
end

figname7 = [metric,'-RA'];

for fig = 1:Nband
    switch fig
        case 1
            N = idsrcBand1;
        case 2
            N = idsrcBand2;
    end
    figure
    plot(dif_ra_max(1:N,fig),rho_max{fig},'ob')
    xlabel('Difference of RA Percentage (%)')
    ylabel(metric)
    title(['Band ',num2str(fig)])
    saveas(gcf,[prefix,filesep,figname7,'Band ',num2str(fig)],'png');
    savefig([prefix,filesep,figname7,'Band ',num2str(fig)]);
end

figname8 = [metric,'-DEC'];

for fig = 1:Nband
    switch fig
        case 1
            N = idsrcBand1;
        case 2
            N = idsrcBand2;
    end
    figure
    plot(dif_dec_max(1:N,fig),rho_max{fig},'ob')
    xlabel('Difference of DEC Percentage (%)')
    ylabel(metric)
    title(['Band ',num2str(fig)])
    saveas(gcf,[prefix,filesep,figname8,'Band ',num2str(fig)],'png');
    savefig([prefix,filesep,figname8,'Band ',num2str(fig)]);
end


toc
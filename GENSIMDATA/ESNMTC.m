function [gamma,rho,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR1,estSNR2] = ESNMTC(Nband,BandSrc,EstSrc1,EstSrc2,simParams,yr,threshold)
% A function calculates cross-correlation coefficients using NMTC above a chosen
% threshold for different set of estimated sources.
% [gamma,rho,dif_freq_max,dif_ra_max,dif_dec_max,id_max,estSNR1,estSNR2] =
% ESNMTC(Nband,NestsrcBand,EstSrc1,EstSrc2,simParams,yr,threshold)
% gamma: cross-correlation coefficient matrix
% rho: maximum value of rho.
% dif_freq_max: error in frequency.
% dif_ra_max: error in RA.
% dif_dec_max: error in DEC.
% id_max: index of sources which reach the maximum of coefficients.
% estSNRx: SNR value for estimated sources.
% Nband: number of band.
% BandSrc: band sources info for each band.
% EstSrcx: cell collects all the parameters of estimated source.
% simParams: pulsar config.
% yr: observation span.
% threshold: a threshold chosen by user.

% Author: QYQ 5/24/2020

%% Cross-Corelation
Np = simParams.Np; % number of pulsars
deltaP = simParams.deltaP;
alphaP = simParams.alphaP;
kp = simParams.kp;
% distP = simParams.distP;

rho_tmp = zeros(Np,1);

rho = {}; % cross-correlation coefficients matrix
gamma = cell(1,2); % averaged cross-correlation coefficients

% investigations
MestSrc1Band = max(BandSrc.NestSrc1band1,BandSrc.NestSrc1band2); % choose the greater number of sources as the dimension
NestSrc2 = BandSrc.NestSrc2Band;
estSNR1 = zeros(Nband,MestSrc1Band);
estSNR2 = zeros(Nband,BandSrc.NestSrc2Band);
% dif_freq = {}; % frequency difference
% dif_ra = {};
% dif_dec = {};

id_max = zeros(MestSrc1Band,Nband); % index of max. cc
dif_freq_max = zeros(MestSrc1Band,Nband);
dif_ra_max = zeros(MestSrc1Band,Nband);
dif_dec_max = zeros(MestSrc1Band,Nband);


for band = 1:Nband
    if BandSrc.NestSrc1band1 ~= BandSrc.NestSrc1band2
        switch band
            case 1
                NestSrc1 = BandSrc.NestSrc1band1; % number of Est. Src1 sources in band 1
            case 2
                NestSrc1 = BandSrc.NestSrc1band2;
        end
    else
        NestSrc1 = BandSrc.NestSrc1band1; % choose any band src.
    end
    gamma{band} = zeros(NestSrc2,NestSrc1); % initialize the gamma cell.
    % search along y-axis
    for src1 = 1:NestSrc1
        [snr1,~] = Amp2Snr(EstSrc1{band,src1},simParams,yr); % get SNR for estimated source
        estSNR1(band,src1) = snr1;
        
        for src2 = 1:NestSrc2
            [snr2,~] = Amp2Snr(EstSrc2{band,src2},simParams,yr); % get SNR for estimated source
            estSNR2(band,src2) = snr2;
            %             tmp_true = 0; % for gamma star
            %             tmp_est1 = 0;
            %             tmp2 = 0;
            for psr = 1:Np
                % GW sky location in Cartesian coordinate
                k=zeros(1,3);  % unit vector pointing from SSB to source
                k(1)=cos(EstSrc1{band,src1}.delta)*cos(EstSrc1{band,src1}.alpha);
                k(2)=cos(EstSrc1{band,src1}.delta)*sin(EstSrc1{band,src1}.alpha);
                k(3)=sin(EstSrc1{band,src1}.delta);
                theta=acos(k*kp(psr,:)');
                %sprintf('%d pulsar theta=%g',i,theta)
                %phiI(i)=mod(phi0-omega*distP(i)*(1-cos(theta)), 2*pi);  % modulus after division
                %phiI(i)=mod(2*phi0-omega_tmp(l)*distP(i)*(1-cos(theta)), pi);  % modulus after division, YW 09/10/13
                %                 phiI(psr)=mod(EstSrc1{band,tsrc}.phi0-0.5*EstSrc1{band,tsrc}.omega*distP(psr)*(1-cos(theta)), pi);  % modulus after division, YW 04/30/14 check original def. of phiI
                
                tmp = FullResiduals(EstSrc1{band,src1}.alpha,EstSrc1{band,src1}.delta,EstSrc1{band,src1}.omega,EstSrc1{band,src1}.phi0,EstSrc1{band,src1}.phiI(psr),alphaP(psr),deltaP(psr),...
                    EstSrc1{band,src1}.Amp,EstSrc1{band,src1}.iota,EstSrc1{band,src1}.thetaN,theta,yr); % timing residuals for true src
                
                tmp_est = FullResiduals(EstSrc2{band,src2}.alpha,EstSrc2{band,src2}.delta,EstSrc2{band,src2}.omega,EstSrc2{band,src2}.phi0,EstSrc2{band,src2}.phiI(psr),alphaP(psr),deltaP(psr),...
                    EstSrc2{band,src2}.Amp,EstSrc2{band,src2}.iota,EstSrc2{band,src2}.thetaN,theta,yr); % timing residuals for estimated source
                
                %                 tmp_est1 = tmp_est1 + norm(tmp_est);
                %                 tmp_true = tmp_true + norm(tmp); % for gamma star
                
                rho_tmp(psr,src2) = abs(tmp' * tmp_est/(norm(tmp)*norm(tmp_est))); % cross-correlation
                %                 rho_tmp(psr,tsrc) = tmp' * tmp_est/(norm(tmp)*norm(tmp_est)); % don't use abs.
                
                %                 tmp2 = tmp2 + rho_tmp(psr,tsrc) * norm(tmp_est);
                %                 tmp2 = tmp2 + rho_tmp(psr,tsrc) * norm(tmp); % for gamma star
                
            end
            
        end
        above_threshold = sum(rho_tmp > threshold);
        [~,id_max(src1,band)] = max(above_threshold);
        
        %         gamma{band}(src,id_max(src,band)) = max(rho_tmp(:,id_max(src,band))); % maximize method
        gamma{band}(id_max(src1,band),src1) = sum(rho_tmp(:,id_max(src1,band))) / Np; % nomalized over Np (1000) pulsars.
    end
    
    rho_tmp = zeros(Np,1); % need to re-init. rho_tmp when change band, in case the size of rho_tmp is changing
    
    rho{band} = max(gamma{band},[],2); % get index of true sources when rho reaches maximum
    
    %     dif_freq_max(:,band) = abs(arrayfun(@(x) EstSrc{band,x}.omega, 1:NestsrcBand) - SrcOmega{band}(id_max(:,band)')) / (365*24*3600*2*pi); % convert to Hz
    dif_freq_max(1:NestSrc1,band) = arrayfun(@(x) abs(EstSrc1{band,x}.omega - EstSrc2{band,id_max(x,band)}.omega) * 100 / EstSrc2{band,id_max(x,band)}.omega, 1:NestSrc1); % error as percentage
    %     dif_ra_max(:,band) = abs(arrayfun(@(x) EstSrc{band,x}.alpha, 1:NestsrcBand) - SrcAlpha{band}(id_max(:,band)'));
    dif_ra_max(1:NestSrc1,band) = arrayfun(@(x) abs(EstSrc1{band,x}.alpha - EstSrc2{band,id_max(x,band)}.alpha) * 100 / EstSrc2{band,id_max(x,band)}.alpha, 1:NestSrc1); % error as percentage
    %     dif_dec_max(:,band) = abs(arrayfun(@(x) EstSrc{band,x}.delta, 1:NestsrcBand) - SrcDelta{band}(id_max(:,band)'));
    dif_dec_max(1:NestSrc1,band) = arrayfun(@(x) abs(EstSrc1{band,x}.delta - EstSrc2{band,id_max(x,band)}.delta) * 100 / EstSrc2{band,id_max(x,band)}.delta, 1:NestSrc1); % error as percentage
end
%% (1) - Define sparse and dense grid
clear all;

%Sparse Lebedev Grid
%Azimuth, Colatitude, Weight
Ns = 3;
sgS = supdeq_lebedev([],Ns); %according to paper Ns=3 --> 26 sampling points

%Dense Fliege Grid (Target grid for upsampling) according to paper
%Azimuth, Colatitude, Weight

Nd = 29;  % mca paper upsampling fliege grid with N = 29
%Nd = input('Enter SH Order for upsampling: ');
sgD = supdeq_fliege(Nd);

%% (2) - Get sparse HRTF set

%HRIRdataset_measured_SOFA = SOFAload('materials/HUTUBS_HRIRs/pp91_HRIRs_measured.sofa'); 
%SHcoeffficiets_measured = load('materials/HUTUBS_HRIRs/pp91_SHcoefficients_measured.mat'); % SHcoeffficiets_measured

%According to the paper simulated HRIR are used
% subject 91 HRIR-Datasets
HRIRdataset_simulated_SOFA = SOFAload('materials/HUTUBS_HRIRs/pp91_HRIRs_simulated.sofa'); % HRIR--> p(t) data 1730X256
SHcoeffficiets_simulated = load('materials/HUTUBS_HRIRs/pp91_SHcoefficients_simulated.mat'); % SHcoeffficiets 1296X129

ref = SHcoeffficiets_simulated;
samplingGrid = sgS;
mode = 'DEG';
channel = 2;
transformCore = 'ak';
[sparseHRTFdataset.HRTF_L, sparseHRTFdataset.HRTF_R] = supdeq_getArbHRTF_HUTUBS(ref,samplingGrid,mode,channel,transformCore);

NmaxSparse= Ns;
FFToversize = 1; % ----> figure out the right fftoversize ...
sparseGrid = sgS;

%Fill struct with additional info
sparseHRTFdataset.f = ref.HRIR.f;
sparseHRTFdataset.fs = ref.HRIR.f(end)*2;
sparseHRTFdataset.Nmax = NmaxSparse;
sparseHRTFdataset.FFToversize = FFToversize;
sparseHRTFdataset.samplingGrid = sparseGrid;
if isfield(ref,'ReceiverPosition')
    sparseHRTFdataset.sourceDistance = ref.ReceiverPosition;
end

sparseHRTF = sparseHRTFdataset;


%% (3) - Perform spatial upsampling to dense grid

headRadius = 0.0889; % set head Radius according to paper subject 91

% according to paper: N interpolation SH Order [1 2 3 4 5]

%Interpolation / upsampling with SH interpolation but without any
%pre/post-processing ('none'), called SH here
%interpHRTF_sh = supdeq_interpHRTF(sparseHRTF,sgD,'None','SH',nan,headRadius);

%Interpolation / upsampling with SUpDEq time alignment and SH
%interpolation, called 'conventional'
interpHRTF_con = supdeq_interpHRTF(sparseHRTF,sgD,'SUpDEq','SH',nan,headRadius);

%Interpolation / upsampling with MCA interpolation, i.e., in this example
%SUpDEq time alignment and SH interpolation plus post-interpolation
%magnitude correction, as described in the paper
%Maximum boost of magnitude correction set to inf (unlimited gain), 
%resulting in no soft-limiting (as presented in the paper)
%The other MCA settings are by default as described in the paper, i.e.:
% (a) Magnitude-correction filters are set to 0dB below spatial aliasing
% frequency fA
% (b) Soft-limiting knee set to 0dB (no knee)
% (c) Magnitude-correction filters are designed as minimum phase filters
interpHRTF_mca = supdeq_interpHRTF(sparseHRTF,sgD,'SUpDEq','SH',inf,headRadius,[],[],[],[],[],false);

% with ILD-filter applied on the averted side
interpHRTF_ild = supdeq_interpHRTF(sparseHRTF,sgD,'SUpDEq','SH',inf,headRadius);

%The resulting datasets can be saved as SOFA files using the function
%supdeq_writeSOFAobj

%% (4) - Optional: Get reference HRTF set
% 
% %Get reference dataset (using the "supdeq_getSparseDataset" function for
% %convenience here)
% refHRTF = supdeq_getSparseDataset(sgD,Nd,44,'ku100');
% 
% %Also get HRIRs
% refHRTF.HRIR_L = ifft(AKsingle2bothSidedSpectrum(refHRTF.HRTF_L.'));
% refHRTF.HRIR_L = refHRTF.HRIR_L(1:end/refHRTF.FFToversize,:);
% refHRTF.HRIR_R = ifft(AKsingle2bothSidedSpectrum(refHRTF.HRTF_R.'));
% refHRTF.HRIR_R = refHRTF.HRIR_R(1:end/refHRTF.FFToversize,:);
% 
% %% (5) - Optional: Plot HRIRs
% % 
% %Plot frontal left-ear HRIR (Az = 0, Col = 90) of conventional, MCA and ILD-Filter
% %interpolated dataset. Differences are small.
% idFL = 16; %ID in sgD
% supdeq_plotIR(interpHRTF_con.HRIR_L(:,idFL),interpHRTF_mca.HRIR_L(:,idFL),[],[],8);
% 
% %Plot contralateral left-ear HRIR (Az = 270, Col = 90) of SH-only and MCA
% %interpolated dataset. Differences are strong
% idCL = 2042; %ID in sgD
% supdeq_plotIR(interpHRTF_sh.HRIR_L(:,idCL),interpHRTF_mca.HRIR_L(:,idCL),[],[],8);
% 
% %Plot contralateral left-ear HRIR (Az = 270, Col = 90) of conventional and MCA
% %interpolated dataset. Differences are still significant.
% supdeq_plotIR(interpHRTF_con.HRIR_L(:,idCL),interpHRTF_mca.HRIR_L(:,idCL),[],[],8);
% 
% %Plot contralateral left-ear HRIR (Az = 270, Col = 90) of SH-only 
% %interpolated dataset and reference.
% supdeq_plotIR(interpHRTF_sh.HRIR_L(:,idCL),refHRTF.HRIR_L(:,idCL),[],[],8);
% 
% %Plot contralateral left-ear HRIR (Az = 270, Col = 90) of conventional 
% %interpolated dataset and reference.
% supdeq_plotIR(interpHRTF_con.HRIR_L(:,idCL),refHRTF.HRIR_L(:,idCL),[],[],8);
% 
% %Plot contralateral left-ear HRIR (Az = 270, Col = 90) of MCA 
% %interpolated dataset and reference.
% %MCA interpolated HRTF is much closer to the reference than HRTF from
% %conventional interpolation. The "bump" above 10 kHz is corrected through
% %the magnitude correction. Interpolation errors (in this case spatial
% %aliasing errors at the contralateral ear) are reduced
% supdeq_plotIR(interpHRTF_mca.HRIR_L(:,idCL),refHRTF.HRIR_L(:,idCL),[],[],8);
% 
% %% (6) - Optional: Calculate log-spectral difference 
% 
% %Calculate left-ear log-spectral differences in dB.
% %Log-spectral difference is often used as a measure for spectral distance
% %between a reference and an interpolated HRTF set. Not the same as 
% %the magnitude error in auditory filters presented in the paper!
% 
% lsd_sh =  supdeq_calcLSD_HRIR(interpHRTF_sh.HRIR_L,refHRTF.HRIR_L,fs,16);
% lsd_con = supdeq_calcLSD_HRIR(interpHRTF_con.HRIR_L,refHRTF.HRIR_L,fs,16);
% lsd_mca = supdeq_calcLSD_HRIR(interpHRTF_mca.HRIR_L,refHRTF.HRIR_L,fs,16);
% 
% %Quick plot of log-spectral difference averaged over all directions of the
% %2702-point Lebedev grid. As shown in the paper, MCA provides the most
% %significant benefit in the critical contralateral region. Thus, when 
% %averaging over all positions, the benefit of MCA seems smaller. The
% %analysis in the paper as well as the provided audio examples reveal
% %in much more detail the considerable improvements that the proposed 
% %magnitude correction provides.
% AKf(18,9);
% semilogx(lsd_sh.f,lsd_sh.lsd_freq,'LineWidth',1.5);
% hold on;
% semilogx(lsd_con.f,lsd_con.lsd_freq,'LineWidth',1.5);
% semilogx(lsd_mca.f,lsd_mca.lsd_freq,'LineWidth',1.5);
% xlim([500 20000])
% legend('SH W/O MC','SH SUpDEq W/O MC','SH SUpDEq W/ MC','Location','NorthWest');
% xlabel('Frequency in Hz');
% ylabel('Log-Spectral Difference in dB');
% grid on;
% 
% %% (7) - Optional: Calculate magnitude error in auditory filters (similar to paper)
% 
% % Left ear
% %[erb_sh,fc_erb] = AKerbError(interpHRTF_sh.HRIR_L,refHRTF.HRIR_L, [50 fs/2], fs);
% %erb_con = AKerbError(interpHRTF_con.HRIR_L,refHRTF.HRIR_L, [50 fs/2], fs);
% %erb_mca = AKerbError(interpHRTF_mca.HRIR_L,refHRTF.HRIR_L, [50 fs/2], fs);
% 
% % Right ear
% [erb_sh,fc_erb] = AKerbError(interpHRTF_sh.HRIR_R,refHRTF.HRIR_R, [50 fs/2], fs);
% erb_con = AKerbError(interpHRTF_con.HRIR_R,refHRTF.HRIR_R, [50 fs/2], fs);
% erb_mca = AKerbError(interpHRTF_mca.HRIR_R,refHRTF.HRIR_R, [50 fs/2], fs);
% 
% %Quick plot of absolute magnitude error in auditory filters averaged over all
% %directions of the 2702-point Lebedev grid. 
% AKf(18,9);
% semilogx(fc_erb,mean(abs(erb_sh),2),'LineWidth',1.5);
% hold on;
% semilogx(fc_erb,mean(abs(erb_con),2),'LineWidth',1.5);
% semilogx(fc_erb,mean(abs(erb_mca),2),'LineWidth',1.5);
% xlim([500 20000])
% legend('SH W/O MC','SH SUpDEq W/O MC','SH SUpDEq W/ MC','Location','NorthWest');
% xlabel('Frequency in Hz');
% ylabel('\DeltaG(f_c) in dB');
% grid on;

%% (8) Compare HRTF of the Reference set with the interpolated HRTF of ^H and the magnitude-corrected interpolated HRTF of ^H_C with the applied ILD-Filter

% ref = SHcoeffficiets_simulated;
% samplingGrid = sgD;
% mode = 'DEG';
% channel = 2;
% transformCore = 'ak';
% [denseHRTFdataset.HRTF_L, denseHRTFdataset.HRTF_R] = supdeq_getArbHRTF_HUTUBS(ref,samplingGrid,mode,channel,transformCore);
% 
% NmaxSparse= Ns;
% FFToversize = 1; % ----> figure out the right fftoversize ...
% denseGrid = sgD;
% 
% %Fill struct with additional info
% denseHRTFdataset.f = ref.HRIR.f;
% denseHRTFdataset.fs = ref.HRIR.f(end)*2;
% denseHRTFdataset.Nmax = NmaxSparse;
% denseHRTFdataset.FFToversize = FFToversize;
% denseHRTFdataset.samplingGrid = sparseGrid;
% if isfield(ref,'ReceiverPosition')
%     denseHRTFdataset.sourceDistance = ref.ReceiverPosition;
% end
% 
% ref_HRTF = denseHRTFdataset;

%Get reference data
FFToversize_ref = 1; %Set FFT-Blocksize
sparseHRIRdataset_SOFA = HRIRdataset_simulated_SOFA;
%Convert reference  hrir to hrtf
ref_HRTF = supdeq_sofa2hrtf(sparseHRIRdataset_SOFA, Nd,[],FFToversize);

% add SH Order to struct for further processing
ref_HRTF.N = Nd;

%Get SampelingGrid of the ref and interpolated data
ref_HRTF_sampgrid = ref_HRTF.samplingGrid(:,1:2);
intpHRTF_con_sampgrid = interpHRTF_con.samplingGrid(:,1:2);
intpHRTF_mca_sampgrid = interpHRTF_mca.samplingGrid(:,1:2);
intpHRTF_ild_sampgrid = interpHRTF_ild.samplingGrid(:,1:2);

% set coordinate_system --> grids are generate with [180° 90° 0°]
%coordinate_system = input('Enter 0 for elevation: [90° 0° -90°] and enter 1 for elevation: [180° 90° 0°]: '); % N:180° S:0°

%default angle:
% azimuth: [0, 90, 180, 270]
% elevation: [90, 0 -90]

% --generate grid with supdeq_lebedev() or supdeq_fliege() -> always [180°90°0°]--

% --> enter 1 to adapt the angles to [90° 0° -90°]
%coordinate_system = input('Enter 0 for elevation: [90° 0° -90°] 
% and enter 1 for elevation: [180° 90° 0°]: '); % N:180° S:0°


%if coordinate_system
    %Adjust Elevation angle according to Magnitude-Corrected and Time-Aligned
    %Interpolation of Head-Related Transfer Functions Paper if
    %Dataset-coordinates are differ
    ref_HRTF_sampgrid(:,2) = ref_HRTF.samplingGrid(:,2)-90;
    intpHRTF_con_sampgrid(:,2) = interpHRTF_con.samplingGrid(:,2)-90;
    intpHRTF_mca_sampgrid(:,2) = interpHRTF_mca.samplingGrid(:,2)-90;
    intpHRTF_ild_sampgrid(:,2) = interpHRTF_ild.samplingGrid(:,2)-90;

%end

%Set azimuth and elevation angle
azimuth = input('Enter azimuth angle: ');
elevation = input('Enter elevation angle: ');

%Set Target angle [azimuth elevation]
target = [azimuth, elevation];

%Get angle for the facing side of the source
azimuthVector_ip = ref_HRTF.samplingGrid(:,1,1);
iEarsideOrientation_ip = zeros(length(ref_HRTF.samplingGrid),1);
iEarsideOrientation_ip(azimuthVector_ip == 0 | azimuthVector_ip == 180) = 0; %Center
iEarsideOrientation_ip(azimuthVector_ip > 0 & azimuthVector_ip < 180) = 1; %Left ear
iEarsideOrientation_ip(azimuthVector_ip > 180 & azimuthVector_ip < 360) = -1; %Right ear

%Find the nearest coordinates next to the target values
%(Should always be the same idx only for test purposes)
diff_refHRTF = sum(abs(ref_HRTF_sampgrid - target),2);
diff_intpHRTF_con = sum(abs(intpHRTF_con_sampgrid - target),2);
diff_intpHRTF_mca = sum(abs(intpHRTF_mca_sampgrid - target),2);
diff_intpHRTF_ild = sum(abs(intpHRTF_ild_sampgrid - target),2);

%Get index of the target angle
[~, idx_refHRTF] = min(diff_refHRTF);
[~, idx_intpHRTF_con] = min(diff_intpHRTF_con);
[~, idx_intpHRTF_mca] = min(diff_intpHRTF_mca);
[~, idx_intpHRTF_ild] = min(diff_intpHRTF_ild);

%Set L & R marker 
if iEarsideOrientation_ip(idx_refHRTF) == 1 %Left ear

    [max_mc,idx_max_mc] = max(20*log10(abs(interpHRTF_mca.HRTF_L(idx_intpHRTF_mca,:))));
    max_interpHRTF_mca = 20*log10(abs(interpHRTF_mca.HRTF_L(idx_intpHRTF_mca,idx_max_mc)));
    value_other_channel = 20*log10(abs(interpHRTF_mca.HRTF_R(idx_intpHRTF_mca,idx_max_mc)));
    upper_lab = 'L';
    lower_lab = 'R';

elseif iEarsideOrientation_ip(idx_refHRTF) == -1 %Right ear

   [max_mc,idx_max_mc] = max(20*log10(abs(interpHRTF_mca.HRTF_R(idx_intpHRTF_mca,:))));
   max_interpHRTF_mca = 20*log10(abs(interpHRTF_mca.HRTF_R(idx_intpHRTF_mca,idx_max_mc)));
   value_other_channel = 20*log10(abs(interpHRTF_mca.HRTF_L(idx_intpHRTF_mca,idx_max_mc)));
   upper_lab = 'R';
   lower_lab = 'L';

elseif iEarsideOrientation_ip(idx_refHRTF) == 0 %Center --> test with center == L 
   [max_mc,idx_max_mc] = max(20*log10(abs(interpHRTF_mca.HRTF_R(idx_intpHRTF_mca,:))));
   max_interpHRTF_mca = 20*log10(abs(interpHRTF_mca.HRTF_R(idx_intpHRTF_mca,idx_max_mc)));
   value_other_channel = 20*log10(abs(interpHRTF_mca.HRTF_L(idx_intpHRTF_mca,idx_max_mc)));
   upper_lab = 'R';
   lower_lab = 'L';

end

%Plot the reference, conv. time aligned and mca + ILD-Filter HRTF's at
% desired coordinates to compare

AKf(18,9);
%Reference HRTF
p1 = semilogx(ref_HRTF.f,20*log10(abs(ref_HRTF.HRTF_L(idx_refHRTF,:))) ...
    ,'LineWidth',2.0,'Color',[0,0,66]/255); %,'alpha', 0.8);
hold on;
p2 = semilogx(ref_HRTF.f,20*log10(abs(ref_HRTF.HRTF_R(idx_refHRTF,:))) ...  
    ,'LineWidth',2.0,'Color',[0,0,66]/255);  %,'alpha', 0.8);

%Conventional HRTF 
p3 = semilogx(interpHRTF_con.f,20*log10(abs(interpHRTF_con.HRTF_L(idx_intpHRTF_con,:))), ... 
    'LineWidth',2.0,'Color',[160,160,160]/255);
p4 = semilogx(interpHRTF_con.f,20*log10(abs(interpHRTF_con.HRTF_R(idx_intpHRTF_con,:))), ... 
    'LineWidth',2.0,'Color',[160,160,160]/255);

%Mca HRTFT + ILD-filter on the averted side
p5 = semilogx(interpHRTF_ild.f,20*log10(abs(interpHRTF_ild.HRTF_L(idx_intpHRTF_ild,:))) ... 
    ,'LineWidth',2.0,'Color',[0,255,0]/255);
p6 = semilogx(interpHRTF_ild.f,20*log10(abs(interpHRTF_ild.HRTF_R(idx_intpHRTF_ild,:))) ... 
    ,'LineWidth',2.0,'Color',[0,255,0]/255);

%Mca HRTFT
p7 = semilogx(interpHRTF_mca.f,20*log10(abs(interpHRTF_mca.HRTF_L(idx_intpHRTF_mca,:))) ... 
    ,'LineWidth',2.0,'Color',[255,102,102]/255);
p8 = semilogx(interpHRTF_mca.f,20*log10(abs(interpHRTF_mca.HRTF_R(idx_intpHRTF_mca,:))) ... 
    ,'LineWidth',2.0,'Color',[255,102,102]/255);

xlabel('Frequency in Hz','LineWidth',14);
ylabel('Magnitude in dB','LineWidth',14);
title('HUTUBS Subject 91')
grid on;

xlim([interpHRTF_mca.f(1) interpHRTF_mca.f(end)])

legend([p1,p3,p5,p7],'$H_{\mathrm{R}}$','$\widehat{H}$','$\widehat{H}_{\mathrm{ILD}}$','$\widehat{H}_{\mathrm{C}}$', ...
    'Interpreter','latex','FontSize',20,'Location','southwest');

xlim = get(gca, 'XLim');
ylim = get(gca, 'YLim');

str = sprintf(' = (%.2f, %.2f)',[intpHRTF_mca_sampgrid(idx_intpHRTF_mca,1),intpHRTF_mca_sampgrid(idx_intpHRTF_mca,2)]);
combinedStr = strcat('$\Omega$ ',str);
text(xlim(1)+250, ylim(2)-3,combinedStr ,'Interpreter','latex','FontSize',20,'FontWeight','bold')

%combinedStr = ['N = ',num2str(Nd)];
%text(xlim(1)+250, ylim(2)-3,combinedStr ,'Interpreter','latex','FontSize',20,'FontWeight','bold')

%Set R and L text
text(interpHRTF_mca.f(idx_max_mc), max_interpHRTF_mca + 1.5,upper_lab,'FontSize',24,'FontWeight','bold')
text(interpHRTF_mca.f(idx_max_mc), value_other_channel - 1.5,lower_lab,'FontSize',24,'FontWeight','bold')
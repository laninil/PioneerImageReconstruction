%>@brief Brief description of the function
%>
%> An example of image reconstruction for time domain modality 
%> based on MC
%>

%% ADD PATHS (temporary)
addpath(genpath('./'))
% mc 
% fld_my = '/media/jiang/WD10T/Data/Projects/NIROTreconstruction/RECONSTRUCTION_MATLAB';
% addpath([fld_my '/src/']);
% addpath([fld_my '/config/']);

% nirfast
% addpath('/media/jiang/WD10T/Data/Projects/NIROTreconstruction/RECONSTRUCTION_NIRFAST2019/')

%% flags
isCombRep = 0
isGenerateMesh = 1

%% folders
FOLDER = ['/media/jiang/WD10T/Data/Projects/NIROTreconstruction/PioneerMeasurement2021/Data/']
flag_prj = '/lp_20210615_depth2incl/lq_dist_11_6/';
fldr = [FOLDER flag_prj];
% file = [fldr '/laser-lqp_longexp.hdf5'];
Prefix = 'laser';
waveList = [689 725  ];
srcList =  [1:11];
depth_list = [10  15 20 25 30]; % depth [mm]
distance_list = 8;%  lateral distance [mm]
rep_list = 1:100;
group_list = {'target_48.5_-1.5_26_-41.76',... % depth > 71 mm
   'target_48.5_66_26_-41.76',... % depth = 5 mm
   'target_48.5_61_26_-41.76',... % depth = 10 mm
   'target_48.5_56_26_-41.76',...% depth = 15 mm
   'target_48.5_51_26_-41.76',...% depth = 20 mm
   'target_48.5_46_26_-41.76'}; % depth = 25 mm

%% STAGE 1 Preparation 
%% Step 1a: define imaging modality 
nirot.ImagingModality = 'TD';
nirot.ReconstructionDataType = 'FD'; % single frequency
%% Step 1b: define forward model
% add corresponding forward package
nirot.Model = 'MC';
%% Step 1c: define tissue  
% nirot.Volume.Name = 'colin27_v3';
% nirot.Volume.Path = '/media/jiang/WD10T/Data/SoftwarePackages/mcx2021/mcxlab/examples/colin27_v3.mat';
nirot.Volume.Name = 'Slab';
nirot.Volume.Path = [];
%% Step 1d: get positions of sources and detectors
% get the positions from the Martin tapping experiment
% (homogeneous tissue)
nirot.probe.type = 'Flat';
nirot.det.pixel = 1.09;
nirot.det.fovC = [15 15] % approximate center of FOV
nirot.det.ratioR = 0.87; % ratio of FOV region
nirot.det.modelCenter = [45 45];
nirot.wavelengths = [689 725 ];
nirot.iwav = 2;
% measured data for calibration
i_group = 1;
wav = num2str(nirot.wavelengths(nirot.iwav))
group = group_list{i_group};
fldr_r = [fldr '/' 'timing_data_corrected/' group]
flnm_h_r={['/timing_response_' Prefix '_' ...
    wav '_'], '.mat'};
nirot.calibration.dataPath = [fldr_r flnm_h_r];
nirot.src.num = [1:11];

[pos nirot] = getSourceDetector(nirot.calibration.dataPath,...
    nirot);

%% Step 1e: prepare measured data 



%% STAGE 2: Forward simulation
%% Step 2a: create tissue volume / mesh

%load Colin27 brain atlas
load nirot.Volume.Path
nirot.cfg.vol = colin27

%% Step 2b: add optical properties
nirot.cfg.prop=[         0         0    1.0000    1.0000 % background/air
    0.0190    7.8182    0.8900    1.3700 % scalp
    0.0190    7.8182    0.8900    1.3700 % skull
    0.0040    0.0090    0.8900    1.3700 % csf
    0.0200    9.0000    0.8900    1.3700 % gray matters
    0.0800   40.9000    0.8400    1.3700 % white matters
         0         0    1.0000    1.0000]; % air pockets

%% Step 2c: add sources and detectors

%load source detector from Step 1d

 
%% Step 2d: calculation of forward results

% MCX simulation
forwardTimeMC

%% STAGE 3: Image reconstruction
%% Step 3a: calibration of measured data

%% Step 3b: image reconstruction
reconstructionFD


 
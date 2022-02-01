%>@brief Brief description of the function (not finished
%>
%> An example of image reconstruction for time domain modality 
%> based on FEM (Nirfast)
%> author: jingjing jiang jing.jing.jiang@outlook.com
%% ADD PATHS (temporary)
addpath(genpath('./'))
% path_mcxlab = '/media/jiang/WD10T/Data/SoftwarePackages/mcx2021/';
% addpath(genpath(path_mcxlab))
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
Prefix = 'laser';
waveList = [689 725  ];
% ISS measured result
muas_bulk = [0.004  0.0045   ]  ;
mus_r_bulk = [0.648  0.593  ] ;  % estimated 2021.06.22 [mm-1]

srcList =  [1:11];
depth_list = [10  15 20 25 30]; % depth [mm]
distance_list = 8;%  lateral distance [mm]
rep_list = 1:100;
group_list = {'target_48.5_-1.5_26_-41.76',... % depth > 71 mm
      'target_48.5_61_26_-41.76'  %   depth = 25 mm
 }; % depth = 25 mm

%% STAGE 1 Preparation 
%% Step 1a: define imaging modality 
nirot.ImagingModality = 'TD';
nirot.ReconstructionDataType = 'FD'; % single frequency
%% Step 1b: define forward model
% add corresponding forward package
nirot.Model = 'FEM';
%% Step 1c: define tissue  
% nirot.Volume.Name = 'colin27_v3';
% nirot.Volume.Path = '/media/jiang/WD10T/Data/SoftwarePackages/mcx2021/mcxlab/examples/colin27_v3.mat';
nirot.Volume.Name = 'Cylinder';
nirot.Volume.Path = [];
%% Step 1d: get positions of sources and detectors
% get the positions from the Martin tapping experiment
% (homogeneous tissue)
nirot.probe.type = 'Flat';
nirot.det.pixel = 1.09;
nirot.det.fovC = [15 15] % approximate center of FOV
nirot.det.ratioR = 0.87; % ratio of FOV region
nirot.det.modelCenter = [45 45];
% nirot.det.modelCenter = [30 30];

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
nirot.repetitionID = 0; % no repetitions
[pos2D nirot] = getSourceDetector(nirot.calibration.dataPath,...
    nirot);

%% Step 1e: prepare measured data and select detectors
% specify time gates
len_bin =  50
bin0 = 13;
bin_select = bin0:bin0+len_bin-1; 
isSavePosition = 1;

% specify time
cfg.tstart=0;
cfg.tstep=0.0488e-9;
cfg.tend=cfg.tstep*len_bin;%5e-09;

nPhoton_thresh = 1e2;

[pos2D dataRef nirot] = prepareMeasData(...
    nirot.calibration.dataPath,...
    nirot,...
    bin_select,...
    cfg, ...
    isSavePosition,...
    nPhoton_thresh);
nirot.calibration.data = dataRef;
 
%% STAGE 2: Forward simulation
%% Step 2a: create tissue volume / mesh with sources and detectors
% mesh for Nirfast
% generate / load mesh
isGenerateMesh = 0; 
if isGenerateMesh
    path_nirfast8 = '/media/jiang/WD10T/Data/SoftwarePackages/nirfast8';
    addpath(genpath(path_nirfast8))
    mesh = create_cylinder_D90(pos2D, 3, 1, 1); %D90 d50
    save( [fn_mesh  '.mat'], 'mesh');
else % load mesh
    fn_mesh = 'exampleVolumeFEM/Cylinder_D90/Cylinder_1_mesh.mat';
    mesh=load([fn_mesh  '.mat']);
end
 
%% Step 2b: add optical properties to the mesh
g = 0.35;
mus  =  mus_r_bulk ./ (1-g);
n = 1.37;
val_p.mua=muas_bulk(nirot.iwav);  
val_p.mus=mus_r_bulk(nirot.iwav); 
val_p.ri=n; % pdms

n_region = unique(mesh.region);
mesh_homo = mesh;
for ii = n_region'
mesh_homo = set_mesh(mesh_homo,ii,val_p);
end

% backup the optical properties
nirot.prop=[         0         0    1.0000    1.0000 ;% background/air
    val_p.mua(nirot.iwav)    mus(nirot.iwav)   g    n % liquid
    ];
filename_vol_tiss = ['./exampleVolumeFEM/'  nirot.Volume.Name ...
    '_opticalProperties.txt']
fileID = fopen(filename_vol_tiss, 'w');
fprintf(fileID,'%1.4f %1.4f %1.2f %1.2f\n',nirot.prop');
fclose(fileID);

%% Step 2d: calculation of forward results
% datatype 1: Frequency domain


% datatype 2: time gate


% datatype 3: temporal moments



%% STAGE 3: 

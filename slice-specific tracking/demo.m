% Slice-specific tracking Demo
%**************************************************************************
% ShenZhen Institute of Advanced Technology
% Written by:   Xi XU 
% Email:        xi.xu@siat.ac.cn
% Last update:  1/8/2022
%**************************************************************************

% This is a Demo for the manuscript "Slice-specific tracking for free-
% breathing diffusion tensor cardiac magnetic resonance imaging"
% In order to protect the privacy of the tested person, we provide the 
% pre-processed data, % which are "img.mat" and "nav.mat" in the 
% "sample_data" folder. 
% Finally, the result of the slice-specific factors will be saved in 
% "coe.txt", which is in the "result" folder.


%% The whole calculating process :
% 1 import the image and get information
% 2 load rawdata and extract the respiratory motion and delete outliers
% 3 calclate the displacements of each slice
% 4 fitting with linear least square method to get the tracking factor of
% each slice

%% initialize parameters
clear;clc;
addpath(genpath(pwd))
tic;
m_dFovRO = 150;% m_dFovRO in Root.Seq.GLI.Navigator.1.FOVro, the 2nd RO
reject_index = 0; % reject some images which is wrong in acquisition
slice_number =4 ;

option.fit = 1; % 1: linear fit
option.feature = 1; % 1: line  2: features on the coutour  % no obvious difference
option.dilate = 1; % 0: no dilate   1: do
option.show = 0; % show the images during processing
option.load = 1; % load the mask,0 :no 1: yes

% import dcm
load('./sample_data/img.mat');
% load navigator_rawdata
load('./sample_data/nav.mat');
%reject the wrong images
if sum(reject_index >0)>0
    reject_index = reject_index-1;
    for rejind = 1:length(reject_index)
        img{1}.dcm(:,:,reject_index(rejind)) = []; % dicom are good for fit
        nav{1}(:,reject_index(rejind)) = [];% navigator are good for fit
    end
end

if option.load == 1
    load('./sample_data/endo_mask.mat');
end
v = 1;
mkdir('result');
dcm = img{v}.dcm;
matrix = img{v}.rotmat ;
Line_img = img{v}.Line;
img_space = img{v}.pixelspace;
nav_img = nav{v};
% process the navigator signal
[nav_mm,index_eep,index_eip,outlier_index]  = nav_process(nav_img,m_dFovRO);
dcm(:,:,outlier_index) = [];
% calclate the motion of each slice in mm :
[dsp_slice,pixelvalue_ori,pixelvalue_reg] = motion_specific_slice(dcm,matrix,Line_img,img_space,index_eep,slice_number,option);

% fit the whole heart motion and slice-specific motion with nav
[coe_slice] = fit_heart_nav(nav_mm,dsp_slice);
%     display_curve(nav_mm,dsp_slice,dsp_heart,coe_heart,v);
time_execute = toc;
save(('sample_data\time_execute.mat'),'time_execute');


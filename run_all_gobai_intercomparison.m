% make sure working directory is correct
cd /raid/sharp/matlab/O2_Intercomparison

% set limits (global, 2004 to present)
latlim=[-90 90];
lonlim=[-180 180];
y1 = 1965;
y2 = 2023;

% Import data
wod = process_WOD_profile_data(y1,y2);
save(['wod_data_' num2str(y1) '_' num2str(y2)],'wod','-v7.3');

% display the number of matching cruises/floats and profiles
disp(['# of matching CTD cruises: ' num2str(length(unique(wod.cruise(wod.type==1))))]);
disp(['# of matching CTD profiles: ' num2str(length(unique(wod.profile(wod.type==1))))]);
disp(['# of matching OSD cruises: ' num2str(length(unique(wod.cruise(wod.type==2))))]);
disp(['# of matching OSD profiles: ' num2str(length(unique(wod.profile(wod.type==2))))]);
disp(['# of matching Argo floats: ' num2str(length(unique(wod.cruise(wod.type==3))))]);
disp(['# of matching Argo profiles: ' num2str(length(unique(wod.profile(wod.type==3))))]);

% add correction to float data
load('float_corr_29-Apr-2024.mat');
wod.Oxygen(wod.type==3) = wod.Oxygen(wod.type==3) + slp.*wod.Oxygen(wod.type==3) + int;
clear slp int
save('corrected_wod_data','wod');

% Assemble data into table
wod.pressure = gsw_p_from_z(-wod.depth,wod.lat);
wod.sal_abs = gsw_SA_from_SP(wod.Salinity,wod.pressure,wod.lon,wod.lat);
wod.temp_cns = gsw_CT_from_t(wod.sal_abs,wod.Temperature,wod.pressure);
wod.sigma = gsw_sigma0(wod.sal_abs,wod.temp_cns);
OXY_table = table(wod.cruise,wod.lat,wod.lon,wod.sigma,wod.pressure,wod.time,...
    wod.Temperature,wod.temp_cns,wod.Salinity,wod.sal_abs,wod.Oxygen,...
    'VariableNames',{'platform','latitude','longitude','sigma','pressure',...
    'time','temperature','temperature_cns','salinity','salinity_abs','oxygen'});

% create basin shapes
createShapes

% process imported data
processData
save(['processed_wod_data_' num2str(y1) '_' num2str(y2)],'OXY','Poly');

% Create basin indices for model fits
basin_index = basin_indices('Data',OXY,Poly);
% fit final model for oxygen (NN)
fit_NN('All',OXY,basin_index,preds_oxy_NN);
% fit final model for oxygen (RFR)
fit_RFR('All',OXY,basin_index,all_oxy_RF,1);

% use all the extracted data to create O2 fields for the region
% with machine learning and a gridded T/S Argo-based data product
% create_GOBAI_O2_RG
create_GOBAI_O2_EN4

% calculate uncertainty in GOBAI-O2
% Uncertainty

% convert to NetCDF
RG_to_GOBAI

% clean up
clearvars
close all

function wod = process_WOD_profile_data(y1,y2)

% load WOD profile data
folder = 'WOD_Profiles_data';
types = {'CTD' 'OSD' 'PFL'};

% for oxygen
vars_o2 = {'cruise' 'profile' 'time' 'year' 'month' 'day' 'lat' 'lon' 'depth' 'Oxygen'};
vars_other = {'Temperature' 'Salinity'};
vars_both = [vars_o2 vars_other];
% pre-allocate
for v = 1:length(vars_both); wod.(vars_both{v}) = []; end
wod.type = [];
% load oxygen variables
for y = y1:y2
    for x = 1:length(types)
        file = [folder '/Oxygen_' types{x} '_NCEI/Oxygen_' types{x} '_' num2str(y) '.nc'];
        if exist(file,'file')
            schema = ncinfo(file);
            pdim = schema.Dimensions(1).Length;
            zdim = schema.Dimensions(2).Length;
            % oxygen
            for v = 1:length(vars_o2)
                wod_temp.(vars_o2{v}) = ncread(file,vars_o2{v});
            end
            % temp
            file = [folder '/Temperature_' types{x} '_NCEI/Temperature_' types{x} '_' num2str(y) '.nc'];
            wod_temp.Temperature = ncread(file,'Temperature');
            wod_temp.temp_profile = ncread(file,'profile');
            % sal
            file = [folder '/Salinity_' types{x} '_NCEI/Salinity_' types{x} '_' num2str(y) '.nc'];
            wod_temp.Salinity = ncread(file,'Salinity');
            wod_temp.sal_profile = ncread(file,'profile');
            % indices
            idx_o2 = ismember(wod_temp.profile,wod_temp.temp_profile) & ismember(wod_temp.profile,wod_temp.sal_profile);
            idx_temp = ismember(wod_temp.temp_profile,wod_temp.profile) & ismember(wod_temp.temp_profile,wod_temp.sal_profile);
            idx_sal = ismember(wod_temp.sal_profile,wod_temp.profile) & ismember(wod_temp.sal_profile,wod_temp.temp_profile);
            % filter to only profiles with oxygen, temperature, and salinity
            for v = 1:length(vars_o2)
                if strcmp(vars_o2{v},'depth')
                    wod_temp.(vars_o2{v}) = repmat(wod_temp.(vars_o2{v}),1,sum(idx_o2));
                elseif strcmp(vars_o2{v},'Oxygen')
                    wod_temp.(vars_o2{v}) = wod_temp.(vars_o2{v})(1:zdim,idx_o2);
                else
                    wod_temp.(vars_o2{v}) = repmat(wod_temp.(vars_o2{v})(idx_o2)',zdim,1);
                end
            end
            wod_temp.Temperature = wod_temp.Temperature(1:zdim,idx_temp);
            wod_temp.Salinity = wod_temp.Salinity(1:zdim,idx_sal);
            % add values to vector
            idx = ~isnan(wod_temp.Oxygen);
            for v = 1:length(vars_both)
                wod.(vars_both{v}) = [wod.(vars_both{v});wod_temp.(vars_both{v})(idx)];
            end
            wod.type = [wod.type;repmat(x,sum(idx(:)),1)];
        end
    end
end

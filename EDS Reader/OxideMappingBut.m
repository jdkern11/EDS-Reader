function OxideMappingBut(varargin)


% Identify the buttons on the figure window
buttons = get(gcf,'Children');

% Identify the button number of the Oxide Mapping button
OxideMappingButNum = findButNum(buttons,'Tag','OxideMapping');
set(buttons(OxideMappingButNum),'Value',0); % Set the value of the button == 0


% Get the UserData of the figure, which contains: nameMatrix, matrixEDSData, pathName, pixelSize, and grayImage
maps = get(gcf,'UserData');
if isempty(maps)
    return
end

% ElementList contains a list of all possible elements encountered.
% Note: if an element of interest does not appear in this list, feel free
% to add it.
[ElementList, colorArray] = MasterElementList();

% Match the elements in nameMatrix with their corresponding colors in
% colorArray
nameMatrix = maps{1};
data_type = maps{10};
indx = maps{8};
cf = maps{11};

% Store legend names
legendNameMatrix = strings(length(indx),1); 
for k = 1:length(indx)
   legendNameMatrix(k,1) = nameMatrix(indx(k));
end

% Search if there is oxygen present. If not, return
oxygen_present = 0;
oxygen_index = 0;
for i = 1:length(nameMatrix)
    if (contains(nameMatrix(i), 'O '))
        oxygen_present = 1;
        oxygen_index = i;
        disp ('O present');
    end
end

if (oxygen_present == 0)
    msgbox('O not present in the sample');
    return
end

colorList = zeros(length(nameMatrix),3);
% find colors
for i = 1:length(nameMatrix)
    colorInd = find(contains(ElementList,nameMatrix(i)));
    colorList(i,:) = colorArray(colorInd,:); % colorList contains the colors for the elements in nameMatrix
end

matrixEDSData = maps{2}; % Retrieve the EDS matrices

% Gaussian smoothing filter to redue noise (OPTIONAL)
for i = 1:length(nameMatrix)
    matrixEDSData(:,:,i) = imgaussfilt(matrixEDSData(:,:,i),0.75);
end

pathName = maps{3}; % Retrieve the path name


% Create new directory for the Oxide Map (not added to the colored map as
dirName = strcat(pathName, '\ColoredMaps_', char(data_type));
if ~(exist(dirName, 'dir'))
    ColoredMapsBut();
end

if ~(exist(dirName, 'dir'))
    msgbox('Element Mapping Not Run... Returning');
    return;
end
%extract sizes of matrices
x = size(matrixEDSData,1);
y = size(matrixEDSData,2);

%create a matrix that has a color array in positions 1-3
colorImage = zeros(x, y, 3);

%%% For the combined map, determine which element is dominant at each pixel
% Matrix to store the element with the largest intensity for each pixel
max_intensity_loc = zeros(x, y); 
% Matrix to store the intensity value of the dominant element
max_intensity_val = zeros(x, y);

% Thresholding for element and oxygen points (chosen by user)
min_oxygen_percentage = inputdlg('Input the detection threshold (%) for oxygen (0-100):');
min_element_percentage = inputdlg('Input the detection threshold (%) for the oxidized element (0-100):');
if (isempty(min_oxygen_percentage) || isempty(min_element_percentage))
    msgbox('No threshold chosen... Returning')
    return
end

min_element_percentage = str2double(min_element_percentage);
min_oxygen_percentage = str2double(min_oxygen_percentage);
if (isnan(min_oxygen_percentage) || isnan(min_element_percentage))
    msgbox('No threshold chosen... Returning')
    return
end

% Determine max elements at any oxidized point (That isn't oxygen)
combined_data = 0;
Oxy_map = matrixEDSData(:,:,oxygen_index)/cf;
for i = 1:length(nameMatrix)
    if (i ~= oxygen_index && (ismember(i, indx)))
        EDSmap = matrixEDSData(:,:,i)/cf; % load in EDS map
        for j = 1:y
            for k = 1:x
                if (Oxy_map(k,j) >= min_oxygen_percentage)
                    if ((EDSmap(k,j) >= max_intensity_val(k,j)) && (EDSmap(k,j) >= min_element_percentage))
                        max_intensity_loc(k,j) = i;
                        max_intensity_val(k,j) = EDSmap(k,j);
                        combined_data = 1;
                    end
                end
            end
        end
    end  
end



% Determine which EDSmaps are members of the combined colormap
color_members = 0;
color_member_indices = zeros(length(nameMatrix),1);
for i = 1:length(nameMatrix)
    if (ismember(i, max_intensity_loc))
        color_members = color_members+1;
        color_member_indices(color_members) = i;
    end
end

% Store legend names
colorNameMatrix = strings(color_members,1); 
max_name_len = 0;
for k = 1:color_members
   colorNameMatrix(k,1) = nameMatrix(color_member_indices(k,1));
   if (strlength(colorNameMatrix(k,1)) > max_name_len)
       max_name_len = strlength(colorNameMatrix(k,1))-2;
   end
end

combinedImage = zeros(x, y, 3);
combined_color_map = zeros(100*color_members,3); 
combined_color_map_max_intensity = zeros(1,color_members);
% Boolean to determine when the combined color bar begins being created
combined_start = 0;
uiwait(msgbox('For visualization purposes, any pixels that are brighter than 99.5% of the pixels will be rounded down to the 99.5% level. Press Ok to continue.'));
for i = 1:length(nameMatrix)
    
     EDSmap = matrixEDSData(:,:,i); % load in EDS map
    
    % The purpose of the following several lines is to find the intensity value
    % of the map that 99.5% of the data fall below. This intensity, maxIntensity, will
    % then be the maximum intensity displayed in the map.
    [hist_values, edges] = histcounts(EDSmap); % make a histogram of the intensity values in the map
    hist_BinLimits = [min(edges), max(edges)];
    
    D1 = hist_values; % retrieve the intensity values in the histogram
    Lims = hist_BinLimits/cf; % retrieve the limits of the historgram, and normalize 
                            % by cf due to the max intensity of the map being equal to 100*cf (e.g., if cf = 100, then 10,000/100 = 100)
    D2 = cumsum(D1); % generate the cumulative sum of the intensity values
    D2 = D2/max(D2); % normalize the cumsum to make the max of the cumulative sum equal to 1
    d = linspace(Lims(1),Lims(2),length(D2)); % generate the x-axis for the cumsum
    maxIntensityInd = find(D2>=0.995,1); % determine the index of the intensity that is 99.5% of the max
    maxIntensity = d(maxIntensityInd); % retrieve that intensity
    maxIntensity = ceil(maxIntensity/5)*5; % round maxIntensity up to the nearest multiple of 5

    % Create colorImage, where colorImage is a 3D RGB matrix. Note that all
    % intensity values that are equal to maxIntensity will be normalized to
    % 1, and any intensity values greater than maxIntensity (i.e., the top 
    % 0.5% of the intensity values) will be > 1
    
    % Create colorImage, where colorImage is a 3D RGB matrix. Note that all
    % intensity values that are equal to maxIntensity will be normalized to
    % 1, and any intensity values greater than maxIntensity (i.e., the top 
    % 0.5% of the intensity values) will be > 1
    colorImage(:,:,1) = EDSmap*colorList(i,1)/(cf*maxIntensity);
    colorImage(:,:,2) = EDSmap*colorList(i,2)/(cf*maxIntensity);
    colorImage(:,:,3) = EDSmap*colorList(i,3)/(cf*maxIntensity);
    
    % Find all pixel locations where the present element is dominant
    [map_loc_rows, map_loc_cols] = find(max_intensity_loc == i);
    % Create a map that combines the colors of the dominant elements into a single map
    if ~isempty(map_loc_rows)
        for j = 1:length(map_loc_rows)
            combinedImage(map_loc_rows(j), map_loc_cols(j),1) = colorImage(map_loc_rows(j), map_loc_cols(j),1);
            combinedImage(map_loc_rows(j), map_loc_cols(j),2) = colorImage(map_loc_rows(j), map_loc_cols(j),2);
            combinedImage(map_loc_rows(j), map_loc_cols(j),3) = colorImage(map_loc_rows(j), map_loc_cols(j),3);
        end
    end
    
%     % Creat a colormap for the colorbar, which ranges from 0 -- > colorList(i,:)
     colorMap = [linspace(0,colorList(i,1),100)' linspace(0,colorList(i,2),100)' linspace(0,colorList(i,3),100)'];
     if (ismember(i, color_member_indices))
        if (combined_start == 0)
            combined_color_map(1:100,:) = colorMap;
            combined_start = 1;
            combined_color_map_max_intensity(combined_start) = maxIntensity;
        else
            offset = combined_start * 100;
            combined_color_map((1+offset):(offset+100),:) = colorMap;
            combined_start = combined_start + 1;
            combined_color_map_max_intensity(combined_start) = maxIntensity;
        end
    end
    
end


if (combined_data == 0)
    msgbox('No oxide map produced')
    return
end

fig3 = figure('color','w');
pos=get(gca,'position');  % retrieve the current figure position
pos(3)= 0.85*pos(3);      % reduce width
set(gca,'position',pos);  % update position
%Plot the combined map and save
image(combinedImage)
hold on
xlim([0 y])
ylim([0 x])
axis equal
axis off
drawnow
titleLabel = title('Dominant-Oxide Map', 'fontsize', 18);
set(titleLabel, 'Position', [y/2 2 1]); 
drawnow

colormap(combined_color_map);

cb = colorbar(gca, 'horizontal', 'location', 'southoutside'); % creat a colorbar
cbPos = cb.Position; % get the position of the color bar
mid = (pos(1) + pos(3)) / 3.66;
set(cb,'Position',[mid pos(2)+.015 cbPos(3) cbPos(4)/2])%[x/5 y/5 cbPos(3) cbPos(4)/2]) % move the color bar to the side and shrink it
drawnow

% Implementation of a combined color bar
ticks_lower = zeros(1,color_members); % create tick marks
ticks_upper = zeros(1,color_members);
inc = 1/color_members; % create even spacing
curr = 0;
labels_upper = zeros(color_members, 1);
labels_lower = zeros(color_members, 1);
labels_upper(color_members) = combined_color_map_max_intensity(color_members);
for i = 1:(color_members)
    labels_lower(i) = 11^(max_name_len-1);
    ticks_upper(i) = curr+inc;
    ticks_lower(i) = curr+(inc/2);
    labels_upper(i) = combined_color_map_max_intensity(i); % add each max intensity
    curr = curr+inc;
end
ticks_upper(color_members) = 0.999; % Prevent number from falling off edge
labels_upper = num2str(labels_upper);
labels_lower = num2str(labels_lower);

% add names of each element. May need to change later if any elements with
% 3 letters show up
for i = 1:(color_members)
    curr_name = char(colorNameMatrix(i,1));
    labels_lower(i,1:2) = curr_name(1:2);
end

% add second axes
cbPos = get(cb, 'position');
cbPos = [cbPos(1), cbPos(2), cbPos(3), cbPos(4)];
sec_axes = axes('position',cbPos,'color','none','ytick',[], 'yticklabel',[]...
               ,'xtick', ticks_upper);
set (sec_axes, 'YColor', 'none')
set (sec_axes, 'XAxisLocation', 'Top')
set (cb, 'YTick', ticks_lower)
color_bar_font_size = 8.5-.15*color_members;
set (sec_axes, 'XTickLabel', labels_upper, 'fontsize', color_bar_font_size)
set (cb, 'YTickLabel', labels_lower, 'fontsize', color_bar_font_size)
% End combined color bar


xlabel(cb,data_type, 'fontsize', 18);
pause(0.05)
drawnow


% Create save name for the dominant element map
name = char(strcat(dirName,'\Dominant-Oxide Map'));
for k = 1:length(indx)
   name = char(strcat(name, '_', legendNameMatrix(k,1)));
end

% Create save name for the dominant element map
name = char(strcat(name,'_ele%_', num2str(min_element_percentage)...
        ,'_O%_', num2str(min_oxygen_percentage), '.jpg'));

print(figure(fig3),name,'-djpeg','-r600');
crop(name)
close(fig3)
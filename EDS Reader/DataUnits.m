function DataUnits(varargin)

buttons = get(gcf,'Children');

% Identify the button number of the Oxide Mapping button
AtomicToWeightButNum = findButNum(buttons,'Tag','OxideMapping');
set(buttons(AtomicToWeightButNum),'Value',0); % Set the value of the button == 0

% Extract the which data type is currently choosen
dataTypeButNum = findButNum(buttons,'Tag','DataUnits');
dataTypeBut = get(buttons(dataTypeButNum));
dataTypeContent = dataTypeBut.String;
currDataType = dataTypeBut.Value;

% Get the UserData of the figure, which contains: nameMatrix, matrixEDSData, pathName, pixelSize, and grayImage
maps = get(gcf,'UserData');
if isempty(maps)
    return
end

% Return if not conversion is needed
if (maps{10} == dataTypeContent{currDataType})
    return;
end

matrixEDSData = maps{2};
nameMatrix = maps{1};

x = size(matrixEDSData,1);
y = size(matrixEDSData,2);

[elements, atomic_weights] = ElementConversionList();

num_elements = length(nameMatrix);
atomic_weights_elements = zeros(1, num_elements);
% extract the atomic masses for these elements
for i = 1:num_elements
    string_length = strlength(nameMatrix(i));
    ele = char(nameMatrix(i));
    % eliminate the ' K' or ' L'
    ele = ele(1:(string_length-2));
    mass_index = find(contains(elements,ele));
    % if multiple elements have the same pattern (i.e. O is O and Os)
    % determine which index is the exact match to the pattern
    for j = 1:length(mass_index)
        comp = char(elements(mass_index(j)));%
        if (strcmpi(comp, ele) == 1)
            mass_index = mass_index(j);
            break
        end
    end
    atomic_weights_elements(1,i) = atomic_weights(mass_index);
end

% determine the max intensity that values will be multiplied by
max_intensity = max(matrixEDSData);
max_intensity = max(max_intensity);
max_intensity = max(max_intensity);
max_intensity = max_intensity(1,1,1);
convertedEDSData = matrixEDSData;

pixel_sum = zeros(x,y);  %sum of all % at pixel
if (strcmpi(char(maps{10}), 'AT%') == 1) %converting to wt%
    % sum all of the weights and then convert to wt%
    maps{10} = 'WT%';
    for j = 1:y
        for k = 1:x
            for i = 1:num_elements
                pixel_sum(k,j) = (matrixEDSData(k,j,i)*atomic_weights_elements(1,i))+pixel_sum(k,j);
            end
            % do not want to divide 0 by 0 so set to 1
            if (pixel_sum(k,j) == 0)
                pixel_sum(k,j) = 1;
            end
            % conversion here
            for i = 1:num_elements
                convertedEDSData(k,j,i) = max_intensity*(matrixEDSData(k,j,i)*atomic_weights_elements(1,i))/pixel_sum(k,j);
            end
        end
    end
    
else
    % sum all of the points and then convert to at%
    maps{10} = 'AT%';
    for j = 1:y
        for k = 1:x
            for i = 1:num_elements
                pixel_sum(k,j) = (matrixEDSData(k,j,i)/atomic_weights_elements(1,i))+pixel_sum(k,j);
            end
            % do not want to divide 0 by 0 so set to 1
            if (pixel_sum(k,j) == 0)
                pixel_sum(k,j) = 1;
            end
            % conversion here
            for i = 1:num_elements
                convertedEDSData(k,j,i) = max_intensity*(matrixEDSData(k,j,i)/atomic_weights_elements(1,i))/pixel_sum(k,j);
            end
        end
    end
end

maps{2} = convertedEDSData;
set(gcf,'UserData',maps);
shortmsg = msgbox('Conversion Complete');
pause(.5)
close(shortmsg);
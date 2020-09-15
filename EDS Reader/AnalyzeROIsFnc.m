function AnalyzeROIsFnc(varargin)

scrsz = get(0,'ScreenSize');
fig1Percent = 0.75; % Percent of screen that fig1 occupies
fig1W = fig1Percent*scrsz(3);
fig1H = 0.5*fig1Percent*scrsz(4);
fig1L = 0.5*(scrsz(3)-fig1W);
fig1B = 0.5*(scrsz(4)-fig1H);
figZPos = [fig1L,fig1B,fig1W,fig1H];

figX = gcf;

% Identify the buttons on the figure window
buttons = get(gcf,'Children');
% Identify the button number of the pop-up menu
menuButNum = findButNum(buttons,'Tag','ROIList');

% Get the coordinates of all ROIs, which are stored in the UserData of the
% pop-up menu button. Note: for each ROI, curveCoordsList contains:
                            % 1. The coordinates of the ROI
                            % 2. A plot handle for the ROI coordinates
                            % 3. A flag (1x2 matrix) tracking:
                            %    a. whether or not the correct region has
                            %    been identified (first column)
                            %    b. which region is the correct one (second column)
curveCoordsList = get(buttons(menuButNum),'UserData');

if isempty(curveCoordsList)
    return
end

N = int32(length(curveCoordsList)/3); % The number of ROIs drawn
centroidsList = zeros(N,2); % This will contain the coordinates of the centroids of the ROIs
ElementConcentrations = cell(N,1);

% info for saving data later
headers = strings(3,1);
headers(1) = 'Element';
headers(2) = 'Mean_Distribution_Percentage';
headers(3) = 'Standard_Deviation';

% Get the UserData of the figure, which contains: nameMatrix,
% matrixEDSData, pathName, and ROI Names
maps = get(gcf,'UserData');
nameMatrix = maps{1};
matrixEDSData = maps{2};
pathName = maps{3};
ROI_Names = maps{6};
indices = maps{8};
data_type = maps{10};
cf = maps{11};
legendNameMatrix = strings(length(indices),1); 
for k = 1:length(indices)
   legendNameMatrix(k,1) = nameMatrix(indices(k));
end
[L1, L2] = size(matrixEDSData(:,:,1)); % The size of the EDS matrices
maxL = max([L1, L2]); % The largest dimension o the EDS matrices
n = 1;
f = waitbar(0, 'Analyzing ROIs');
inc = .5/(4.0*double(N));
curr_inc = 0;
for i = 1:N
    if i == 1 % If i == 1, have the user chose the save directory and file name
        
        % Create a directory and save name
        userDirName = inputdlg('What do you want your storage folder and data to be named?');
        if (isempty(userDirName))
            disp('No name choosen, returning');
            waitbar(1,f, 'Analyzing ROIs');
            close(f)
            return
        end
        
        fileName = strcat(pathName, {'\'}, userDirName, '_', data_type);
        fileName = strjoin(fileName);
        temp = 1;
        while exist(fileName, 'dir')
            number = num2str(temp, '%2d');
            tempName = strcat({'\'}, userDirName, '_', data_type, {'('}, number, {')'});
            tempName = strjoin(tempName);
            fileName = strcat(pathName, tempName);
            temp = temp+1;
        end
        mkdir(fileName);
        
        % Creates data name
        dataName = strcat(fileName, '\', userDirName);
        dataNameExcel = strcat(dataName, '.xlsx');
        
    end
    figure(f);
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    
    curveN = curveCoordsList{n}; % Retrieve the coordinates of the nth ROI
    
    curveN = curveN{1};
    x = curveN(:,1); % x-coordinates of the ROI
    y = curveN(:,2); % y-coordinates of the ROI
    imMask = zeros(L1,L2); % imMask will contain 1's in the pixel locations
    % of the (x,y) coordinates of the ROI's boundary
    for j = 1:length(x)
        imMask(int32(y(j)),int32(x(j))) = 1;
    end
    figure(f);
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    flagN = curveCoordsList{n+2}; % Retrieve the flag for the nth ROI
                                  % Note: this is not being used in this
                                  % version of the code, but it may be
                                  % useful in future versions
    
    BW = imbinarize(imMask, 0.5); % Make imMask binary
    
    edgeImage = zeros(size(BW)); % edgeImage will contain the interpolated
    % boundary of the ROI (i.e., the 'gaps' in
    % the boundary of imMask will be filled
    % in).
    M = length(x);
    spacing = 0.4; % pixels between boundary points (<0.5, to prevent any gaps)
    for j = 1:M
        
        if j == M
            x1 = round(x(M));
            x2 = round(x(1));
            y1 = round(y(M));
            y2 = round(y(1));
            
        else
            
            x1 = round(x(j));
            x2 = round(x(j+1));
            y1 = round(y(j));
            y2 = round(y(j+1));
            
        end
        
        distance = sqrt((x2-x1)^2+(y2-y1)^2);
        numPoints = distance/spacing;
        xLine = linspace(x1, x2, numPoints); % The interpolated x-coordinates
        yLine = linspace(y1, y2, numPoints); % The interpolated y-coordinates
        rows = round(yLine);
        columns = round(xLine);
        for k = 1:length(xLine)
            edgeImage(rows(k), columns(k)) = 1; % Make boundary pixels == 1
        end
    end
    figure(f);
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    BW1 = imbinarize(edgeImage, 0.5); % make edgeImage binary
    
    % The next step is to make all pixels within the ROI == 1. I.e., to
    % fill in the ROI. The function imclose will be used to do that.
    nhood = true(maxL); % Define the largest neighborhood within which the ROI will be filled
    
    % Fill in the ROI.
    BW2 = imclose(BW1,nhood);
     
    CC = bwconncomp(BW2,4); % Identify the independent regions in BW3. If
                              % the number of regions > 1, then the ROI is concave.
     
    BW3 = zeros(size(BW2)); % BW4 will contain the final filled-in ROI
  
    BW3(CC.PixelIdxList{1}) = 1; % If BW3 only contains one region, then
                                  % that region is the correct ROI, and BW4 is made to contain that ROI

%     figure;
%     surf(BW3)
%     shading interp
%     colormap bone
    
    % Find the centroid of the ROI
    s = regionprops(BW3,'centroid');
    centroids = cat(1, s.Centroid);
    centroidsList(i,:) = centroids;
    
    disp(char(ROI_Names(1,i)));
    elementConcentrations = zeros(length(indices),2); % This will contain the element concentrations for graphing
    saveConcentrations = zeros(length(nameMatrix),2); %This will save all element concs.
    elementConcPos = 1;
    for j = 1:length(nameMatrix)
        
        matrixEDSDataJ = matrixEDSData(:,:,j); % Extract the EDS map of element j
        ROIdataJ = matrixEDSDataJ.*BW3/cf; % ROIdataJ contains only the data within the ROI
        % Note: normalize ROIdataJ by cf to give results as atomic (%)
        ROIdataJ = ROIdataJ(:);
        ROIdataJ(BW3 == 0) = []; % Remove all 0's that are outside of the ROI
        
        saveConcentrations(j,1) = mean(ROIdataJ); % Find the average atomic % of element j within the ROI
        saveConcentrations(j,2) = std(ROIdataJ); % Find the standard deviaiton of the atomic % of element j within the ROI
        % Display the results to the command prompt
         if (ismember(j,indices))
            elementConcentrations(elementConcPos,:) = saveConcentrations(j,:);
            elementConcPos = elementConcPos + 1;
            disp(nameMatrix(j));
            disp([num2str(saveConcentrations(j,1)), ' +/- ', num2str(saveConcentrations(j,2))]);
         end
    end
    ElementConcentrations{i} = elementConcentrations;
    %disp('Correctly read');
    disp('');
    figure(f);
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    n = n + 3;
    
    %Create table of data
    %dataTypeTable = array2table(data_type, 'VariableNames', {'Data_Type'});
    nameTable = array2table(nameMatrix, 'VariableNames', {'Element'});
    quantTable = array2table(saveConcentrations, 'VariableNames', {'Mean_Distribution_Percentage', 'Standard_Deviation'});
    combinedTable = [nameTable quantTable];
    sheet = sprintf(char(ROI_Names(1,i)));
    writetable(combinedTable, dataNameExcel{1}, 'Sheet', sheet);
    
    xlswrite(dataNameExcel{1}, {data_type}, sheet, 'D1');
    % Save the results as text file
    saveName = [fileName, '\', sheet, '.txt'];
    fid = fopen(saveName, 'wt');
    len = length(nameMatrix);
    for q = 1:len+2
        if (q == 1)
            fprintf(fid, '%s %s\n', char(ROI_Names(1,i)), char(data_type));
        else
            for t = 1:3
                if (q == 2)
                    if t < 3
                        fprintf(fid, '%s\t', headers(t));
                    else
                        fprintf(fid, '%s\n', headers(t));
                    end
                else
                    if t == 1
                        fprintf(fid, '%s\t', nameMatrix(q-2));
                    elseif t == 2
                        fprintf(fid, '%s\t', saveConcentrations(q-2, 1));
                    elseif t == 3
                        fprintf(fid, '%s\n', saveConcentrations(q-2, 2));
                    else
                    end
                end
            end
        end
    end
    fclose(fid);
end

% Remove default Excel sheets Sheet1, Sheet2, and Sheet3 
% (ref: https://www.mathworks.com/matlabcentral/answers/92449-how-can-i-delete-the-default-sheets-sheet1-sheet2-and-sheet3-in-excel-when-i-use-xlswrite)
objExcel = actxserver('Excel.Application'); % Open Excel file
objExcel.Workbooks.Open(dataNameExcel{1}); % Full path

% Delete sheets
for i = 1:3
    try
        objExcel.ActiveWorkbook.Worksheets.Item(['Sheet', num2str(i)]).Delete;
    catch
        % Do nothing
    end
end

% Save, close and clean up.
objExcel.ActiveWorkbook.Save;
objExcel.ActiveWorkbook.Close;
objExcel.Quit;
objExcel.delete;

% In order to save only the Grey image with the ROIs drawn on it (and not
% the GUI buttons), make a new figure that contains only the image and the
% ROIs
figure(figX);
axOld = gca;
figY = figure;
axNew = copyobj(axOld,figY);
set(axNew,'Position','default')
title('');

% Save that image as _ROIsDrawn.jpg
saveName1 = strrep(dataNameExcel{1},'.xlsx','_ROIsDrawn');
print(figY,saveName1,'-djpeg')

% Now label the ROIs, and save that image as _ROIsLabeled.jpg
figure(figY);
hold on
inc = (.75-.50)/(2.0*double(N));
for i = 1:N
    figure(f)
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    figure(figY)
    text(centroidsList(i,1),centroidsList(i,2),num2str(i),'Color','red','FontSize',14);
end
saveName2 = strrep(dataNameExcel{1},'.xlsx','_ROIsLabeled');
print(figY,saveName2,'-djpeg')

close(figY);

% Plot the results
figZ = figure('color','w','Position',figZPos);
xVals = double(1:length(elementConcentrations));
barWidth = 1/(length(indices)+2);
spacings = barWidth*(double(1:N) - double(N+1)/2);
minI = 0;
maxI = 0;
legendStr = cell(N,1);
colorArray = {'c', 'r', 'b', 'y', 'g', 'm'};
for i = 1:N
    figure(f)
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    figure(figZ)
    currColor = mod(i, length(colorArray)) + 1; 
    elementConcentrations = ElementConcentrations{i};
    minI = min([minI min(elementConcentrations(:,1)-elementConcentrations(:,2))]);
    maxI = max([maxI max(elementConcentrations(:,1)+elementConcentrations(:,2))]);
    bar(xVals+spacings(i),elementConcentrations(:,1),'BarWidth', barWidth, 'FaceColor', colorArray{1,currColor});
    hold on
    %h = inputdlg('What is this region named?');
    legendStr{i} = char(ROI_Names(1,i));
    %legendStr{i} = ['ROI #', num2str(i)];
end
inc = (.95-.75)/(double(N));
for i = 1:N
    figure(f)
    curr_inc = curr_inc + inc;
    waitbar(curr_inc,f, 'Analyzing ROIs');
    elementConcentrations = ElementConcentrations{i};
    figure(figZ)
    errorbar(xVals+spacings(i),elementConcentrations(:,1),elementConcentrations(:,2),'.','MarkerSize',0.1,'color','k')
end
set(gca,'XTick',1:length(elementConcentrations),'XTickLabel',legendNameMatrix,'YMinorTick', 'on','TickLength',[0 0], 'fontsize', 18)
xlim([0 length(indices)+1])
ylim([-10 70])
%ylim([10*floor(minI/10) 10*ceil(maxI/10)])
ylabel(data_type, 'fontsize', 18)
lgnd = legend(legendStr,'Location','northeastoutside');
lgnd.FontSize = 18;
legend('boxoff')

% Save the results as _Results.jpg
saveName3 = strrep(dataNameExcel{1},'.xlsx','_Results');
print(figZ,saveName3,'-djpeg')
figure(f)
waitbar(1,f, 'Analyzing ROIs');
pause(.5)
close(f)
end

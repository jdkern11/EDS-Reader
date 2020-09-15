function PickFilePathAndReadData(varargin)
% figPosition = varargin{3};
fig1 = gcf;
cla
axis off
colorbar('off')
title(' ');
% Clear user data
set(fig1,'UserData',{});
% Close all figures except for the main figure
set(fig1, 'HandleVisibility', 'off');
close all;
set(fig1, 'HandleVisibility', 'on');

%%%%
% Identify the buttons on the figure window
buttons = get(gcf,'Children');
bar_len = 0;
f = waitbar(bar_len, 'Loading CSV data');
bar_len = .1;
% Retrieve all button numbers
menuButNum = findButNum(buttons,'Tag','ROIList');
dataTypeButNum = findButNum(buttons,'Tag','DataUnits');
fullViewButNum = findButNum(buttons,'Tag','FullView');
deleteButNum = findButNum(buttons,'Tag','DeleteROI'); 
drawButNum = findButNum(buttons,'Tag','DrawROI');
zoomButNum = findButNum(buttons,'Tag','ZoomDrag');
drawLineButNum = findButNum(buttons,'Tag','DrawLine');

% Reset all UserData data
set(buttons(fullViewButNum),'UserData',{});
set(buttons(menuButNum),'UserData',{});
set(buttons(deleteButNum),'UserData',{});

% Reset button values
set(buttons(drawButNum),'Value',0)
set(buttons(drawLineButNum),'Value',0);
set(buttons(menuButNum),'String','Empty');        
set(buttons(zoomButNum),'Value',0);
set(buttons(dataTypeButNum),'Value',1)

try
    load temp % If a folder was chosen previously, that info. was saved as 'temp'
catch
    pathName = [cd,'\']; % If no folder has been chosen previously, start in the current directory
end

%Find the path of the directroy
%If there is not prior path, call from current path
try
    pathName = uigetdir(pathName);
catch
    pathName = uigetdir();
end

if pathName == 0
    close(f)
    return
end

save temp pathName % Save the path name, and next time you'll start in that same folder
set(0, 'currentfigure', fig1);

%create a listing of all the files
fileName = "";
listing = dir([pathName, '\*.csv']);
for i = 1:length(listing) 
    if(contains(listing(i).name,('_Grey.csv')))
        fileName = listing(i).name;
    end
end

%Throw error if gray file could not be found
if(fileName == "")
    warndlg('No gray image csv file in the directory.','Warning')
    return
end

datafile = [pathName,'\',fileName];

%Read the Grey.csv file and create a gray image. Display on GUI
datafileRead = csvread(datafile, 5, 0);
imageShowGray = mat2gray(datafileRead, [0 255]);
imageShowGray = histeq(imageShowGray); % Enhance the contrast of the image                                     
imshow(imageShowGray)
hold on
[L1, L2, ~] = size(imageShowGray);
set(gca,'Xlim',[0.5 L2]);
set(gca,'Ylim',[0.5 L1]);
Xlim = get(gca,'Xlim');                                                    
Ylim = get(gca,'Ylim');                                                    
set(buttons(fullViewButNum),'UserData',[Xlim; Ylim]);                      

waitbar(bar_len,f, 'Loading CSV data');
bar_len = .2;
set(0, 'currentfigure', fig1);
%Read the data range for the CSV files
xRange = csvread(datafile,1,1,'B2..B2');
yRange = csvread(datafile,2,1,'B3..B3');
% read pixel in nm or microns
fid = fopen(datafile);
data = textscan(fid, '%s %s %f %s', 'HeaderLines', 3);
fclose(fid);
% pixelText = fileread(datafile,3,1,'B4..B4');
% pixelSize = csvread(datafile,3,1,'B4..B4'); % nanometers
pixelSize = data{1,3}; %nm or microns
pixelUnit = data{1,4};
if(strcmp(pixelUnit, 'nm'))
    pixelSize = pixelSize/1000;
end

%1D matrix to hold names of the material
nameMatrix = strings(length(listing)-1,1) ;                                
%3D matrix to hold all information
matrixEDSData = zeros(yRange, xRange, length(listing)-1);

%Adds the element name and data files to separate matrices. Index of each
%corresponds to one another (i.e. at index 1 in names corresponds to index
%one of 3d Matrix
indexCounter = 1;
found_d_type = 0;
list_len = length(listing);
waitbar(bar_len,f, 'Loading CSV data');
set(0, 'currentfigure', fig1);
bar_increment = (.9-bar_len)/list_len;
%Conversion factor
cf = 1; %set to one in event the read file is in counts
for i = 1:list_len
    fileName = listing(i).name;
    datafile = [pathName,'\',fileName];
    %ignore gray data
    if(~contains(listing(i).name,('_Grey.csv')))
        %Read element names
        fidi = fopen(datafile);
        elementName = textscan(fidi, '%s %s', 1,'Delimiter', ',');
        if (found_d_type == 0)
           found_d_type = 1;
           data_type = textscan(fidi, '%s %s', 4, 'Delimiter', ',');
           data_type = data_type{2}{4};
           if (~strcmp(data_type,'Counts'))
               data_type = strsplit(data_type);
               cf = str2double(data_type{3});
               data_type = data_type{1};
           else
               data_type = 'cts';
           end
        end
        fclose(fidi);
        elementName = elementName{2}{1};
        nameMatrix(indexCounter) = elementName;                            
        %Read csv data
        matrixEDSData(:, :, indexCounter) = csvread(datafile, 5, 0);       
        indexCounter = indexCounter + 1;
    end
    
    % update waitbar
    bar_len = bar_len + bar_increment;
    waitbar(bar_len,f, 'Loading CSV data');
    set(0, 'currentfigure', fig1);
    
end
[indx, tf] = listdlg('ListString', nameMatrix, 'PromptString', 'Choose the desired elements');
%Add ROI naming, arbitrarily supports a max of 20
ROI_Names = strings(1, 20);
ROI_Index = 1;
if (strcmp(data_type,'AT%'))
    set(buttons(dataTypeButNum), 'String', {'AT%','WT%'});
elseif (strcmp(data_type,'WT%'))
    set(buttons(dataTypeButNum), 'String', {'WT%','AT%'});
else
    set(buttons(dataTypeButNum), 'String', {'cts'});
end
%Add nameMatrix, matrixEDSData, and pathName to the UserData of the figure
set(fig1,'UserData',{nameMatrix,matrixEDSData,pathName,pixelSize,datafileRead,ROI_Names,ROI_Index,indx,tf,data_type,cf});

bar_len = 1;
waitbar(bar_len,f, 'Loading CSV data');
set(0, 'currentfigure', fig1);
pause(.5);
close(f)
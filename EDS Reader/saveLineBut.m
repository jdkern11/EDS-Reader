function saveLineBut(varargin)

% Get the UserData of the figure, which contains: nameMatrix,pathName,fig2,fig3,profileResults
lineResults = get(gcf,'UserData');
nameMatrix = lineResults{1};
pathName = lineResults{3};
data_type = lineResults{10};

% Determine cell for excel that is empty
if (2*length(nameMatrix) < 25)
    excel_cell = char('A' + (length(nameMatrix)*2+1));
    excel_cell = strcat(excel_cell, '1:', excel_cell, '1');
else
    r = rem(2*length(nameMatrix)+1, 26);
    f = floor((2*length(nameMatrix)+1)/26);
    first_let = char('A' + f - 1);
    second_let = char('A' + r);
    excel_cell = strcat(first_let, second_let, '1:', first_let, second_let, '1');
end

try
    fig2 = lineResults{12};
catch
    return % If there is no line profile data stored in UserData, terminate this script
end
figure(fig2);
profileResults = lineResults{13}; % The first column of profileResults is 
                                 % the x axis, which is the distance in microns.
                                 % The subsequent columns of profileResults
                                 % contain the at. % of those elements listed
                                 % in nameMatrix
 %Creates new director for the linescans
dirName = strcat(pathName, '\Linescans');
if ~(exist(dirName, 'dir'))
    mkdir(dirName)
end

%Create a directory for every linescan
usrInput = inputdlg('Input directory name');
if (isempty(usrInput))
    disp('No name choosen, returning');
    return;
end
fileName = strcat(dirName, {'\'}, usrInput, '_', data_type);
fileName = strjoin(fileName);
temp = 1;
while exist(fileName, 'dir')
    number = num2str(temp, '%2d');
    tempName = strcat({'\'}, usrInput, '_', data_type, {'('}, number, {')'});
    tempName = strjoin(tempName);
    fileName = strcat(dirName, tempName);
    temp = temp+1;
end
mkdir(fileName);
%create a filename to save data to
file = strcat(fileName, '\Line.csv');

%Add distance to header names
tempName = nameMatrix.';
tempNameSTD = nameMatrix.';
for i = 1:length(nameMatrix)
    tempNameSTD(1,i) = strcat(tempNameSTD(1,i), '_std');
    tempNameSTD(1,i) = strjoin(tempNameSTD(1,i), '_std');
end
tempName = ['Distance' tempName tempNameSTD];

%Create table of data
combinedTable = array2table(profileResults);
tempName2 = cellstr(tempName);
tempName2 = strrep(tempName2,' ','_');
combinedTable.Properties.VariableNames = tempName2(1,:);
writetable(combinedTable, file);
xlswrite(file, {data_type}, excel_cell);
saveas(fig2,[fileName '\LineProfileGrayImage.jpg'])


% Save the line-profile results as text file
saveName1 = [fileName, '\LineProfileResults.txt'];
fid = fopen(saveName1, 'wt');
len = length(tempName);
fprintf(fid, '%s\n', char(data_type));
for i = 1:len
    if (i < len)
        fprintf(fid, '%s\t', tempName(1,i));
    else
        fprintf(fid, '%s\n', tempName(1,i));
    end
end
fclose(fid);
dlmwrite(saveName1, profileResults,'-append','delimiter','\t');
msg = msgbox('save complete');
pause(.5);
close(msg);
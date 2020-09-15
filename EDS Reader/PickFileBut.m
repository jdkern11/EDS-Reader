function PickFileBut(varargin)

fig1 = gcf;
cla
axis off
title(' ');

figPosition = varargin{3};

try
    load temp % If a folder was chosen previously, that info. was saved as 'temp'
catch
    pathName = [cd,'\']; % If no folder has been chosen previously, start in the current directory
end

[fileName, pathName] = uigetfile([pathName,'*.csv'], 'Pick a data file', 'MultiSelect', 'on');

if fileName == 0
    % User aborted
    disp('No new file loaded.');
    return
end

save temp pathName % Save the path name, and next time you'll start in that same folder

buttons = get(gcf,'Children');

drawButNum = findButNum(buttons,'String','Draw');
set(buttons(drawButNum),'Value',0);


menuButNum = findButNumFromPos(buttons,'Position',[.91 .4 0.09 0.05]);
set(buttons(menuButNum),'Value',1);
set(buttons(menuButNum),'String','Empty');
set(buttons(menuButNum),'UserData','');

saveNameButNum = findButNum(buttons,'Style','edit');
set(buttons(saveNameButNum),'String',strrep(fileName,'.tif',''));

% saveButNum = findButNum(buttons,'Style','popupmenu');
% fileName

datafile = [pathName,fileName];
%imageShow = double(rgb2gray(imageShow1));
datafileRead = csvread(datafile, 5, 0);
imageShowGrey = mat2gray(datafileRead, [0 255]);
imageShowGrey = imageShowGrey(end:-1:1,:);

[L1,L2] = size(imageShowGrey);

if L2 > 1024
    L2 = floor(L2/4);
    imageShowGrey = imageShowGrey(1:L1,1:L2);
end

[X,Y] = meshgrid(1:L2,1:L1);

imageShowGrey = imageShowGrey - 1.05*max(max(imageShowGrey));

figure(fig1);
title('');
cla
surf(X,Y,imageShowGrey)
set(gcf, 'Renderer','OpenGL');
set(gca,'FontSize',13,'FontWeight','bold');
view(0,90)
colormap bone
shading interp
axis equal
axis off
drawnow
hold on

set(gca,'Xlim',[min(min(X)) max(max(X))]);
set(gca,'Ylim',[min(min(Y)) max(max(Y))]);

%Find other csv files, store in a matrix
listings = dir(pathName);
matrices = zeros((x(1,2)-1), resolutiony, resolutionx);
for i = 1:x(1,2)-1
     tempArray = csvread(allNames(i+1), 5, 0);
   for j = 1:resolutiony
       for k = 1:resolutionx
           matrices(i,j,k) = tempArray(j,k);
       end
   end
end


%TODO
title('Draw area to find EDS averages')

Xlim = get(gca,'Xlim');
Ylim = get(gca,'Ylim');

saveNameButNum = findButNum(buttons,'Style','edit');
loadButNum = findButNum(buttons,'String','Load image');
fullViewButNum = findButNum(buttons,'String','Full view');

set(buttons(saveNameButNum),'UserData',pathName);
set(buttons(loadButNum),'UserData',scaleFactor);
set(buttons(fullViewButNum),'UserData',[Xlim; Ylim]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xy] = ginputFunc1(nPts,limit)

% if limit == 1, then nPts is the max number of pts. allowed
% if limit == 0, then any number of pts can be clicked

Xlims = get(gca,'Xlim');
Ylims = get(gca,'Ylim');

if limit == 1
    maxPts = nPts;
else
    maxPts = 99999;
end

xy=[];
n = 0;
keepClicking = 1;
while keepClicking == 1 % Left click = 1, Right click = 3
    [x, y, but] = ginput(1);
    if isempty(but)
        but = 0;
    end
    
    if but == 1 && n < maxPts
        n = n+1;
        xy(n,1) = x;
        xy(n,2) = y;
        if mod(n,2) ~= 0
            marker_handle(n) = plot(x,y,'r+','MarkerSize', 15);
        else
            marker_handle(n) = plot(x,y,'r+','MarkerSize', 15);
        end
        hold on;
    end
    
    if but == 3
        if n >= 1
            delete(marker_handle(n))
            
            xy_temp = xy(1:n-1,:);
            clear xy
            xy = xy_temp;
            n = n-1;
        end
    end
    
    if limit == 1
        if (but == 32) && (n == nPts)
            keepClicking = 0;
        end
    else
        if (but == 32) && (n >= nPts)
            keepClicking = 0;
        end
    end
end

plot([xy(1,1) xy(2,1) xy(2,1) xy(1,1) xy(1,1)],...
    [xy(1,2) xy(1,2) xy(2,2) xy(2,2) xy(1,2)],'r--','LineWidth',1)
pause(1)
close(gcf);

end

function [xy] = ginputFunc2(nPts,limit)

% if limit == 1, then nPts is the max number of pts. allowed
% if limit == 0, then any number of pts can be clicked

Xlims = get(gca,'Xlim');
Ylims = get(gca,'Ylim');

if limit == 1
    maxPts = nPts;
else
    maxPts = 99999;
end

xy=[];
n = 0;
keepClicking = 1;
while keepClicking == 1 % Left click = 1, Right click = 3
    [x, y, but] = ginput(1);
    if isempty(but)
        but = 0;
    end
    
    if but == 1 && n < maxPts
        n = n+1;
        xy(n,1) = x;
        xy(n,2) = y;
        if mod(n,2) ~= 0
            marker_handle(n) = plot([x x],[Ylims(1) Ylims(2)],'r--','Linewidth', 2.5);
        else
            marker_handle(n) = plot([x x],[Ylims(1) Ylims(2)],'r--','Color',[1 0.4 0.4],'Linewidth', 2.5);
        end
        hold on;
    end
    
    if but == 3
        if n >= 1
            delete(marker_handle(n))
            
            xy_temp = xy(1:n-1,:);
            clear xy
            xy = xy_temp;
            n = n-1;
        end
    end
    
    if limit == 1
        if (but == 32) && (n == nPts)
            keepClicking = 0;
        end
    else
        if (but == 32) && (n >= nPts)
            keepClicking = 0;
        end
    end
end

pause(1)
close(gcf);
end

function [xy] = ginputFunc3(nPts,limit)

% if limit == 1, then nPts is the max number of pts. allowed
% if limit == 0, then any number of pts can be clicked

Xlims = get(gca,'Xlim');
Ylims = get(gca,'Ylim');

if limit == 1
    maxPts = nPts;
else
    maxPts = 99999;
end

xy=[];
n = 0;
keepClicking = 1;
while keepClicking == 1 % Left click = 1, Right click = 3
    [x, y, but] = ginput(1);
    if isempty(but)
        but = 0;
    end
    
    if but == 1 && n < maxPts
        n = n+1;
        xy(n,1) = x;
        xy(n,2) = y;
        if mod(n,2) ~= 0
            marker_handle(n) = plot(x,y,'r+','MarkerSize', 15);
        else
            marker_handle(n) = plot([xy(1,1) xy(2,1)],[xy(1,2) xy(2,2)],'r--','LineWidth', 2.5);
        end
        hold on;
    end
    
    if but == 3
        if n >= 1
            delete(marker_handle(n))
            
            xy_temp = xy(1:n-1,:);
            clear xy
            xy = xy_temp;
            n = n-1;
        end
    end
    
    if limit == 1
        if (but == 32) && (n == nPts)
            keepClicking = 0;
        end
    else
        if (but == 32) && (n >= nPts)
            keepClicking = 0;
        end
    end
end

% plot([xy(1,1) xy(2,1) xy(2,1) xy(1,1) xy(1,1)],...
%     [xy(1,2) xy(1,2) xy(2,2) xy(2,2) xy(1,2)],'r--','LineWidth',1)
pause(1)
close(gcf);

end

function [outputImage,boxSize] = RedRes(inputImage, boxSize)
%%% Note: Box size must be an odd integer

if nargin < 2
    boxSize = 3;
end

[sy,sx] = size(inputImage);

boxEdge = 0.5*(boxSize-1);

jmin = 0.5*(boxSize + 1);
jmax = floor(sy/boxSize)*boxSize - boxEdge;
imin = jmin;
imax = floor(sx/boxSize)*boxSize - boxEdge;

outputImage = zeros((jmax-jmin)/boxSize+1, (imax-imin)/boxSize+1);

n = 0;
for j = jmin:boxSize:jmax
    n = n + 1;
    m = 0;
    for i = imin:boxSize:imax
        m = m + 1;
        %            Norm_coarse_images(j-boxEdge:j+boxEdge,i-boxEdge:i+boxEdge,k) = sum(sum(Norm_images(j-boxEdge:j+boxEdge,i-boxEdge:i+boxEdge,k)))/boxSize^2;
        outputImage(n,m) = sum(sum(inputImage(j-boxEdge:j+boxEdge,i-boxEdge:i+boxEdge)))/boxSize^2;
    end
end

end
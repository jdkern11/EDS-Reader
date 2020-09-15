function DrawBut(varargin)

maps = get(gcf,'UserData');

if isempty(maps)
    return
end

% Identify the buttons on the figure window
buttons = get(gcf,'Children');

% Identify the button numbers of the Full View button, the Draw button, and
% the Zoom button
fullViewButNum = findButNum(buttons,'Tag','FullView');
drawButNum = findButNum(buttons,'Tag','DrawROI');
zoomButNum = findButNum(buttons,'Tag','ZoomDrag');

if ~isempty(get(buttons(fullViewButNum),'UserData'))
    title('');
    
    if get(buttons(drawButNum),'Value') == 1
        set(buttons(zoomButNum),'Value',0);
        set(gcf,'WindowButtonDownFcn',@DrawDownFunction);
        set(gcf,'WindowButtonMotionFcn','');
        set(gcf,'WindowButtonUpFcn','');
    else
        set(gcf,'WindowButtonDownFcn',@DragDownFunction);
        set(gcf,'WindowButtonMotionFcn','');
        set(gcf,'WindowButtonUpFcn','');
    end
    
else
    
    set(buttons(drawButNum),'Value',0);
    set(buttons(zoomButNum),'Value',0);
    
end

end % DrawBut


function DrawDownFunction(varargin)

Xlimits = get(gca,'Xlim');
Ylimits = get(gca,'Ylim');

point1 = get(gca,'CurrentPoint');

if (point1(1,1) >= Xlimits(1)) && (point1(1,1) <= Xlimits(2)) && (point1(1,2) >= Ylimits(1)) && (point1(1,2) <= Ylimits(2))
    inside = 1;
else
    inside = 0;
end

if inside == 1
    set(gcf,'WindowButtonMotionFcn',@DrawMotionFunction);
else
    set(gcf,'WindowButtonMotionFcn','');
    set(gcf,'WindowButtonUpFcn','');
end

end % DrawDownFunction(varargin)


function DrawMotionFunction(varargin)

Xlimits = get(gca,'Xlim');
Ylimits = get(gca,'Ylim');

point2 = get(gca,'CurrentPoint');

if point2(1,1) <= Xlimits(1)
    point2(1,1) = Xlimits(1);
elseif point2(1,1) >= Xlimits(2)
    point2(1,1) = Xlimits(2);
end

if point2(1,2) <= Ylimits(1)
    point2(1,2) = Ylimits(1);
elseif point2(1,2) >= Ylimits(2)
    point2(1,2) = Ylimits(2);
end

plot(point2(1,1),point2(1,2),'ro','MarkerSize',3.0,'MarkerFaceColor','r');

set(gcf,'WindowButtonUpFcn',@DrawUpFunction);

end %ZoomMotionFunction(varargin)
%
function DrawUpFunction(varargin)

scrsz = get(0,'ScreenSize');
fig1Percent = 0.75; % Percent of screen that fig1 occupies
fig1W = fig1Percent*scrsz(3);
fig1H = 0.5*fig1Percent*scrsz(4);
fig1L = 0.5*(scrsz(3)-fig1W);
fig1B = 0.5*(scrsz(4)-fig1H);
figYPos = [fig1L,fig1B,fig1W,1.5*fig1H];

buttons = get(gcf,'Children');
%Import data for ROI naming
maps = get(gcf,'UserData');
ROI_Names = maps{6};
ROI_Index = maps{7};

menuButNum = findButNum(buttons,'Tag','ROIList');

circleMarkers = findobj(gca,'Marker', 'o');

X = get(circleMarkers,'XData');
x = zeros(length(X),1);
for i = 1:length(X)
    x(i) = X{i};
end
Y = get(circleMarkers,'YData');
y = zeros(length(Y),1);
for i = 1:length(Y)
    y(i) = Y{i};
end
delete(circleMarkers);

set(gcf,'WindowButtonMotionFcn','');

hp = plot(x,y,'y.-');

title('Outline an ROI')

curveCoords{1} = [x y];
plotHandle{1} = hp;

Ans = questdlg('Do you want to keep the ROI?');

if strcmp(Ans(1),'Y')
    
    matrixEDSData = maps{2};
    [L1, L2] = size(matrixEDSData(:,:,1)); % The size of the EDS matrices
    maxL = max([L1, L2]); % The largest dimension o the EDS matrices
    
    imMask = zeros(L1,L2); % imMask will contain 1's in the pixel locations
                           % of the (x,y) coordinates of the ROI's boundary
    for j = 1:length(x)
        imMask(int32(y(j)),int32(x(j))) = 1;
    end
    
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
    
    BW1 = imbinarize(edgeImage, 0.5); % make edgeImage binary
    
    % The next step is to make all pixels within the ROI == 1. I.e., to
    % fill in the ROI. The function imclose will be used to do that.
    nhood = true(maxL); % Define the largest neighborhood within which the ROI will be filled
    
    % Fill in the ROI.
    BW2 = imclose(BW1,nhood);
    % Note: This only works when the ROI is convex. If the ROI is concave, this
    % will fill in the concave sections of the shape as well. To correct this, 
    % do the following:
    BW3 = BW2 - BW1; % Create a matrix, BW3, that is the difference between 
    % the filled-in ROI (BW2) and the ROI boundary (BW1). If BW3 contains 
    % more than one shape, this means that the ROI was concave. Therefore, 
    % have the user choose (manually) which region is the correct region.
    
    CC = bwconncomp(BW3,4); % Identify the independent regions in BW3. If
    % the number of regions > 1, then the ROI is concave.
    
    BW4 = zeros(size(BW3)); % BW4 will contain the final filled-in ROI
    
    if CC.NumObjects > 1 % If there is more than one region in BW3, then have the user
                           % select the correct region manually
             
        ok = 0;
        while ok == 0 % This while loop is needed in case the user accidentally clicks
                      % on a region that does not contain white pixels
                      % (i.e., the user clicks outside of all possible
                      % ROIs)
            
            h = msgbox(sprintf(['The exact region for the ROI needs to be identified. \n',...
                'Left-click a point that is located anywhere within the ROI,\n',...
                'then press SPACE BAR.\n',...
                'Right-click to undo your selection.']));
            waitfor(h);
            try
                close(h)
            catch
            end
            
            imageShow = BW3;
            imageShow(imageShow == 0) = 0.3;
            figY = figure;
            imshow(imageShow) % Show the image, setting the background to be grey
            % to allow the black crosshairs to be visible
            set(gcf,'Color','w','Position',figYPos);
            hold on
            
            [xy, ~] = ginputFunc(1,1);
            close(figY)
            
            xCoord = xy(1,1);
            yCoord = xy(1,2);
            
            %         plot(x,y,'r+','MarkerSize',15)
            %         hold off
            %         waitforbuttonpress
            %         close(figY)
            
            ptInd = sub2ind(size(BW3), round(yCoord), round(xCoord)); % This is the point that the user clicked
            
            % Now search through the regions, and find the one that ptInd is within
            testRegions = CC.PixelIdxList;
            for j = 1:length(testRegions)
                testRegion = testRegions{j};
                checkMember = ismember(ptInd,testRegion);
                
                if checkMember == 1
                    BW4(testRegion) = 1; % Fill in BW4 with the correct ROI
                    break
                end
            end
            
            if checkMember ~= 0 % If checkMember is not equal to zero, then the user
                                % clicked within a region that contains
                                % white pixels
                ok = 1; % This will end the while loop
                
            end
        end % This ends the while loop
    else
        
        BW4(CC.PixelIdxList{1}) = 1;
    
    end
      
    boundaries = bwboundaries(BW4); % Find the boundary coordinates of the identified ROI
    xyBndry = boundaries{1};
    curveCoords{1} = [xyBndry(:,2) xyBndry(:,1)]; % Update the coordinates with those of the identified ROI
    delete(hp);
    hp = plot(xyBndry(:,2), xyBndry(:,1),'y.-');
    plotHandle{1} = hp; % Update the plot handle with the plot of the coordinates of the identified ROI
    
    % Name the ROI and save the data
    h = inputdlg('What is this region named?');
    ROI_Names{1, ROI_Index} = char(h);
    ROI_Index = ROI_Index + 1;
    maps{6} = ROI_Names;
    maps{7} = ROI_Index;
    set(gcf,'UserData', maps);
    
    menuList = get(buttons(menuButNum),'String');
    
    if strcmp(menuList,'Empty') == 1
        
        curveNum{1} = '1';
        set(buttons(menuButNum),'String',curveNum);
        
        curveCoordsList{1} = curveCoords;
        curveCoordsList{2} = plotHandle;
        curveCoordsList{3} = [1 1]; % This will serve as a flag to identify:
                                    % 1. Whether or not the user has
                                    %    identified the correct region (0 = no, 1 = yes)
                                    % 2. Which region is the correct one (1, 2, 3, ...)
                                    % This is needed because, depending on
                                    % the shape of the region, there may be
                                    % multiple options for the desired region
        set(buttons(menuButNum),'UserData',curveCoordsList);
    else
        
        lastCurveNum = menuList{end};
        newCurveNum{1} = num2str(str2num(lastCurveNum)+1);
        
        menuList = [menuList;newCurveNum];
        
        set(buttons(menuButNum),'String',menuList);
        
        curveCoordsList = get(buttons(menuButNum),'UserData');
        curveCoordsList{end+1} = curveCoords;
        curveCoordsList{end+1} = plotHandle;
        curveCoordsList{end+1} = [0 0];
        set(buttons(menuButNum),'UserData',curveCoordsList);
        
    end
    
else
    
    title('');
    delete(hp);
end

end %DrawUpFunction(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DragDownFunction(varargin)

X_lim = get(gca,'Xlim');
Y_lim = get(gca,'Ylim');
point1 = get(gca,'CurrentPoint');
set(gcf,'WindowButtonMotionFcn',{@DragMotionFunction,X_lim,Y_lim,point1});

end %DragDownFunction(varargin)

function DragMotionFunction(varargin)

X_lim = varargin{3};
Y_lim = varargin{4};
point1 = varargin{5};

point2 = get(gca,'CurrentPoint');

x_diff = point2(1,1)-point1(1,1);
y_diff = point2(1,2)-point1(1,2);

set(gca,'Xlim',X_lim - x_diff,'Ylim',Y_lim - y_diff);
set(gcf,'WindowButtonUpFcn',@DragUpFunction);

end %DragMotionFunction(varargin)
%
function DragUpFunction(varargin)

set(gcf,'WindowButtonMotionFcn','');

end %DragUpFunction(varargin)

function [xy,markerHandle] = ginputFunc(nPts,limit)

% if limit == 1, then nPts is the max number of pts. allowed
% if limit == 0, then any number of pts can be clicked

Xlims = get(gca,'Xlim');
Ylims = get(gca,'Ylim');
Zlims = get(gca,'Zlim');

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
        if x < Xlims(1)
            x = Xlims(1);
        elseif x > Xlims(2)
            x = Xlims(2);
        end
        
        if y < Ylims(1)
            y = Ylims(1);
        elseif y > Ylims(2)
            y = Ylims(2);
        end
        
        xy(n,1) = x;
        xy(n,2) = y;
        
        if mod(n,2) ~= 0
            markerHandle(n) = plot3(x,y,max(abs(Zlims(2))),'ro','MarkerFaceColor','r','MarkerSize', 8);
        else
            markerHandle(n) = plot3(x,y,max(abs(Zlims(2))),'ro','Color',[0.7 0 0],'MarkerSize', 3);
        end
        hold on;
    end
    
    if but == 3
        if n >= 1
            delete(markerHandle(n))
            
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
end
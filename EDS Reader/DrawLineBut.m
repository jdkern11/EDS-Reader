function DrawLineBut(varargin)

% Get the UserData of the figure, which contains: nameMatrix, matrixEDSData, pathName, pixelSize, and grayImage
maps = get(gcf,'UserData');

if isempty(maps)
    return
end

scrsz = get(0,'ScreenSize');
figPercent = 0.85; % Percent of screen that the figure occupies
figLR = ((1-figPercent)/2)*scrsz(3);
figBot = ((1-figPercent)/2)*scrsz(4);
figW = figPercent*scrsz(3);
figH = figPercent*scrsz(4);

fig2Position = [figLR figBot figW figH];
% fig3Position = fig2Position;
% fig3Position(1) = scrsz(3)/2;

% ElementList contains a list of all possible elements encountered.
% Note: if an element of interest does not appear in this list, feel free
% to add it.
[ElementList, colorArray] = MasterElementList();

% Identify the buttons on the figure window
buttons = get(gcf,'Children');

% Identify the button number of the Draw Line button
drawLineButNum = findButNum(buttons,'Tag','DrawLine');
set(buttons(drawLineButNum),'Value',0); % Set the value of the button == 0

% Match the elements in nameMatrix with their corresponding colors in
% colorArray

nameMatrix = maps{1};
data_type = maps{10};
colorList = zeros(length(nameMatrix),3);
for i = 1:length(nameMatrix)
    colorInd = find(contains(ElementList,nameMatrix(i)));
    colorList(i,:) = colorArray(colorInd,:); % colorList contains the colors for the elements in nameMatrix
end

matrixEDSData = maps{2}; % Retrieve the EDS matrices
% legendNameMatrix = strings(length(indices),1);   
% for k = 1:length(indices)
%    legendNameMatrix(k,1) = nameMatrix(indices(k));
% end
dX = maps{4}; % Retrieve the pixel size
dY = dX;
grayImage = maps{5}; % Retrieve the gray image
[L1, L2] = size(grayImage);
% Display the gray image in a new figure window

imageShowGray = mat2gray(grayImage, [0 255]);

imageShowGray = histeq(imageShowGray);
fig2 = figure('color','w');
subplot(1,2,1)
imshow(imageShowGray);
hold on
set(gcf,'Position',fig2Position);
drawnow

% Add a scale bar
scaleBarL= round(dX*L2/30)*5; % create a scalebar that is approximately 1/6 the width of the image, 
                              % rounded to the nearest multiple of 5
scaleBarPix = round(scaleBarL/dX);
plot([0.05*L2 0.05*L2 + scaleBarPix], [0.92*L1 0.92*L1], '-r', 'LineWidth', 2)
text(0.004*L2 + scaleBarPix/2, 0.88*L1, [num2str(scaleBarL),' {\mu}m'],'color','r');
hold off

% The  button will be used to save the results, including: the line
% drawn on the gray image, the line profile, and the data file
saveButton = uicontrol(fig2,'Style','pushbutton', 'String', 'Save', ...
    'Units','Normalized', 'Position', [0 0 0.09 0.05], ...
    'Callback', @saveLineBut);

uicontrol('Parent',fig2,'Style','togglebutton','String', 'Choose Elements',...
    'Tag', 'ChooseElements',...
    'Units','Normalized','Position',[0 0.9 0.09 0.05],...
    'Callback',@ChooseElementsBut);

set(fig2,'UserData',maps);

h = msgbox(sprintf(['-----------------------\n',...
    'INSTRUCTIONS.\n',...
    '-----------------------\n',...
    'Left click and right click to define the endpoints of a line. \n',...
    'Press UP ARROW to double the averaging width and DOWN ARROW to halve the averaging width.\n',...
    'Press RIGHT ARROW to increase the averaging width by two and DOWN ARROW to decrease the averaging width by two.\n',...
    'Press SPACE BAR to close.']));
% Note that there will be a red dot where the user left-clicked, and a blue
% dot where the user right-clicked, and the dots will be displayed both on
% the gray image and on the profile.
waitfor(h);
try
    close(h)
catch
end

xy = [];
done = 0;

width = 1; % width of line averaging

while done ~= 1  % Left click = 1, right click = 3
    
    figure(fig2);
    subplot(1,2,1)
    hold on
    
    try
        [x, y, but] = ginput(1);
        % if the user has closed the figure manually, this will cause an
        % error
    catch
        % fi the figure has been close manually, exit DrawLineBut
        return
    end
    
    if isempty(but) % Enter
        but = 0;
    end
    
    if but == 32 % Space bar
        done = 1;
        xy = [0;0];
    end
    
    if (done ~= 1) && (x > -0.05*L2) && (x < 1.05*L2) &&  (y > -0.05*L1) && (y < 1.05*L1) % only proceed with the x and y values if the
        % user clicks within boundary of the image +/- 5%
        
        % replace the clicked coordinates with coordinates that fall
        % within the image
        x = min([L2-1 max([x 2])]);
        y = min([L1-1 max([y 2])]);
        
        if but == 1 % Left click
            xy(1,1) = x;
            xy(2,1) = y;
        end
        
        if but == 3 % Right click
            xy(1,2) = x;
            xy(2,2) = y;
        end
               
        if width > 1
            % if there are extra lines for averaging, then replace the
            % clicked (x,y) coordinates with coordinates that
            % can accomodate those lines if need be
            
            x1 = xy(1,1); % Extract the x and y points from xy
            y1 = xy(2,1);
            x2 = xy(1,2);
            y2 = xy(2,2);
                       
            [x1y1Lim1test, x2y2Lim1test, x1y1Lim2test, x2y2Lim2test] = getWidthPts(width,x1,x2,y1,y2);
            
            if outofbounds(x1y1Lim1test,x1y1Lim2test,x2y2Lim1test,x2y2Lim2test, L1, L2)
%                 disp('Warning #2: edge boundary reached')
                [x1, x2, y1, y2] = updateXYpts(width,x1,x2,y1,y2,L1,L2); % update x and y pts if needed
                
                xy(1,1) = x1; % Update the x and y points for xy
                xy(2,1) = y1;
                xy(1,2) = x2;
                xy(2,2) = y2;
            end
            
        end
    else
%         disp('Warning #1: edge boundary reached')
        but = 0;
    end
    
    if (but == 29) && ~isempty(xy) && (size(xy,2) > 1) %  Right arrow

        width = width + 2;
        [x1y1Lim1test, x2y2Lim1test, x1y1Lim2test, x2y2Lim2test] = getWidthPts(width,x1,x2,y1,y2);
        
        % check to see if the new width lines would end up out of bounds
        if outofbounds(x1y1Lim1test,x1y1Lim2test,x2y2Lim1test,x2y2Lim2test, L1, L2) == 1            
%             disp('Warning #2: edge boundary reached')
            width = width - 2; % do not increase width if a limit would be met
        else
            % do nothing
        end
    end
    
    if (but == 28)  && ~isempty(xy) && (size(xy,2) > 1) % Left arrow
        if (width - 2) < 1
            width = 1;
        else
            width = width - 2; % decrement averaging
        end
    end
    
    if (but == 30)  && ~isempty(xy) && (size(xy,2) > 1) %  Up arrow
        
        width = width*2 + 1;
        [x1y1Lim1test, x2y2Lim1test, x1y1Lim2test, x2y2Lim2test] = getWidthPts(width,x1,x2,y1,y2);
        
        % check to see if the new width lines would end up out of bounds
        if outofbounds(x1y1Lim1test,x1y1Lim2test,x2y2Lim1test,x2y2Lim2test, L1, L2) == 1
%             disp('Warning #2: edge boundary reached')
            width = (width-1)/2; % do not increase width if a limit would be met
        else
            % do nothing
        end
    end
    
    if (but == 31)  && ~isempty(xy) && (size(xy,2) > 1) % Down arrow
        if (width-1)/2 < 1
            width = 1;
        else
            width = (width-1)/2; % decrement averaging
            if mod(width,2) == 0
                width = width + 1; % make sure that width stays odd
            else
                % do nothing
            end
        end
    end
    
    try
        delete(RedDot)
        delete(BlueDot)
        delete(ProfileLine)
        delete(ProfileLowerLine)
        delete(ProfileUpperLine)
        hold on
    catch
    end
    
    if ~isempty(xy) && (size(xy,2) > 1) % If both a left and a right points have been clicked, then proceed
        
        x1 = xy(1,1); % Extract the x and y points from xy
        y1 = xy(2,1);
        x2 = xy(1,2);
        y2 = xy(2,2);
        
        ZimageShowGrayMax = max(max(imageShowGray))+.1; % set the z-height of the line to be above the image
        ZimageShowGrayPlot = [ZimageShowGrayMax ZimageShowGrayMax];
        
        % Plot a red dot where the user left-clicked, and a blue dot where the user right-clicked
        RedDot = plot3(x1,y1,ZimageShowGrayMax, 'ro','MarkerEdgeColor', 'k','LineWidth', 0.5,'MarkerFaceColor', 'r','MarkerSize', 7);
        BlueDot = plot3(x2,y2,ZimageShowGrayMax,'bo','MarkerEdgeColor', 'k','LineWidth', 0.5, 'MarkerFaceColor', 'b','MarkerSize', 7);
     
        % Plot the line from which the profile will be extracted
        ProfileLine = plot3([x1 x2],[y1 y2],ZimageShowGrayPlot,'LineWidth', 2, 'Color', 'k');
        % plot the width lines
        
        [x1y1Lim1, x2y2Lim1, x1y1Lim2, x2y2Lim2] = getWidthPts(width,x1,x2,y1,y2); % update the end points of the width lines
        
        if width > 1
            % plot the width lines
            ProfileLowerLine = plot3([x1y1Lim1(1) x2y2Lim1(1)],[x1y1Lim1(2) x2y2Lim1(2)],ZimageShowGrayPlot,'LineWidth', 1, 'Color', 'r', 'LineStyle', '--');
            ProfileUpperLine = plot3([x1y1Lim2(1) x2y2Lim2(1)],[x1y1Lim2(2) x2y2Lim2(2)],ZimageShowGrayPlot,'LineWidth', 1, 'Color', 'r', 'LineStyle', '--');          
        end
        hold off;
        
        % Determine the length of the profile (in pixels)
        XPixelRange = abs(round(x1)-round(x2));
        YPixelRange = abs(round(y1)-round(y2));
        
        try
            clear LineProfile
        catch
        end
        
        subplot(1,2,2)
        cla
        profileResults = zeros(max([XPixelRange YPixelRange])+1,2*length(nameMatrix)+1); % profileResults will contain the at. % results        
        LineProfilesAvging = zeros(max([XPixelRange YPixelRange])+1, 2*width); % this will contain all the line profiles to be averaged 
        data = get(fig2,'UserData');
        indices = data{8};
        cf = data{11};
        legendNameMatrix = strings(length(indices),1);   
        for k = 1:length(indices)
            legendNameMatrix(k,1) = nameMatrix(indices(k));
        end                                                                     % for a given element. The allocation will be: 
                                                                               % [x-axis #1, profile #1, x-axis #2, profile #2, etc.]
        for j = 1:length(nameMatrix)
            
            matrixEDSDataJ = matrixEDSData(:,:,j); % Extract the EDS map of element j
            
            n = 1;
            for k = 1:width  
                
                if width == 1
                    x1end = x1;
                    x2end = x2;
                    y1end = y1;
                    y2end = y2;
                else
                    diffX = (x1y1Lim2(1) - x1y1Lim1(1))/(width-1);
                    diffY = (x1y1Lim2(2) - x1y1Lim1(2))/(width-1); 
                    x1end = x1y1Lim1(1) + (k-1)*diffX;
                    x2end = x2y2Lim1(1) + (k-1)*diffX;
                    y1end = x1y1Lim1(2) + (k-1)*diffY;
                    y2end = x2y2Lim1(2) + (k-1)*diffY;
                end
                [LineProfilesAvging(:,n:n+1)] = getProfile(matrixEDSDataJ,XPixelRange,YPixelRange,x1end,x2end,y1end,y2end,dX,dY); % The function getProfile extracts the results
                % Note: LineProfilesAvging will contain a series of columns as: [x-axis #1, profile #1, x-axis #2, profile #2, etc.]
                n = n+2;
            end
            LineProfile(:,1) = LineProfilesAvging(:,width); % use the original (central) x-axis as the x-axis to save
            LineProfile(:,1) = LineProfile(:,1) - min(LineProfile(:,1)); % set the min x value to be == 0
            LineProfile(:,2) = mean(LineProfilesAvging(:,(2:2:2*width)),2)/cf; % average the profiles (i.e., every other column in LineProfilesAvging)         
            LineProfile(:,3) = std(LineProfilesAvging(:,(2:2:2*width)),0,2)/cf;
            % Plot the new (averaged) profile
            if (ismember(j,indices))
                plot(LineProfile(:,1), LineProfile(:,2),'k-','LineWidth',2.3,'color',colorList(j,:))
                hold on
            end

            % Add the new profile results to profileResults
            if j == 1
                profileResults(:,1) = LineProfile(:,1);
                profileResults(:,2) = LineProfile(:,2);
                profileResults(:,length(nameMatrix)+2) = LineProfile(:,3);
            else
                profileResults(:,j+1) = LineProfile(:,2);
                profileResults(:,length(nameMatrix)+j+1) = LineProfile(:,3);
            end
        end
        
        plot(0, 0,'o','MarkerEdgeColor', 'k','LineWidth', 0.5,'MarkerFaceColor', 'r','MarkerSize', 7);
        plot(LineProfile(end,1), 0,'o','MarkerEdgeColor', 'k','LineWidth', 0.5,'MarkerFaceColor', 'b','MarkerSize', 7);
        
        pbaspect([1.1 1 1])
        xlabel('Distance (\mum)','FontSize',14,'FontWeight','bold');
        ylabel(data_type,'FontSize',14,'FontWeight','bold');
        set(gca,'FontSize',12,'FontWeight','bold')

        legend(legendNameMatrix,'Location','northeastoutside');
        legend 'boxon'
            
        % Store the necessary information in the user data of the figure
        set(fig2,'UserData', {data{1},data{2},data{3},data{4},data{5},data{6},data{7},data{8},data{9},data{10},data{11},fig2,profileResults});
        figure(fig2);
        drawnow      
    end
         
end

% Close the figures if the SPACE BAR was pressed
try
    close(fig2);
catch
end

end

function [x1, x2, y1, y2] = updateXYpts(width,x1,x2,y1,y2,L1,L2)
% If the new clicked point will push the width lines beyond the boundaries
% of the image, update the x1, x2, y1, and y2 coordinates to allow the
% width lines to stay within the image

[x1y1Lim1test, x2y2Lim1test, x1y1Lim2test, x2y2Lim2test] = getWidthPts(width,x1,x2,y1,y2);

if (x1y1Lim1test(1) <= 2) || (x1y1Lim2test(1) <= 2)
    x1 = 2 + (width-1)/2;
end

if (x1y1Lim1test(1) >= L2-1) || (x1y1Lim2test(1) >= L2-1)
    x1 = L2 - (width-1)/2 - 1;
end

if (x2y2Lim1test(1) <= 2) || (x2y2Lim2test(1) <= 2)
x2 = 2 + (width-1)/2;
end

if (x2y2Lim1test(1) >= L2-1) || ( x2y2Lim2test(1) >= L2-1)
    x2 = L2 - (width-1)/2 - 1;
end


if (x1y1Lim1test(2) <= 2) || (x1y1Lim2test(2) <= 2)
    y1 = 2 + (width-1)/2;
end

if (x1y1Lim1test(2) >= L1-1) || (x1y1Lim2test(2) >= L1-1)
    y1 = L1 - (width-1)/2 - 1;
end

if (x2y2Lim1test(2) <= 2) || (x2y2Lim2test(2) <= 2)
    y2 = 2 + (width-1)/2;
end

if (x2y2Lim1test(2) >= L1-1) || ( x2y2Lim2test(2) >= L1-1)
        y2 = L1 - (width-1)/2 - 1;
end

end

function [x1y1Lim1, x2y2Lim1, x1y1Lim2, x2y2Lim2] = getWidthPts(width,x1,x2,y1,y2)

% Math to plot width lines
lim = (width+1)/2-1; % lim defines the number of width lines per side of the profile line
v = [(x2-x1) (y2-y1) 0]; % create a vector, v, that the two clicked points define
m = sqrt((x2-x1)^2 + (y2-y1)^2); % find the magnitude of that vector
vNorm = v/m; % normalize the vector
e = [0 1 0]; % define a unit vector pointing along the y-axis
TH = acos(dot(vNorm,e)); % find the angle, TH, between v and e
BET = cross(vNorm,e); % find the vector perpendicular to v and e
BET = BET(end);

% the following code calculates the x and y distances (in pixels) between
% the end points of the line and the width line, depending on which
% quadrant the v vector lies in
if TH <= pi/2
    if BET > 0 % QUAD IV
        dx1 = lim*cos(TH);
        dx2 = -dx1;
        dy1 = -lim*sin(TH);
        dy2 = -dy1;
    else % QUAD III
        dx1 = -lim*cos(TH);
        dx2 = -dx1;
        dy1 = -lim*sin(TH);
        dy2 = -dy1;
    end
elseif TH > pi/2
    if BET < 0 % QUAD II
        dx1 = lim*cos(TH);
        dx2 = -dx1;
        dy1 = lim*sin(TH);
        dy2 = -dy1;
    else % QUAD I
        dx1 = -lim*cos(TH);
        dx2 = -dx1;
        dy1 = lim*sin(TH);
        dy2 = -dy1;
    end
end
% store the four (4) end points of the two (2) width lines in the
% following:
x1y1Lim1 = [x1+dx1 y1+dy1];
x2y2Lim1 = [x2+dx1 y2+dy1];
x1y1Lim2 = [x1+dx2 y1+dy2];
x2y2Lim2 = [x2+dx2 y2+dy2];

end

function [out] = outofbounds(x1y1Lim1,x1y1Lim2,x2y2Lim1,x2y2Lim2, L1, L2)
% determine if any points out of a set of four points extends beyond the
% boundary of an image

if (x1y1Lim1(1) < 2) || (x1y1Lim2(1) < 2) || (x2y2Lim1(1) < 2) || (x2y2Lim2(1) < 2) || ...
        (x1y1Lim1(2) < 2) || (x1y1Lim2(2) < 2) || (x2y2Lim1(2) < 2) || (x2y2Lim2(2) < 2) || ...
        (x1y1Lim1(1) > L2-1) || (x1y1Lim2(1) > L2-1) || (x2y2Lim1(1) > L2-1) || (x2y2Lim2(1) > L2-1) || ...
        (x1y1Lim1(2) > L1-1) || (x1y1Lim2(2) > L1-1) || (x2y2Lim1(2) > L1-1) || (x2y2Lim2(2) > L1-1)
    out = 1;
else
    out = 0;
end

end

function [LineProfile] = getProfile(EDSmatrix,XPixelRange,YPixelRange,x1,x2,y1,y2,dX,dY)

% This function extracts the at. % results from a line drawn on the gray
% image

if XPixelRange >= YPixelRange % First determine which range of pixels is larger
    
    LargerPixelRange = XPixelRange; % Use the x pixel range as the x axis for the profile
    
    ProfileRes = sqrt((XPixelRange*dX)^2 + (YPixelRange*dY)^2)/LargerPixelRange; % This is the true resolution (in microns) of the profile
    
    if x2 >= x1
        % do nothing
    else
        % switch (x1, y1) with (x2, y2)
        x2temp = x1;
        x1 = x2;
        x2 = x2temp;
        y2temp = y1;
        y1 = y2;
        y2 = y2temp;        
    end
    
    LineProfile(:,1) = x1*dX + (0:LargerPixelRange)*ProfileRes;
    % First do a polyfit to determine the y coordinates of the line
    poly1 = polyfit([x1 x2],[y1 y2],1);
    %poly1(1) is the slope
    %poly1(2) is the y-intercept
    
    % These are the coordinates of the image from which the at. % numbers
    % will be extracted.
    PtsForInterp(:,1) = round(x1)+ (0:length(LineProfile)-1); % These are integers
    PtsForInterp(:,2) = poly1(1)*PtsForInterp(:,1)+poly1(2); % These are not yet integers
    
    for i = 1:length(LineProfile)

        % Determine the the values for the atomic percentages via
        % interpolation
        PixelOffset = round(PtsForInterp(i,2)) - PtsForInterp(i,2);
        if PixelOffset >= 0
            EDSmatrixChange = EDSmatrix(int32(PtsForInterp(i,2)), PtsForInterp(i,1)) - EDSmatrix(int32(PtsForInterp(i,2)-1),PtsForInterp(i,1));
            LineProfile(i,2) = EDSmatrix(int32(PtsForInterp(i,2)-1),PtsForInterp(i,1))  + (1-PixelOffset)*EDSmatrixChange;
        else
            EDSmatrixChange = EDSmatrix(int32(PtsForInterp(i,2)+1),PtsForInterp(i,1)) - EDSmatrix(int32(PtsForInterp(i,2)),PtsForInterp(i,1));
            LineProfile(i,2) = EDSmatrix(int32(PtsForInterp(i,2)),PtsForInterp(i,1))  + abs(PixelOffset)*EDSmatrixChange;
        end
        
    end
    
else
    
    % If YPixelRange is larger, follow a similar procedure as that above,
    % but now using the y-range as the x axis of the profile.
    LargerPixelRange = YPixelRange;
    
    ProfileRes = sqrt((double(XPixelRange)*dX)^2 + (double(YPixelRange)*dY)^2)/LargerPixelRange;
    
    if y2 >= y1
        LineProfile(:,1) = y1*dY + (0:LargerPixelRange)*ProfileRes;
    else
        LineProfile(:,1) = y1*dY - (0:LargerPixelRange)*ProfileRes;
    end
    
    poly1 = polyfit([y1 y2],[x1 x2],1);
    %poly1(1) is the slope
    %poly1(2) is the y-intercept
    
    if y2 >= y1
        PtsForInterp(:,1) = round(y1 + (0:length(LineProfile)-1));
    else
        PtsForInterp(:,1) = round(y1 - (0:length(LineProfile)-1));
    end
    PtsForInterp(:,2) = poly1(1)*PtsForInterp(:,1)+poly1(2);
    for i = 1:length(LineProfile)

        PixelOffset = round(PtsForInterp(i,2)) - PtsForInterp(i,2);
        if PixelOffset >= 0
            EDSmatrixChange = EDSmatrix(PtsForInterp(i,1),int32(PtsForInterp(i,2))) - EDSmatrix(PtsForInterp(i,1),int32(PtsForInterp(i,2)-1));
            LineProfile(i,2) = EDSmatrix(PtsForInterp(i,1),int32(PtsForInterp(i,2)-1))  + (1-PixelOffset)*EDSmatrixChange;
        else
            EDSmatrixChange = EDSmatrix(PtsForInterp(i,1),int32(PtsForInterp(i,2)+1)) - EDSmatrix(PtsForInterp(i,1),int32(PtsForInterp(i,2)));
            LineProfile(i,2) = EDSmatrix(PtsForInterp(i,1),int32(PtsForInterp(i,2)))  + abs(PixelOffset)*EDSmatrixChange;
        end
        
    end
    
    if y2 < y1
        LineProfile(:,1) = LineProfile(length(LineProfile):-1:1,1);
    end
    
end

end


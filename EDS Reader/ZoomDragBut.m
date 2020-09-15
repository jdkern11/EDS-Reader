function ZoomDragBut(varargin)

maps = get(gcf,'UserData');

% Identify the buttons on the figure window
buttons = get(gcf,'Children');
% Identify the button numbers of the Full View button, the Draw button, the
% Zoom button, and the Delete button
fullViewButNum = findButNum(buttons,'Tag','FullView');
drawButNum = findButNum(buttons,'Tag','DrawROI');
zoomButNum = findButNum(buttons,'Tag','ZoomDrag');
deleteButNum = findButNum(buttons,'Tag','DeleteROI');

if isempty(maps)
    set(buttons(zoomButNum),'Value',0);
    return
end

if ~isempty(get(buttons(fullViewButNum),'UserData'))
    title('');
    
    if get(buttons(zoomButNum),'Value') == 1
        set(buttons(drawButNum),'Value',0);
        set(gcf,'WindowButtonDownFcn',@ZoomDownFunction);
        set(gcf,'WindowButtonMotionFcn','');
        set(gcf,'WindowButtonUpFcn','');
    else
        set(gcf,'WindowButtonDownFcn',@DragDownFunction);
        set(gcf,'WindowButtonMotionFcn','');
        set(gcf,'WindowButtonUpFcn','');
        
        try
            h4 = get(buttons(deleteButNum),'UserData');
            delete(h4);
        catch
        end
    end
    
else
    
    set(buttons(zoomButNum),'Value',0);
    
end

end %ZoomDragBut(varargin)


function ZoomDownFunction(varargin)

Xlimits = get(gca,'Xlim');
Ylimits = get(gca,'Ylim');

point1 = get(gca,'CurrentPoint');

if (point1(1,1) >= Xlimits(1)) && (point1(1,1) <= Xlimits(2)) && (point1(1,2) >= Ylimits(1)) && (point1(1,2) <= Ylimits(2))
    inside = 1;
else
    inside = 0;
end

if inside == 1
    set(gcf,'WindowButtonMotionFcn',{@ZoomMotionFunction,point1});
else
    set(gcf,'WindowButtonMotionFcn','');
    set(gcf,'WindowButtonUpFcn','');
end

end %ZoomDownFunction(varargin)

function ZoomMotionFunction(varargin)

point1 = varargin{3};

buttons = get(gcf,'Children');
deleteButNum = findButNum(buttons,'Tag','DeleteROI');

try
    h4 = get(buttons(deleteButNum),'UserData');
    delete(h4);
catch
end

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

width = abs(point1(1,1)- point2(1,1));
height = abs(point1(1,2)- point2(1,2));

if (width >0) && (height >0)
    rect_pts = [min([point1(1,1), point2(1,1)]),min([point1(1,2), point2(1,2)]), width, height];
    h4 = plot([rect_pts(1) rect_pts(1)+width rect_pts(1)+width rect_pts(1) rect_pts(1)],[rect_pts(2) rect_pts(2) rect_pts(2)+height rect_pts(2)+height rect_pts(2)],'Color','r','LineWidth',1.8);
    set(buttons(deleteButNum),'UserData',h4);
    set(gcf,'WindowButtonUpFcn',{@ZoomUpFunction,rect_pts});
end

end %ZoomMotionFunction(varargin)
%
function ZoomUpFunction(varargin)

rect_pts = varargin{3};

buttons = get(gcf,'Children');
deleteButNum = findButNum(buttons,'Tag','DeleteROI');

set(gcf,'WindowButtonMotionFcn','');

try
    
    h4 = get(buttons(deleteButNum),'UserData');
    delete(h4);
catch
end

set(gca,'Xlim',[rect_pts(1) rect_pts(1)+rect_pts(3)]);
set(gca,'Ylim',[rect_pts(2) rect_pts(2)+rect_pts(4)]);
drawnow

end %ZoomUpFunction(varargin)

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
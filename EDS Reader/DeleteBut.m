function DeleteBut(varargin)

maps = get(gcf,'UserData');

if isempty(maps)
    return
end

% Identify the buttons on the figure window
buttons = get(gcf,'Children');
% Identify the button numbers of the Full View button, the Draw button, the
% Zoom button, and the pop-up menu button
fullViewButNum = findButNum(buttons,'Tag','FullView');
drawButNum = findButNum(buttons,'Tag','DrawROI');
zoomButNum = findButNum(buttons,'Tag','ZoomDrag');
menuButNum = findButNum(buttons,'Tag','ROIList');


if ~isempty(get(buttons(fullViewButNum),'UserData'))
    title('');
    
    set(buttons(zoomButNum),'Value',0);
    set(buttons(drawButNum),'Value',0);
    
    pickedCurveNum = get(buttons(menuButNum),'Value');
    
    curveCoordsList = get(buttons(menuButNum),'UserData');
    
    menuList = get(buttons(menuButNum),'String');
    
    if ~strcmp(menuList(1),'E')
        
        plotHandleNum = pickedCurveNum*3-1;
        
        h = curveCoordsList{plotHandleNum};
        h = h{1};
        set(h,'color','r');
        
        questStr = ['Are you sure you want to delete curve #', num2str(pickedCurveNum),'?'];
        Ans = questdlg(questStr);
        
        if strcmp(Ans(1),'Y')
            
            %update ROI naming
            maps = get(gcf,'UserData');
            ROI_Names = maps{6};
            maps{7} = maps{7} - 1;
            for i = pickedCurveNum:maps{7}-1
                ROI_Names{1,i} = ROI_Names{1,i+1};
            end
            maps{6} = ROI_Names;
            set(gcf,'UserData', maps);
            
            curveCoordsList{plotHandleNum} = [];
            curveCoordsList{plotHandleNum-1} = [];
            curveCoordsList{plotHandleNum+1} = [];
            
            delete(h);
            curveCoordsList = curveCoordsList(~cellfun(@isempty, curveCoordsList));
            
            set(buttons(menuButNum),'UserData',curveCoordsList);
            L = length(menuList);
            
            if (pickedCurveNum == L) && (L ~= 1)
                
                set(buttons(menuButNum),'Value',L-1);
                
            end
            
            if L > 1
                menuList(length(menuList)) = [];
                
                set(buttons(menuButNum),'String',menuList);
            else
                
                set(buttons(menuButNum),'String','Empty');
                
            end
            
        else
            
            set(h,'color','y');
            
        end
        
    else
        
        % Do nothing
        
    end
    
end

end
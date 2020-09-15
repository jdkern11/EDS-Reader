function PopUpMenuFnc(varargin)

% Identify the buttons on the figure window
buttons = get(gcf,'Children');
% Identify the button number of the Full View button
fullViewButNum = findButNum(buttons,'Tag','FullView');
% Identify the button number of the pop-up menu
menuButNum = findButNum(buttons,'Tag','ROIList');

if ~isempty(get(buttons(fullViewButNum),'UserData'))
    
    title('');
    
    menuList = get(buttons(menuButNum),'String');
    
    if ~strcmp(menuList(1),'E')
        pickedCurve = get(buttons(menuButNum),'Value');
        
        curveCoordsList = get(buttons(menuButNum),'UserData');
        
        plotDataNum = pickedCurve*3-2;
        
        plotData = curveCoordsList{plotDataNum};
        
        plotData = plotData{1};
        
        hp = plot(plotData(:,1),plotData(:,2),'r.-');
        
        pause(0.5);
        
        delete(hp);
    else
        
        % Do nothing
        
    end
    
end
end
function FullViewBut(varargin)

maps = get(gcf,'UserData');

if isempty(maps)
    return
end

% Identify the buttons on the figure window
buttons = get(gcf,'Children');
% Identify the button number of the Full View button
fullViewButNum = findButNum(buttons,'Tag','FullView');

if ~isempty(get(buttons(fullViewButNum),'UserData'))
    title('');
    
    try
        hd = get(gcf,'UserData');
        delete(hd);
    catch
    end
    
    Lims = get(gco,'UserData');
    
    set(gca,'Xlim',Lims(1,1:2));
    set(gca,'Ylim',Lims(2,1:2));
else
    
    set(buttons(fullViewButNum),'Value',0);
    
end

end
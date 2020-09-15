function ChooseElementsBut(varargin)


% Identify the buttons on the figure window
buttons = get(gcf,'Children');

% Identify the button number of the Choose Elements button
ChooseElementsButNum = findButNum(buttons,'Tag','ChooseElements');
set(buttons(ChooseElementsButNum),'Value',0); % Set the value of the button == 0

% Acquire the user data
maps = get(gcf,'UserData');

if isempty(maps)
    return
end

nameMatrix = maps{1};
old_indices = maps{8};
str = {'Choose the desired elements,'; 'then click figure window to update'};
% Ask user to change chosen elements and store in user data
[maps{8},maps{9}] = listdlg('ListString', nameMatrix, 'PromptString', str);
% if the user cancels then maintain old elements
if (maps{9} == 0)
    maps{8} = old_indices;
end

set(gcf,'UserData', maps);
end
function [butNum] = findButNumFromPos(buttons,str,pos)
format long g
% This program returns the number of the button in question
pos = round(pos*100)/100;
for i = 1:length(buttons)
    try
        pos2 = get(buttons(i),str);
        pos2 = round(pos2*100)/100;
        if (isequal(pos,pos2))
            butNum = i;
            break
        end
    catch
    end
end

end
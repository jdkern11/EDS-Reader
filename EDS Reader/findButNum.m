function [butNum] = findButNum(buttons,str1,str2)

% This program returns the number of the button in question

for i = 1:length(buttons)
    try
        if strcmp(num2str(get(buttons(i),str1)),num2str(str2))
            butNum = i;
            break
        end
    catch
    end
end

end
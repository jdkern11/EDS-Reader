function ThresholdMappingBut(varargin)


    %%% Get button information and parameters of data
    % Identify the buttons on the figure window
    buttons = get(gcf,'Children');
    % Get the UserData of the figure, which contains: nameMatrix, matrixEDSData, pathName, pixelSize, and grayImage
    maps = get(gcf,'UserData');
    if isempty(maps)
        return
    end


    % Identify the button number of the Threshold Mapping button
    ThresholdMappingButNum = findButNum(buttons,'Tag','ThresholdMapping');
    set(buttons(ThresholdMappingButNum),'Value',0); % Set the value of the button == 0

    bar_len = 0;
    f = waitbar(bar_len, 'Loading Threshold Data','WindowStyle', 'modal');
    % Get waitbar to always be on top
    frames = java.awt.Frame.getFrames();
    frames(end).setAlwaysOnTop(1); 
    bar_len = .1;
    
    % ElementList contains a list of all possible elements encountered.
    % Note: if an element of interest does not appear in this list, feel free
    % to add it.
    [ElementList, colorArray] = MasterElementList();

    % Match the elements in nameMatrix with their corresponding colors in
    % colorArray
    nameMatrix = maps{1};
    pathName = maps{3}; % Retrieve the path name
    data_type = maps{10};
    indx = maps{8};
    cf = maps{11};
    nelements = length(nameMatrix);

    colorList = zeros(length(nameMatrix),3);
    % find colors
    for i = 1:length(nameMatrix)
        colorInd = find(contains(ElementList,nameMatrix(i)));
        colorList(i,:) = colorArray(colorInd,:); % colorList contains the colors for the elements in nameMatrix
    end
    bar_len = bar_len+.1;
    waitbar(bar_len,f, 'Loading Threshold Data','WindowStyle', 'modal');
    matrixEDSData = maps{2}; % Retrieve the EDS matrices

    % Gaussian smoothing filter to redue noise (OPTIONAL)
    for i = 1:length(nameMatrix)
        matrixEDSData(:,:,i) = imgaussfilt(matrixEDSData(:,:,i),0.75);
    end


    % Create new directory for the Oxide Map (not added to the colored map as
    dirName = strcat(pathName, '\ColoredMaps_', char(data_type));
    if ~(exist(dirName, 'dir'))
        ColoredMapsBut();
    end

    if ~(exist(dirName, 'dir'))
        msgbox('Element Mapping Not Run... Returning');
        return;
    end
    %extract sizes of matrices
    x = size(matrixEDSData,1);
    y = size(matrixEDSData,2);


    %%% Create a new windows for the threshold mapping and colormap
    scrsz = get(0,'ScreenSize');
    figPercent = 0.85; % Percent of screen that the figure occupies
    figLR = ((1-figPercent+.65)/2)*scrsz(3);
    figBot = ((1-figPercent)/2)*scrsz(4);
    figW = (figPercent-.25)*scrsz(3);
    figH = figPercent*scrsz(4);

    fig2Position = [figLR figBot figW figH];
    fig2 = uifigure('color','w','name','thresholdcontrol','Scrollable','on');
    set(fig2,'Position',fig2Position);
%     main_panel = uipanel(fig2, 'Position', fig2Position);
%     main_panel.Scrollable = 'on';

    fig3 = figure('color','w', 'name','thresholdmap');
    movegui(fig3,'west');



    %%% create sliders for rich elements and combos of 2 or 3
    labels = cell(1,4*nelements);
    label_headers = cell(1,12);
    
    base_checkboxes = cell(1,nelements);
    rich_checkboxes = cell(1,nelements);
    combo_2_checkboxes = cell(1,nelements);
    combo_3_checkboxes = cell(1,nelements);
    
    % Lower bound of elements
    rich_sliders_lower = cell(1,nelements);
    combo_2_sliders_lower = cell(1,nelements);
    combo_3_sliders_lower = cell(1,nelements);
    lower_base_textboxes = cell(1,nelements);
    old_lower_base_textboxes = cell(1,nelements);
    slider_values_lower = cell(3,nelements);
    old_slider_values_lower = cell(3,nelements);
    
    % Upper bound of elements
    upper_base_textboxes = cell(1,nelements);
    rich_sliders_upper = cell(1,nelements);
    combo_2_sliders_upper = cell(1,nelements);
    combo_3_sliders_upper = cell(1,nelements);
    old_upper_base_textboxes = cell(1,nelements);
    slider_values_upper = cell(3,nelements);
    old_slider_values_upper = cell(3,nelements);
    

    left_pos = figW-5*figW/8;
    for i = 1:nelements
        bar_len = bar_len + .3/nelements; %go to .5
        waitbar(bar_len,f, 'Loading Threshold Data','WindowStyle', 'modal');
        top_pos = figH-i*figH/16;
        base_checkboxes{i} = uicheckbox(fig2,'Text','','Position',[left_pos-100, top_pos-20, 100, 32]);
        base_checkboxes{i}.Value = 1;
        rich_checkboxes{i} = uicheckbox(fig2,'Text','','Position',[left_pos+70, top_pos-20, 100, 32]);
        rich_checkboxes{i}.Value = 0;
        combo_2_checkboxes{i} = uicheckbox(fig2,'Text','','Position',[left_pos+475, top_pos-20, 100, 32]);
        combo_2_checkboxes{i}.Value = 0;
        combo_3_checkboxes{i} = uicheckbox(fig2,'Text','','Position',[left_pos+880, top_pos-20, 100, 32]);
        combo_3_checkboxes{i}.Value = 0;
        labels{i} = uilabel(fig2,'Text',nameMatrix(i,1),'Position',[left_pos-135, top_pos-29, 32, 50]);
        labels{i+nelements} = uilabel(fig2,'Text',nameMatrix(i,1),'Position',[left_pos+35, top_pos-29, 32, 50]);
        labels{i+(2*nelements)} = uilabel(fig2,'Text',nameMatrix(i,1),'Position',[left_pos+440, top_pos-29, 32, 50]);
        labels{i+(3*nelements)} = uilabel(fig2,'Text',nameMatrix(i,1),'Position',[left_pos+845, top_pos-29, 32, 50]);
        
        % Lower bound of elements
        lower_base_textboxes{1,i} = uitextarea(fig2,'Value','0','Position',[left_pos - 80, top_pos-14, 40, 20]);
        old_lower_base_textboxes{1,i} = lower_base_textboxes{1,i}.Value;
        rich_sliders_lower{i} = uislider(fig2, 'Position',[left_pos+95, top_pos, 100, 3], 'Limits',[0 100]);
        rich_sliders_lower{i}.Value = 0;
        slider_values_lower{1,i} = uitextarea(fig2,'Value',num2str(rich_sliders_lower{i}.Value),'Position',[left_pos + 210, top_pos-14, 40, 20]);
        combo_2_sliders_lower{i} = uislider(fig2, 'Position',[left_pos+500, top_pos, 100, 3],'Limits',[0 100]);
        combo_2_sliders_lower{i}.Value = 0;
        slider_values_lower{2,i} = uitextarea(fig2,'Value',num2str(rich_sliders_lower{i}.Value),'Position',[left_pos + 615, top_pos-14, 40, 20]);
        combo_3_sliders_lower{i} = uislider(fig2, 'Position',[left_pos+905, top_pos, 100, 3],'Limits',[0 100]);
        combo_3_sliders_lower{i}.Value = 0;
        slider_values_lower{3,i} = uitextarea(fig2,'Value',num2str(rich_sliders_lower{i}.Value),'Position',[left_pos + 1020, top_pos-14, 40, 20]);
        old_slider_values_lower{1,i} = slider_values_lower{1,i}.Value;
        old_slider_values_lower{2,i} = slider_values_lower{2,i}.Value;
        old_slider_values_lower{3,i} = slider_values_lower{3,i}.Value;
        
        % Upper bound of elements
        upper_base_textboxes{1,i} = uitextarea(fig2,'Value','100','Position',[left_pos-30, top_pos-14, 40, 20]);
        old_upper_base_textboxes{1,i} = lower_base_textboxes{1,i}.Value;
        rich_sliders_upper{i} = uislider(fig2, 'Position',[left_pos+260, top_pos, 100, 3], 'Limits',[0 100]);
        rich_sliders_upper{i}.Value = 100;
        slider_values_upper{1,i} = uitextarea(fig2,'Value',num2str(rich_sliders_upper{i}.Value),'Position',[left_pos + 375, top_pos-14, 40, 20]);
        combo_2_sliders_upper{i} = uislider(fig2, 'Position',[left_pos+665, top_pos, 100, 3],'Limits',[0 100]);
        combo_2_sliders_upper{i}.Value = 100;
        slider_values_upper{2,i} = uitextarea(fig2,'Value',num2str(rich_sliders_upper{i}.Value),'Position',[left_pos + 780, top_pos-14, 40, 20]);
        combo_3_sliders_upper{i} = uislider(fig2, 'Position',[left_pos+1070, top_pos, 100, 3],'Limits',[0 100]);
        combo_3_sliders_upper{i}.Value = 100;
        slider_values_upper{3,i} = uitextarea(fig2,'Value',num2str(rich_sliders_upper{i}.Value),'Position',[left_pos + 1185, top_pos-14, 40, 20]);
        old_slider_values_upper{1,i} = slider_values_upper{1,i}.Value;
        old_slider_values_upper{2,i} = slider_values_upper{2,i}.Value;
        old_slider_values_upper{3,i} = slider_values_upper{3,i}.Value;
        
        
    end
    top_pos = figH-figH/16;
    label_headers{1} = uilabel(fig2,'Text','Single Element Thresholds','Position',[left_pos+160, top_pos+20, 200, 32]);
    label_headers{2} = uilabel(fig2,'Text','Lower','Position',[left_pos+127.5, top_pos, 200, 32]);
    label_headers{3} = uilabel(fig2,'Text','Upper','Position',[left_pos+292.5, top_pos, 200, 32]);
    label_headers{4} = uilabel(fig2,'Text','Binary Combination Thresholds','Position',[left_pos+565, top_pos+20, 200, 32]);
    label_headers{5} = uilabel(fig2,'Text','Lower','Position',[left_pos+532.5, top_pos, 200, 32]);
    label_headers{6} = uilabel(fig2,'Text','Upper','Position',[left_pos+697.5, top_pos, 200, 32]);
    label_headers{7} = uilabel(fig2,'Text','Ternary Combination Thresholds','Position',[left_pos+970, top_pos+20, 200, 32]);
    label_headers{8} = uilabel(fig2,'Text','Lower','Position',[left_pos+937.5, top_pos, 200, 32]);
    label_headers{9} = uilabel(fig2,'Text','Upper','Position',[left_pos+1102.5, top_pos, 200, 32]);
    label_headers{10} = uilabel(fig2,'Text','Base Elements Thresholds','Position',[left_pos-115, top_pos+20, 200, 32]);
    label_headers{11} = uilabel(fig2,'Text','Lower','Position',[left_pos-80, top_pos, 200, 32]);
    label_headers{12} = uilabel(fig2,'Text','Upper','Position',[left_pos-30, top_pos, 200, 32]); 
    %%% Create list of colors for single, binary, and ternary combinations
    rich_colors = zeros(nelements,3);
    for i=1:nelements
        rich_colors(i, 1) = colorList(i,1);
        rich_colors(i, 2) = colorList(i,2);
        rich_colors(i, 3) = colorList(i,3);
    end
    
    binary_colors = zeros(nelements*(nelements-1)/2,3);
    curr_indx = 0;
    for i = 1:(nelements-1)
        for n = (i+1):nelements
            curr_indx = curr_indx + 1;
            R1 = colorList(i,1);
            G1 = colorList(i,2);
            B1 = colorList(i,3);
            R2 = colorList(n,1);
            G2 = colorList(n,2);
            B2 = colorList(n,3);
            newc = binaryColorMeld(R1,G1,B1,R2,G2,B2);
            binary_colors(curr_indx,1) = newc(1);
            binary_colors(curr_indx,2) = newc(2);
            binary_colors(curr_indx,3) = newc(3);
        end
    end
    
    ternary_colors = zeros(nelements*(nelements-1)*(nelements-2)/6,3);
    curr_indx = 0;
    for i = 1:(nelements-2)
        for n = (i+1):(nelements-1)
            for m = n+1:nelements
                curr_indx = curr_indx + 1;
                R1 = colorList(i,1);
                G1 = colorList(i,2);
                B1 = colorList(i,3);
                R2 = colorList(n,1);
                G2 = colorList(n,2);
                B2 = colorList(n,3);
                R3 = colorList(m,1);
                G3 = colorList(m,2);
                B3 = colorList(m,3);
                newc = ternaryColorMeld(R1,G1,B1,R2,G2,B2,R3,G3,B3);
                ternary_colors(curr_indx,1) = newc(1);
                ternary_colors(curr_indx,2) = newc(2);
                ternary_colors(curr_indx,3) = newc(3);
            end
        end
    end
    
    
    single_name_matrix = strings(nelements,1);
    for k = 1:nelements
        temp_len = strlength(nameMatrix(k,1));
        temp = nameMatrix(k,1);
        rich_name = extractBetween(temp,1,temp_len-2);
        temp = strcat(rich_name,'-rich');
        single_name_matrix(k,1) = temp;
    end       
    
    
    %%% create list of binary combinations possible
    binary_combos = strings(nelements*(nelements-1)/2,4);
    % determines if combo_1 (0) or combo_2 (1) for name is used;
    binary_choices = zeros(nelements*(nelements-1)/2,1);
    curr_indx = 0;
    for k = 1:(nelements-1)
        bar_len = bar_len + .25/(nelements-1); %go to .75
        waitbar(bar_len,f, 'Loading Threshold Data','WindowStyle', 'modal');
        for j = (k+1):nelements
            curr_indx = curr_indx + 1;
            indx1 = k;
            indx2 = j;
            temp_len_1 = strlength(nameMatrix(indx1,1));
            temp_1 = nameMatrix(indx1,1);
            temp_len_2 = strlength(nameMatrix(indx2,1));
            temp_2 = nameMatrix(indx2,1);
            name_1 = extractBetween(temp_1,1,temp_len_1-2);
            name_2 = extractBetween(temp_2,1,temp_len_2-2);
            temp_1 = strcat(name_1,'-',name_2);
            temp_2 = strcat(name_2,'-',name_1);
            temp_3 = strcat(name_1,'-',name_2,'-rich');
            temp_4 = strcat(name_2,'-',name_1,'-rich');
            % set this for now
            binary_combos(curr_indx,1) = temp_1;
            binary_combos(curr_indx,2) = temp_2;
            binary_combos(curr_indx,3) = temp_3;
            binary_combos(curr_indx,4) = temp_4;
        end
    end
    binary_check_boxes = cell(1,nelements*(nelements-1)/2);
    for k = 1:nelements*(nelements-1)/2
        % hide all boxes offscreen initially
        binary_check_boxes{k} = uicheckbox(fig2,'Text',binary_combos(k,1),'Position',[0, 0, 100, 32]);
        binary_check_boxes{k}.Value = 1;
    end
    
    %%% create list of binary combinations possible
    ternary_combos = strings(nelements*(nelements-1)*(nelements-2)/6,12);
    ternary_choices = zeros(nelements*(nelements-1)*(nelements-2)/6,1);
    curr_indx = 0;
    for k = 1:(nelements-2)
        bar_len = bar_len + .20/(nelements-2); %go to .95
        waitbar(bar_len,f, 'Loading Threshold Data','WindowStyle', 'modal');
        for j = (k+1):nelements-1
            for n = (j+1):nelements
                curr_indx = curr_indx + 1;
                combo_3_1_indx = k;
                combo_3_2_indx = j;
                combo_3_3_indx = n;
                temp_1 = nameMatrix(combo_3_1_indx,1);
                temp_len_1 = strlength(temp_1);
                temp_2 = nameMatrix(combo_3_2_indx,1);
                temp_len_2 = strlength(temp_2);
                temp_3 = nameMatrix(combo_3_3_indx,1);
                temp_len_3 = strlength(temp_3);
                name_1 = extractBetween(temp_1,1,temp_len_1-2);
                name_2 = extractBetween(temp_2,1,temp_len_2-2);
                name_3 = extractBetween(temp_3,1,temp_len_3-2);
                % set this for now
                ternary_combos(curr_indx,1) = strcat(name_1,'-',name_2,'-',name_3);
                ternary_combos(curr_indx,2) = strcat(name_1,'-',name_3,'-',name_2);
                ternary_combos(curr_indx,3) = strcat(name_2,'-',name_1,'-',name_3);
                ternary_combos(curr_indx,4) = strcat(name_2,'-',name_3,'-',name_1);
                ternary_combos(curr_indx,5) = strcat(name_3,'-',name_2,'-',name_1);
                ternary_combos(curr_indx,6) = strcat(name_3,'-',name_1,'-',name_2);
                ternary_combos(curr_indx,7) = strcat(name_1,'-',name_2,'-',name_3,'-rich');
                ternary_combos(curr_indx,8) = strcat(name_1,'-',name_3,'-',name_2,'-rich');
                ternary_combos(curr_indx,9) = strcat(name_2,'-',name_1,'-',name_3,'-rich');
                ternary_combos(curr_indx,10) = strcat(name_2,'-',name_3,'-',name_1,'-rich');
                ternary_combos(curr_indx,11) = strcat(name_3,'-',name_2,'-',name_1,'-rich');
                ternary_combos(curr_indx,12) = strcat(name_3,'-',name_1,'-',name_2,'-rich');
            end
        end
    end
    ternary_check_boxes = cell(1,nelements*(nelements-1)*(nelements-2)/6);
    for k = 1:nelements*(nelements-1)*(nelements-2)/6
        ternary_check_boxes{k} = uicheckbox(fig2,'Text',ternary_combos(k,1),'Position',[0, 0, 100, 32]);
        ternary_check_boxes{k}.Value = 1;
    end


    % some data for easier offsetting
    combo_2_offsets = zeros(nelements-1,1);
    for i = 1:nelements-1
        if (i == 1)
        combo_2_offsets(i) = nelements-1;
        else
            combo_2_offsets(i) = combo_2_offsets(i-1) + nelements - i;
        end
    end
    
    % set base color
    base_c = [82 82 82]./255;
    base_name = 'Base';
    % 0 means not a base pixel, 1 means is a base pixel
    base_loc = zeros(x,y);
    % set all pixels to base pixel
    for j = 1:y
        for k = 1:x
            base_loc(k,j) = 1;
        end
    end

    %%% create buttons
    uibutton('Parent',fig2,'Text','Re(name/color) Single',...
        'Tag', 'Single',...
        'Position',[0,figH-figH/10, 150, 22],...
        'ButtonPushedFcn',@RichColorsBut);
    
    uibutton('Parent',fig2,'Text','Re(name/color) Binary',...
        'Tag', 'BinaryCombo',...
        'Position',[0,figH-2*figH/10, 150, 22],...
        'ButtonPushedFcn',@BinaryCombosBut);
    
    uibutton('Parent',fig2,'Text','Re(name/color) Ternary',...
        'Tag', 'TernaryCombo',...
        'Position',[0,figH-3*figH/10, 150, 22],...
        'ButtonPushedFcn',@TernaryCombosBut);
    
    uibutton('Parent',fig2,'Text','Re(name/color) Base',...
        'Tag', 'BaseName',...
        'Position',[0,figH-4*figH/10, 150, 22],...
        'ButtonPushedFcn',@BaseNameBut);
    
    uibutton('Parent',fig2,'Text','Update Figure',...
        'Tag', 'UpdateFig',...
        'Position',[0,figH-5*figH/10, 150, 22],...
        'ButtonPushedFcn',@UpdateFigBut);
    
    uibutton('Parent',fig2,'Text','Save Figure',...
        'Tag', 'SaveFig',...
        'Position',[0,figH-6*figH/10, 150, 22],...
        'ButtonPushedFcn',@SaveFigBut);
        
    uibutton('Parent',fig2,'Text','Close',...
        'Tag', 'CloseThreshold',...
        'Position',[0,figH-7*figH/10, 150, 22],...
        'ButtonPushedFcn',@CloseThresholdBut);

   
    
    %%% create while loop to continue running until figure 2 is exited
    % exit while loop if figure closed
    done = 0;
    % update_data figure only if changes occur
    update_data = 1;
    update_fig = 0;
    include_base_checkbox = uicheckbox(fig2,'Text','Base','Position',[(10+75), 10, 100, 32]);
    include_base_checkbox.Value = 1;
    
    bar_len = bar_len + 0.05; %go to 1
    waitbar(bar_len,f, 'Loading Threshold Data','WindowStyle', 'modal');
    close(f)
    
    
    
    while done ~= 1 
        bar_len = 0;
        % If an error is thrown, assume figure exited and return
        try   
            %disp(rich_sliders{1}.Value)
        catch
            break
        end
        % determines if fig2 is still open. If it is not, return
        open = findobj(fig2,'name','thresholdcontrol');
        if (isempty(open))
            done=1;
            break;
        end
        
        for i = 1:nelements
            % Lower elements
            val = str2double(lower_base_textboxes{1,i}.Value);
            if (isnan(val) || val < 0 || val > 100)
                lower_base_textboxes{1,i}.Value = old_lower_base_textboxes{1,i};
            end
            if (str2double(old_slider_values_lower{1,i}) ~= str2double(slider_values_lower{1,i}.Value))
                val = str2double(slider_values_lower{1,i}.Value);
                if (~isnan(val) && val >= rich_sliders_lower{i}.Limits(1) && val <= rich_sliders_lower{i}.Limits(2))
                    rich_sliders_lower{i}.Value = str2double(slider_values_lower{1,i}.Value);
                end
            end
            if (str2double(old_slider_values_lower{2,i}) ~= str2double(slider_values_lower{2,i}.Value))
                val = str2double(slider_values_lower{2,i}.Value);
                if (~isnan(val) && val >= combo_2_sliders_lower{i}.Limits(1) && val <= combo_2_sliders_lower{i}.Limits(2))
                    combo_2_sliders_lower{i}.Value = str2double(slider_values_lower{2,i}.Value);
                end
            end
            if (str2double(old_slider_values_lower{3,i}) ~= str2double(slider_values_lower{3,i}.Value))
                val = str2double(slider_values_lower{3,i}.Value);
                if (~isnan(val) && val >= combo_3_sliders_lower{i}.Limits(1) && val <= combo_3_sliders_lower{i}.Limits(2))
                    combo_3_sliders_lower{i}.Value = str2double(slider_values_lower{3,i}.Value);
                end
            end
            slider_values_lower{1,i}.Value = num2str(rich_sliders_lower{i}.Value);
            slider_values_lower{2,i}.Value = num2str(combo_2_sliders_lower{i}.Value);
            slider_values_lower{3,i}.Value = num2str(combo_3_sliders_lower{i}.Value);
            
            % Upper Elements
            val = str2double(upper_base_textboxes{1,i}.Value);
            if (isnan(val) || val < 0 || val > 100)
                upper_base_textboxes{1,i}.Value = old_upper_base_textboxes{1,i};
            end
            if (str2double(old_slider_values_upper{1,i}) ~= str2double(slider_values_upper{1,i}.Value))
                val = str2double(slider_values_upper{1,i}.Value);
                if (~isnan(val) && val >= rich_sliders_upper{i}.Limits(1) && val <= rich_sliders_upper{i}.Limits(2))
                    rich_sliders_upper{i}.Value = str2double(slider_values_upper{1,i}.Value);
                end
            end
            if (str2double(old_slider_values_upper{2,i}) ~= str2double(slider_values_upper{2,i}.Value))
                val = str2double(slider_values_upper{2,i}.Value);
                if (~isnan(val) && val >= combo_2_sliders_upper{i}.Limits(1) && val <= combo_2_sliders_upper{i}.Limits(2))
                    combo_2_sliders_upper{i}.Value = str2double(slider_values_upper{2,i}.Value);
                end
            end
            if (str2double(old_slider_values_upper{3,i}) ~= str2double(slider_values_upper{3,i}.Value))
                val = str2double(slider_values_upper{3,i}.Value);
                if (~isnan(val) && val >= combo_3_sliders_upper{i}.Limits(1) && val <= combo_3_sliders_upper{i}.Limits(2))
                    combo_3_sliders_upper{i}.Value = str2double(slider_values_upper{3,i}.Value);
                end
            end
            slider_values_upper{1,i}.Value = num2str(rich_sliders_upper{i}.Value);
            slider_values_upper{2,i}.Value = num2str(combo_2_sliders_upper{i}.Value);
            slider_values_upper{3,i}.Value = num2str(combo_3_sliders_upper{i}.Value);
        end

        if (update_data == 1)
            f = waitbar(bar_len, 'Updating Threshold Data','WindowStyle', 'modal');
            frames = java.awt.Frame.getFrames();
            frames(end).setAlwaysOnTop(1); 
            
            for k = 1:nelements*(nelements-1)/2
                % re-hide all boxes offscreen
                binary_check_boxes{k}.Position = [1, 1, 100, 32];
                binary_check_boxes{k}.Visible = 'off';
            end
            for k = 1:nelements*(nelements-1)*(nelements-2)/6
                % re-hide all boxes offscreen
                ternary_check_boxes{k}.Position = [1, 1, 100, 32];
                ternary_check_boxes{k}.Visible = 'off';
            end
            binary_check_box_update_datas = zeros(nelements*(nelements-1)/2,1);
            ternary_check_box_update_datas = zeros(nelements*(nelements-1)*(nelements-2)/6,1);
            set(0, 'CurrentFigure', fig3)
            %%% Store data for rich elements
            % matrix to store the max element of the pixel
            max_intensity_loc_rich = zeros(x,y);
            % Matrix to store the intensity value of the rich elements
            max_intensity_val_rich = zeros(x, y);

            % store data for the rich elements
            for i = 1:nelements
                bar_len = bar_len + .1/nelements; %go to .1
                waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
                EDSmap = matrixEDSData(:,:,i)/cf;
                if (rich_checkboxes{i}.Value == 1)
                    for j = 1:y
                        for k = 1:x
                            if (EDSmap(k,j) >= rich_sliders_lower{i}.Value && EDSmap(k,j) <= rich_sliders_upper{i}.Value)
                                if ((EDSmap(k,j) >= max_intensity_val_rich(k,j)))
                                    max_intensity_loc_rich(k,j) = i;
                                    max_intensity_val_rich(k,j) = EDSmap(k,j);
                                end
                            end
                        end
                    end
                end
            end


            %%% store data for 2 combo element
            % matrix to store the max element of the pixel
            combo_2_loc = zeros(x,y);
            % Matrix to store the intensity value of lower intensity of any
            % combo
            intensity_val_2_combo = zeros(x, y);
            % store data for the rich elements
            curr_indx = 0;
            for i = 1:(nelements-1)
                bar_len = bar_len + .2/(nelements-1); %go to .3
                waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
                EDSmap1 = matrixEDSData(:,:,i)/cf;
                for n = (i+1):nelements
                    curr_indx = curr_indx + 1;
                    EDSmap2 = matrixEDSData(:,:,n)/cf;
                    if (combo_2_checkboxes{i}.Value == 1 && combo_2_checkboxes{n}.Value == 1)
                        for j = 1:y
                            for k = 1:x
                                % see if both intensities between the
                                % thresholds
                                if (EDSmap1(k,j) >= combo_2_sliders_lower{i}.Value &&...
                                        EDSmap2(k,j) >= combo_2_sliders_lower{n}.Value &&...
                                        EDSmap1(k,j) <= combo_2_sliders_upper{i}.Value && ...
                                        EDSmap2(k,j) <= combo_2_sliders_upper{n}.Value)
                                    % if both above value they are a
                                    % possible combo, so put checkbox
                                    binary_check_box_update_datas(curr_indx) = 1;                                    
                                    if (binary_check_boxes{curr_indx}.Value == 1)
                                        % compare min intensities. Could add ability to
                                        % choose min or max
                                        %min_intensity = 0;
                                        if (EDSmap1(k,j) > EDSmap2(k,j))
                                            min_intensity = EDSmap2(k,j);
                                        else
                                            min_intensity = EDSmap1(k,j);
                                        end
                                        if ((min_intensity >= intensity_val_2_combo(k,j)))
                                            combo_2_loc(k,j) = curr_indx;
                                            intensity_val_2_combo(k,j) = min_intensity;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            %%% store data for tenary element combos
            % matrix to store the max element of the pixel
            combo_3_loc = zeros(x,y);
            % Matrix to store the intensity value of lower intensity of any
            % combo
            intensity_val_3_combo = zeros(x, y);
            % store data for the rich elements
            curr_indx = 0;
            for i = 1:(nelements-2)
                bar_len = bar_len + .3/(nelements-2); %go to .6
                waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
                EDSmap1 = matrixEDSData(:,:,i)/cf;
                for n = (i+1):(nelements-1)
                    EDSmap2 = matrixEDSData(:,:,n)/cf;
                    for m = n+1:nelements
                        curr_indx = curr_indx + 1;
                        EDSmap3 = matrixEDSData(:,:,m)/cf;
                        if (combo_3_checkboxes{i}.Value == 1 && combo_3_checkboxes{n}.Value == 1 &&...
                                combo_3_checkboxes{m}.Value == 1)
                            for j = 1:y
                                for k = 1:x
                                    % see if all intensities between threshold
                                    if (EDSmap1(k,j) >= combo_3_sliders_lower{i}.Value &&...
                                            EDSmap2(k,j) >= combo_3_sliders_lower{n}.Value &&...
                                            EDSmap3(k,j) >= combo_3_sliders_lower{m}.Value &&...
                                            EDSmap1(k,j) <= combo_3_sliders_upper{i}.Value &&...
                                            EDSmap2(k,j) <= combo_3_sliders_upper{n}.Value &&...
                                            EDSmap3(k,j) <= combo_3_sliders_upper{m}.Value)
                                        % if both above value they are a
                                        % possible combo, so put checkbox
                                        ternary_check_box_update_datas(curr_indx) = 1;                                    
                                        if (ternary_check_boxes{curr_indx}.Value == 1)
                                            % compare min intensities. Could add ability to
                                            % choose min or max
                                            %min_intensity = 0;
                                            if (EDSmap1(k,j) >= EDSmap2(k,j) && EDSmap2(k,j) >= EDSmap3(k,j))
                                                min_intensity = EDSmap3(k,j);
                                            elseif (EDSmap2(k,j) >= EDSmap1(k,j) && EDSmap1(k,j) >= EDSmap3(k,j))
                                                min_intensity = EDSmap3(k,j);
                                            elseif (EDSmap3(k,j) >= EDSmap2(k,j) && EDSmap2(k,j) >= EDSmap1(k,j))
                                                min_intensity = EDSmap1(k,j);
                                            elseif (EDSmap2(k,j) >= EDSmap3(k,j) && EDSmap3(k,j) >= EDSmap1(k,j))
                                                min_intensity = EDSmap1(k,j);
                                            elseif (EDSmap1(k,j) >= EDSmap3(k,j) && EDSmap3(k,j) >= EDSmap2(k,j))
                                                min_intensity = EDSmap2(k,j);
                                            elseif (EDSmap3(k,j) >= EDSmap1(k,j) && EDSmap1(k,j) >= EDSmap2(k,j))
                                                min_intensity = EDSmap2(k,j);
                                            end
                                            if ((min_intensity >= intensity_val_3_combo(k,j)))
                                                combo_3_loc(k,j) = curr_indx;
                                                intensity_val_3_combo(k,j) = min_intensity;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            % add rich color members to list
            color_members = 0;
            color_members_rich = 0;
            color_member_rich_indices = zeros(nelements,1);
            for i = 1:nelements
                if (ismember(i, max_intensity_loc_rich))
                    color_members = color_members+1;
                    color_members_rich = color_members_rich + 1;
                    color_member_rich_indices(color_members_rich) = i;
                end
            end

            % add combo 2 color members to list
            color_member_combo_2_indices = zeros(nelements*(nelements-1)/2,1);
            for j = 1:y
                for k = 1:x
                    if (combo_2_loc(k,j) ~= 0)
                        color_member_combo_2_indices(combo_2_loc(k,j)) = 1;
                    end
                end
            end
            
            % add combo 3 color members to list
            color_member_combo_3_indices = zeros(nelements*(nelements-1)*(nelements-2)/6,1);
            %todo
            for j = 1:y
                for k = 1:x
                    if (combo_3_loc(k,j) ~= 0)
                        color_member_combo_3_indices(combo_3_loc(k,j)) = 1;
                    end
                end
            end

            %update_data check box pos
            row = 1;
            col = 1;
            for k = 1:nelements*(nelements-1)/2
                if (binary_check_box_update_datas(k) == 1)
                    col = col+1;
                    if (mod(col,3) == 1)
                        row = row + 1;
                    end
                    binary_check_boxes{k}.Position = [10+75*row, 10+50*mod(col-1,3), 100, 32];
                    binary_check_boxes{k}.Visible = 'on';
                end
            end          
            for k = 1:nelements*(nelements-1)*(nelements-2)/6
                if (ternary_check_box_update_datas(k) == 1)
                    col = col+1;
                    if (mod(col,3) == 1)
                        row = row + 1;
                    end
                    ternary_check_boxes{k}.Position = [10+75*row, 10+50*mod(col-1,3), 100, 32];
                    ternary_check_boxes{k}.Visible = 'on';
                end
            end
            
            color_members_combo_2 = 0;
            for i = 1:length(color_member_combo_2_indices)
                if (color_member_combo_2_indices(i) ~= 0)
                    color_members = color_members + 1;
                    color_members_combo_2 = color_members_combo_2 + 1;
                end
            end
            
            color_members_combo_3 = 0;
            for i = 1:length(color_member_combo_3_indices)
                if (color_member_combo_3_indices(i) ~= 0)
                    color_members = color_members + 1;
                    color_members_combo_3 = color_members_combo_3 + 1;
                end
            end

            % Store legend names
            colorNameMatrix = strings(color_members,1); 
            max_name_len = 0;
            % add rich names
            for k = 1:color_members_rich
                curr_indx = color_member_rich_indices(k);
                colorNameMatrix(k,1) = single_name_matrix(curr_indx,1);
               if (strlength(colorNameMatrix(k,1)) > max_name_len)
                   max_name_len = strlength(colorNameMatrix(k,1));
               end
            end       

            combinedImage = zeros(x, y, 3);
            colorImage_temp = zeros(x, y, 3);
            combined_color_map = zeros(100*(color_members),3); 
            % Boolean to determine when the combined color bar begins being created
            colorMap_temp = zeros(100,3);
            combined_color_map(1:100,:) = colorMap_temp;
            combined_start = 0;
            % add colormap for rich index
            for i=1:color_members_rich
                curr_ind = color_member_rich_indices(i);
                colorMap_temp(:,1) = rich_colors(curr_ind,1);
                colorMap_temp(:,2) = rich_colors(curr_ind,2);
                colorMap_temp(:,3) = rich_colors(curr_ind,3);
                if (combined_start == 0)
                    combined_color_map(1:100,:) = colorMap_temp;
                    combined_start = 1;
                else
                    offset = combined_start * 100;
                    combined_color_map((1+offset):(offset+100),:) = colorMap_temp;
                    combined_start = combined_start + 1;
                end
            end

            % add colormap for combo 2 elements
            % algo from albfan, “Calculation of a mixed color in RGB,” Stack Overflow, 30-Jan-2013. [Online]. Available: https://stackoverflow.com/questions/4255973/calculation-of-a-mixed-color-in-rgb?noredirect=1. [Accessed: 28-Dec-2019].
            curr_indx = 0;
            for i = 1:(nelements-1)
                for n = (i+1):nelements
                    curr_indx = curr_indx + 1;
                    if (color_member_combo_2_indices(curr_indx) ~= 0)
                        colorMap_temp(:,1) = binary_colors(curr_indx,1);
                        colorMap_temp(:,2) = binary_colors(curr_indx,2);
                        colorMap_temp(:,3) = binary_colors(curr_indx,3);
                        if (combined_start == 0)
                            combined_color_map(1:100,:) = colorMap_temp;
                            combined_start = 1;
                        else
                            offset = combined_start * 100;
                            combined_color_map((1+offset):(offset+100),:) = colorMap_temp;
                            combined_start = combined_start + 1;
                        end
                    end
                end
            end
            
            curr_indx = 0;
            % add colormap for combo 3 elements
            for i = 1:(nelements-2)
                for n = (i+1):(nelements-1)
                    for m = n+1:nelements
                        curr_indx = curr_indx + 1;
                        if (color_member_combo_3_indices(curr_indx) ~= 0)
                            colorMap_temp(:,1) = ternary_colors(curr_indx,1);
                            colorMap_temp(:,2) = ternary_colors(curr_indx,2);
                            colorMap_temp(:,3) = ternary_colors(curr_indx,3);
                            if (combined_start == 0)
                                combined_color_map(1:100,:) = colorMap_temp;
                                combined_start = 1;
                            else
                                offset = combined_start * 100;
                                combined_color_map((1+offset):(offset+100),:) = colorMap_temp;
                                combined_start = combined_start + 1;
                            end
                        end
                    end
                end
            end
            if( include_base_checkbox.Value == 1)
                % add colormap for base
                colorMap_temp(:,1) = base_c(1,1);
                colorMap_temp(:,2) = base_c(1,2);
                colorMap_temp(:,3) = base_c(1,3);
                if (combined_start == 0)
                    combined_color_map(1:100,:) = colorMap_temp;
                    combined_start = 1;
                else
                    offset = combined_start * 100;
                    combined_color_map((1+offset):(offset+100),:) = colorMap_temp;
                    combined_start = combined_start + 1;
                end
            end
            %%% Graph the thresholds
            
            % base pixels
            if( include_base_checkbox.Value == 1)
                color_members = color_members + 1;
                for j = 1:y
                    for k = 1:x
                        base_loc(k,j) = 1;
                    end
                end
                for i = 1:nelements
                    if(base_checkboxes{i}.Value == 1)
                        EDSmap = matrixEDSData(:,:,i)/cf;
                        lower_val = str2double(lower_base_textboxes{i}.Value);
                        upper_val = str2double(upper_base_textboxes{i}.Value);
                        for j = 1:y
                            for k = 1:x
                                if (EDSmap(k,j) < lower_val || EDSmap(k,j) > upper_val)
                                    base_loc(k,j) = 0;
                                end
                            end
                        end
                    end
                end
                colorImage_temp(:,:,1) = base_c(1,1);
                colorImage_temp(:,:,2) = base_c(1,2);
                colorImage_temp(:,:,3) = base_c(1,3);
                [map_loc_rows, map_loc_cols] = find(base_loc == 1);
                if ~isempty(map_loc_rows)
                    for j = 1:length(map_loc_rows)
                        combinedImage(map_loc_rows(j), map_loc_cols(j),1) = colorImage_temp(map_loc_rows(j), map_loc_cols(j),1);
                        combinedImage(map_loc_rows(j), map_loc_cols(j),2) = colorImage_temp(map_loc_rows(j), map_loc_cols(j),2);
                        combinedImage(map_loc_rows(j), map_loc_cols(j),3) = colorImage_temp(map_loc_rows(j), map_loc_cols(j),3);
                    end
                end
            end
            
            % rich pixels
            for i = 1:nelements
                bar_len = bar_len + .1/(nelements); %go to .7
                waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
                colorImage_temp(:,:,1) = rich_colors(i,1);
                colorImage_temp(:,:,2) = rich_colors(i,2);
                colorImage_temp(:,:,3) = rich_colors(i,3);

                % Find all pixel locations where the present element is dominant
                [map_loc_rows_rich, map_loc_cols_rich] = find(max_intensity_loc_rich == i);
                % Create a map that combines the colors of the dominant elements into a single map
                if ~isempty(map_loc_rows_rich)
                    for j = 1:length(map_loc_rows_rich)
                        combinedImage(map_loc_rows_rich(j), map_loc_cols_rich(j),1) = colorImage_temp(map_loc_rows_rich(j), map_loc_cols_rich(j),1);
                        combinedImage(map_loc_rows_rich(j), map_loc_cols_rich(j),2) = colorImage_temp(map_loc_rows_rich(j), map_loc_cols_rich(j),2);
                        combinedImage(map_loc_rows_rich(j), map_loc_cols_rich(j),3) = colorImage_temp(map_loc_rows_rich(j), map_loc_cols_rich(j),3);
                    end
                end
            end

            % combo 2 pixels
            bar_len = bar_len + .8/(y); %go to .8
            waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
            if (color_members_combo_2 > 0)
                for j = 1:y
                    for k = 1:x
                        if (combo_2_loc(k,j) ~= 0)
                            curr_indx = combo_2_loc(k,j);
                            colorImage_temp(k,j,1) = binary_colors(curr_indx,1);
                            colorImage_temp(k,j,2) = binary_colors(curr_indx,2);
                            colorImage_temp(k,j,3) = binary_colors(curr_indx,3);
                            combinedImage(k,j,1) = colorImage_temp(k,j,1);
                            combinedImage(k,j,2) = colorImage_temp(k,j,2);
                            combinedImage(k,j,3) = colorImage_temp(k,j,3);
                        end
                    end
                end
            end
            bar_len = bar_len + .1; %go to .9
            waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
            if (color_members_combo_3 > 0)
                for j = 1:y
                    for k = 1:x
                        if (combo_3_loc(k,j) ~= 0)
                            curr_indx = combo_3_loc(k,j);
                            colorImage_temp(k,j,1) = ternary_colors(curr_indx,1);
                            colorImage_temp(k,j,2) = ternary_colors(curr_indx,2);
                            colorImage_temp(k,j,3) = ternary_colors(curr_indx,3);
                            combinedImage(k,j,1) = colorImage_temp(k,j,1);
                            combinedImage(k,j,2) = colorImage_temp(k,j,2);
                            combinedImage(k,j,3) = colorImage_temp(k,j,3);
                        end
                    end
                end
            end
            bar_len = bar_len + .1; %go to 1
            waitbar(bar_len,f, 'Updating Threshold Data','WindowStyle', 'modal');
            close(f);
            update_fig = 1;
        end
        
        if (update_fig == 1)
            curr_indx = 0;
            % add 2 combo names
            for k = 1:nelements*(nelements-1)/2
                if (color_member_combo_2_indices(k) ~= 0)
                    curr_indx = curr_indx + 1;
                    if (binary_choices(k) == 0)
                        colorNameMatrix(curr_indx + color_members_rich,1) = binary_combos(k,1);
                    elseif (binary_choices(k) == 1)
                        colorNameMatrix(curr_indx + color_members_rich,1) = binary_combos(k,2);
                    elseif (binary_choices(k) == 2)
                        colorNameMatrix(curr_indx + color_members_rich,1) = binary_combos(k,3);
                    else
                        colorNameMatrix(curr_indx + color_members_rich,1) = binary_combos(k,4);
                    end
                end
            end
            curr_indx = 0;
            % add 3 combo names
            for k = 1:nelements*(nelements-1)*(nelements-2)/6
                if (color_member_combo_3_indices(k) ~= 0)
                    curr_indx = curr_indx + 1;
                    if (ternary_choices(k) == 0)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,1);
                    elseif (ternary_choices(k) == 1)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,2);
                    elseif (ternary_choices(k) == 2)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,3);
                    elseif (ternary_choices(k) == 3)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,4);
                    elseif (ternary_choices(k) == 4)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,5);
                    elseif (ternary_choices(k) == 5)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,6);
                    elseif (ternary_choices(k) == 6)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,7);
                    elseif (ternary_choices(k) == 7)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,8);
                    elseif (ternary_choices(k) == 8)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,9);
                    elseif (ternary_choices(k) == 9)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,10);
                    elseif (ternary_choices(k) == 10)
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,11);
                    else
                        colorNameMatrix(curr_indx + color_members_rich + color_members_combo_2,1) = ternary_combos(k,12);
                    end
                end
            end
            
            %add base name
            if( include_base_checkbox.Value == 1)
                colorNameMatrix(color_members_rich + color_members_combo_2 + color_members_combo_3 + 1,1) = base_name;
            end
            % see if 2 or 3 combo max name length longer
            for k = 1:length(colorNameMatrix)
                if (strlength(colorNameMatrix(k,1)) > max_name_len)
                   max_name_len = strlength(colorNameMatrix(k,1));
                end
            end
            set(0, 'CurrentFigure', fig3)
            get(fig3);
            clf(fig3);
            pos=get(gca,'position');  % retrieve the current figure position
            pos(3)= 0.85*pos(3);      % reduce width
            set(gca,'position',pos);  % update_data position
            %Plot the combined map and save
            set(0, 'CurrentFigure', fig3)
            image(combinedImage)
            hold on
            xlim([0 y])
            ylim([0 x])
            axis equal
            axis off
            drawnow
            set(0, 'CurrentFigure', fig3)
            colormap(combined_color_map);

            cb = colorbar(gca, 'horizontal', 'location', 'southoutside'); % creat a colorbar
            cbPos = cb.Position; % get the position of the color bar
            mid = (pos(1) + pos(3)) / 3.66;
            set(cb,'Position',[mid pos(2)+.015 cbPos(3) cbPos(4)/2])%[x/5 y/5 cbPos(3) cbPos(4)/2]) % move the color bar to the side and shrink it
            set(0, 'CurrentFigure', fig3)
            drawnow

            % Implementation of a combined color bar
            ticks_lower = zeros(1,color_members); % create tick marks
            inc = 1/color_members; % create even spacing
            curr_lower = 0;
            labels_lower = zeros(color_members, 1);

            for i = 1:(color_members)
                labels_lower(i) = 11^(max_name_len-1);
                ticks_lower(i) = curr_lower+(inc/2);
                curr_lower = curr_lower+inc;
            end
            labels_lower = num2str(labels_lower);

            % add names of each element. May need to change later if any elements with
            % 3 letters show up
            for i = 1:(color_members)
                name_len = strlength(colorNameMatrix(i,1));
                curr_name = char(colorNameMatrix(i,1));
                labels_lower(i,1:name_len) = curr_name(1:name_len);
                if (name_len < max_name_len)
                    rem = max_name_len-name_len;
                    rem_floor = floor(rem/2);
                    rem_ceil = ceil(rem/2);
                    for j = 1:rem_floor
                        labels_lower(i,j) = ' ';
                    end
                    for j = 1:name_len
                        labels_lower(i,j+rem_floor) = curr_name(j);
                    end
                    for j = 1:rem_ceil
                        labels_lower(i,j+rem_floor+name_len) = ' ';
                    end
                else
                    labels_lower(i,1:name_len) = curr_name(1:name_len);
                end
            end
            % add second axes
            set(0, 'CurrentFigure', fig3)
            set (cb, 'YTick', ticks_lower)
            color_bar_font_size = 8.5-.15*color_members;
            set(0, 'CurrentFigure', fig3)
            set (cb, 'YTickLabel', labels_lower, 'fontsize', color_bar_font_size)
            % End combined color bar  
        end
        for k = 1:nelements
            for i = 1:3
                val = str2double(slider_values_lower{i,k}.Value);
                if (~isempty(val) && val >= 0 && val <= 100)
                    old_slider_values_lower{i,k} = slider_values_lower{i,k}.Value;
                end
                val = str2double(slider_values_upper{i,k}.Value);
                if (~isempty(val) && val >= 0 && val <= 100)
                    old_slider_values_upper{i,k} = slider_values_upper{i,k}.Value;
                end
            end
            val = str2double(lower_base_textboxes{1,k}.Value);
            if (~isnan(val) && val >= 0 && val <= 101)
                old_lower_base_textboxes{1,k} = lower_base_textboxes{1,k}.Value;
            end
            val = str2double(upper_base_textboxes{1,k}.Value);
            if (~isnan(val) && val >= 0 && val <= 101)
                old_upper_base_textboxes{1,k} = upper_base_textboxes{1,k}.Value;
            end
        end
        % set update_data to 0 and wait a second
        update_data = 0;
        update_fig = 0;
        pause(1)
    end

    % nested functions for utilities
    %% update data manually
    function UpdateFigBut(varargin)
        update_data = 1;
    end
    
    %% close all figues
    function CloseThresholdBut(varargin)
        try
            close(fig2)
        catch
        end
        try
            close(fig3)
        catch
        end
        try
            close(findall(groot, 'Type', 'figure','name','fig4'))
        catch
        end
        try
            close(findall(groot, 'Type', 'figure','name','fig5'))
        catch
        end
        try
            close(findall(groot, 'Type', 'figure','name','fig6'))
        catch
        end
        try
            close(findall(groot, 'Type', 'figure','name','fig7'))
        catch
        end
    end

    %% update rich colors
    function RichColorsBut(varargin)
        fig4 = uifigure('color','w', 'name','fig4');
        fig4_pos = fig4.Position; %[left top  w h]
        panel4 = uipanel(fig4, 'Position', [0 0 fig4_pos(3) fig4_pos(4)]);
        panel4.Scrollable = 'on';
        % panel15_names position
        p5pos = panel4.Position; %[left top w h]
        popups = cell(1,color_members_rich);
        new_colors = cell(3, color_members_rich);
        current_indx = 0;
        name_row = 0;
        for t = 1:color_members_rich
            current_indx = color_member_rich_indices(t);
            name_row = name_row+1;
            popups{current_indx} = uitextarea(panel4,...
                'Value', single_name_matrix(current_indx),...
                'Position',[p5pos(1)+3*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
            new_colors{1,current_indx} = uitextarea(panel4,'Value',num2str(255*rich_colors(current_indx,1))...
                ,'Position',[p5pos(1)+7*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
            new_colors{2,current_indx} = uitextarea(panel4,'Value',num2str(255*rich_colors(current_indx,2))...
                ,'Position',[p5pos(1)+11*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
            new_colors{3,current_indx} = uitextarea(panel4,'Value',num2str(255*rich_colors(current_indx,3))...
                ,'Position',[p5pos(1)+15*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
        end
        name_row = name_row + 1;
        uilabel(panel4,'Text','R (0-255)','Position',[p5pos(1)+7*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16])
        uilabel(panel4,'Text','G (0-255)','Position',[p5pos(1)+11*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16])
        uilabel(panel4,'Text','B (0-255)','Position',[p5pos(1)+15*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16])
        uibutton(panel4,'Text', 'Save Naming',...
        'Tag', 'SaveCombo',...
        'Position',[p5pos(1) p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16],...
        'ButtonPushedFcn',@RichColorSaveBut);
         %% Save update to rich namess and colors
        function RichColorSaveBut(varargin)
            for q = 1:color_members_rich
                current_indx = color_member_rich_indices(q);
                single_name_matrix(current_indx) = popups{current_indx}.Value;
                new_Rc = str2double(new_colors{1,current_indx}.Value);
                new_Gc = str2double(new_colors{2,current_indx}.Value);
                new_Bc = str2double(new_colors{3,current_indx}.Value);
                if (~isnan(new_Rc) && new_Rc >= 0 && new_Rc <= 255 ...
                && ~isnan(new_Gc) && new_Gc >= 0 && new_Gc <= 255 ...
                && ~isnan(new_Bc) && new_Bc >= 0 && new_Bc <= 255)
                    new_c = [new_Rc new_Gc new_Bc]./255;
                    if (~isequal(rich_colors(q,:),new_c))
                        rich_colors(q,:) = new_c;
                        update_data = 1;
                    end
                end    
            end
            update_fig = 1;
            close(fig4);
        end
    end
    %% Update binary names
    function BinaryCombosBut(varargin)
        fig5 = uifigure('color','w', 'name','fig5');
        fig5_pos = fig5.Position; %[left top  w h]
        panel5 = uipanel(fig5, 'Position', [0 0 fig5_pos(3) fig5_pos(4)]);
        panel5.Scrollable = 'on';
        % panel15_names position
        p5pos = panel5.Position; %[left top w h]
        popups = cell(1,color_members_combo_2);
        new_colors = cell(3, color_members_combo_2);
        current_indx = 0;
        name_row = 0;
        for t = 1:length(color_member_combo_2_indices)
            if (color_member_combo_2_indices(t) ~= 0)
                current_indx = current_indx + 1;    
                name_row = name_row+1;
                str_array = string({binary_combos(t,1),binary_combos(t,2),binary_combos(t,3),binary_combos(t,4)});
                popups{current_indx} = uidropdown(panel5,...
                    'Items', str_array,...
                    'Tag','DataUnits',...
                    'Position',[p5pos(1)+3*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16],...
                    'Value',(binary_combos(t,binary_choices(t)+1)));
                new_colors{1,current_indx} = uitextarea(panel5,'Value',num2str(255*binary_colors(t,1))...
                    ,'Position',[p5pos(1)+7*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
                new_colors{2,current_indx} = uitextarea(panel5,'Value',num2str(255*binary_colors(t,2))...
                    ,'Position',[p5pos(1)+11*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
                new_colors{3,current_indx} = uitextarea(panel5,'Value',num2str(255*binary_colors(t,3))...
                    ,'Position',[p5pos(1)+15*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/8 p5pos(4)/16]);
            end
        end
        name_row = name_row + 1;
        uilabel(panel5,'Text','R (0-255)','Position',[p5pos(1)+7*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16])
        uilabel(panel5,'Text','G (0-255)','Position',[p5pos(1)+11*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16])
        uilabel(panel5,'Text','B (0-255)','Position',[p5pos(1)+15*p5pos(3)/16 p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16])
        uibutton(panel5,'Text', 'Save Naming',...
        'Tag', 'SaveCombo',...
        'Position',[p5pos(1) p5pos(2)+name_row*p5pos(4)/8 p5pos(3)/6 p5pos(4)/16],...
        'ButtonPushedFcn',@BinaryNameSaveBut);
         %% Save update to binary names
        function BinaryNameSaveBut(varargin)
            current_indx = 0;
            for q = 1:length(color_member_combo_2_indices)
                if (color_member_combo_2_indices(q) ~= 0)
                    current_indx = current_indx + 1;
                    for p=1:4
                        if (strcmp(popups{current_indx}.Value, popups{current_indx}.Items(p))== 1)
                            binary_choices(q) = p - 1;
                        end
                    end
                    new_Rc = str2double(new_colors{1,current_indx}.Value);
                    new_Gc = str2double(new_colors{2,current_indx}.Value);
                    new_Bc = str2double(new_colors{3,current_indx}.Value);
                    if (~isnan(new_Rc) && new_Rc >= 0 && new_Rc <= 255 ...
                    && ~isnan(new_Gc) && new_Gc >= 0 && new_Gc <= 255 ...
                    && ~isnan(new_Bc) && new_Bc >= 0 && new_Bc <= 255)
                        new_c = [new_Rc new_Gc new_Bc]./255;
                        if (~isequal(binary_colors(q,:),new_c))
                            binary_colors(q,:) = new_c;
                            update_data = 1;
                        end
                    end    
                end
            end
            update_fig = 1;
            close(fig5);
        end
    end

    %% Update ternary names
    function TernaryCombosBut(varargin)
        fig6 = uifigure('color','w', 'name','fig6');
        fig6_pos = fig6.Position; %[left top  w h]
        panel6 = uipanel(fig6, 'Position', [0 0 fig6_pos(3) fig6_pos(4)]);
        panel6.Scrollable = 'on';
        p6pos = panel6.Position; %[left top w h]
        popups = cell(1,color_members_combo_3);
        new_colors = cell(3, color_members_combo_3);
        current_indx = 0;
        name_row = 0;
        for t = 1:length(color_member_combo_3_indices)
            if (color_member_combo_3_indices(t) ~= 0)
                current_indx = current_indx + 1;    
                name_row = name_row+1;
                str_array = string({ternary_combos(t,1),ternary_combos(t,2),ternary_combos(t,3),ternary_combos(t,4),ternary_combos(t,5),ternary_combos(t,6),ternary_combos(t,7),ternary_combos(t,8),ternary_combos(t,9),ternary_combos(t,10),ternary_combos(t,11),ternary_combos(t,12)});
                popups{current_indx} = uidropdown(panel6,...
                    'Items', str_array,...
                    'Tag','DataUnits',...
                    'Position',[p6pos(1)+3*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/8 p6pos(4)/16],...
                    'Value',(ternary_combos(t,ternary_choices(t)+1)));
                new_colors{1,current_indx} = uitextarea(panel6,'Value',num2str(255*ternary_colors(t,1))...
                    ,'Position',[p6pos(1)+7*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/8 p6pos(4)/16]);
                new_colors{2,current_indx} = uitextarea(panel6,'Value',num2str(255*ternary_colors(t,2))...
                    ,'Position',[p6pos(1)+11*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/8 p6pos(4)/16]);
                new_colors{3,current_indx} = uitextarea(panel6,'Value',num2str(255*ternary_colors(t,3))...
                    ,'Position',[p6pos(1)+15*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/8 p6pos(4)/16]);
            end
        end
        name_row = name_row + 1;
        uilabel(panel6,'Text','R (0-255)','Position',[p6pos(1)+7*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/6 p6pos(4)/16])
        uilabel(panel6,'Text','G (0-255)','Position',[p6pos(1)+11*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/6 p6pos(4)/16])
        uilabel(panel6,'Text','B (0-255)','Position',[p6pos(1)+15*p6pos(3)/16 p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/6 p6pos(4)/16])
        uibutton(panel6,'Text', 'Save Naming',...
        'Tag', 'SaveCombo',...
        'Position',[p6pos(1) p6pos(2)+name_row*p6pos(4)/8 p6pos(3)/6 p6pos(4)/16],...
        'ButtonPushedFcn',@TernaryNameSaveBut);
         %% Save update to binary names
        function TernaryNameSaveBut(varargin)
            current_indx = 0;
            for q = 1:length(color_member_combo_3_indices)
                if (color_member_combo_3_indices(q) ~= 0)
                    current_indx = current_indx + 1;
                    for p=1:4
                        if (strcmp(popups{current_indx}.Value, popups{current_indx}.Items(p))== 1)
                            ternary_choices(q) = p - 1;
                        end
                    end
                    new_Rc = str2double(new_colors{1,current_indx}.Value);
                    new_Gc = str2double(new_colors{2,current_indx}.Value);
                    new_Bc = str2double(new_colors{3,current_indx}.Value);
                    if (~isnan(new_Rc) && new_Rc >= 0 && new_Rc <= 255 ...
                    && ~isnan(new_Gc) && new_Gc >= 0 && new_Gc <= 255 ...
                    && ~isnan(new_Bc) && new_Bc >= 0 && new_Bc <= 255)
                        new_c = [new_Rc new_Gc new_Bc]./255;
                        if (~isequal(ternary_colors(q,:),new_c))
                            ternary_colors(q,:) = new_c;
                            update_data = 1;
                        end
                    end    
                end
            end
            update_fig = 1;
            close(fig6);
        end
    end
    %% Rename base name
    function BaseNameBut(varargin)
        fig7 = uifigure('color','w', 'name','fig7');
        pos7 = get(gcf, 'Position');
        w7 = pos7(3);
        h7 = pos7(4);
        new_name = uitextarea(fig7,'Value',base_name,'Position',[w7/2-50, h7/2-10, 100, 20]);
        new_R = uitextarea(fig7,'Value',num2str(255*base_c(1)),'Position',[w7/2-105, h7/2-40, 40, 20]);
        uilabel(fig7,'Text','R (0-255)','Position',[w7/2-105, h7/2-60, 100, 20]);
        new_G = uitextarea(fig7,'Value',num2str(255*base_c(2)),'Position',[w7/2-25, h7/2-40, 40, 20]);
        uilabel(fig7,'Text','G (0-255)','Position',[w7/2-25, h7/2-60, 100, 20]);
        new_B = uitextarea(fig7,'Value',num2str(255*base_c(3)),'Position',[w7/2+55, h7/2-40, 40, 20]);
        uilabel(fig7,'Text','B (0-255)','Position',[w7/2+55, h7/2-60, 100, 20]);
        uibutton('Parent',fig7,'Text','Save Name/Color',...
        'Tag', 'SaveBase',...
        'Position',[0,h7-3*h7/10, w7/4, 22],...
        'ButtonPushedFcn',@BaseNameSaveBut);
        %% save name
        function BaseNameSaveBut(varargin)
            base_name = new_name.Value;
            new_Rc = str2double(new_R.Value);
            new_Gc = str2double(new_G.Value);
            new_Bc = str2double(new_B.Value);
            if (~isnan(new_Rc) && new_Rc >= 0 && new_Rc <= 255 ...
                && ~isnan(new_Gc) && new_Gc >= 0 && new_Gc <= 255 ...
                && ~isnan(new_Bc) && new_Bc >= 0 && new_Bc <= 255)
                new_base_c = [new_Rc new_Gc new_Bc]./255;
                if (~isequal(base_c,new_base_c))
                    update_data = 1;
                    base_c = new_base_c;
                end
            end
               
            update_fig = 1;
            close(fig7);
        end
    end
    
    %% Save figure
    function SaveFigBut(varargin)
        bar_len = 0;
        f = waitbar(bar_len, 'Saving Threshold Data','WindowStyle', 'modal');
        % Get waitbar to always be on top
        frames = java.awt.Frame.getFrames();
        frames(end).setAlwaysOnTop(1); 
        pic_name = char(strcat(dirName,'\Threshold_Map.tif'));
        xl_name = char(strcat(dirName,'\Threshold_Map.xlsx'));
        text_name = char(strcat(dirName,'\Threshold_Map.txt'));
        temp_num = 1;
        while exist(pic_name, 'file')
            number = num2str(temp_num, '%2d');
            tempName = strcat({'\'}, 'Threshold_Map',{'('}, number, {')'},'.tif');
            tempName2 = strcat({'\'}, 'Threshold_Map',{'('}, number, {')'},'.xlsx');
            tempName3 = strcat({'\'}, 'Threshold_Map',{'('}, number, {')'},'.txt');
            tempName = strjoin(tempName);
            pic_name = char(strcat(dirName, tempName));
            xl_name = char(strcat(dirName, tempName2));
            text_name = char(strcat(dirName, tempName3));
            temp_num = temp_num+1;
        end

        nameTable = array2table(nameMatrix, 'VariableNames', {'Element'});
        saveConcentrations = zeros(nelements,5);
        for q = 1:nelements
            bar_len = bar_len + .5/nelements; %go to .5
            waitbar(bar_len,f, 'Saving Threshold Data','WindowStyle', 'modal');
            if (base_checkboxes{q}.Value == 1)
                saveConcentrations(q,1) = str2double(lower_base_textboxes{1,q}.Value);
                saveConcentrations(q,2) = str2double(upper_base_textboxes{1,q}.Value);
            else
                saveConcentrations(q,1) = 101;
                saveConcentrations(q,2) = -1;
            end
            if (rich_checkboxes{q}.Value == 1)
                saveConcentrations(q,3) = rich_sliders_lower{q}.Value;
                saveConcentrations(q,4) = rich_sliders_upper{q}.Value;
            else
                saveConcentrations(q,3) = 101;
                saveConcentrations(q,4) = -1;
            end
            if (combo_2_checkboxes{q}.Value == 1)
                saveConcentrations(q,5) = combo_2_sliders_lower{q}.Value;
                saveConcentrations(q,6) = combo_2_sliders_upper{q}.Value;
            else
                saveConcentrations(q,5) = 101;
                saveConcentrations(q,6) = -1;
            end
            if (combo_3_checkboxes{q}.Value == 1)             
                saveConcentrations(q,7) = combo_3_sliders_lower{q}.Value;
                saveConcentrations(q,8) = combo_3_sliders_upper{q}.Value;
            else
                saveConcentrations(q,7) = 101;
                saveConcentrations(q,8) = -1;
            end
        end
        
        quantTable = array2table(saveConcentrations, 'VariableNames',...
                                                   {'Base_Lower_Percentage',...
                                                    'Base_Upper_Percentage',...
                                                    'Rich_Percentage_Lower',...
                                                    'Rich_Percentage_Upper',...
                                                    'Binary_Percentage_Lower',...
                                                    'Binary_Percentage_Upper',...
                                                    'Ternary_Percentage_Lower',...
                                                    'Ternary_Percentage_Upper'});
        combinedTable = [nameTable quantTable];
        sheet = sprintf('Thresholds');

        writetable(combinedTable, xl_name, 'Sheet', sheet);

        current_indx = 0;
        colorValues = zeros(1+color_members_rich+color_members_combo_2+color_members_combo_3,3);
        for t = 1:length(color_member_rich_indices)
            if (color_member_rich_indices(t) ~= 0)
                current_indx = current_indx + 1;  
                colorValues(current_indx,1) = rich_colors(t,1)*255;
                colorValues(current_indx,2) = rich_colors(t,2)*255;
                colorValues(current_indx,3) = rich_colors(t,3)*255;
            end
        end
        for t = 1:length(color_member_combo_2_indices)
            if (color_member_combo_2_indices(t) ~= 0)
                current_indx = current_indx + 1;  
                colorValues(current_indx,1) = binary_colors(t,1)*255;
                colorValues(current_indx,2) = binary_colors(t,2)*255;
                colorValues(current_indx,3) = binary_colors(t,3)*255;
            end
        end
        for t = 1:length(color_member_combo_3_indices)
            if (color_member_combo_3_indices(t) ~= 0)
                current_indx = current_indx + 1;  
                colorValues(current_indx,1) = ternary_colors(t,1)*255;
                colorValues(current_indx,2) = ternary_colors(t,2)*255;
                colorValues(current_indx,3) = ternary_colors(t,3)*255;
            end
        end
        current_indx = current_indx + 1;
        colorValues(current_indx,1) = base_c(1)*255;
        colorValues(current_indx,2) = base_c(2)*255;
        colorValues(current_indx,3) = base_c(3)*255;
        colorTable = array2table(colorNameMatrix, 'VariableNames', {'Labels'});
        colorQuantTable = array2table(colorValues, 'VariableNames', {'R', 'G', 'B'});
        sheet2 = sprintf('Colors');
        combinedColorTable = [colorTable colorQuantTable];
        writetable(combinedColorTable, xl_name, 'Sheet', sheet2);
        
        xlswrite(xl_name, {data_type}, sheet, 'J1');
        % Remove default Excel sheets Sheet1, Sheet2, and Sheet3 
        % (ref: https://www.mathworks.com/matlabcentral/answers/92449-how-can-i-delete-the-default-sheets-sheet1-sheet2-and-sheet3-in-excel-when-i-use-xlswrite)
        objExcel = actxserver('Excel.Application'); % Open Excel file
        objExcel.Workbooks.Open(xl_name); % Full path

        % Delete sheets
        for q = 1:3
            try
                objExcel.ActiveWorkbook.Worksheets.Item(['Sheet', num2str(q)]).Delete;
            catch
                % Do nothing
            end
        end
        % Save, close and clean up.
        objExcel.ActiveWorkbook.Save;
        objExcel.ActiveWorkbook.Close;
        objExcel.Quit;
        objExcel.delete;
        
        % save data as text file
        headers = strings(6,1);
        headers(1) = 'Element';
        headers(2) = 'Base_Lower_Percentage';
        headers(3) = 'Base_Upper_Percentage';
        headers(4) = 'Rich_Percentage_Lower';
        headers(6) = 'Binary_Percentage_Lower';
        headers(8) = 'Ternary_Percentage_Lower';
        headers(5) = 'Rich_Percentage_Upper';
        headers(7) = 'Binary_Percentage_Upper';
        headers(9) = 'Ternary_Percentage_Upper';
        headers2 = strings(4,1);
        headers2(1) = 'Labels';
        headers2(2) = 'R';
        headers2(3) = 'G';
        headers2(4) = 'B';
        fid = fopen(text_name, 'wt');
        len = length(nameMatrix);
        len2 = length(colorNameMatrix);
        
        % print values for sliders
        for q = 1:len+2
            bar_len = bar_len + .4/(len+2); %go to .9
            waitbar(bar_len,f, 'Saving Threshold Data','WindowStyle', 'modal');
            if (q == 1)
                fprintf(fid, '%s\n', char(data_type));
            else
                for t = 1:9
                    if (q == 2)
                        if t < 9
                            fprintf(fid, '%s\t', headers(t));
                        else
                            fprintf(fid, '%s\n', headers(t));
                        end
                    else
                        if t == 1
                            fprintf(fid, '%s\t', nameMatrix(q-2));
                        elseif t == 2
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 1));
                        elseif t == 3
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 2));
                        elseif t == 4
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 3));
                        elseif t == 5
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 4));
                        elseif t == 6
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 5));
                        elseif t == 7
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 6));
                        elseif t == 8
                            fprintf(fid, '%d\t', saveConcentrations(q-2, 7));
                        elseif t == 9
                            fprintf(fid, '%d\n', saveConcentrations(q-2, 8));
                        else
                        end
                    end
                end
            end
        end
        
        % print colors
        for q = 1:len2+2
            if (q == 1)
                fprintf(fid, '\n');
            else
                for t = 1:4
                    if (q == 2)
                        if t < 4
                            fprintf(fid, '%s\t', headers2(t));
                        else
                            fprintf(fid, '%s\n', headers2(t));
                        end
                    else
                        if t == 1
                            fprintf(fid, '%s\t', colorNameMatrix(q-2));
                        elseif t == 2
                            fprintf(fid, '%d\t', colorValues(q-2, 1));
                        elseif t == 3
                            fprintf(fid, '%d\t', colorValues(q-2, 2));
                        elseif t == 4
                            fprintf(fid, '%d\n', colorValues(q-2, 3));
                        else
                        end
                    end
                end
            end
        end
        fclose(fid);
        
        % save pic
        print(figure(fig3),pic_name,'-dtiffn','-r600');
        crop(pic_name)
        bar_len = bar_len + .1; %go to 1
        waitbar(bar_len,f, 'Saving Threshold Data','WindowStyle', 'modal');
        close(f);
    end
end

function [newc] = binaryColorMeld(R1,G1,B1,R2,G2,B2)
    newc = zeros(3,1);
    newc(1) = (R1 + R2)/2;
    newc(2) = (G1 + G2)/2;
    newc(3) = (B1 + B2)/2;
end

function [newc] = ternaryColorMeld(R1,G1,B1,R2,G2,B2,R3,G3,B3)
    newc = zeros(3,1);
    newc(1) = (R1 + R2 + R3)/3;
    newc(2) = (G1 + G2 + G3)/3;
    newc(3) = (B1 + B2 + B3)/3;
end
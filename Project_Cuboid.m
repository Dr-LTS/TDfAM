clear;      %clear memory
clc;        %clear command window

%Select printer type,i.e. does nozzle move up or platform move down in vertical direction?
printer_type = questdlg('Should Z value increase or decrease between layers?','Printer functions as:','Nozzle moves up','Platform moves down','');    
pt = strcmp(printer_type,'Nozzle moves up');

bvalue = true;     %value to stop following while loop

while bvalue == true
    
    %Read cuboid dimensions from user
    prompt = {'Length in x (mm)' , 'Height in y (mm)', 'Depth in z(mm)'};
    title = 'Part Dimensions';
    dims = [1 50];
    definput = {'20','10','5'};
    answer = inputdlg(prompt,title,dims,definput);
    
    %Read print parameters from user
    prompt = {'Horizontal shells' , 'Vertical Shells' , 'Infill density (%)' , 'Fill angle (degrees)'};
    title = 'Shell and Infill Print Parameters';
    dims = [1 60];
    definput = {'0','0','30','45'};
    answer2 = inputdlg(prompt,title,dims,definput);
    
    %Read diameter of filament to be laid (i.e. resolution)
    answer3 = questdlg('Which resolution will be used? (mm)','Layer Thickness','0.1','0.2','0.3','');    %user selects layer thickness
    thickness = str2double(answer3);
    
    %Save read variables from matrix into double variables
    lc = str2double(cell2mat(answer(1,1)));
    hc = str2double(cell2mat(answer(2,1)));
    depth = str2double(cell2mat(answer(3,1)));
    shells_h = str2double(cell2mat(answer2(1,1)));
    shells_v = str2double(cell2mat(answer2(2,1)));
    infill = str2double(cell2mat(answer2(3,1)));
    angle = str2double(cell2mat(answer2(4,1)));
    
    %Check if inputted values lie within acceptable range
    if (lc <= shells_v * 2 * thickness) || (lc >= 240)
        uiwait(msgbox('The length value you entered is out of range'));
    elseif (hc <= shells_v * 2 * thickness) || (hc >= 240)
        uiwait(msgbox('The height value you entered is out of range'));
    elseif (depth <= shells_h * 2 * thickness) || (depth > 150)
        uiwait(msgbox('The depth value you entered is out of range'));
    elseif (shells_h < 0) || (shells_h > 6)
        uiwait(msgbox('The number of horizontal shells you entered is out of range'));
    elseif (shells_v < 0) || (shells_v > 6)
        uiwait(msgbox('The number of vertical shells you entered is out of range'));
    elseif (infill < 10) || (infill > 100)
        uiwait(msgbox('The infill value you entered is out of range'));
    elseif (abs(angle) < 0) || (abs(angle) > 90)
        uiwait(msgbox('The angle value you entered is out of range'));
    else bvalue = false;        %Loop stops if all values lie within the acceptable range
    end
end

%Work out total number of layers required
layers = depth ./ thickness ;

%total number of layers excluding horizontal shells
mlayers = layers - (2 * shells_h);

%Initialisation such that user does not wish any parameter during print
vary_sb = 0;    %Vary speed in between layers if 1
vary_sw = 0;    %Vary speed within layers if 1
vary_sr = 0;    %Vary speed every r_s layers if 1. r_s obtained later.
vary_a  = 0;    %Vary angle in between layers if 1
vary_ar = 0;    %Vary angle every r_a layers if 1. r_a obtained later.

%Check if user wants to vary speed during the print
answer8 = questdlg('Would you like to vary the speed during print?' ...
    ,'','Yes','No','');
tf1 = strcmp(answer8,'Yes');

%Check when the user wants to vary the speed
if tf1 == 1
    answer9 = questdlg('How would you like to vary the speed?' ...
        ,'','Between Layers','Within Layers','After __ layers','');
    tf2 = strcmp(answer9,'Between Layers');
    tf2_2 = strcmp(answer9,'Within Layers');
    if tf2 == 1
        vary_sb = 1;
    elseif tf2_2 == 1
        vary_sw = 1;
    else
        vary_sr = 1;
    end
end

%If user wants to vary the speed after a certain number of iterations, read this value
bvalue = true;

if vary_sr == 1
    while bvalue == true
        prompt = sprintf('After how many layers would you like to change the speed? (%.0f must be dividible by selection.', mlayers);
        title = 'Speed';
        dims = [1 70];
        definput = {'1'};
        answer10 = inputdlg(prompt,title,dims,definput);
        r_s = str2double(cell2mat(answer10(1,1)));
        %Checks wether inputted values are realistic
        if rem(layers,r_s) ~= 0
            uiwait(msgbox('Please select a number dividible by the total number of layers'));
        else bvalue = false;        %Loop stops if all values lie within their range
        end
    end
end

bvalue = true;

s_s = 3600;   %start speed if user does not wish to vary it (set according to Makerbot 2x's manual) in mm/s
s_f = 3600;   %final speed if user does not wish to vary it (set according to Makerbot 2x's manual) in mm/s

%Read start and final speed if user wishes to vary the speed
if tf1 == 1
    while bvalue == true
        %If user wishes to vary the speed, the start and final speeds are read and stored in s_s and s_f
        prompt = {'Initial Speed (mm/s)' , 'Final Speed (mm/s)'};
        title = 'Speed';
        dims = [1 35];
        definput = {'60','80'};
        answer11 = inputdlg(prompt,title,dims,definput);
        s_scm = str2double(cell2mat(answer11(1,1)));
        s_fcm = str2double(cell2mat(answer11(2,1)));
        s_s = s_scm * 60;
        s_f = s_fcm * 60;
        %Checks wether inputted values are realistic
        if (s_s < 60) || (s_s > 12000)
            uiwait(msgbox('The initial speed value is out of range'));
        elseif (s_f < 60) || (s_f > 12000)
            uiwait(msgbox('The final speed value is out of range'));
        else bvalue = false;        %Loop stops if all values lie within their range
        end
    end
end

%Check if user wants to vary angle during the print
answer12 = questdlg('Would you like to vary the angle in between layers during print?' ...
    ,'','Yes','No','');
tf3 = strcmp(answer12,'Yes');

%Check when the user wants to vary the speed
if tf3 == 1
    answer13 = questdlg('How would you like to vary the angle?' ...
        ,'','Between Layers','After __ layers','');
    tf4 = strcmp(answer13,'Between Layers');
    if tf4 == 1
        vary_a = 1;
    else
        vary_ar = 1;
    end
end

%If user wants to vary the angle after a certain number of iterations, read this value
bvalue = true;

if vary_ar == 1
    while bvalue == true
        prompt = sprintf('After how many layers would you like to change the angle? (%.0f must be dividible by selection.', mlayers);
        title = 'Angle';
        dims = [1 70];
        definput = {'1'};
        answer14 = inputdlg(prompt,title,dims,definput);
        r_a = str2double(cell2mat(answer14(1,1)));
        %Checks wether inputted values are realistic
        if rem(layers,r_a) ~= 0
            uiwait(msgbox('Please select a number dividible by the total number of layers'));
        else bvalue = false;        %Loop stops if all values lie within their range
        end
    end
end

bvalue = true;

a_s = 45;   %start angle if user does not wish to vary it
a_f = 45;   %final angle if user does not wish to vary it

%Read start and final angles if user wishes to vary the angle between layers
if vary_a == 1 || vary_ar == 1
    while bvalue == true
        %If user wishes to vary the angle, the start and final angles are read and stored in a_s and a_f
        prompt = {'Initial Angle (degrees)' , 'Final Angle (degrees)'};
        title = 'Angles';
        dims = [1 35];
        definput = {'0','90'};
        answer11 = inputdlg(prompt,title,dims,definput);
        a_s = str2double(cell2mat(answer11(1,1)));
        a_f = str2double(cell2mat(answer11(2,1)));
        %Checks wether inputted values are realistic
        if (a_s < 0) || (a_s > 90)
            uiwait(msgbox('The initial angle value is out of range'));
        elseif (a_f < 0) || (a_f > 90)
            uiwait(msgbox('The final angle value is out of range'));
        else bvalue = false;        %Loop stops if all values lie within their range
        end
    end
end

%Check if user wants to alternate material between layers i.e. use dual nozzles
answer_15 = questdlg('Would you like to change materials between layers? (requires compatible printer)' ...
    ,'','Yes','No','');
dual = strcmp(answer_15,'Yes');

%Save values of length and height since these might be altered in loops
lct = lc - thickness;
hct = hc - thickness;

%Set the maximum value as the length such that orientation of part is consistent
lc = max(lct,hct);
hc = min(lct,hct);

%Assignment of speed
s_shell = 1200;    %Speed to complete outer shells

%Working out speed increment/decrement in between layers to be applied if user selected option
ds = abs(s_f - s_s) ./ (layers - 1);
if s_f < s_s
    ds = -ds;
end

%Working out speed increment/decrement in between range r_t to be applied if user selected option
if vary_sr == 1
    ds = abs(s_f - s_s) ./ (mlayers ./ r_s - 1);
    if s_f < s_s
        ds = -ds;
    end
end

if vary_sb || vary_sr || vary_sw
    s_s = s_s - ds;
end


%Working out angle increment/decrement in between layers to be applied if user selected option
da = 0;

if vary_a == 1
    da = abs(a_f - a_s) ./ layers;
    if a_f < a_s
        da = -da;
    end
end

%Working out angle increment/decrement in between range r_t to be applied if user selected option
if vary_ar == 1
    da = abs(a_f - a_s) ./ (mlayers ./ r_a);
    if a_f < a_s
        da = -da;
    end
end

if vary_a || vary_ar 
    a_s = a_s - da;
end

%Assigning starting speed and angle to variables which will be altered throughout execution of the code
s_c = s_s;
a_c = a_s;

%initialisation of extrusion axis
Eu = 0;

%initialisation of x-coordinates for outer vertical shells
xo_coor([],1:shells_v) = zeros;

%initialisation of y-coordinates for outer vertical shells
yo_coor([],1:shells_v) = zeros;

%Counter for number of points in outer vertical shells
pointso = 1;

%Initialisation of z
if pt == 1
    z = thickness ./ 2;
else
    z = - thickness ./ 2;
end

%Calculation of total material to be extruded
vol_mm_i = (pi * (1.75 ./ 2) ^ 2) * 1;
vol_mm_f = (pi * (thickness ./ 2) ^ 2) * 1;
vol_r = (vol_mm_i ./ vol_mm_f) ./ 3;

%Opening text file to write code into
fdes = fopen('gcode.txt','wt');

%Writing initial G-code into gcode.txt
fprintf(fdes, 'M104 S200 T0;\n');   %set extruder temp
fprintf(fdes, 'M140 S50;\n');   %set plate temperature
fprintf(fdes, 'G21;\n');         %set units to mm
fprintf(fdes, 'G90;\n');         %choose absolute positioning
fprintf(fdes, 'G28;\n');         %home all axes
fprintf(fdes, sprintf('G1 Z%0.02f F5000;\n', z));   %retract nozzle to higher depth
fprintf(fdes, 'M109 S200 T0;\n');   %set initial extruder temp and wait for tool 1
if dual == 1
    fprintf(fdes, 'M109 S200 T1;\n');   %set initial extruder temp and wait for tool 2
end

%The number of the layer being printed starting from 1 at bottom.
%Used to select which nozzle is used in case of composite materials
count_l = 1;

%Create bottom horizontal shells with 100% infill
if shells_h > 0
    for l = 1 : shells_h
        lc = lct;   %resetting length to initial value
        hc = hct;   %resetting height to initial value
        
        if dual == 1    %if dual nozzles is switched on
            if rem(count_l,2) ~= 0
                fprintf(fdes, 'T0;\n');         %select extruder 1 containing first material
                count_l = count_l + 1;
            else
                fprintf(fdes, 'T1;\n');         %select extruder 2 containing second material
                count_l = count_l + 1;
            end
        end
              
        if vary_sb == 1      %if speed is set to vary
            s_c = s_c + ds;     %increase/decrease speed
        end
        
        %Create outer vertical shells
        for j = 1 : shells_v
            %First coordinate is upper left. No material is extruded while moving to this point
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso)));
            pointso = pointso + 1;
            
            %Second coordinate is upper right
            xo_coor(j,pointso) = lc./2 - (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            %Calculates material to be extruded from previous point to current point
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            %Stores value of total material extruded up till now in mm
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            %Third coordinate is lower right
            xo_coor(j,pointso) = lc./2 - (thickness ./ 2) + 100;
            yo_coor(j,pointso) = -hc./2 + (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            %Fourth coordinate is lower left
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = -hc./2 + (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            %Nozzle is sent back to first coordinate, completing the first outline
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            
            %Dimensions of next rectangle/square are altered such that they fit exactly inside previous one
            lc = lc - thickness;
            hc = hc - thickness;
        end
        
        %Following IF used to alter angle between negative and positive for
        %cross hatching pattern when user doesn't wish to vary magnitude of angle
        if vary_a == 0 && vary_ar == 0
            %Following IF used to create crossing pattern in between layers
            if vary_sw == 0
                if rem(l,2) ~= 0
                    [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,angle,thickness,vary_sw,s_s,s_f);
                else
                    [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,-angle,thickness,vary_sw,s_s,s_f);
                end
            else
                [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,angle,thickness, vary_sw,s_s,s_f);
            end
        end
        
        %IF user selects to vary magnitude of the angle, bottom horizontal shells are set to the initial angle the user wants
        if vary_a == 1 || vary_ar == 1
            [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,a_s,thickness,vary_sw,s_s,s_f);
        end
        
        %Creates infill pattern for horizontal shells
        for i = 2 : points
            dist = sqrt((x_coor(i)-x_coor(i-1))^2+(y_coor(i)-y_coor(i-1))^2) ./ vol_r;
            %Following IF makes sure material is not extruded upon repositioning to coordinate on new layer
            if i == 2
                fprintf(fdes, sprintf('G1 X%.02f Y%.02f\n', x_coor(i-1),y_coor(i-1)));
            else
                Eu = Eu + dist;
                fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', x_coor(i-1),y_coor(i-1), s_shell, Eu));
            end
        end
        
        %Move to next layer
        if pt == 1
            z = z + thickness;
        else
            z = z - thickness;
        end
        fprintf(fdes, sprintf('G1 Z%.02f\n', z));
    end
end

%Reset rectangle/square dimensions to original values
lc = lct;
hc = hct;

r_counter = 0;

%Creating middle layers
for l = 1 : layers - (2 * shells_h)
    
    lc = lct;   %resetting length to initial value
    hc = hct;   %resetting height to initial value
    
    if dual == 1
        if rem(count_l,2) ~= 0
            fprintf(fdes, 'T0;\n');
            count_l = count_l + 1;
        else
            fprintf(fdes, 'T1;\n');
            count_l = count_l + 1;
        end
    end
    
    if vary_sb == 1
        s_c = s_c + ds;
    end
    
    if vary_sr == 1
        if rem(r_counter,r_s) == 0
            s_c = s_c + ds;
        end
    end
    
    if vary_a == 1
        a_c = a_c + da;
        if a_c > 90
            a_c = 90;
        end
        if a_c < 0.5
            a_c = 0;
        end
    end
    
    if vary_ar == 1
        if rem(r_counter,r_a) == 0
            a_c = a_c + da;
            if a_c > 90
                a_c = 90;
            end
            if a_c < 0.5
                a_c = 0;
            end
        end
    end
    
    if shells_v > 0
        for j = 1 : shells_v    %creating outer vertical shells
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso)));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = lc./2 - (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = lc./2 - (thickness ./ 2) + 100;
            yo_coor(j,pointso) = -hc./2 + (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = -hc./2 + (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2 ./ vol_r);
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            
            lc = lc - thickness;
            hc = hc - thickness;
        end
    end
    
    if vary_a == 0 && vary_ar == 0
        if vary_sw == 0
            if rem(l,2) ~= 0
                [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,infill,angle,thickness,vary_sw,s_s,s_f);
            else
                [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,infill,-angle,thickness,vary_sw,s_s,s_f);
            end
            %If at least one parameter is set to vary within a layer, no cross-hatching will occur since this would cancel out effect
        else
            [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,infill,angle,thickness,vary_sw,s_s,s_f);
        end
    end
    
    if vary_a == 1 || vary_ar == 1
        [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,infill,a_c,thickness,vary_sw,s_s,s_f);
    end
    
    for i = 2 : points
        if i == 2   %To ensure no material is extruded upon repositioning to next layer
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f\n', x_coor(i-1),y_coor(i-1)));
        else
            if vary_sw == 1 %If speed is varied within the layer, G-Code is different and hence this code will be executed
                dist = sqrt(((x_coor(i)-x_coor(i-1))^2)+((y_coor(i)-y_coor(i-1))^2)) ./ vol_r;
                Eu = Eu + dist;
                fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', x_coor(i-1),y_coor(i-1), s_c_w(i-2), Eu));
            else   %If speed is not varied within the layer this code will be executed (uses s_c i.e. constant not s_c_w)
                dist = sqrt(((x_coor(i)-x_coor(i-1))^2)+((y_coor(i)-y_coor(i-1))^2)) ./ vol_r;
                Eu = Eu + dist;
                fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', x_coor(i-1),y_coor(i-1), s_c, Eu));
            end
        end
    end
    
    if pt == 1
        z = z + thickness;
    else
        z = z - thickness;
    end
    fprintf(fdes, sprintf('G1 Z%.02f\n', z));
    r_counter = r_counter + 1;
end

lc = lct;
hc = hct;

%Creating top horizontal shells with 100% infill (works exactly like creating the bottom shells but at different z)
if shells_h > 0
    for l = 1 : shells_h
        lc = lct;   %resetting length to initial value
        hc = hct;   %resetting height to initial value
        
        if dual == 1
            if rem(count_l,2) ~= 0
                fprintf(fdes, 'T0;\n');
                count_l = count_l + 1;
            else
                fprintf(fdes, 'T1;\n');
                count_l = count_l + 1;
            end
        end
        
        if vary_sb == 1
            s_c = s_c + ds;
        end
        
        for j = 1 : shells_v    %creating outer vertical shells
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso)));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = lc./2 - (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = lc./2 - (thickness ./ 2) + 100;
            yo_coor(j,pointso) = -hc./2 + (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = -hc./2 + (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            pointso = pointso + 1;
            
            xo_coor(j,pointso) = -lc./2 + (thickness ./ 2) + 100;
            yo_coor(j,pointso) = hc./2 - (thickness ./ 2) + 100;
            dist = sqrt((xo_coor(j,pointso)-xo_coor(j,pointso-1))^2+(yo_coor(j,pointso)-yo_coor(j,pointso-1))^2) ./ vol_r;
            Eu = Eu + dist;
            fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', xo_coor(j,pointso),yo_coor(j,pointso),s_shell,Eu));
            
            lc = lc - thickness;
            hc = hc - thickness;
        end
        
        if vary_a == 0 && vary_ar == 0
            if vary_sw == 0
                if rem(l,2) ~= 0
                    [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,angle,thickness,vary_sw,s_s,s_f);
                else
                    [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,-angle,thickness,vary_sw,s_s,s_f);
                end
            else
                [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,angle,thickness,vary_sw,s_s,s_f);
            end
        end
        
        if vary_a == 1 || vary_ar == 1
            [x_coor, y_coor, points, s_c_w] = Create_TP_Cuboid(lc,hc,100,a_f,thickness,vary_sw,s_s,s_f);
        end
        
        for i = 2 : points
            dist = sqrt((x_coor(i)-x_coor(i-1))^2+(y_coor(i)-y_coor(i-1))^2) ./ vol_r;
            if i == 2
                fprintf(fdes, sprintf('G1 X%.02f Y%.02f\n', x_coor(i-1),y_coor(i-1)));
            else
                Eu = Eu + dist;
                fprintf(fdes, sprintf('G1 X%.02f Y%.02f F%.02f E%.02f\n', x_coor(i-1),y_coor(i-1), s_shell, Eu));
            end
        end
        
        if pt == 1
            z = z + thickness;
        else
            z = z - thickness;
        end
        fprintf(fdes, sprintf('G1 Z%.02f\n', z));
    end
end

%Writing final G-code into gcode.txt
fprintf(fdes, 'G1 X0 Y0 F5000;\n');   %retract nozzle to higher depth
fprintf(fdes, sprintf('G1 Z%0.02f F5000;\n', z + (5 * thickness)));   %retract nozzle to higher depth
fprintf(fdes, 'M84\n');   %turn steppers off
fprintf(fdes, 'M140 S30;\n');   %set plate temperature
fprintf(fdes, 'M109 S30 T0;\n');   %set initial extruder temp and wait for tool 1
if dual == 1
    fprintf(fdes, 'M109 S30 T1;\n');   %set initial extruder temp and wait for tool 2
end

%Show toolpath for final layer
plot(x_coor,y_coor);

fclose(fdes);       %Close text file
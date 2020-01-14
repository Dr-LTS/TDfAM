function [xo_coor, yo_coor, points, s_c_w] = Create_TP_Cuboid(lc, hc, infill, angle, thickness, vary_sw, s_s, s_f)

%outputs
%xo_coor - matrix of x coordinates  
%yo_coor - matrix of y coordinates 
%points - outputs a scalar equal to the total number of coordinates forming the infill pattern.
%s_c_w - outputs speeds to be used for the printing of each line of the infill pattern as an array.

%inputs
%lc - length
%hc - height
%infill - infill density
%angle - tool path angle of the infill
%thickness - depth
%vary_sw -
%s_s -
%s_f -

if infill > 0    %if infill = 0, no action

    s_c_w = 0; 
    %outer shells are programmed in the main section
    
    t = thickness * (100 ./ infill);   
    %t -  the distance between each subsequent infill line. Larger infills lead to a smaller t.
    %When infill = 100, t = thickness such that the distance between subsequent fill lines is the diameter of the filament.
    
    
    %The function is subdivided into 3 main parts: 
    %1) When angle = 0 
    %2) When angle = 90
    %3) When the angle is anything in between
    
    %When angle is 0
    if abs(angle) == 0
        yt = - hc ./ 2;
        k = 1;      %counter
        while yt <= hc ./ 2
            x_coor(k) = -lc ./ 2;
            y_coor(k) = yt;
            k = k + 1;
            x_coor(k) = lc ./ 2;
            y_coor(k) = yt;
            k = k + 1;
            yt = yt + t;
        end
        k = k - 1;
end
   
%When angle is 90
if abs(angle) == 90
        xt = lc ./ 2;
        k = 1;      %Counts the total number of points
        while xt >= -lc ./ 2
            x_coor(k) = xt;
            y_coor(k) = -hc./2;
            k = k + 1;
            x_coor(k) = xt;
            y_coor(k) = hc./2;
            k = k + 1;
            xt = xt - t;
        end
        k = k - 1;
end
    
if (abs(angle) > 0) && (abs(angle) < 90)
        
        m = tand(abs(angle));
        %m - gradient of the infill lines. 
        %For now only a positive gradient will be computed. 
        %All x-coordinates will be changed later in the program if the angle is negative to allow for an alternating pattern between layers
            
        %The cross section is divided into 3 sections (please refer to the method).
        %xa_coor and ya_coor store those found in section A 
        %xb_coor and yb_xoor store those found in section B
        %xc_coor and yc_coor store those found in section C
        xa_coor = [];
        ya_coor = [];
        xb_coor = [];
        yb_coor = [];
        xc_coor = [];
        yc_coor = [];
        
        %The arrays of coordinates of all 3 sections are joined in x_coor, y_coor
        x_coor = [];
        y_coor = [];
        
        lines = 1;          %counter
        c_up = [];          %Stores y-intercept of lines found in the upper half of rectangle
        c_down = [];        %Stores y-intercept of lines found in the lower half of rectangle
        c_up(lines) = 0;    %initialisation
        c_down(lines) = 0;  %initialisation
        y_temp = 0;
        
        while y_temp <= hc ./ 2    %an exagerated value such that all the area of the rectangle is covered with the infill even at very large angles
            lines = lines + 1;
            %the following is a relationship to obtain the varying y-intercept of each diagonal depending on the previously obtained value of t.
            c_up(lines) = c_up(lines-1) + (t ./ cosd(abs(angle)));
            %y-intercepts are symmetrical over the line y = 0 since the origin is at the centre of the cuboid.
            c_down(lines) = -c_up(lines);
            y_temp = (m * -lc./2) + c_up(lines);
        end
        
        
        c = [];
        %c - an array to store all y-intercepts in order starting from the most negative to the most positive
        
        %Rearranging the lower half of y-intercepts
        for j = 1 : lines - 1
            c(j) = c_down(lines-(j-1));
        end
        
        c(lines) = 0;   %Sets the middle value of array c as the y-intercept passing through the origin
        
        k = 2; %counter
        
        %Rearranging the upper half of y-intercepts
        for j = lines + 1 : (2 * lines) - 1
            c(j) = c_up(k);
            k = k + 1;
        end
        
        yt = 0;     %stores temporary check value
        xt = lc;
        
        a = 1;      %stores number of points in section A
        b = 1;      %stores number of points in section B
        d = 1;      %stores number of points in section C. Variable c is already in use.
        i = 1;      %counter
        
        %Works out the points in section A
        while (yt <= hc ./ 2) && (xt >= -lc ./ 2)
            yref = -hc ./ 2;                        %y-coordinate lies on lower edge
            xc = (yref - c(i)) ./ m;                %work out corresponding x-coordinate
            xt = xc;
            if (xc >= -lc./2) && (xc <= lc./2)      %Checks if xc lies within limits
                xa_coor(a) = xc;                    %store x
                ya_coor(a) = yref;                  %store y
                a = a + 1;                          %increment number of points
            end
            xref = lc ./ 2;                         %x-coordinate lies on right edge
            yc = (m * xref) + c(i);                 %work out corresponding y-coordinate
            yt = yc;                                %sets check variable to this y-coordinate
            if (yc >= -hc./2) && (yc <= hc./2)      %Checks if yc lies within limits
                xa_coor(a) = xref;                     %store x
                ya_coor(a) = yc;                    %store y
                a = a + 1;                          %increment number of points
            end
            i = i + 1;                  %use next line
        end
        
        a = a - 2;      %a is reduced by 2 since the last 2 points worked out actually lie in section B not section A
        if rem(a,2) ~= 0
            a = a - 1;
        end
        i = i - 1;
        
        %Stores coordinates found in section A into (x_coor,y__coor), after checking that any coordinates do exist
        if numel(xa_coor) > 0
            for l = 1 : a
                x_coor(l) = xa_coor(l);
                y_coor(l) = ya_coor(l);
            end
        end
        
        check_angle = atand(hc ./ lc);
        
        if abs(angle) > check_angle
            
            xt = lc;    %stores temporary check value (intialisation is exagerated)
            xt2 = 0;
            
            %Working out the points in section B similarily to section A, but with different constraints.
            while (xt >= -lc ./ 2) && (xt2 <= lc ./ 2)
                yref = -hc ./ 2;            %y-coordinate lies on lower edge
                xc = (yref - c(i)) ./ m;
                xt = xc;
                if (xc >= -lc./2) && (xc <= lc./2)
                    xb_coor(b) = xc;
                    yb_coor(b) = yref;
                    b = b + 1;
                end
                yref = hc ./ 2;             %y_coordinate lies on higher edge
                xc = (yref - c(i)) ./ m;
                xt2 = xc;
                if (xc >= -lc./2) && (xc <= lc./2)
                    xb_coor(b) = xc;
                    yb_coor(b) = yref;
                    b = b + 1;
                end
                i = i + 1;
            end
            
        else
            
            yt = hc;    %stores temporary check value (intialisation is exagerated)
            yt2 = 0;
            
            %Working out the points in section B similarily to section A, but with different constraints.
            while (yt >= -hc ./ 2) && (yt2 <= hc ./ 2)
                xref = -lc ./ 2;            %x-coordinate lies on left edge
                yc = (m * xref) + c(i);
                yt = yc;
                if (yc >= -hc./2) && (yc <= hc./2)
                    xb_coor(b) = xref;
                    yb_coor(b) = yc;
                    b = b + 1;
                end
                xref = lc ./ 2;             %x_coordinate lies on higher edge
                yc = (m * xref) + c(i);
                yt2 = yc;
                if (yc >= -hc./2) && (yc <= hc./2)
                    xb_coor(b) = xref;
                    yb_coor(b) = yc;
                    b = b + 1;
                end
                i = i + 1;
            end
        end
        
        b = b - 2;   %b is negated by 2 since the last 2 points worked out actually lie in section C not section B
        if rem(b,2) ~= 0
            b = b - 1;
        end
        i = i - 1;
        
        %Stores coordinates found in section B into (x_coor,y__coor), after
        %checking that any coordinates do exist
        if numel(xb_coor) > 0
            for l = 1 : b
                x_coor(l+a) = xb_coor(l);
                y_coor(l+a) = yb_coor(l);
            end
        end
        
        yt = 0;     %stores temporary check value
        xt = lc;
        
        while (yt <= hc ./ 2)&& (xt >= - lc ./ 2)
            xref = -lc ./ 2;    %x-coordinate lies on left edge
            yc = (m * xref) + c(i);
            yt = yc;
            if yc >= -hc./2 && yc <= hc./2
                xc_coor(d) = xref;
                yc_coor(d) = yc;
                d = d + 1;
            end
            yref = hc ./ 2;     %y-coordinate lies on upper edge
            xc = (yref - c(i)) ./ m;
            if (xc >= -lc./2) && (xc <= lc./2)
                xc_coor(d) = xc;
                yc_coor(d) = yref;
                d = d + 1;
            end
            i = i + 1;
        end
        
        d = d - 2;
        if rem(d,2) ~= 0
            d = d - 1;
        end
        i = i - 1;
        
        if numel(xc_coor) > 0
            for l = 1 : d
                x_coor(l+a+b) = xc_coor(l);
                y_coor(l+a+b) = yc_coor(l);
            end
        end
        
        k = a + b + d;
        
    end
    
    %Remaining code is executed for angles including 0 and 90:
    
    points = k;     %Stores total number of points
    
    %Initialisation for temparary variables used in switching coordinates
    x_temp = 0;
    y_temp = 0;
    
    %Switching coordinate order such that zig-zag pattern is transformed into rectilinear pattern
     pt = 1;
    
    for l = 1 : (k ./ 2)
        if rem(l,2) ~= 0
            xo_coor(pt) = x_coor(pt);
            xo_coor(pt+1) = x_coor(pt+1);
            yo_coor(pt) = y_coor(pt);
            yo_coor(pt+1) = y_coor(pt+1);
        else
            xo_coor(pt) = x_coor(pt+1);
            xo_coor(pt+1) = x_coor(pt);
            yo_coor(pt) = y_coor(pt+1);
            yo_coor(pt+1) = y_coor(pt);
        end
        pt = pt + 2;
    end
    
    for l = 1 : k
        if xo_coor(l) < -lc./2
            xo_coor(l) = -lc./2;
        else if yo_coor(l) < -hc./2
                yo_coor(l) = -hc./2;
            end
        end
        if xo_coor(l) > lc./2
            xo_coor(l) = lc./2;
        else if yo_coor(l) > hc./2
                yo_coor(l) = hc./2;
            end
        end
    end
    
    %Mirroring in the line x=0 if angle is negative
    if angle < 0
        for j = 1 : k
            xo_coor(j) = -xo_coor(j) + 100;
            yo_coor(j) = yo_coor(j) + 100;
        end
    else
        for j = 1 : k
            xo_coor(j) = xo_coor(j) + 100;
            yo_coor(j) = yo_coor(j) + 100;
        end
    end
    
    if (vary_sw == 1)
        %Calculating total distance
        d = [];
        d_total = 0;
        
        for l = 1 : k-1
            d(l) = sqrt((xo_coor(l+1)-xo_coor(l))^2+(yo_coor(l+1)-yo_coor(l))^2);
            d_total = d_total + d(l);
        end
       
        if vary_sw == 1
            diff_s = abs(s_f - s_s);        %Stores difference between start and final temperature
            ds_w = diff_s ./ d_total;       %Stores change which should be done every 1mm
            s_c_w = [];
            s_c_w(1) = s_s;
            
            for l = 2 : k-1
                s_c_w(l) = s_c_w(l-1) + (d(l) * ds_w);
            end
        end
        
        plot(xo_coor,yo_coor);  %Plot points for verification
        
    end
end
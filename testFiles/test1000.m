disp(rectOverlap(savedPositions{1}, [680, 310, 680+108, 310+108]))

function overlap = rectOverlap(rect1, rect2)
    x1 = rect1(1);
    y1 = rect1(2);
    w1 = rect1(3) - x1;
    h1 = rect1(4) - y1;
    
    x2 = rect2(1);
    y2 = rect2(2);
    w2 = rect2(3) - x2;
    h2 = rect2(4) - y2;
    
    % Calculate the right and bottom edges of the rectangles
    right1 = x1 + w1;
    bottom1 = y1 + h1;
    
    right2 = x2 + w2;
    bottom2 = y2 + h2;
    
    % Check for overlap
    if x1 < right2 && x2 < right1 && y1 < bottom2 && y2 < bottom1
        overlap = true;
    else
        overlap = false;
    end
end
function [theta] = verifyPolygonAngle(theta)
    if(theta <= -360), theta = theta + 360; elseif(theta >= 360), theta = theta - 360; end
    if(theta < 0), theta = theta + 360; end 
end

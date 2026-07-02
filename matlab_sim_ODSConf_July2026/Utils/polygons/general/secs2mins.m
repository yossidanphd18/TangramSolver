function [mins] = secs2mins(secs)
   mins = round(10000*(secs/60))/10000;
end
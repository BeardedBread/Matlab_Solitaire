%   Original author: En Yi
%   The card class used in the solitaire game
%   Not optimised though
%   Anyone can modify it, just need to give credits to the original author
classdef Cards
    properties(SetAccess = private)
        value
        image_data
        backimage_data
    end
    methods
        function crd = Cards(value,image_data,backimage_data)
            crd.value = value;
            crd.image_data = image_data;
            crd.backimage_data = backimage_data;
        end
        function [num,colour,suit] = get_Card_Info(crd)
            num = mod(crd.value,100);
            suit = floor(crd.value/100);
            colour = mod(suit,2);
        end
        function img_data = get_Card_Image(crd,side)
            if strcmp(side,'back')
                img_data = crd.backimage_data;
            else 
                 img_data = crd.image_data;
            end
            img_data = (double(flipud(img_data)))/255;
        end
    end
end
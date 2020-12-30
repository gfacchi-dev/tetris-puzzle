function [out mirror] = bruteForce(scene, scheme, label)
scheme2 = imresize(scheme, 1);
fine = false;
i=1;
minValue = size(scheme2,1)* size(scheme2,2);
minNormal = 0;
while (i<360)
    process = imrotate(scene, i);
    process = imresize(process, [size(scheme2,1) size(scheme2,2)]);

    matching = (double(process) - double(scheme2))==1;
    num = sum(matching(:) == 1);
    if (num<minValue)
        minValue = num;
        minNormal = i;
    end
    i = i+1 ;
end
minMirror = 0;
i=1;
mirror = 0;

if(uint8(label) == 5 )
while (i<360)
    process=  flip(scene,2); 
    process = imrotate(process, i);
    process = imresize(process, [size(scheme2,1) size(scheme2,2)]);

    matching = (double(process) - double(scheme2))==1;
    num = sum(matching(:) == 1);
    if (num<minValue )
        minValue = num;
        minMirror = i;
        mirror = 1;
    end
    i = i+1 ;
end
end

if(mirror == 1)
out = minMirror;

else
    out = minNormal;
end
end
function X2 = useralign(file1,file2,X1,X2,xL1,xL2,max_dist)

%  Input:
%   file1 = filepath to first image
%   file2 = filepath to second image
%   X1 = 3XN matrix of points
%   X2 = 3XN matrix of points
%   xL1 = 3XN matrix of points
%   xL2 = 3XN matrix of points
%   max_dist = integer specifying the max distance two points can be apart
% Output:
%   X2 = 3XN Matrix with SVD R matrix and t vector applied

flag = 1;
while(flag)
    flag = 0;
    %have the user click 4+ points in both images
    [pic1,pic2] = cpselect(file1,file2,'Wait',true);
    
    %for each clicked on point in pic1 get the nearest point in xL1
    for i = 1:size(pic1,1)
        least = 1000000;
        for j = 1:size(xL1,2)
            dx = pic1(i,1) - xL1(1,j);
            dy = pic1(i,2) - xL1(2,j);
            dist = sqrt(dx * dx + dy * dy);
            if(dist < least)  
                ind1(i,1) = j;
                ind1(i,2) = dist;
                least = dist;
            end
        end
    end

    %for each clicked on point in pic2 get the nearest point in xL2
    for i = 1:size(pic2,1)
        least = 1000000;
        for j = 1:size(xL2,2)
            dx = pic2(i,1) - xL2(1,j);
            dy = pic2(i,2) - xL2(2,j);
            dist = sqrt(dx * dx + dy * dy);
            if(dist < least)  
                ind2(i,1) = j;
                ind2(i,2) = dist;
                least = dist;
            end
        end
    end
    
    %make sure none of the distance between a point and its counterpart is
    %greater than max_dist otherwise restart the loop
    for i = 1:size(ind1,1)
        if(ind1(i,2) > max_dist)
            state = strcat('In left picture, point',num2str(i),' value is more than maximum distance');
            disp(state);
            flag = 1;
        end
        if(ind2(i,2) > max_dist)
            state = strcat('In right picture, point',num2str(i),' value is more than maximum distance');
            disp(state);
            flag = 1;
        end
    end
end

%find 3D point correlations in X1 and X2
for i = 1:size(ind1,1)
    X_svd1(:,i) = X1(:,ind1(i));
    X_svd2(:,i) = X2(:,ind2(i));
end

%run SVD and get results
[~,R,t] = rigidalignment(X_svd1,X_svd2);
X2 = R*X2 + repmat(t,1,size(X2,2)); %apply R and t to X2


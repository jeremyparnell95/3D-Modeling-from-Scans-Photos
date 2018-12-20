function X2 = ICP(X1,X2,max_dist,iter)

%  Input:
%   X1 = 3XN matrix of points
%   X2 = 3XN matrix of points
%   max_dist = integer specifying the max distance two points can be apart
%   iter = integer value indicating how many iterations of the loop to go
%   through
% Output:
%   X2 = 3XN Matrix with ICP applied

%start the number of loops to go through
for a = 1:iter  
    % For each point in X1, compute the closest point in X2.
    for i = 1:size(X1,2)
        least = 1000000;
        for j = 1:size(X2,2)
            dx = X1(1,i) - X2(1,j);
            dy = X1(2,i) - X2(2,j);
            dz = X1(3,i) - X2(3,j);
            dist = sqrt(dx * dx + dy * dy + dz * dz);
            if(dist < least)  
                pairs(1,i) = j;
                pairs(2,i) = dist;
                least = dist;
            end
        end
    end

    count = 1;
    % Find the subset of points in X1 whose nearest neighbor is closer than some small threshold distance  (e.g. something like 5mm or less assuming they are already decently aligned).
    for i = 1:size(pairs,2)
        if(pairs(2,i) < max_dist)    
            temp(1,count) = i;
            temp(2,count) = pairs(1,i);
            count = count + 1;
        end
    end

    %Let ind1 be the subset of points in X1 and ind2 be their corresponding nearest neighbors in X2.  Use the SVD method to find the R,t which maps X2(:,ind2) to X1(:,ind1)
    for i = 1:size(temp,2)
        X_svd1(:,i) = X1(:,temp(1,i));
        X_svd2(:,i) = X2(:,temp(2,i));
    end

    % X2 <-- R*X2 + t
    [~,R,t] = rigidalignment(X_svd1,X_svd2);
    X2 = R*X2 + repmat(t,1,size(X2,2));
    % repeat until convergence...
end




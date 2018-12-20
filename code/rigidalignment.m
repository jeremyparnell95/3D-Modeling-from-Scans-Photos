function [X2aligned,R,t] = rigidalignment(X1,X2)

% 
% Input
%     X1 = 3XN Matrix of Points
%     X2 = 3XM Matrix of Points
% 
% Output
%     X2aligned = 3XN Matrix
%     R = 3X3 Matrix Rotation
%     t = 3X1 Vector Translation


X1c	= X1 - repmat(mean(X1,2),1,size(X1,2));
X2c	= X2 - repmat(mean(X2,2),1,size(X2,2));
H = X2c * X1c';
[U,S,V]	= svd(H);
R =	V * U'; % get rotation matrix
t = mean(X1,2) - R*mean(X2,2); %get translation vector
X2aligned =	R*X2 + repmat(t,1,size(X2,2)); % apply to R2
%Jeremy Parnell
%27005248

thresh = 0.02;
scan = 'C:\Users\jerem\OneDrive\Desktop\project_code\couple\grab_';
nimages = 7;

xmin = [220, 275, 280, 230, 290, 260, 170];
xmax = [450, 400, 410, 420, 415, 450, 440];
ymin = [-100. -100, -100, -100, -100, -100, -100];
ymax = [250, 250, 250, 250, 250, 250, 250];
zmin = [-150, -210, -220, -190, -220, -180, -280];
zmax = [-100, -60, -70, -70, -110, -20, 50];

load camParam cameraParams

camL.f = mean(cameraParams.CameraParameters1.FocalLength);
camL.c = cameraParams.CameraParameters1.PrincipalPoint;
camL.R = cameraParams.CameraParameters1.RotationMatrices(:,:,5);
camL.t = -camL.R * cameraParams.CameraParameters1.TranslationVectors(5,:)';

camR.f = mean(cameraParams.CameraParameters2.FocalLength);
camR.c = cameraParams.CameraParameters2.PrincipalPoint;
camR.R = cameraParams.CameraParameters2.RotationMatrices(:,:,5);
camR.t = -camR.R * cameraParams.CameraParameters2.TranslationVectors(5,:)';

for i = 1:nimages
    scandir = strcat(scan,num2str(i-1),'\');
    
    [L_h,L_h_good] = decode([scandir 'frame_C1_'],0,19,thresh);
    [L_v,L_v_good] = decode([scandir 'frame_C1_'],20,39,thresh);
    [R_h,R_h_good] = decode([scandir 'frame_C0_'],0,19,thresh);
    [R_v,R_v_good] = decode([scandir 'frame_C0_'],20,39,thresh);

    %
    % combine horizontal and vertical codes
    % into a single code and a single mask.
    %
    Rmask = R_h_good & R_v_good;
    R_code = R_h + 1024*R_v;
    Lmask = L_h_good & L_v_good;
    L_code = L_h + 1024*L_v;

    %
    % now find those pixels which had matching codes
    % and were visible in both the left and right images
    %
    % only consider good pixels
    Rsub = find(Rmask(:));
    Lsub = find(Lmask(:));

    % find matching pixels 
    [matched,iR,iL] = intersect(R_code(Rsub),L_code(Lsub));
    indR = Rsub(iR);
    indL = Lsub(iL);

    % indR,indL now contain the indices of the pixels whose 
    % code value matched

    % pull out the pixel coordinates of the matched pixels
    [h,w] = size(Rmask);
    [xx,yy] = meshgrid(1:w,1:h);
    xL = []; xR = [];
    xR(1,:) = xx(indR);
    xR(2,:) = yy(indR);
    xL(1,:) = xx(indL);
    xL(2,:) = yy(indL);

    %
    % now triangulate the matching pixels using the calibrated cameras
    %
    X = triangulate(xL,xR,camL,camR);
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % cleaning step 1: remove points outside known bounding box
    %
    goodpoints = find( (X(1,:)>xmin(i)) & (X(1,:)<xmax(i)) & (X(2,:)>ymin(i)) & (X(2,:)<ymax(i)) & (X(3,:)>zmin(i)) & (X(3,:)<zmax(i)) );
    fprintf('dropping %2.2f %% of points from scan\n',100*(1 - (length(goodpoints)/size(X,2))));


    %
    % drop points from both 2D and 3D list
    %
    X = X(:,goodpoints);
    xR = xR(:,goodpoints);
    xL = xL(:,goodpoints);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % cleaning step 2: remove triangles which have long edges
    %

    trithresh = 10;   %10mm

    fprintf('triangulating from left view\n');
    tri = delaunay(xL(1,:),xL(2,:));
    ntri = size(tri,1);
    npts = size(xL,2);
    terr = zeros(ntri,1);
    for j = 1:ntri
      fprintf('\rtraversing triangles %d/%d',j,ntri);
      d1 = sum((X(:,tri(j,1)) - X(:,tri(j,2))).^2);
      d2 = sum((X(:,tri(j,1)) - X(:,tri(j,3))).^2);
      d3 = sum((X(:,tri(j,2)) - X(:,tri(j,3))).^2);
      terr(j) = max([d1 d2 d3]).^0.5;
    end
    fprintf('\n');
    subt = find(terr<trithresh);

    fprintf('dropping %2.2f %% of triangles from scan\n',100*(1 - (length(subt)/size(tri,1))));

    tri = tri(subt,:);

    %
    % remove unreferenced points which don't appear in any triangle
    %
    allpoints = (1:size(X,2))';
    refpoints = unique(tri(:)); %list of unique points mentioned in tri

    % build a table describing how we reindex points
    newid = -1*ones(size(allpoints));
    newid(refpoints) = 1:length(refpoints);

    %now newid(k) contains the new index for current point k
    % apply this mapping to all the indicies in tri

    tri = newid(tri);

    % and drop un-referenced points
    X = X(:,refpoints);
    xR = xR(:,refpoints);
    xL = xL(:,refpoints);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % display results
    %
    xColor = 0.7*ones(size(X,2),3);
    h = trimesh(tri,X(1,:),X(2,:),X(3,:),'facevertexcdata',xColor,'edgecolor','interp','facecolor','interp');
   
    %saving information to mat data file
    file = strcat('grab',num2str(i-1),'.mat');
    save(file,'X','xL','xR','tri','xColor'); 
end

%smoothing points and saving them out to files
for i = 1:nimages
    load(['grab' num2str(i-1)]);
    X_mesh = nbr_smooth(tri,X,4);
    file = strcat('X_mesh',num2str(i-1),'.mat');
    save(file,'X_mesh');
end

%Loading in all alignment information from each grab
%*************************************************************************
load grab0 xL xR xColor tri
xL0 = xL;
xR0 = xR;
xColor0 = xColor;
tri0 = tri;
load X_mesh0 X_mesh
X0 = X_mesh;

load grab1 xL xR xColor tri
xL1 = xL;
xR1 = xR;
xColor1 = xColor;
tri1 = tri;
load X_mesh1 X_mesh
X1 = X_mesh;

load grab2 xL xR xColor tri
xL2 = xL;
xR2 = xR;
xColor2 = xColor;
tri2 = tri;
load X_mesh2 X_mesh
X2 = X_mesh;

load grab3 xL xR xColor tri
xL3 = xL;
xR3 = xR;
xColor3 = xColor;
tri3 = tri;
load X_mesh3 X_mesh
X3 = X_mesh;

load grab4 xL xR xColor tri
xL4 = xL;
xR4 = xR;
xColor4 = xColor;
tri4 = tri;
load X_mesh4 X_mesh
X4 = X_mesh;

load grab5 xL xR xColor tri
xL5 = xL;
xR5 = xR;
xColor5 = xColor;
tri5 = tri;
load X_mesh5 X_mesh
X5 = X_mesh;

load grab6 xL xR xColor tri
xL6 = xL;
xR6 = xR;
xColor6 = xColor;
tri6 = tri;
load X_mesh6 X_mesh
X6 = X_mesh;

%ALIGNMENT
%*************************************************************************
X6 = useralign('g0.png','g6.png',X0,X6,xL0,xL6,5);  %aligning all the meshes
X1 = useralign('g0.png','g1.png',X0,X1,xL0,xL1,5);
X5 = useralign('g0.png','g5.png',X0,X5,xL0,xL5,5);
X4 = useralign('g5.png','g4.png',X5,X4,xL5,xL4,5);
X3 = useralign('g4.png','g3.png',X4,X3,xL4,xL3,5);
X2 = useralign('g1.png','g2.png',X1,X2,xL1,xL2,5);
X3 = useralign('g2.png','g3.png',X2,X3,xL2,xL3,5);

X6 = ICP(X0,X6,5,5);    %running ICP on all the initial mesh alignments
X5 = ICP(X0,X5,5,5);
X4 = ICP(X5,X4,5,5);
X1 = ICP(X0,X1,5,5);
X2 = ICP(X1,X2,5,5);
X3 = ICP(X2,X3,5,5);

mesh_2_ply(X0,xColor0',tri0, strcat('mesh0.ply')); %saving all the mesh information
mesh_2_ply(X1,xColor1',tri1, strcat('mesh1.ply'));
mesh_2_ply(X2,xColor2',tri2, strcat('mesh2.ply'));
mesh_2_ply(X3,xColor3',tri3, strcat('mesh3.ply'));
mesh_2_ply(X4,xColor4',tri4, strcat('mesh4.ply'));
mesh_2_ply(X5,xColor5',tri5, strcat('mesh5.ply'));
mesh_2_ply(X6,xColor6',tri6, strcat('mesh6.ply'));

%***********END*************************************************************
disp('Load mesh files 0 - 6 into MESHLAB and use Poisson Reconstruction and texture mapping to finish up project');







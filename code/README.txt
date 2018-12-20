Decode: Given a image path, a starting image, stopping image and a threshold, decode returns an array of decoded faules for 10-bit values and a binary image that indicates which pixels were decodable


Triangulate: Given points in a left and right image and the camera parameters of both the left and right camera, Triangulate will return a matrix of 3D points in world space


ICP: Given two sets of 3D points, a max distance threshold, and a number of iterations, runs iterative closest point algorithm on 3D points for better alignment


Mesh_2_ply: Given by a previous  year’s student, mesh_2_ply simply converts a given mesh to a “.ply” file in order to be used elsewhere. I used it for the purposes of Meshlab in my project


Nbr_smooth: Given a set of points, their triangulation, and a specified integer number of rounds, nbr_smooth smooths point locations. This was used in order to smooth my meshes in preparation for alignment. 


Rigidaling: Takes two sets of 3D coordinates, runs SVD on them, and return X2 with R and t applied 


Useralign: Given two image paths, two sets of 3D points as well as each of their corresponding sets of 2D points from their left cameras, and a max distance threshold integer, this function takes user clicks and solves for the best initial rotation and translation between two point clouds


Demo: a script for scanning objects and creating a high-quality 3D model. User input required
# StrokeClassifier
This is a SVM classifier that differentiate strokes as contour or shading.

Drawing is a way to transfer our three dimensional perception about world to a two
dimensional surface. Our brains are capable of perceiving this third dimension, namely depth,
in a drawing but computers cannot. I searched for the drawing techniques that are used by
artists to achieve this depth feeling and I concluded that there are mainly 2 types of strokes
which are used by artist commonly. These are contour and shading strokes. In this project, I
trained a model that classify the strokes as outline or shading.

There are 24 sketches in the data folder. In total, there are 6535 strokes, labeled as contour or shade,  in these sketces.
The strokes are represented in the dataset as an array of points and each point has 4 variable: x-coordinate, y-coordinate, drawing
time and pen pressure.

62 features are calculated for each stroke. 
length + frequency + curvature(20) + speed(20) + pressure(20) = 62

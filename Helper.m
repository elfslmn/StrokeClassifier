classdef Helper
    properties
        Property1
    end
    
    methods (Static = true)
        % stroke: structure , sum: double
        function sum = getPathLength(stroke)
            X = stroke.X;
            Y = stroke.Y;
            sum = 0;
            for j = 2: length(X)
                sum = sum + norm(Y(j) - Y(j-1), X(j) - X(j-1));
            end
        end
        
        % stroke: structure , curvatures: column vector
        function curvatures = getCurvatures(stroke)
            X = stroke.X;
            Y = stroke.Y;
            n = length(X);
            curvatures = zeros(n, 1);
            for j = 2:n
                curvatures(j) = atan2(Y(j) - Y(j-1), X(j) - X(j-1));
            end
            % convert all negative angles to positive by adding pi to the
            curvatures(curvatures < 0) = curvatures(curvatures < 0) + pi;
        end
        
          % stroke: structure , speeds: column vector
        function speeds = getSpeeds(stroke)
            X = stroke.X;
            Y = stroke.Y;
            time = stroke.Time;
            n = length(X);
            speeds = zeros(n, 1);
            for j = 2:n
                speeds(j) = ( norm(Y(j) - Y(j-1), X(j) - X(j-1)))/ (time(j)- time(j-1)) ;
            end
        end
        
     
        % stroke: structure , curvatures: column vector
        function equalizedFeatures = equalizeFeatureSizes(features, count)
            pointCount =  length(features);
            equalizedFeatures = [];
            
            if(count < pointCount) % means bin count < pointCount -> combine point curvatures
                binSize = floor(pointCount / count);
                remainder = mod(pointCount, count);
                
                binSize = binSize +1;
                for i = 0:remainder-1
                    equalizedFeatures(i+1) = mean (features((i*binSize+1):((i+1)*binSize)));
                end
                binSize = binSize -1;
                for i = remainder : count-1
                    equalizedFeatures(i+1) = mean (features((i*binSize+1):((i+1)*binSize)));
                end
            elseif(count == pointCount)
                equalizedFeatures = features;
            else  % means bin count > pointCount -> spread curvatures
                binSize = floor( count / pointCount);
                remainder = mod(count, pointCount);
                binSize = binSize +1;
                for i = 0:remainder-1
                    equalizedFeatures((i*binSize+1):((i+1)*binSize)) = features(i+1);
                end
                
                binSize = binSize -1;
                for i = 0 : pointCount-1-remainder
                    start = remainder*(binSize+1) + i*binSize+1;
                    fin = start + binSize -1;
                    equalizedFeatures(start:fin) = features(i+1+remainder);
                end
            end
            
        end
                   
        % data: nx5 matrix (stroke no, x, y, press, time, timeStamp)
        function reducedData = reducePointsByTime(data)
            times = unique(data(:,5));
            start = times(1);
            n = length(times);
            reducedData = zeros(n,5);
            
            for i = 1: n
                indices = find(data(:,5) == times(i));
                id = unique (data(indices,1));
                if( length(id) ~= 1)
                    disp('error: reducePoints STROKE ID DIFFERNCE');
                else
                    reducedData(i,1) = id;
                    reducedData(i,2:4) = mean (data(indices,2:4),1);
                    reducedData(i,5) = times(i)-start; % drawing starts at 0 time
                end
            end
            
        end
              
        function fftCount = getFrequencyFeature(strokes)
            fig=figure;
            hold on;
            set(fig, 'Visible', 'off');
            for i= 1: length(strokes)
                s= strokes(i);
                X = s.X;
                Y=s.Y;
                for j = 1:length(X)-1
                    p=plot([X(j), X(j+1)], [-Y(j), -Y(j+1)]);
                    set(p, 'Color',[0,0,0]);
                    p.LineWidth = 1;
                end
            end
            frame = getframe;
            img = frame.cdata;
            img = rgb2gray(img);
            F = fft2(img);
            Fsc =log(1+abs(fftshift(F)));
            %imagesc(Fsc);
            fftCount = sum(sum(Fsc>10));
            hold off;
            close(gcf);
        end
        
         
    end
end


function [TransMatrix, OldCorr] = C_BestTrans(Metrics)

tic

MetricNames = fieldnames(Metrics{1});
% 
% OriginalImage = Metrics{2}.(MetricNames{1});
% baseImage = Metrics{1}.(MetricNames{1});
% 
% % Parameter ranges as vectors
% translationX = -10:2:10;
% translationY = -10:2:10;
% rotationAngle = -45:5:45;
% scaleFactor = 0.8:0.05:1.2;
% shearFactor = -0.2:0.05:0.2;
% 
% % Create combinations using nested meshgrid calls (two calls)
% [X, Y] = meshgrid(translationX, translationY);
% [Z, W, V] = meshgrid(rotationAngle, scaleFactor, shearFactor);
% 
% % Combine parameters into a single array
% transformations = cat(3, ...
%     repmat(W .* diag([1, 1, 1]), size(X, 1), size(X, 2), 1), ...
%     repmat(V .* diag([shearFactor, shearFactor, 0]), size(X, 1), size(X, 2), 1), ...
%     repmat(X(:) .* [1 0 0] + Y(:) .* [0 1 0] + ones(numel(X), 1) .* [0 0 1], 1, 1, size(Z, 3)) ...
% );
% 
% % Apply transformations and calculate correlations efficiently
% transformedImages = imtransform(OriginalImage, transformations);
% correlations = normxcorr2(transformedImages, baseImage);
% 
% % Find indices of maximum correlation
% [maxCorrValue, maxIdx] = max(correlations(:));
% 
% % Extract best transformation and correlation
% bestCorrelation = maxCorrValue;
% bestTransformation = transformations(:,:,maxIdx);
% 
% disp('Best correlation: ');
% disp(bestCorrelation);
% disp('Best transformation matrix: ');
% disp(bestTransformation);


% Define parameter ranges
TranslationRange = [-50:10:50]; 
ScaleRange = [0.5:0.1:1.5]; 
RotationRange = [-20:5:20]; 
ShearingRange = [-0.2:0.05:0.2]; 

[tx, ty, scale_x, scale_y, angle, shear_x, shear_y] = ndgrid(TranslationRange, TranslationRange, ScaleRange, ScaleRange, RotationRange, ShearingRange, ShearingRange);

% Reshape the parameter grids to column vectors
tx = tx(:);
ty = ty(:);
scale_x = scale_x(:);
scale_y = scale_y(:);
angle = angle(:);
shear_x = shear_x(:);
shear_y = shear_y(:);

OldCorr = 0;
% 
% % Calculate affine transformation matrices directly without explicit loops
% num_transformations = numel(tx);
% 
% % Translation matrix for each set of parameters
% translation_matrix = [eye(2), zeros(2, 1); 0, 0, 1] * [eye(2), [tx'; ty']; zeros(1, 3)];
% 
% % Scaling and rotation matrix for each set of parameters
% scaling_rotation_matrix = zeros(3, 3, num_transformations);
% for i = 1:num_transformations
%     scaling_rotation_matrix(:, :, i) = [scale_x(i)*cosd(angle(i)), -scale_x(i)*sind(angle(i)), 0; ...
%                                        scale_y(i)*sind(angle(i)), scale_y(i)*cosd(angle(i)), 0; ...
%                                        0, 0, 1];
% end
% 
% % Shearing matrix
% shearing_matrix = [1, shear_x, 0; shear_y, 1, 0; 0, 0, 1];
% 
% % Combine transformations into a single matrix for each set of parameters
% combined_matrix = bsxfun(@mtimes, translation_matrix, scaling_rotation_matrix);
% combined_matrix = bsxfun(@mtimes, combined_matrix, shearing_matrix);
% 
% % Reshape to cell array of matrices
% combined_matrix = mat2cell(combined_matrix, 3, 3, ones(1, num_transformations));
% 
% % Read the original image and the reference image
% original_image = Metrics{Animal}.(MetricNames{Metric});
% reference_image = Metrics{1}.(MetricNames{Metric});
% 
% % Apply the affine transformations to the original image
% transformed_images = cellfun(@(transform) imwarp(original_image, affine2d(transform), 'OutputView', imref2d(size(original_image))), combined_matrix, 'UniformOutput', false);
% 
% % Calculate the correlation between each transformed image and the reference image
% correlation_values = cellfun(@(transformed_image) corr2(transformed_image, reference_image), transformed_images);
% 
% % Find the index of the transformation with the highest correlation
% [max_correlation, max_index] = max(correlation_values);
% 
% % Display or save the transformed image with the highest correlation
% imshow(transformed_images{max_index});
% title(['Highest Correlation: ' num2str(max_correlation)]);

% Iterate through all combinations of parameters
for i = 1:numel(tx)
    % Create individual transformation matrices
    translation_matrix = [1, 0, tx(i); 0, 1, ty(i); 0, 0, 1];
    rotation_matrix = [cosd(angle(i)), -sind(angle(i)), 0; sind(angle(i)), cosd(angle(i)), 0; 0, 0, 1];
    scaling_matrix = [scale_x(i), 0, 0; 0, scale_y(i), 0; 0, 0, 1];
    shearing_matrix = [1, shear_x(i), 0; shear_y(i), 1, 0; 0, 0, 1];

    % Combine transformations into a single matrix
    combined_matrix = (translation_matrix * rotation_matrix * scaling_matrix * shearing_matrix)';

    for Animal = 1:size(Metrics, 2)-1
        NewCorr = 0;
        for Metric = 1:numel(MetricNames)-1
            OrigImage = Metrics{Animal}.(MetricNames{Metric});
            % Apply the combined transformation to the image

            TransImage = imwarp(OrigImage, affine2d(combined_matrix), 'OutputView', imref2d(size(OrigImage)));
            GroundImage = Metrics{1}.(MetricNames{Metric});
            NewCorr = NewCorr+corr2(TransImage, GroundImage);
        end
        if NewCorr > OldCorr
            TransMatrix = combined_matrix;
            OldCorr = NewCorr;
        end
    end
end



% % Iterate through all combinations of parameters
% for tx = TranslationRange
%     display(tx)
%     for ty = TranslationRange
%         for scale_x = ScaleRange
%             for scale_y = ScaleRange
%                 for angle = RotationRange
%                     for shear_x = ShearingRange
%                         for shear_y = ShearingRange
%                             % Create individual transformation matrices
%                             TranslationMatrix = [1, 0, tx; 0, 1, ty; 0, 0, 1];
%                             RotationMatrix = [cosd(angle), -sind(angle), 0; sind(angle), cosd(angle), 0; 0, 0, 1];
%                             ScalingMatrix = [scale_x, 0, 0; 0, scale_y, 0; 0, 0, 1];
%                             ShearingMatrix = [1, shear_x, 0; shear_y, 1, 0; 0, 0, 1];
% 
%                             % Combine transformations into a single matrix
%                             combined_matrix = (TranslationMatrix * RotationMatrix * ScalingMatrix * ShearingMatrix)';
%                             for Animal = 1:size(Metrics, 2)-1
%                                 NewCorr = 0;
%                                 for Metric = 1:numel(MetricNames)-1
%                                     OrigImage = Metrics{Animal}.(MetricNames{Metric});
%                                     % Apply the combined transformation to the image
% 
%                                     TransImage = imwarp(OrigImage, affine2d(combined_matrix), 'OutputView', imref2d(size(OrigImage)));
%                                     GroundImage = Metrics{1}.(MetricNames{Metric});
%                                     NewCorr = NewCorr+corr2(TransImage, GroundImage);
%                                 end
%                                 if NewCorr > OldCorr
%                                     TransMatrix = combined_matrix;
%                                     OldCorr = NewCorr;
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end

toc
end
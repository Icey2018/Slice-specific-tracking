function [dsp_slice,pixelvalue_ori,pixelvalue_reg] = motion_specific_slice(dcm,matrix,Line_img,img_space,index,slice_number,option)
% dcm: all the images
% matrix: rot matrix of dcm
% index: index of EEP
% option
% dsp_slice:[img_index,slice,[x,y,z]] ,  displacement each slice
% pixelvalue_ori: the value of pixels in the images before registration
if option.load == 0
    figure;imshow(dcm(:,:,index),[]);
    disp('Please draw rectangle for cropping around heart... ')
    h = drawrectangle;
    pos_BASE = round(h.Position);
    save(('sample_data\pos_COR.mat'),'pos_BASE');
else
    load('sample_data\pos_COR.mat');
end
% drawrectangle(gca,'Position',[pos_BASE(1) pos_BASE(2) pos_BASE(3) pos_BASE(4)],'FaceAlpha',0);
img = dcm(pos_BASE(2):pos_BASE(2)+pos_BASE(4),pos_BASE(1):pos_BASE(1)+pos_BASE(3),:);


[field,img_deformed] = register_demons(img,index(1));
if option.show == 1
    as(img_deformed)
end
%% overlay lines to the image of End_expiratory, get pixel value and displacement
if option.load == 0
    figure;imshow(img(:,:,index),[]);
    disp('Please draw an epi-contour...');
    hf =  drawpolygon(gca);
    epi_mask = createMask(hf);
    save(strcat(num2str(v),'\','epi_mask.mat'),'epi_mask');
else
    load('sample_data\epi_mask.mat');
end

Line_img = Line_img(pos_BASE(2):pos_BASE(2)+pos_BASE(4),pos_BASE(1):pos_BASE(1)+pos_BASE(3));
%  position of point on the line which is in the ROI
Line_ROI = Line_img.*epi_mask;
se = strel('line',5,135);

if option.dilate == 1
    Line_ROI = imdilate(Line_ROI,se);
%     figure;imshow(Line_ROI); title('imdilated lines')
end

if option.show == 1
    figure;imshow(Line_ROI);title('Line_ROI lines');
end

if option.feature == 2
    if option.load == 0
        disp('draw endo-contour of the LV....')
        figure;imshow(img(:,:,index(1)),[]);
        hf1 =  drawpolygon(gca);
        endo_mask = createMask(hf1);
        save(('sample_data\endo_mask.mat'),'endo_mask');
    else
        load('sample_data\endo_mask.mat');
    end
end

for k = 1:slice_number
    [r,c]   = find(bwlabel(Line_ROI)==k);% each pixel on each line
    if option.feature == 1 %line
        Line{k} = [r,c]; % save pixel position of image row and column
    elseif option.feature == 2
        last_mask = epi_mask - endo_mask;
        [r_mask,c_mask]   = find(last_mask==1);
        % 如果点既在mask中又在线上
        features = intersect([r,c],[r_mask,c_mask],'stable','rows');
        Line{k} = [features(:,1),features(:,2)];
        figure;imshow(last_mask);hold on;scatter(features(:,2),features(:,1));hold off;
    end
    
    for img_index = 1:size(img_deformed,3)
        %% cal coefficient of x and y in image
        field_y            = field{1,img_index}{2};% displacement in vertical direction
        displacement_y       = field_y(sub2ind(size(field_y),Line{k}(:,1),Line{k}(:,2)));% greyvalue of pixel on line
        % (frame,line_index) -- mean displacement of point
        disp_mean_y        = mean(displacement_y);% get mean of all pixels each line
        % xyz 3D tracking
        field_x            = field{1,img_index}{1};% displacement in horizontal direction
        displacement_x     = field_x(sub2ind(size(field_x),Line{k}(:,1),Line{k}(:,2)));% greyvalue of pixel on line
        % (frame,line_index) -- mean displacement of point
        disp_mean_x        = mean(displacement_x);% get mean of all pixels each line
        %% change coordinate system
        vector_Img      = [disp_mean_x,disp_mean_y,0]';
        vector_Physical = matrix * vector_Img;
        disp_physical(img_index,k,:)   = vector_Physical; % img,line,[x,y,z]
        %% grayvalue of line in original image
        img_ori                   = img(:,:,img_index);
        value_ori{k}(:,img_index) = img_ori(sub2ind(size(img_ori),Line{k}(:,1),Line{k}(:,2)));
        % grayvalue of line in registered image
        img_reg                   = img_deformed(:,:,img_index);
        value_reg{k}(:,img_index) = img_reg(sub2ind(size(img_reg),Line{k}(:,1),Line{k}(:,2)));
    end
    
end
    dsp_slice = disp_physical.*img_space;
    pixelvalue_ori = value_ori;
    pixelvalue_reg = value_reg;
end
function [nav_mm,index_eep,index_eip,outlier_index]  = nav_process(nav,m_dFovRO)
    % nav:the nav_img(selected cols)
    % m_dFovRO: FovRO of the navigator signal acquisition
    
% denoising with wiener filter
K2=wiener2(nav,[3 3]);
% figure;subplot(1,2,1);imshow(nav,[]);subplot(1,2,2);imshow(K2,[]);
% contrast enhancement
dwi = K2;
dwi_minGray = min(min(dwi));
dwi_maxGray = max(max(dwi));
dwi_distance = dwi_maxGray-dwi_minGray;
dwi = (dwi-dwi_minGray)/dwi_distance;
nav_imadjust = imadjust(dwi);
nav_imadjust = nav_imadjust(2:end,:);

%% select kernel with the middle half part and find the positon in the whole img
img = nav_imadjust;
step = 1/4;
a = round(size(img,1)*step);
b = size(img,1) - a;
% calculate the threshold from imhist -- the pixel value when 1/3 counts
% of the total pixels is reached
[counts,binLocations] = imhist(nav_imadjust);
sum_cout = sum(counts);
sum_total = 0;
for kk = 1:size(counts,1)
    sum_total = sum_total+counts(kk);
    if sum_total>1/3*sum_cout
        num =  counts(kk);
        break
    end
end
separate = binLocations(kk); %threshold
nav_imadjust(nav_imadjust<separate)=0;

img = nav_imadjust;
for nn = 1:size(img,2)
    kernel = img(a:b,1);%kernel with the middle half part
    C = normxcorr2 (kernel, img(:,nn)) ;
    displace(1,nn) = find(C == max(C));% get similar position in each colume
end
%     change the reference to the 1st position to get the relative
%     displacements
delta_Z(1,:) = bsxfun(@minus,displace(1,:),displace(1,1));

%% Extract_outlier in navigator signal
% delete the outlier (>mean+2std|<mean-2std)
[clear_nav,outlier_index,~] = Extract_outlier(delta_Z);
index_eep   = find(clear_nav == max(clear_nav));% End_expiratory
index_eep   = index_eep(1);
index_eip   = find(clear_nav == min(clear_nav)); % End_inspiratory
index_eip   = index_eip(1);
End_deltaZ  = clear_nav - max(clear_nav); % change reference to End_expiratory
pixelspace = m_dFovRO/256; % m_dFovRO in Root.Seq.GLI.Navigator.1.FOVro/Matrix_RO in cardiac_navigator_feedback.cpp
nav_mm = End_deltaZ'*pixelspace; % negative value
end
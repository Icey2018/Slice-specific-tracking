function [coe_slice] = fit_heart_nav(nav_mm,dsp_slice)
% dsp_heart: frames * [x,y,z], the physical displacement of the whole heart
% dsp_slice:[img_index,slice,[x,y,z]] ,  displacement each slice
% coe_heart: [x,y,z] coes of each dimension in physical domain
% coe_slice:slice*[x,y,z] coes of each slice and each dimension in physical domain


f  = fittype('a*t','independent','t','coefficients',{'a'});
% calculate coes of each slice
for k = 1:size(dsp_slice,2) %slice
    for dim = 1:size(dsp_slice,3)
        nav_slice = nav_mm;
        dspslc = squeeze(dsp_slice(:,k,dim));
        [cleardspslc,outlier,~] = Extract_outlier(dspslc);
        nav_slice(outlier) = [];
        
        cfun   = fit(nav_slice,cleardspslc,f);
        coe_slice(k,dim) = cfun.a;
        error_linearslice(k,dim) = norm(nav_slice*cfun.a-cleardspslc);
    end
end
factor(1:size(coe_slice,1),:) = coe_slice;
save(('sample_data\coe_slice.mat'),'coe_slice');
save(('sample_data\nav_mm.mat'),'nav_mm');
save(('sample_data\dsp_slice.mat'),'dsp_slice');
save(('result\coe.txt'),'factor','-ascii');
end


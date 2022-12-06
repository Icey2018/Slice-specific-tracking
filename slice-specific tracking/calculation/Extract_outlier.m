function [clean_nav,outlier_index,outlier_value] = Extract_outlier(nav_mm)
    mean_value = mean(nav_mm);
    Std_value = std(nav_mm);
    upper_range = mean_value+Std_value*2;
    down_range = mean_value-Std_value*2;
    up_index = find(nav_mm>upper_range);
    down_index = find(nav_mm<down_range);
    outlier_index = [up_index;down_index];
    outlier_value = nav_mm(outlier_index);
    nav_mm(outlier_index)=[];
    clean_nav = nav_mm;
end
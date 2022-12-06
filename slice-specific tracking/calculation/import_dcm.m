function [img] = import_dcm(rootdir)
% import the image and get information including pixelspaceing, frame
% num, overlay of the slice lines
filelist = dir(rootdir);
cnt      = 1;
for n = 1:length(filelist)
    if ~filelist(n).isdir
        fid = fopen(fullfile(rootdir, filelist(n).name));
        fseek(fid, 128, 'bof');
        filetype = fread(fid, 4, 'char');
        fclose(fid);
        if strcmp(native2unicode(filetype', 'UTF-8'), 'DICM')
            img_dicom(:,:,cnt) = dicomread(fullfile(rootdir, filelist(n).name));
            cnt = cnt + 1;
        end
    end
end

    dcm = double(img_dicom(:,:,2:end)); % the 1st is deleted for wrong phase
    imfo      = dicominfo(fullfile(rootdir, filelist(3).name));
    imOrien   = imfo.ImageOrientationPatient;
    matrix    = [imOrien(1:3),imOrien(4:6),[0 0 0]'];
    Line_img  = double(imfo.OverlayData_0);
    img_space = imfo.PixelSpacing(1);
    img{1}.dcm = dcm;
    img{1}.rotmat = matrix;
    img{1}.Line = Line_img;
    img{1}.pixelspace = img_space;
end

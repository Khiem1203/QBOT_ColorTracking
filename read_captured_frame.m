function [frame, count, nbytes] = read_captured_frame(file)
% READ_CAPTURED_FRAME  Latest complete frame written by QBot2e_Color_Picker.
% The file holds back-to-back packets of [count mod 256; 240*320*3 uint8 RGB].
% Returns frame = [] and count = -1 if no complete packet is available yet.

REC = 1 + 240 * 320 * 3;
frame = [];
count = -1;
nbytes = 0;

fid = fopen(file, 'r');
if fid < 0
    return;
end
closer = onCleanup(@() fclose(fid));

fseek(fid, 0, 'eof');
nbytes = ftell(fid);
nrec = floor(nbytes / REC);
if nrec == 0
    return;
end
fseek(fid, (nrec - 1) * REC, 'bof');
rec = fread(fid, REC, '*uint8');
if numel(rec) < REC
    return;
end
count = double(rec(1));
frame = reshape(rec(2:end), 240, 320, 3);
end

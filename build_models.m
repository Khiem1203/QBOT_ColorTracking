function build_models()
% Generates the four QBot 2e models of this folder from the original lab models.
% Run once in MATLAB R2019b (the version the lab models were saved with).

here = fileparts(mfilename('fullpath'));
labs = fileparts(here);
teleopSrc = fullfile(labs, '1-Introduction', 'Software', 'QBot2e_Keyboard_Teleop_Normal.mdl');
lfSrc     = fullfile(labs, '4-Computer Vision', 'Software', 'QBot2e_Image_Proc_Line_Following.mdl');

names = {'QBot2e_Manual_Control', 'QBot2e_Color_Picker', ...
         'QBot2e_Color_Line_Tracking', 'QBot2e_Manual_Track_Switch'};
for i = 1:numel(names)
    if bdIsLoaded(names{i}), close_system(names{i}, 0); end
end

% QUARC objects (Host-1, Video3D-1) must be unique among open models,
% so each model is closed before the next one is opened.
close_system(copyModel(teleopSrc, here, 'QBot2e_Manual_Control'), 0);
buildColorPicker(teleopSrc, here);
close_system(copyModel(lfSrc, here, 'QBot2e_Color_Line_Tracking'), 0);
buildManualTrackSwitch(lfSrc, here);

fprintf('\nDone. Models written to:\n  %s\n', here);
end

% -------------------------------------------------------------------------
function m = copyModel(src, outDir, newName)
[~, srcName] = fileparts(src);
if bdIsLoaded(srcName), close_system(srcName, 0); end
load_system(src);
out = fullfile(outDir, [newName '.mdl']);
if exist(out, 'file'), delete(out); end
save_system(srcName, out);
m = newName;
fprintf('Created %s\n', out);
end

% -------------------------------------------------------------------------
function buildColorPicker(teleopSrc, outDir)
m = copyModel(teleopSrc, outDir, 'QBot2e_Color_Picker');

% Arrow keys + C (virtual key 67) -> 5th keyboard output.
set_param([m '/Host Keyboard'], 'virtual_key', '[38 40 37 39 67]');
set_param([m '/Data Type Conversion'], 'OutDataTypeStr', 'double');
set_param([m '/Demux'], 'Outputs', '5');

fcn = [m '/capture_frame'];
addMatlabFunction(fcn, [1050 520 1180 600], captureFrameCode());

add_line(m, 'Video3D Capture/1', 'capture_frame/1', 'autorouting', 'on');
% Keyboard runs at the base step, the camera slower: bring the C key to the camera rate.
add_block('simulink/Signal Attributes/Rate Transition', [m '/C key to camera rate'], ...
    'OutPortSampleTime', get_param([m '/Video3D Capture'], 'sample_time'), ...
    'Position', [960 560 1000 600]);
add_line(m, 'Demux/5', 'C key to camera rate/1', 'autorouting', 'on');
add_line(m, 'C key to camera rate/1', 'capture_frame/2', 'autorouting', 'on');

dispSrc = [m '/Video Compressed' newline 'Display (RGB)1'];
dispDst = [m '/Video Compressed' newline 'Display (Captured Frame)'];
add_block(dispSrc, dispDst, 'Position', [1260 500 1360 580]);
add_line(m, 'capture_frame/1', ['Video Compressed' newline 'Display (Captured Frame)/1'], 'autorouting', 'on');

add_block('simulink/Sinks/To Workspace', [m '/To Workspace captured_frame'], ...
    'VariableName', 'captured_frame', 'MaxDataPoints', '1', 'Decimation', '15', ...
    'SaveFormat', 'Structure', 'Position', [1260 610 1380 640]);
add_line(m, 'capture_frame/1', 'To Workspace captured_frame/1', 'autorouting', 'on');

add_block('simulink/Sinks/Display', [m '/Frame captured (1 = yes)'], ...
    'Position', [1260 660 1325 680]);
add_line(m, 'capture_frame/2', 'Frame captured (1 = yes)/1', 'autorouting', 'on');

addNote(m, [1050 470], ...
    'Press C to freeze a frame. Stop the model, then run pick_color in MATLAB.');
save_system(m);
close_system(m, 0);
end

% -------------------------------------------------------------------------
function buildManualTrackSwitch(lfSrc, outDir)
m = copyModel(lfSrc, outDir, 'QBot2e_Manual_Track_Switch');
traj = 'Trajectory control (Way-points from Kinect Camera Image)';

% Keyboard blocks, configured like the Lab 1 teleop model.
load_system('quarc_library');
add_block('quarc_library/Devices/Peripherals/Host/Host Initialize', [m '/Host Initialize'], ...
    'Position', [-520 380 -380 478], 'object_name', 'Host-1', ...
    'uri_source', 'Use external mode communications', 'run_client', 'on', 'use_window', 'off');
add_block('quarc_library/Devices/Peripherals/Host/Host Keyboard', [m '/Host Keyboard'], ...
    'Position', [-520 520 -390 689], 'object_name', 'Host-1', ...
    'virtual_key', '[38 40 37 39 80]');

add_block('simulink/Sinks/Terminator', [m '/Host Term1'], 'Position', [-350 390 -340 400]);
add_block('simulink/Sinks/Terminator', [m '/Host Term2'], 'Position', [-350 450 -340 460]);
add_block('simulink/Sinks/Terminator', [m '/Key Term'], 'Position', [-350 535 -340 545]);
add_line(m, 'Host Initialize/1', 'Host Term1/1');
add_line(m, 'Host Initialize/2', 'Host Term2/1');
add_line(m, 'Host Keyboard/1', 'Key Term/1');

add_block('simulink/Signal Attributes/Data Type Conversion', [m '/Keys to double'], ...
    'OutDataTypeStr', 'double', 'Position', [-330 620 -290 640]);
add_line(m, 'Host Keyboard/2', 'Keys to double/1');

fcn = [m '/mode_select'];
addMatlabFunction(fcn, [300 900 430 990], modeSelectCode());
add_line(m, 'Keys to double/1', 'mode_select/1', 'autorouting', 'on');

% Re-route the tracking controller through mode_select.
delete_line(m, [traj '/1'], 'Product1/1');
delete_line(m, [traj '/2'], 'Product2/1');
add_line(m, [traj '/1'], 'mode_select/2', 'autorouting', 'on');
add_line(m, [traj '/2'], 'mode_select/3', 'autorouting', 'on');
add_line(m, 'mode_select/1', 'Product1/1', 'autorouting', 'on');
add_line(m, 'mode_select/2', 'Product2/1', 'autorouting', 'on');

add_block('simulink/Sinks/Display', [m '/Mode (0 manual, 1 track)'], ...
    'Position', [480 965 545 985]);
add_line(m, 'mode_select/3', 'Mode (0 manual, 1 track)/1', 'autorouting', 'on');

% Motors enabled by default; the Manual Switch is still the e-stop.
set_param([m '/Manual Switch'], 'sw', '1');

addNote(m, [300 860], ...
    'Arrow keys = manual drive. P = toggle color tracking on/off. Manual Switch = motor enable.');
save_system(m);
close_system(m, 0);
end

% -------------------------------------------------------------------------
function addMatlabFunction(blk, pos, code)
add_block('simulink/User-Defined Functions/MATLAB Function', blk, 'Position', pos);
chart = sfroot().find('-isa', 'Stateflow.EMChart', 'Path', blk);
chart.Script = code;
end

function addNote(m, xy, txt)
a = Simulink.Annotation([m '/note']);
a.Text = txt;
a.Position = [xy xy + [400 20]];
end

function code = captureFrameCode()
code = strjoin({
'function [frame, captured] = capture_frame(rgb, c_key)'
'%#codegen'
'% Holds a half-resolution copy of the camera frame taken on the C key press.'
'persistent held prev has'
'if isempty(held)'
'    held = zeros(240, 320, 3, ''uint8'');'
'    prev = 0;'
'    has = 0;'
'end'
'if c_key > 0.5 && prev < 0.5'
'    held = rgb(1:2:end, 1:2:end, :);'
'    has = 1;'
'end'
'prev = c_key;'
'frame = held;'
'captured = has;'
}, newline);
end

function code = modeSelectCode()
code = strjoin({
'function [vC, Omega, mode] = mode_select(keys, Vf_trk, W_trk)'
'%#codegen'
'% keys = [up down left right P]. P rising edge toggles manual (0) / tracking (1).'
'persistent m prevP'
'if isempty(m)'
'    m = 0;'
'    prevP = 0;'
'end'
'p = keys(5);'
'if p > 0.5 && prevP < 0.5'
'    m = 1 - m;'
'end'
'prevP = p;'
'if m == 0'
'    vC = 0.15 * (keys(1) - keys(2));'
'    Omega = 0.6 * (keys(3) - keys(4));'
'else'
'    vC = Vf_trk;'
'    Omega = W_trk;'
'end'
'mode = m;'
}, newline);
end

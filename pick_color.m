function th = pick_color(varargin)
% PICK_COLOR  Live color picker for the QBot 2e line tracker.
%
%   pick_color              open the picker window; it waits for C presses
%                           from the running QBot2e_Color_Picker model
%   pick_color('Tol', 40)   start with a wider minimum tolerance (default 30)
%
% Each C press on the robot pops the frozen frame up in the window. Click the
% line (click several spots, bright and shaded, to cover the whole color),
% check the mask preview, press "Save color": the RGB ranges are written
% into QBot2e_Color_Line_Tracking.mdl and QBot2e_Manual_Track_Switch.mdl.
%
% Headless (testing): th = pick_color('Frame', img, 'Point', [x1 y1; x2 y2], 'Save', true)

p = inputParser;
p.addParameter('Tol', 30);
p.addParameter('Frame', []);
p.addParameter('Point', []);
p.addParameter('Save', false);
p.parse(varargin{:});
opt = p.Results;

here = fileparts(mfilename('fullpath'));
th = [];

if ~isempty(opt.Frame)
    th = thresholdsAt(uint8(opt.Frame), opt.Point, opt.Tol);
    th.mask_fraction = mean(mean(applyThreshold(uint8(opt.Frame), th)));
    if opt.Save
        saveThresholds(here, th);
    end
    return;
end

capFile = fullfile(here, 'captured_frames.bin');
delete(findall(0, 'Type', 'figure', 'Tag', 'QBotColorPicker'));

S = struct('frame', [], 'count', -1, 'bytes', 0, 'points', zeros(0, 2), 'th', []);

fig = figure('Tag', 'QBotColorPicker', 'Name', 'QBot 2e Color Picker', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Position', [100 100 1000 580], 'CloseRequestFcn', @onClose);
axImg = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.03 0.24 0.46 0.68]);
axMask = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.51 0.24 0.46 0.68]);

hImg = image(axImg, zeros(240, 320, 3, 'uint8'), 'ButtonDownFcn', @onClick);
axis(axImg, 'image', 'off');
title(axImg, 'Captured frame: click on the line (several spots OK)');
hold(axImg, 'on');
hMark = plot(axImg, NaN, NaN, 'c+', 'MarkerSize', 20, 'LineWidth', 2, 'HitTest', 'off');

hMask = image(axMask, zeros(240, 320, 3, 'uint8'));
axis(axMask, 'image', 'off');
title(axMask, 'Mask preview (white = will be followed)');

hStatus = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.03 0.02 0.47 0.17], 'HorizontalAlignment', 'left', 'FontSize', 10, ...
    'String', sprintf(['Waiting for a frame...\n' ...
    'Run QBot2e_Color_Picker (Build, Connect, Start) and press C.']));
hTolText = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.60 0.12 0.18 0.05], 'FontSize', 10, ...
    'String', sprintf('Tolerance: %d', round(opt.Tol)));
hTol = uicontrol(fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.60 0.07 0.18 0.05], 'Min', 10, 'Max', 80, 'Value', opt.Tol, ...
    'SliderStep', [1 5] / 70, 'Callback', @onTol);
hClear = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.51 0.07 0.08 0.06], 'String', 'Clear points', 'Enable', 'off', ...
    'Callback', @onClear);
hSave = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.81 0.06 0.16 0.10], 'FontSize', 12, 'FontWeight', 'bold', ...
    'String', 'Save color', 'Enable', 'off', 'Callback', @onSave);

tmr = timer('Period', 0.3, 'ExecutionMode', 'fixedSpacing', 'BusyMode', 'drop', ...
    'TimerFcn', @(~, ~) poll());
poll();
start(tmr);

    function poll()
        if ~isvalid(fig)
            return;
        end
        try
            [f, c, nb] = read_captured_frame(capFile);
        catch
            return;
        end
        if nb < S.bytes
            S.count = -1;   % model restarted, file was overwritten
        end
        S.bytes = nb;
        if isempty(f) || c == S.count
            return;
        end
        S.count = c;
        S.frame = f;
        set(hImg, 'CData', f);
        clearPoints();
        setStatus(sprintf(['Frame #%d received. Click on the line color.\n' ...
            'Click several spots (bright and shaded parts) to cover the whole color.'], c));
        figure(fig);
    end

    function onClick(~, ~)
        if isempty(S.frame)
            return;
        end
        cp = get(axImg, 'CurrentPoint');
        S.points(end + 1, :) = cp(1, 1:2);
        refresh();
    end

    function onClear(~, ~)
        clearPoints();
        setStatus('Points cleared. Click on the line color.');
    end

    function clearPoints()
        S.points = zeros(0, 2);
        S.th = [];
        set(hMark, 'XData', NaN, 'YData', NaN);
        set(hMask, 'CData', zeros(240, 320, 3, 'uint8'));
        title(axMask, 'Mask preview (white = will be followed)');
        set(hSave, 'Enable', 'off');
        set(hClear, 'Enable', 'off');
    end

    function onTol(~, ~)
        set(hTolText, 'String', sprintf('Tolerance: %d', round(get(hTol, 'Value'))));
        refresh();
    end

    function refresh()
        if isempty(S.frame) || isempty(S.points)
            return;
        end
        S.th = thresholdsAt(S.frame, S.points, get(hTol, 'Value'));
        mask = applyThreshold(S.frame, S.th);
        set(hMark, 'XData', S.points(:, 1), 'YData', S.points(:, 2));
        set(hMask, 'CData', repmat(uint8(mask) * 255, [1 1 3]));
        title(axMask, sprintf('Mask preview: %.1f%% of the image matches', 100 * mean(mask(:))));
        setStatus(sprintf(['%d point(s), last RGB = [%d %d %d]\n' ...
            'Range   R [%d %d]   G [%d %d]   B [%d %d]\n' ...
            'Not all of the line white? Click more spots on it.\n' ...
            'Background white? Clear points or lower Tolerance.'], ...
            size(S.points, 1), S.th.last_rgb, S.th.red, S.th.green, S.th.blue));
        set(hSave, 'Enable', 'on');
        set(hClear, 'Enable', 'on');
    end

    function onSave(~, ~)
        try
            msg = saveThresholds(here, S.th);
            setStatus(sprintf(['Saved RGB [%d %d %d] -> R %s  G %s  B %s\n%s\n' ...
                'Rebuild the tracking model so the robot uses the new color.'], ...
                S.th.rgb, mat2str(S.th.red), mat2str(S.th.green), mat2str(S.th.blue), msg));
        catch e
            setStatus(['Save failed: ' e.message]);
        end
    end

    function setStatus(txt)
        set(hStatus, 'String', txt);
        drawnow;
    end

    function onClose(~, ~)
        if isvalid(tmr)
            stop(tmr);
            delete(tmr);
        end
        delete(fig);
    end
end

% -------------------------------------------------------------------------
function th = thresholdsAt(img, pts, tol)
% Union of the ranges around every clicked point (7x7 patch each).
[h, w, ~] = size(img);
lo = [255 255 255];
hi = [0 0 0];
mus = zeros(size(pts, 1), 3);
for k = 1:size(pts, 1)
    x = min(max(round(pts(k, 1)), 1), w);
    y = min(max(round(pts(k, 2)), 1), h);
    patch = double(img(max(y-3, 1):min(y+3, h), max(x-3, 1):min(x+3, w), :));
    patch = reshape(patch, [], 3);
    mus(k, :) = mean(patch, 1);
    halfWidth = max(tol, 2.5 * std(patch, 0, 1));
    lo = min(lo, mus(k, :) - halfWidth);
    hi = max(hi, mus(k, :) + halfWidth);
end
% Vivid colors sit at the ends of the scale (camera saturates, other channels
% near zero), so ranges that come close to an end are opened up to it.
lo(lo < 25) = 0;
hi(hi > 230) = 255;
lo = max(round(lo), 0);
hi = min(round(hi), 255);
th.rgb = round(mean(mus, 1));
th.last_rgb = round(mus(end, :));
th.red = [lo(1) hi(1)];
th.green = [lo(2) hi(2)];
th.blue = [lo(3) hi(3)];
end

function mask = applyThreshold(img, th)
r = img(:, :, 1); g = img(:, :, 2); b = img(:, :, 3);
mask = r >= th.red(1) & r <= th.red(2) & ...
       g >= th.green(1) & g <= th.green(2) & ...
       b >= th.blue(1) & b <= th.blue(2);
end

function msg = saveThresholds(here, th)
th.timestamp = datestr(now);
save(fullfile(here, 'color_config.mat'), '-struct', 'th');
models = {'QBot2e_Color_Line_Tracking', 'QBot2e_Manual_Track_Switch'};
msg = '';
for i = 1:numel(models)
    m = models{i};
    wasLoaded = bdIsLoaded(m);
    if ~wasLoaded
        load_system(fullfile(here, [m '.mdl']));
    end
    set_param([m '/red_th'], 'Value', mat2str(th.red));
    set_param([m '/green_th'], 'Value', mat2str(th.green));
    set_param([m '/blue_th'], 'Value', mat2str(th.blue));
    save_system(m);
    if ~wasLoaded
        close_system(m, 0);
    end
    msg = [msg 'Updated ' m '.mdl. ']; %#ok<AGROW>
    fprintf('Updated %s.mdl: R %s G %s B %s\n', m, mat2str(th.red), mat2str(th.green), mat2str(th.blue));
end
end

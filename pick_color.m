function th = pick_color(varargin)
% PICK_COLOR  Click the line color in the captured frame and write the RGB
% thresholds into the tracking models.
%
%   pick_color                 % uses captured_frame from the base workspace
%   pick_color('Tol', 40)      % wider minimum tolerance (default 30)
%
% Optional (for testing): 'Frame', img, 'Point', [x y], 'NoConfirm', true

p = inputParser;
p.addParameter('Tol', 30);
p.addParameter('Frame', []);
p.addParameter('Point', []);
p.addParameter('NoConfirm', false);
p.parse(varargin{:});
opt = p.Results;

here = fileparts(mfilename('fullpath'));
img = opt.Frame;
if isempty(img)
    img = loadCapturedFrame(here);
end
img = uint8(img);

while true
    xy = opt.Point;
    fig = figure('Name', 'Pick the line color', 'NumberTitle', 'off');
    imshow(img, 'InitialMagnification', 'fit');
    if isempty(xy)
        title('Click on the colored line');
        xy = ginput(1);
    end
    th = thresholdsAt(img, xy, opt.Tol);
    mask = applyThreshold(img, th);

    subplot(1, 2, 1); imshow(img); hold on;
    plot(xy(1), xy(2), 'c+', 'MarkerSize', 16, 'LineWidth', 2);
    title(sprintf('RGB = [%d %d %d]', th.rgb));
    subplot(1, 2, 2); imshow(mask);
    title(sprintf('R[%d %d] G[%d %d] B[%d %d]', th.red, th.green, th.blue));
    drawnow;

    if opt.NoConfirm
        answer = 'y';
    else
        answer = lower(strtrim(input('Save these thresholds? (y = save, r = re-click, n = cancel): ', 's')));
    end
    if isvalid(fig) && ~opt.NoConfirm, close(fig); end
    switch answer
        case 'y'
            break;
        case 'r'
            opt.Point = [];
        otherwise
            disp('Cancelled, nothing saved.');
            th = [];
            return;
    end
end

th.timestamp = datestr(now);
save(fullfile(here, 'color_config.mat'), '-struct', 'th');
writeToModels(here, th);
fprintf('Saved: red_th = %s, green_th = %s, blue_th = %s\n', ...
    mat2str(th.red), mat2str(th.green), mat2str(th.blue));
end

% -------------------------------------------------------------------------
function img = loadCapturedFrame(here)
data = [];
if evalin('base', 'exist(''captured_frame'', ''var'')')
    data = evalin('base', 'captured_frame');
elseif exist(fullfile(here, 'captured_frame.mat'), 'file')
    s = load(fullfile(here, 'captured_frame.mat'));
    data = s.captured_frame;
end
if isempty(data)
    error(['No captured_frame found. Run QBot2e_Color_Picker, press C, ' ...
           'stop the model, then run pick_color again.']);
end

if isstruct(data)
    v = data.signals.values;
elseif isa(data, 'timeseries')
    v = data.Data;
else
    v = data;
end
img = v(:, :, :, end);
if ~any(img(:))
    error('captured_frame is empty (black). Press C while the picker model runs.');
end
end

function th = thresholdsAt(img, xy, tol)
[h, w, ~] = size(img);
x = min(max(round(xy(1)), 1), w);
y = min(max(round(xy(2)), 1), h);
patch = double(img(max(y-3,1):min(y+3,h), max(x-3,1):min(x+3,w), :));
patch = reshape(patch, [], 3);
mu = mean(patch, 1);
halfWidth = max(tol, 2.5 * std(patch, 0, 1));
lo = max(round(mu - halfWidth), 0);
hi = min(round(mu + halfWidth), 255);
th.rgb = round(mu);
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

function writeToModels(here, th)
models = {'QBot2e_Color_Line_Tracking', 'QBot2e_Manual_Track_Switch'};
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
    fprintf('Updated %s.mdl\n', m);
end
end

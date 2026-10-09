function set_tracking_gains(Kv, Kw)
% SET_TRACKING_GAINS  Speed gains of the color tracker in both tracking models.
%   set_tracking_gains            Kv = 0.5, Kw = 1.2 (recommended)
%   set_tracking_gains(Kv, Kw)
% Forward speed = Kv * distance to the blob, turn rate = Kw * angle to the blob.
% The original Lab 4 values (Kv = 0.2, Kw = 0.4) are too slow to move the QBot.
% Rebuild the tracking model afterwards.

if nargin < 1, Kv = 0.5; end
if nargin < 2, Kw = 1.2; end

here = fileparts(mfilename('fullpath'));
models = {'QBot2e_Color_Line_Tracking', 'QBot2e_Manual_Track_Switch'};
for i = 1:numel(models)
    m = models{i};
    wasLoaded = bdIsLoaded(m);
    if ~wasLoaded
        load_system(fullfile(here, [m '.mdl']));
    end
    traj = [m '/Trajectory control (Way-points from Kinect Camera Image)'];
    pc = get_param(traj, 'PortConnectivity');
    inputs = pc(arrayfun(@(p) ~isempty(p.SrcBlock) && p.SrcBlock ~= -1, pc));
    srcOf = @(port) inputs(strcmp({inputs.Type}, num2str(port))).SrcBlock;
    set_param(srcOf(5), 'Value', num2str(Kv));
    set_param(srcOf(6), 'Value', num2str(Kw));
    save_system(m);
    if ~wasLoaded
        close_system(m, 0);
    end
    fprintf('%s: Kv = %g, Kw = %g\n', m, Kv, Kw);
end
end

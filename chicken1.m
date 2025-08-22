%% Chicken Scream - MATLAB GUI Version with Audio Input (Fixed and Improved)
% Author: Improved Version
% Description: Voice-controlled endless runner game where you scream to make the chicken jump

clear; clc; close all;

%% Audio Setup with Better Error Handling
global recObj audioBuffer isRecording;
audioBuffer = [];
isRecording = false;

try
    fs = 16000; % Higher sampling rate for better detection
    fprintf('Initializing audio... Please allow microphone access if prompted.\n');
    
    % Check available audio devices
    info = audiodevinfo;
    if info.input > 0
        fprintf('Found %d audio input device(s)\n', info.input);
        recObj = audiorecorder(fs, 16, 1); % Mono, 16-bit
        
        % Set up continuous recording with callback
        set(recObj, 'TimerPeriod', 0.05); % Check every 50ms
        set(recObj, 'TimerFcn', @audioCallback);
        
        fprintf('Audio initialized successfully!\n');
        fprintf('Starting continuous audio monitoring...\n');
        record(recObj); % Start continuous recording
        isRecording = true;
    else
        error('No audio input devices found');
    end
catch ME
    fprintf('Audio initialization failed: %s\n', ME.message);
    fprintf('Running in demo mode without audio input.\n');
    recObj = [];
end

%% Game State Variables (Global for function access)
global game_state;
game_state = struct();
game_state.chicken_x = 5;
game_state.chicken_y = 0;
game_state.vy = 0; % vertical velocity
game_state.gravity = -0.8;
game_state.jump_strength = 8;
game_state.obstacle_x = 25;
game_state.obstacle_speed = 0.4;
game_state.score = 0;
game_state.game_over = false;
game_state.ground_level = 0;

% Audio thresholds - adjusted for better sensitivity
audio_config = struct();
audio_config.walk_thresh = 0.01;
audio_config.jump_thresh = 0.05;  % Lower threshold for easier jumping
audio_config.max_vol_display = 0.3;
audio_config.current_volume = 0;

%% Figure Setup with Better Graphics
f = figure('Name', '🐔 Chicken Scream - MATLAB Edition', 'NumberTitle', 'off', ...
           'Position', [100, 100, 1000, 600], 'Color', [0.8, 0.9, 1]);

% Create axes
ax = axes('Position', [0.05, 0.1, 0.9, 0.8]);
axis([0, 30, -1, 12]);
axis manual;
axis off;
hold on;

%% Create Game Objects
% Define theta for circular shapes (make it accessible globally)
global theta;
theta = linspace(0, 2*pi, 20);

% Sky gradient effect using patch for better color support
sky_x = [0, 30, 30, 0];
sky_y1 = [6, 6, 8, 8];
sky_y2 = [8, 8, 10, 10];
sky_y3 = [10, 10, 12, 12];

sky1 = patch(sky_x, sky_y1, [0.64, 0.85, 1], 'EdgeColor', 'none');
sky2 = patch(sky_x, sky_y2, [0.4, 0.7, 0.9], 'EdgeColor', 'none');
sky3 = patch(sky_x, sky_y3, [0.2, 0.5, 0.8], 'EdgeColor', 'none');

% Ground with texture
ground_x = [0, 30, 30, 0];
ground_y = [0, 0, 6, 6];
ground = patch(ground_x, ground_y, [0.4, 0.6, 0.2], 'EdgeColor', 'none');
grass_line = line([0, 30], [6, 6], 'Color', [0.2, 0.4, 0.1], 'LineWidth', 3);

% Clouds using ellipse approximation
cloud1_x = 1.5 * cos(theta) + 9.5;
cloud1_y = 0.75 * sin(theta) + 9.75;
cloud1 = patch(cloud1_x, cloud1_y, 'white', 'EdgeColor', 'none', 'FaceAlpha', 0.8);

cloud2_x = 1.25 * cos(theta) + 21.25;
cloud2_y = 0.5 * sin(theta) + 10.5;
cloud2 = patch(cloud2_x, cloud2_y, 'white', 'EdgeColor', 'none', 'FaceAlpha', 0.7);

% Chicken components - declare as global
global chicken_body chicken_wing chicken_eye chicken_pupil chicken_beak leg1 leg2;

% Chicken body (ellipse)
body_x = 0.5 * cos(theta) + game_state.chicken_x + 0.5;
body_y = 0.75 * sin(theta) + game_state.chicken_y + 0.75;
chicken_body = patch(body_x, body_y, 'yellow', 'EdgeColor', [1, 0.5, 0], 'LineWidth', 2);

% Chicken wing (smaller ellipse)
wing_x = 0.3 * cos(theta) + game_state.chicken_x + 0.4;
wing_y = 0.4 * sin(theta) + game_state.chicken_y + 0.7;
chicken_wing = patch(wing_x, wing_y, [1, 0.8, 0], 'EdgeColor', [1, 0.5, 0], 'LineWidth', 1);

% Chicken eye (circle)
eye_x = 0.125 * cos(theta) + game_state.chicken_x + 0.725;
eye_y = 0.125 * sin(theta) + game_state.chicken_y + 1.225;
chicken_eye = patch(eye_x, eye_y, 'white', 'EdgeColor', 'black');

% Chicken pupil (smaller circle)
pupil_x = 0.045 * cos(theta) + game_state.chicken_x + 0.725;
pupil_y = 0.045 * sin(theta) + game_state.chicken_y + 1.225;
chicken_pupil = patch(pupil_x, pupil_y, 'black', 'EdgeColor', 'black');

% Chicken beak
beak_x = [game_state.chicken_x + 0.9, game_state.chicken_x + 1.1, game_state.chicken_x + 0.9];
beak_y = [game_state.chicken_y + 1.0, game_state.chicken_y + 1.1, game_state.chicken_y + 1.2];
chicken_beak = patch(beak_x, beak_y, [1, 0.5, 0], 'EdgeColor', [0.8, 0.2, 0]);

% Chicken legs
leg1 = line([game_state.chicken_x + 0.3, game_state.chicken_x + 0.3], ...
           [game_state.chicken_y, game_state.chicken_y - 0.3], ...
           'Color', [1, 0.5, 0], 'LineWidth', 3);
leg2 = line([game_state.chicken_x + 0.7, game_state.chicken_x + 0.7], ...
           [game_state.chicken_y, game_state.chicken_y - 0.3], ...
           'Color', [1, 0.5, 0], 'LineWidth', 3);

% Obstacle using rectangle with valid colors
global obstacle;
obstacle = rectangle('Position', [game_state.obstacle_x, 0, 1, 3], ...
                    'FaceColor', 'red', 'EdgeColor', 'black', 'LineWidth', 2);

%% UI Elements
% Volume meter background
vol_bg = rectangle('Position', [26, 9, 0.8, 2.5], 'FaceColor', [0.3, 0.3, 0.3], ...
                  'EdgeColor', 'black', 'LineWidth', 1);

% Volume bar
global volume_bar;
volume_bar = rectangle('Position', [26.1, 9.1, 0.6, 0.1], 'FaceColor', 'green', 'EdgeColor', 'none');

% Volume threshold indicators
jump_line = line([26, 26.8], [9.1 + audio_config.jump_thresh * 10, 9.1 + audio_config.jump_thresh * 10], ...
                'Color', [1, 0, 0], 'LineWidth', 2, 'LineStyle', '--');

% Real-time volume display
vol_display = text(26.1, 8.5, '0.00', 'FontSize', 8, 'Color', 'black');

% UI Text
global score_text;
vol_text = text(26.9, 10.8, 'MIC', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0, 0, 0]);
score_text = text(1, 10.5, sprintf('Score: %d', game_state.score), ...
                 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0, 0, 1]);

% Instructions
if isempty(recObj)
    instr_text = text(1, 9.5, 'DEMO MODE - Press SPACE to jump', ...
                     'FontSize', 12, 'Color', [1, 0, 0], 'FontWeight', 'bold');
    demo_text = text(1, 9, 'Audio not available - keyboard controls active', ...
                    'FontSize', 10, 'Color', [0.5, 0.5, 0.5]);
else
    instr_text = text(1, 9.5, 'SCREAM to jump! Louder = higher!', ...
                     'FontSize', 12, 'Color', [0, 0.5, 0], 'FontWeight', 'bold');
    threshold_text = text(1, 9, sprintf('Jump threshold: %.3f (red line)', audio_config.jump_thresh), ...
                         'FontSize', 10, 'Color', [0.5, 0.5, 0.5]);
end

%% Game Loop Setup
fprintf('\nStarting Chicken Scream!\n');
if ~isempty(recObj)
    fprintf('Make noise to make the chicken jump!\n');
    fprintf('Jump threshold: %.3f\n', audio_config.jump_thresh);
    fprintf('Watch the volume meter on the right!\n');
else
    fprintf('Press SPACE to jump in demo mode!\n');
end
fprintf('Close the window to exit.\n\n');

% Set up keyboard callback for demo mode
global demo_jump;
demo_jump = false;
if isempty(recObj)
    set(f, 'KeyPressFcn', @keyPressCallback);
end

% Game timing
last_time = tic;

%% Main Game Loop
while ishandle(f) && ~game_state.game_over
    current_time = toc(last_time);
    
    % Get current volume from audio buffer
    vol = audio_config.current_volume;
    
    % Demo mode - check for spacebar
    if isempty(recObj) && demo_jump
        vol = audio_config.jump_thresh + 0.01;
        demo_jump = false;
    end
    
    % Jump logic with variable jump height
    if vol > audio_config.jump_thresh && game_state.chicken_y <= game_state.ground_level + 0.1
        jump_multiplier = min(vol / audio_config.jump_thresh, 2.5);
        game_state.vy = game_state.jump_strength * jump_multiplier;
        fprintf('JUMP! Volume: %.4f, Multiplier: %.2f\n', vol, jump_multiplier);
    end
    
    % Physics update
    game_state.chicken_y = game_state.chicken_y + game_state.vy * 0.1;
    
    if game_state.chicken_y > game_state.ground_level
        game_state.vy = game_state.vy + game_state.gravity * 0.1;
    else
        game_state.chicken_y = game_state.ground_level;
        game_state.vy = 0;
    end
    
    % Obstacle movement
    game_state.obstacle_x = game_state.obstacle_x - game_state.obstacle_speed;
    
    % Spawn new obstacle and increase score
    if game_state.obstacle_x < -2
        game_state.obstacle_x = 30 + rand() * 10;
        game_state.score = game_state.score + 1;
        
        % Increase difficulty
        if mod(game_state.score, 5) == 0
            game_state.obstacle_speed = game_state.obstacle_speed + 0.05;
        end
    end
    
    % Collision detection (improved)
    chicken_right = game_state.chicken_x + 1;
    chicken_left = game_state.chicken_x;
    chicken_top = game_state.chicken_y + 1.5;
    chicken_bottom = game_state.chicken_y;
    
    obstacle_right = game_state.obstacle_x + 1;
    obstacle_left = game_state.obstacle_x;
    obstacle_top = 3;
    obstacle_bottom = 0;
    
    if (chicken_right > obstacle_left && chicken_left < obstacle_right && ...
        chicken_bottom < obstacle_top && chicken_top > obstacle_bottom)
        game_state.game_over = true;
    end
    
    % Update visual elements
    updateChickenPosition();
    
    % Update obstacle
    set(obstacle, 'Position', [game_state.obstacle_x, 0, 1, 3]);
    
    % Update volume meter
    vol_height = min(vol / audio_config.max_vol_display * 2.3, 2.3);
    vol_color = [0, 1, 0]; % green
    if vol > audio_config.jump_thresh
        vol_color = [1, 0, 0]; % red
    elseif vol > audio_config.walk_thresh
        vol_color = [1, 1, 0]; % yellow
    end
    set(volume_bar, 'Position', [26.1, 9.1, 0.6, vol_height], 'FaceColor', vol_color);
    
    % Update volume display text
    set(vol_display, 'String', sprintf('%.3f', vol));
    
    % Update score
    set(score_text, 'String', sprintf('Score: %d', game_state.score));
    
    % Control frame rate
    pause(0.03);
end

%% Game Over
if game_state.game_over
    % Stop audio recording
    if ~isempty(recObj) && isRecording
        stop(recObj);
        isRecording = false;
    end
    
    % Game over visual effects
    set(ax, 'Color', [1, 0.8, 0.8]);
    
    game_over_text = text(15, 6, '💥 GAME OVER 💥', 'FontSize', 24, 'FontWeight', 'bold', ...
                         'Color', [1, 0, 0], 'HorizontalAlignment', 'center');
    
    final_score_text = text(15, 4, sprintf('Final Score: %d', game_state.score), ...
                           'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.5, 0, 0], ...
                           'HorizontalAlignment', 'center');
    
    restart_text = text(15, 2, 'Close window to exit', 'FontSize', 14, ...
                       'Color', [0, 0, 1], 'HorizontalAlignment', 'center');
    
    fprintf('Game Over! Final Score: %d\n', game_state.score);
end

% Cleanup
if ~isempty(recObj)
    try
        stop(recObj);
    catch
        % Audio object may already be stopped
    end
end

%% Helper Functions
function audioCallback(obj, ~)
    global audioBuffer audio_config;
    try
        % Get the latest audio data
        data = getaudiodata(obj, 'double');
        
        if length(data) > 1000
            % Take the most recent samples
            recent_data = data(end-1000:end);
            
            % Calculate RMS volume
            vol = sqrt(mean(recent_data.^2));
            
            % Apply noise reduction and smoothing
            vol = max(0, vol - 0.005); % Noise floor
            
            % Update current volume with smoothing
            if isfield(audio_config, 'current_volume')
                audio_config.current_volume = 0.7 * audio_config.current_volume + 0.3 * vol;
            else
                audio_config.current_volume = vol;
            end
        end
    catch
        % Handle audio errors gracefully
        audio_config.current_volume = 0;
    end
end

function updateChickenPosition()
    global game_state theta;
    global chicken_body chicken_wing chicken_eye chicken_pupil chicken_beak leg1 leg2;
    
    % Update chicken body
    body_x = 0.5 * cos(theta) + game_state.chicken_x + 0.5;
    body_y = 0.75 * sin(theta) + game_state.chicken_y + 0.75;
    set(chicken_body, 'XData', body_x, 'YData', body_y);
    
    % Update wing
    wing_x = 0.3 * cos(theta) + game_state.chicken_x + 0.4;
    wing_y = 0.4 * sin(theta) + game_state.chicken_y + 0.7;
    set(chicken_wing, 'XData', wing_x, 'YData', wing_y);
    
    % Update eye
    eye_x = 0.125 * cos(theta) + game_state.chicken_x + 0.725;
    eye_y = 0.125 * sin(theta) + game_state.chicken_y + 1.225;
    set(chicken_eye, 'XData', eye_x, 'YData', eye_y);
    
    % Update pupil
    pupil_x = 0.045 * cos(theta) + game_state.chicken_x + 0.725;
    pupil_y = 0.045 * sin(theta) + game_state.chicken_y + 1.225;
    set(chicken_pupil, 'XData', pupil_x, 'YData', pupil_y);
    
    % Update beak
    beak_x = [game_state.chicken_x + 0.9, game_state.chicken_x + 1.1, game_state.chicken_x + 0.9];
    beak_y = [game_state.chicken_y + 1.0, game_state.chicken_y + 1.1, game_state.chicken_y + 1.2];
    set(chicken_beak, 'XData', beak_x, 'YData', beak_y);
    
    % Update legs
    set(leg1, 'XData', [game_state.chicken_x + 0.3, game_state.chicken_x + 0.3], ...
             'YData', [game_state.chicken_y, game_state.chicken_y - 0.3]);
    set(leg2, 'XData', [game_state.chicken_x + 0.7, game_state.chicken_x + 0.7], ...
             'YData', [game_state.chicken_y, game_state.chicken_y - 0.3]);
end

function keyPressCallback(~, event)
    global demo_jump;
    if strcmp(event.Key, 'space')
        demo_jump = true;
        fprintf('Space pressed - jump!\n');
    end
end
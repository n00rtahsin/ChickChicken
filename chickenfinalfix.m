% Chicken Scream - FINAL FIX with Optimized Jump Height and Mic Device ID

clear; clc;

%% Parameters
fs = 8000; % Audio sampling rate
duration = 0.05; % audio slice duration (seconds)
buffer_samples = round(duration * fs);
recObj = audiorecorder(fs, 8, 1, 1); % Use your mic device ID here

% Game State
chicken_x = 5;
chicken_y = 0;
vy = 0;
gravity = -0.7;
jump_strength = 4.5; % Reduced for more controlled jump

obstacle_x = 25;
obstacle_speed = 0.3;
score = 0;

jump_thresh = 0.06;

%% GUI Setup
f = figure('Name','🐔 Chicken Scream - FINAL FIX','NumberTitle','off');
axis([0 30 0 12]); axis manual; axis off;

rectangle('Position',[0 6 30 6],'FaceColor',[0.64 0.85 1],'EdgeColor','none');
rectangle('Position',[0 0 30 6],'FaceColor',[0.55 0.77 0.29],'EdgeColor','none');

chicken_body = rectangle('Position',[chicken_x chicken_y 1 1.5],'Curvature',[1 1],'FaceColor','yellow','EdgeColor','black');
chicken_eye = rectangle('Position',[chicken_x+0.6 chicken_y+1.2 0.2 0.2],'Curvature',[1 1],'FaceColor','white','EdgeColor','black');
chicken_pupil = rectangle('Position',[chicken_x+0.65 chicken_y+1.25 0.1 0.1],'Curvature',[1 1],'FaceColor','black');

obstacle = rectangle('Position',[obstacle_x 0 1 2],'FaceColor','red');
volume_bar = rectangle('Position',[22 10.5 0.1 0.5],'FaceColor','green');
text(22,11,'Volume','FontSize',8);
score_text = text(1,11,['Score: ' num2str(score)],'FontSize',12,'FontWeight','bold');

startBtn = uicontrol('Style','pushbutton','String','Start','Position',[50 20 60 30],'Callback','setappdata(gcbf,''startGame'',true);');
pauseBtn = uicontrol('Style','pushbutton','String','Pause','Position',[120 20 60 30],'Callback','setappdata(gcbf,''pauseGame'',true);');

setappdata(f,'startGame',false);
setappdata(f,'pauseGame',false);

% Wait for Start
disp('Waiting for Start...');
while ~getappdata(f,'startGame') && ishandle(f)
    pause(0.1);
end

% Prime recorder
recordblocking(recObj, 0.1);
record(recObj);

%% Game Loop
while ishandle(f)
    if getappdata(f,'pauseGame')
        pause(0.1);
        continue;
    end

    if recObj.TotalSamples < buffer_samples
        pause(0.01);
        continue;
    end

    % Read latest buffer safely
    try
        data = getaudiodata(recObj);
        buffer = data(end-buffer_samples+1:end);
        vol = sqrt(mean(buffer.^2));
    catch
        vol = 0;
    end

    if vol > jump_thresh && chicken_y <= 0.1
        vy = jump_strength;
    end

    chicken_y = max(0, chicken_y + vy);
    if chicken_y > 0
        vy = vy + gravity;
    else
        vy = 0;
    end

    obstacle_x = obstacle_x - obstacle_speed;
    if obstacle_x < -1
        obstacle_x = 30 + rand()*5;
        score = score + 1;
    end

    if abs(chicken_x - obstacle_x) < 1 && chicken_y < 2
        title('💥 GAME OVER 💥','Color','r','FontSize',16);
        break;
    end

    set(chicken_body,'Position',[chicken_x chicken_y 1 1.5]);
    set(chicken_eye,'Position',[chicken_x+0.6 chicken_y+1.2 0.2 0.2]);
    set(chicken_pupil,'Position',[chicken_x+0.65 chicken_y+1.25 0.1 0.1]);
    set(obstacle,'Position',[obstacle_x 0 1 2]);
    set(volume_bar,'Position',[22 10.5 min(vol*50,3) 0.5]);
    set(score_text,'String',['Score: ' num2str(score)]);

    pause(0.05);
end

stop(recObj);

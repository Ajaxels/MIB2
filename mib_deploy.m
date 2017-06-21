function mib_deploy
% the following wrapper is needed for mib
global running
running = 1;
mib;
while running
    pause(0.05);
end
end
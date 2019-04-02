%To DO: Corials+PGrad, FUnction names need to be standard

clc
clear all
%Variables
numTimeSteps = 10000000; %Num of timesteps
timeStepDuration = 10; %In seconds
time = 1:numTimeSteps; %Array of time
travelDistance = 4078291;
tempUpper = 16.75;
tempLower = 4;
dTdX = (tempUpper - tempLower) / travelDistance;
tugForce = 3000000;


%Initialization of response data
appVeloWater = zeros(numTimeSteps, 2);
appVeloWaterMag = zeros(numTimeSteps, 1);

appVeloAir = zeros(numTimeSteps, 2);
appVeloAirMag = zeros(numTimeSteps, 1);

frictionDragWater = zeros(numTimeSteps, 2);
frictionDragWaterMag = zeros(numTimeSteps, 1);

formDragWater = zeros(numTimeSteps, 2);
formDragWaterMag = zeros(numTimeSteps, 1);

frictionDragAir = zeros(numTimeSteps, 2);
frictionDragAirMag = zeros(numTimeSteps, 1);

formDragAir = zeros(numTimeSteps, 2);
formDragAirMag = zeros(numTimeSteps, 1);

externalForces = zeros(numTimeSteps, 2);

distance = zeros(numTimeSteps, 1);

velocity = zeros(numTimeSteps, 1);
velocity(1) = 0;
acceleration = zeros(numTimeSteps, 1);

temperature = zeros(numTimeSteps, 1);
temperature(1) = tempLower;

mass = zeros(numTimeSteps, 1);
length = zeros(numTimeSteps, 1);
width = zeros(numTimeSteps, 1);
height = zeros(numTimeSteps, 1);

%INITIAL VALUES
length(1) = 175;
width(1) = 175;
height(1) = 175;
mass(1) = length(1) * width(1) * height(1) * 917;

heightBelowWater = zeros(numTimeSteps, 1);
heightAboveWater = zeros(numTimeSteps, 1);

forceTotalMag = zeros(numTimeSteps, 1);

tugAngle = zeros(numTimeSteps, 1);

%Perlin Noise for water and air velocities
waterSpeedX =  PerlinNoise(numTimeSteps, 2 / sqrt(2), 0.05, 10);
waterSpeedY = PerlinNoise(numTimeSteps, 2 / sqrt(2), 0.05, 10);
airSpeedX = PerlinNoise(numTimeSteps, 12 / sqrt(2), 0.1, 10);
airSpeedY = PerlinNoise(numTimeSteps, 12 / sqrt(2), 0.1, 10);

%Travel Simulation Loop
reachedDestination = 0; %Boolean to check if simulation is over
curTF = 1; %Current Time Frame
travelMelted = false;
bergNotMelted = true;
while reachedDestination == 0

    %Apparent Velocity Calculation
    appVeloWater(curTF,1:2) = [waterSpeedX(curTF), waterSpeedY(curTF) - velocity(curTF)];
    appVeloWaterMag(curTF) = VectMag(appVeloWater(curTF, 1:2));

    appVeloAir(curTF,1:2) = [airSpeedX(curTF), airSpeedY(curTF) - velocity(curTF)];
    appVeloAirMag(curTF) = VectMag(appVeloAir(curTF, 1:2));

    %Mass Loss
    [mass(curTF + 1), length(curTF + 1), width(curTF + 1), height(curTF + 1)] = MassLoss([mass(curTF), length(curTF), width(curTF), height(curTF)], appVeloWaterMag(curTF), VectMag([airSpeedX(curTF), airSpeedY(curTF)]), temperature(curTF), timeStepDuration);
    if mass(curTF + 1) <= 0
        disp("Ice Cube melted :(")
        burgNotMelted = 0;
        travelMelted = true;
        break;
    end
    %Water Height
    heightBelowWater(curTF) = mass(curTF) / (997.0 * width(curTF) * length(curTF));
    heightAboveWater(curTF) = height(curTF) - heightBelowWater(curTF);

    %External Forces__________________

    %Frictional Drag Water
    skinArea = (length(curTF) * width(curTF)) + (2 * (heightBelowWater(curTF) * length(curTF)));
    frictionDragWater(curTF,1:2) = FrictionForce(appVeloWaterMag(curTF), appVeloWater(curTF,1:2), skinArea, 997);
    frictionDragWaterMag(curTF) = VectMag(frictionDragWater(curTF, 1:2));

    %From Drag Water
    crossArea = width(curTF) * heightBelowWater(curTF);
    formDragWater(curTF,1:2) = FormForce(appVeloWaterMag(curTF), appVeloWater(curTF,1:2), crossArea, 997);
    formDragWaterMag(curTF) = VectMag(formDragWater(curTF, 1:2));

    %Frictional Drag Air
    skinArea = (length(curTF) * width(curTF)) + (2 * (heightAboveWater(curTF) * length(curTF)));
    frictionDragAir(curTF,1:2) = FrictionForce(appVeloAirMag(curTF), appVeloAir(curTF,1:2), skinArea, 1.28);
    frictionDragAirMag(curTF) = VectMag(frictionDragAir(curTF, 1:2));

    %From Drag Air
    crossArea = width(curTF) * heightAboveWater(curTF);
    formDragAir(curTF,1:2) = FormForce(appVeloAirMag(curTF), appVeloAir(curTF,1:2), crossArea, 1.28);
    formDragAirMag(curTF) = VectMag(formDragAir(curTF, 1:2));

    
    externalForces(curTF,1:2) = frictionDragWater(curTF,1:2) + formDragWater(curTF,1:2) + frictionDragAir(curTF,1:2) + formDragAir(curTF,1:2); %+ other forces
    if abs(externalForces(curTF, 1)) > tugForce
        externalForces(curTF, 1) = tugForce;
    end
    tugAngle = asin(-externalForces(curTF, 1) / tugForce);

    %Tug Boat Force Calulations________________

    forceTotalMag(curTF) = (tugForce * cos(tugAngle)) + externalForces(curTF, 2);

    %Distance
    acceleration(curTF) = forceTotalMag(curTF) / (mass(curTF + 1) + 3855535);
    dV = acceleration(curTF) * timeStepDuration;
    velocity(curTF + 1) = velocity(curTF) + dV;
    dX = velocity(curTF) * timeStepDuration;
    distance(curTF + 1) = distance(curTF) + dX;

    if distance(curTF + 1) >= travelDistance
        reachedDestination = 1;
    end

    disp(travelDistance - distance(curTF))
    %disp(length(curTF))
    
    %Temperature
    temperature(curTF + 1) = (distance(curTF) * dTdX) + 4;

    curTF = curTF + 1;  
end


sittingMelt = zeros(numTimeSteps, 1);
drinkingMelt = 210000000 * timeStepDuration / 86400; %kg per time step

travelTime = curTF;
drinkTime = 0;

while bergNotMelted
    
    %velocity(curTF) = 0;

    appVeloWater(curTF,1:2) = [waterSpeedX(curTF), waterSpeedY(curTF)];
    appVeloWaterMag(curTF) = VectMag(appVeloWater(curTF, 1:2));

    %sitting melt
    [mass(curTF + 1), length(curTF + 1), width(curTF + 1), height(curTF + 1)] = MassLoss([mass(curTF), length(curTF), width(curTF), height(curTF)], appVeloWaterMag(curTF), VectMag([airSpeedX(curTF), airSpeedY(curTF)]), temperature(curTF), timeStepDuration);
    sittingMelt(curTF - travelTime + 1) = mass(curTF) - mass(curTF + 1);
    %Drinking
    mass(curTF + 1) = mass(curTF + 1) - drinkingMelt;

    if(mass(curTF + 1) <= 0)
        bergNotMelted = false;
        drinkTime = curTF - travelTime;
    end
    
    curTF = curTF + 1; 
    disp(mass(curTF))
end

%Outputs
fprintf('\nTravel Statistics for Iceberg: \nLength: %.2f, Width: %.2f, and Height: %.2f', length(1), width(1), height(1))
fprintf('\n========================================================================')
if travelMelted == true
    fprintf('\n\nThe iceberg melted on route to Cape Town. It melted with %.2f meters to go.', travelDistance - distance(curTF))
else
    fprintf('\n\nThe iceberg made it to Cape Town. The trip took %.2f days and the iceberg lost %.2f%% of its mass on the way.', travelTime * timeStepDuration / 60 / 60 / 24, 100 * mass(travelTime) / mass(1))
    fprintf('\nAt Cape Town, the iceberg lasted for %.2f days, supplying %.2f liters per person.', drinkTime * timeStepDuration / 86400, drinkingMelt * drinkTime / 4000000)
end

fprintf('\n\nPress Enter to display figures.')
pause;

%postition
figure(1)
hold on
plot(time(1:travelTime) .* timeStepDuration / 86400, distance(1:travelTime))
title('Distance Travelled vs. Time')
xlabel('Time (days)')
ylabel('Distance Travelled (m)')
grid()
hold off

%velocity
figure(2)
hold on
plot(time(1:travelTime) .* timeStepDuration / 86400 , velocity(1:travelTime))
title('Iceberg Velocity vs Time')
xlabel('Time (days)')
ylabel('Velocity (m/s)')
grid()
hold off

%Mass
figure(3)
hold on
plot(time(1:curTF) .* timeStepDuration / 86400, mass(1:curTF))
title('Iceberg Mass vs. Time')
xlabel('Time (days)')
ylabel('Mass (kg)')
grid()
hold off

%Drag forces
figure(4)
hold on
plot(time(20:travelTime) .* timeStepDuration / 86400, externalForces(20:travelTime,1))
plot(time(20:travelTime) .* timeStepDuration / 86400, externalForces(20:travelTime,2))
title('Drag Forces on Iceberg vs. Time')
xlabel('Time (days)')
ylabel('Drag Forces (newtons)')
legend('Force on X axis (Latitudinal)', 'Force on Y axis (Longitudinal)')
grid()
hold off
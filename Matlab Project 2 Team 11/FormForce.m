function [formForce] = FormForce(appVeloMag, appVelo, crossArea, density)
    waterDensity = 997; %kg/m^3
    Cd = 0.6;

    formForce = (0.5 * density * crossArea * Cd * appVeloMag) .* appVelo;
end
% =========================================================================
% DEMULTIPLEXOR ESTÉREO FM - DISEÑO DE FILTRO ANALÓGICO (PASAALTOS RBDS)
% =========================================================================
clear; clc; close all;

%% 1. ESPECIFICACIONES DEL FILTRO
fp = 55e3; % Frecuencia en banda de paso (55 kHz)[cite: 1]
fs = 45e3; % Frecuencia en banda de rechazo (45 kHz)[cite: 1]
Rp = 3;    % Atenuación máxima en banda de paso (dB)[cite: 1]
Rs = 15;   % Atenuación mínima en banda de rechazo (dB)[cite: 1]

% Conversión a frecuencias angulares (rad/s)
Wp = 2 * pi * fp;
Ws = 2 * pi * fs;

%% 2. CALCULAR EL ORDEN Y LA FRECUENCIA DE CORTE
[n, Wc] = buttord(Wp, Ws, Rp, Rs, 's');
fc = Wc / (2 * pi); % Frecuencia de corte en Hz

fprintf('=========================================================\n');
fprintf('1. RESULTADOS DE ORDEN Y FRECUENCIA DE CORTE\n');
fprintf('=========================================================\n');
fprintf('Orden del filtro (N): %d\n', n);
fprintf('Frecuencia de corte Wc: %.6e rad/s (%.2f Hz)\n\n', Wc, fc);

%% 3. CALCULAR EL DISEÑO DEL FILTRO
[z, p, k] = butter(n, Wc, 'high', 's'); % Ceros, Polos y Ganancia
[b, a] = butter(n, Wc, 'high', 's');    % Coeficientes Polinomiales

%% 4. MOSTRAR LA FUNCIÓN DE TRANSFERENCIA TOTAL EN CONSOLA
H_total = tf(b, a);

fprintf('=========================================================\n');
fprintf('2. FUNCIÓN DE TRANSFERENCIA TOTAL H(s)\n');
fprintf('=========================================================\n');
H_total

%% 5. MOSTRAR EL DIAGRAMA DE BODE DEL FILTRO
figure('Name', 'Diagrama de Bode - Filtro Pasaaltos Analógico', 'NumberTitle', 'off');
opts = bodeoptions;
opts.FreqUnits = 'kHz'; % Escala de frecuencia en kHz
opts.Grid = 'on';

bode(H_total, opts);
title(sprintf('Diagrama de Bode - Filtro Pasaaltos Butterworth (N = %d)', n));

%% 6. MOSTRAR FUNCIONES DE TRANSFERENCIA REDUCIDAS (SOS / ORDEN 1 Y 2)
[sos, g] = zp2sos(z, p, k);
num_secciones = size(sos, 1);

fprintf('=========================================================\n');
fprintf('3. FUNCIONES DE TRANSFERENCIA REDUCIDAS (ORDEN 1 Y 2)\n');
fprintf('Ganancia Global g = %.6e\n', g);
fprintf('=========================================================\n');

H_etapas = cell(num_secciones, 1);

for i = 1:num_secciones
    num = sos(i, 1:3); % Coeficientes del numerador [b0, b1, b2]
    den = sos(i, 4:6); % Coeficientes del denominador [a0, a1, a2]

    H_etapas{i} = tf(num, den);

    fprintf('--- Sección %d de %d ---\n', i, num_secciones);
    H_etapas{i}
end
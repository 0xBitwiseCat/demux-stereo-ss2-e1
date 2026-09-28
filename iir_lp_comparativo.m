clc; clear; close all;
format long e

% Parámetros del sistema y muestreo
Fs = 160000; % Frecuencia de muestreo (160 kHz)
Ts = 1 / Fs; % Período de muestreo

%% =========================================================================
% 1. FILTRO ANALÓGICO
% =========================================================================
% Especificaciones iniciales
W1 = 2*pi*15000; % Frecuencia de paso (rad/s)
W2 = 2*pi*23000; % Frecuencia de rechazo (rad/s)
Rp = 3;          % Atenuación en banda de paso (dB)
As = 15;         % Atenuación en banda de rechazo (dB)

% Orden N y frecuencia de corte Wc
[N, Wc] = buttord(W1, W2, Rp, As, 's');

% Ceros, polos y ganancia en dominio analógico (Evita mal acondicionamiento)
[z, p, k] = butter(N, Wc, 's');

% Función de transferencia H(s) y secciones SOS analógicas
[b, a] = zp2tf(z, p, k);
sys_analog = tf(b, a);
[sos_analog, g_analog] = zp2sos(z, p, k);


%% =========================================================================
% 2. FILTRO DIGITAL IIR INVARIANZA (A PARTIR DEL FILTRO ANALÓGICO)
% =========================================================================
[bz_imp, az_imp] = impinvar(b, a, Fs);
Hz_imp = tf(bz_imp, az_imp, Ts);


%% =========================================================================
% 3. H(z) DEL IIR INVARIANZA EN CONSOLA
% =========================================================================
fprintf('\n=======================================================\n');
fprintf('   H(z) - FILTRO IIR INVARIANZA AL IMPULSO\n');
fprintf('=======================================================\n');
Hz_imp


%% =========================================================================
% 4. SOS DEL IIR INVARIANZA EN CONSOLA
% =========================================================================
[zd_imp, pd_imp, kd_imp] = tf2zp(bz_imp, az_imp);
[sos_imp, g_imp] = zp2sos(zd_imp, pd_imp, kd_imp);

fprintf('=======================================================\n');
fprintf('   MATRIZ SOS - INVARIANZA AL IMPULSO\n');
fprintf('=======================================================\n');
fprintf('Estructura por fila: [b0 b1 b2 a0 a1 a2]\n\n');
disp(sos_imp);
fprintf('Ganancia global (g) = %e\n\n', g_imp);


%% =========================================================================
% 5. FILTRO DIGITAL IIR BILINEAL (A PARTIR DEL FILTRO ANALÓGICO)
% =========================================================================
% Transformación Bilineal sobre ZPK para eliminar advertencias numéricas y errores
[zd_bil, pd_bil, kd_bil] = bilinear(z, p, k, Fs);

% Obtener H(z) y Matriz SOS desde la representación ZPK discreta
[bz_bil, az_bil] = zp2tf(zd_bil, pd_bil, kd_bil);
Hz_bil = tf(bz_bil, az_bil, Ts);
[sos_bil, g_bil] = zp2sos(zd_bil, pd_bil, kd_bil);


%% =========================================================================
% 6. H(z) DEL IIR BILINEAL EN CONSOLA
% =========================================================================
fprintf('=======================================================\n');
fprintf('   H(z) - FILTRO IIR TRANSFORMACIÓN BILINEAL\n');
fprintf('=======================================================\n');
Hz_bil


%% =========================================================================
% 7. SOS DEL IIR BILINEAL EN CONSOLA
% =========================================================================
fprintf('=======================================================\n');
fprintf('   MATRIZ SOS - TRANSFORMACIÓN BILINEAL\n');
fprintf('=======================================================\n');
fprintf('Estructura por fila: [b0 b1 b2 a0 a1 a2]\n\n');
disp(sos_bil);
fprintf('Ganancia global (g) = %e\n\n', g_bil);


%% =========================================================================
% 8. BODE COMPARATIVO ENTRE FILTRO ANALÓGICO, IIR INVARIANZA E IIR BILINEAL
% =========================================================================
fig = figure('Name', 'Comparación de Filtros Butterworth', 'NumberTitle', 'off');

% 1. Definir los colores RGB personalizados
c_verde  = [0.0, 0.65, 0.25]; % Verde
c_fucsia = [0.9, 0.00, 0.55]; % Fucsia
c_azul   = [0.0, 0.45, 0.85]; % Azul

% 2. Asignar el orden de colores para la figura actual
set(fig, 'DefaultAxesColorOrder', [c_verde; c_fucsia; c_azul]);

% 3. Configuración de unidades de frecuencia a Hz
opts = bodeoptions;
opts.FreqUnits = 'Hz';
opts.XLim = [1000, Fs/2]; % Visualización desde 1 kHz hasta frecuencia de Nyquist (80 kHz)

% 4. Graficar los tres sistemas en un solo comando para aplicar la paleta
bode(sys_analog, Hz_imp, Hz_bil, opts);
grid on;

% 5. Cambiar el grosor de todas las líneas del gráfico (Magnitud y Fase)
lineas = findobj(fig, 'Type', 'line');
set(lineas, 'LineWidth', 2.0); % Ajusta este valor (ej. 1.8, 2.0, 2.5) según prefieras

% 6. Leyenda y título
legend('Analógico H(s)', 'Digital IIR (Invarianza)', 'Digital IIR (Bilineal)', 'Location', 'southwest');
title('Respuesta en Frecuencia: H(s) vs H(z) Invarianza vs H(z) Bilineal');
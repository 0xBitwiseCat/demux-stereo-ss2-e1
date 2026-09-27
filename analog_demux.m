% =========================================================================
% DEMULTIPLEXOR DE SEÑALES ESTÉREO - PRUEBA SECUENCIAL CANAL POR CANAL
% Asignatura: Señales y Sistemas II - Primer Parcial 2026-II
% =========================================================================
clear; clc; close all;

%% PASO 1: LEER LA SEÑAL DE PRUEBA
archivo_mat = 'SenalPrueba1.mat'; 

ruta_script = fileparts(mfilename('fullpath'));
if ~isempty(ruta_script)
    cd(ruta_script);
end

if exist(archivo_mat, 'file') == 2
    fprintf('Cargando la señal desde: %s...\n', archivo_mat);
    data = load(archivo_mat);
    nombres_var = fieldnames(data);
    m_in = double(data.(nombres_var{1})(:));
else
    error('El archivo "%s" no existe o no está en la carpeta del script.', archivo_mat);
end

%% PASO 2: PARÁMETROS DE MUESTREO Y TIEMPO
Fs_in  = 160e3;               % Frecuencia de muestreo multiplexada (160 kHz)
Fs_out = 32e3;                % Frecuencia de muestreo final (32 kHz)
factor_dec = Fs_in / Fs_out; % Factor de decimación = 5
N_samples  = length(m_in);
t = (0:N_samples-1)' / Fs_in; % Vector de tiempo continuo

%% PASO 3: DISEÑO DE FILTROS ANALÓGICOS (Convertidos a ss para estabilidad en lsim)
Rp = 3;   % Atenuación máxima en banda de paso (dB)
As = 15;  % Atenuación mínima en banda de rechazo (dB)

% 1. Filtro Pasabajas Analógico (Canal Izquierdo: 0 - 15 kHz)
Wpl = 2*pi*15000; Wsl = 2*pi*23000;
[Nl, Wcl] = buttord(Wpl, Wsl, Rp, As, 's');
[bl, al]   = butter(Nl, Wcl, 's');
sys_l      = ss(tf(bl, al)); % Conversion a espacio de estados

% 2. Filtro Pasabanda Analógico (Canal Derecho: 23 - 53 kHz)
Wpb = [2*pi*23e3, 2*pi*53e3]; Wsb = [2*pi*15e3, 2*pi*61e3]; 
[Nb, Wcb] = buttord(Wpb, Wsb, Rp, As, 's');
[bb, ab]   = butter(Nb, Wcb, 's');
sys_b      = ss(tf(bb, ab));

% 3. Filtro Pasaalto Analógico (RBDS: >= 55 kHz)
Wph = 2*pi*55e3; Wsh = 2*pi*45e3;
[Nh, Wch] = buttord(Wph, Wsh, Rp, As, 's');
[bh, ah]   = butter(Nh, Wch, 'high', 's');
sys_h      = ss(tf(bh, ah));

%% PASO 4: CONFIGURACIÓN Y ALINEACIÓN DE PORTADORAS LOCALES
[mag_b, phase_b_deg] = bode(sys_b, 2*pi*38e3);
[mag_h, phase_h_deg] = bode(sys_h, 2*pi*57e3);

gain_38       = double(squeeze(mag_b));
phi_38_filter = deg2rad(double(squeeze(phase_b_deg)));

gain_57       = double(squeeze(mag_h));
phi_57_filter = deg2rad(double(squeeze(phase_h_deg)));

% Búsqueda del ángulo óptimo de la subportadora para maximizar m_D
m_38_band = lsim(sys_b, m_in, t);
cos38_I = (2 / gain_38) * cos(2 * pi * 38e3 * t + phi_38_filter);
sin38_Q = (2 / gain_38) * sin(2 * pi * 38e3 * t + phi_38_filter);

m_D_I = lsim(sys_l, m_38_band .* cos38_I, t);
m_D_Q = lsim(sys_l, m_38_band .* sin38_Q, t);

phi_opt_rad = 0.5 * atan2(-2 * sum(m_D_I .* m_D_Q), sum(m_D_I.^2) - sum(m_D_Q.^2));

% Portadoras locales finales
cos38 = (2 / gain_38) * cos(2 * pi * 38e3 * t + phi_38_filter + phi_opt_rad); 
cos57 = (2 / gain_57) * cos(2 * pi * 57e3 * t + phi_57_filter); 

%% PASO 5: SIMULACIÓN TEMPORAL (lsim) Y DEMODULACIÓN
m_I = lsim(sys_l, m_in, t);

m_D_raw = m_38_band .* cos38;
m_D     = lsim(sys_l, m_D_raw, t); 

m_57_high   = lsim(sys_h, m_in, t);
m_RBDS_raw  = m_57_high .* cos57;
m_RBDS_base = lsim(sys_l, m_RBDS_raw, t);

%% PASO 6: DECIMACIÓN A 32 kHz Y NORMALIZACIÓN DE VOLUMEN
m_I_dec  = resample(m_I, 1, factor_dec);
m_D_dec  = resample(m_D, 1, factor_dec);
RBDS_dec = resample(m_RBDS_base, 1, factor_dec);

% Normalización independiente para asegurar volumen audible idéntico
if max(abs(m_I_dec)) > 0
    m_I_norm = 0.9 * m_I_dec / max(abs(m_I_dec)); 
else
    m_I_norm = m_I_dec;
end

if max(abs(m_D_dec)) > 0
    m_D_norm = 0.9 * m_D_dec / max(abs(m_D_dec)); 
else
    m_D_norm = m_D_dec;
end

%% DIAGNÓSTICO DE ENERGÍA DE CANALES EN CONSOLA
duracion_sec = length(m_I_dec) / Fs_out;
fprintf('\n=========================================================\n');
fprintf('DIAGNÓSTICO DE SEÑALES EXTRAÍDAS:\n');
fprintf('  Duración del audio: %.2f segundos\n', duracion_sec);
fprintf('  Amplitud Máxima m_I (Izquierdo): %.4f\n', max(abs(m_I_dec)));
fprintf('  Amplitud Máxima m_D (Derecho)  : %.4f\n', max(abs(m_D_dec)));
fprintf('  Energía RMS m_I    (Izquierdo): %.4f\n', rms(m_I_dec));
fprintf('  Energía RMS m_D    (Derecho)  : %.4f\n', rms(m_D_dec));
fprintf('=========================================================\n\n');

%% PASO 7: REPRODUCCIÓN SECUENCIAL PASO A PASO

% 1. REPRODUCIR SOLO CANAL IZQUIERDO (L: m_I, R: Silencio)
fprintf('1/3 Reproduciendo SOLO Canal Izquierdo m_I(t) (Audio por parlante izquierdo)...\n');
sound([m_I_norm, zeros(size(m_I_norm))], Fs_out);
pause(duracion_sec + 1);

% 2. REPRODUCIR SOLO CANAL DERECHO (L: Silencio, R: m_D)
fprintf('2/3 Reproduciendo SOLO Canal Derecho m_D(t) (Audio por parlante derecho)...\n');
sound([zeros(size(m_D_norm)), m_D_norm], Fs_out);
pause(duracion_sec + 1);

% 3. REPRODUCIR AMBOS CANALES EN ESTÉREO
fprintf('3/3 Reproduciendo AMBOS Canales en Estéreo [m_I, m_D]...\n');
AR = [m_I_norm, m_D_norm];
sound(AR, Fs_out);
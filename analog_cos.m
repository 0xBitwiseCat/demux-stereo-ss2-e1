%% =========================================================================
%% PARÁMETROS Y ESPECIFICACIONES DEL FILTRO ANALÓGICO PASABANDA
%% =========================================================================
% Frecuencias características del filtro analógico
f_p1 = 18e3; f_p2 = 20e3; % Banda de paso (-3 dB): 18 kHz a 20 kHz
f_s1 = 15e3; f_s2 = 23e3; % Banda de rechazo (-15 dB): 15 kHz y 23 kHz
Rp = 3;                   % Atenuación máxima en banda de paso (dB)
Rs = 15;                  % Atenuación mínima en banda de rechazo (dB)

% Conversión a frecuencias angulares continuas (rad/s)
Wp_analog = 2 * pi * [f_p1, f_p2];
Ws_analog = 2 * pi * [f_s1, f_s2];

%% =========================================================================
%% 1. DISEÑO DE LA FUNCIÓN DE TRANSFERENCIA ANALÓGICA H(s)
%% =========================================================================
% Cálculo de orden del prototipo y frecuencias de corte continuas
[N_proto, Wc_analog] = buttord(Wp_analog, Ws_analog, Rp, Rs, 's');
N_proto
Wc_analog
% Función de transferencia analógica H(s) = B(s) / A(s)
[num_s, den_s] = butter(N_proto, Wc_analog, 'bandpass', 's');
sys_analog = tf(num_s, den_s);

%% =========================================================================
%% 2. DIAGRAMA DE POLOS Y CEROS EN EL PLANO s (ESTILO EXACTO A LA IMAGEN)
%% =========================================================================
figure('Name', 'Pole-Zero Map - Filtro Analógico', 'Color', 'w');

% Extracción de polos y ceros
polos = roots(den_s);
ceros = roots(num_s);

hold on;
% Líneas de ejes centradas en cero (punteadas gris claro)
xline(0, ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 1);
yline(0, ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 1);

% Graficar Ceros ('o') y Polos ('x')
if ~isempty(ceros)
    plot(real(ceros), imag(ceros), 'o', 'Color', [0 0.4470 0.7410], ...
         'LineWidth', 1.2, 'MarkerSize', 7);
end
plot(real(polos), imag(polos), 'x', 'Color', [0 0.4470 0.7410], ...
     'LineWidth', 1.2, 'MarkerSize', 8);

hold off;
grid on;
box on;
axis equal;

% Formato idéntico de título y etiquetas de ejes
title('Pole-Zero Map', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Real Axis (seconds^{-1})', 'FontSize', 11);
ylabel('Imaginary Axis (seconds^{-1})', 'FontSize', 11);

% Formato de escala científica (10^5) en ambos ejes
ax = gca;
ax.XAxis.Exponent = 5;
ax.YAxis.Exponent = 5;

%% =========================================================================
%% 3. DIAGRAMA DE BODE DEL FILTRO ANALÓGICO
%% =========================================================================
figure('Name', 'Diagrama de Bode - Filtro Pasabanda Analógico', 'Color', 'w');

% Vector de frecuencias para evaluación (5 kHz a 35 kHz)
w_vec = 2 * pi * linspace(5e3, 35e3, 4000);
[mag, phase] = freqs(num_s, den_s, w_vec);
f_vec = w_vec / (2 * pi);

% Magnitud (dB)
subplot(2,1,1);
plot(f_vec/1e3, 20*log10(abs(mag)), 'b', 'LineWidth', 1.5);
grid on;
title('Diagrama de Bode - Respuesta en Magnitud');
xlabel('Frecuencia (kHz)'); ylabel('Magnitud (dB)');
xlim([5 35]); ylim([-50 5]);

% Fase (Grados)
subplot(2,1,2);
plot(f_vec/1e3, angle(mag)*180/pi, 'b', 'LineWidth', 1.5);
grid on;
title('Diagrama de Bode - Respuesta de Fase');
xlabel('Frecuencia (kHz)'); ylabel('Fase (grados)');
xlim([5 35]);
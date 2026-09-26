clc;
% 1. Definición de frecuencias y diseño del pasabanda
Wp = [2*pi*23e3, 2*pi*53e3]; % 23 kHz a 53 kHz
Ws = [2*pi*15e3, 2*pi*61e3]; % 15 kHz y 61 kHz
[n, Wn] = buttord(Wp, Ws, 3, 15, 's');
[z0, p0, k0] = butter(n, Wn, 'bandpass', 's');

%% 1. Especificaciones del problema (frecuencias en kHz)
f1 = 15; f2 = 23; f3 = 53; f4 = 61;
As = 15; Rp = 3;

% Frecuencia central y ancho de banda
f0 = sqrt(f2 * f3);        % f0 approx 34.9142 kHz
B  = f3 - f2;               % B = 30 kHz

% Frecuencia de corte normalizada wc del pasa-bajas (N = 6)
N_lp = 6;
Omega_s = abs((f4^2 - f0^2)/(B * f4));
wc = Omega_s / ((10^(0.1*As) - 1)^(1/(2*N_lp))); % wc approx 1.0288

%% 2. Polos del prototipo pasa-bajas en el semiplano izquierdo (LHP)
k = 0 : (N_lp - 1);
theta_k = pi/2 + (2*k + 1)*pi / (2*N_lp); % Fases entre 7pi/12 y 17pi/12
p_lp = wc * exp(1i * theta_k);            % 6 polos pasa-bajas

%% 3. Transformacion al pasa-banda (Ecuacion cuadratica)
p_bp = zeros(1, 2 * N_lp);

for i = 1:N_lp
    pk = p_lp(i);
    % Raices de: lambda^2 - (pk * B)*lambda + f0^2 = 0
    disc = sqrt((pk * B)^2 - 4 * f0^2);
    p_bp(2*i - 1) = (pk * B + disc) / 2;
    p_bp(2*i)     = (pk * B - disc) / 2;
end

%% 4. Mostrar valores numericos en consola
fprintf('=== POLOS DEL FILTRO PASABANDA (en kHz) ===\n');
for i = 1:length(p_bp)
    fprintf('s_%-2d = %8.4f %+8.4fj\n', i, real(p_bp(i)), imag(p_bp(i)));
end

%% 5. Graficacion en el plano complejo s
figure('Color', 'w', 'Name', 'Polos del Filtro Pasabanda');
plot(real(p_bp), imag(p_bp), 'rx', 'LineWidth', 2, 'MarkerSize', 10);
grid on; hold on;

% Ejes de referencia (Real e Imaginario)
xline(0, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
yline(0, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');

% Marcar frecuencias f0 y -f0 en el eje imaginario
plot(0, f0, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
plot(0, -f0, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 6);

% Ajustes esteticos de la grafica
title('Distribucion de los 12 Polos del Filtro Pasabanda (N=12)', 'FontSize', 12);
xlabel('Parte Real \sigma [kHz]', 'FontSize', 11);
ylabel('Parte Imaginaria j\omega [kHz]', 'FontSize', 11);
legend('Polos Pasa-banda', 'Frecuencia Central \pm f_0', 'Location', 'northeast');
axis equal;


% 2. Generar matriz SOS y ganancia global
[sos_bp, g_bp] = zp2sos(z0, p0, k0);

% 3. Convertir a funciones de transferencia individuales
num_secciones = size(sos_bp, 1);
H_bp_etapas = cell(num_secciones, 1);

for i = 1:num_secciones
    num = sos_bp(i, 1:3); % Coeficientes [0, 1, 0] -> s
    den = sos_bp(i, 4:6); % Coeficientes [1, a1, a2] -> s^2 + a1*s + a2
    H_bp_etapas{i} = tf(num, den);
end

% 4. Mostrar en pantalla cada función de transferencia individual
for i = 1:num_secciones
    fprintf('================ Sección %d ================\n', i);
    H_bp_etapas{i}
end

% Función de transferencia total conectada en cascada
H_bp_total = tf(g_bp, 1);
for i = 1:num_secciones
    H_bp_total = H_bp_total * H_bp_etapas{i};
end


[b,a] = butter(n, Wn, 'bandpass', 's');
% funcion de transferencia completa
% Mostrar la función de transferencia completa
disp('Función de transferencia completa del filtro pasabanda:');
H_bp_total

% calcular diagrama de bode
% Calcular y mostrar el diagrama de Bode del filtro pasabanda
figure;
bode(b, a);
grid on;
title('Diagrama de Bode del filtro pasabanda');
clc;
format long e

% Especificaciones del filtro pasabajos
W1 = 2*pi*15000; 
W2 = 2*pi*23000;
Rp = 3;
As = 15;

% Calcular el orden y la frecuencia del sistema
[N, Wc] = buttord(W1, W2, Rp, As, 's');

% Calcular el filtro
[b, a] = butter(N, Wc, 's');
sys = tf(b, a);
H = tf(b, a)

% =========================================================================
% DESCOMPOSICIÓN EN FRACCIONES PARCIALES DE H(s)
% =========================================================================

% 1. Obtener los coeficientes del numerador (b) y denominador (a)
% (Asumiendo que 'b' y 'a' ya fueron calculados con [b, a] = butter(N, Wc, 's'))
[r, p, k] = residue(b, a);

% 2. Mostrar resultados formateados por consola
fprintf('\n=======================================================\n');
fprintf('   DESCOMPOSICIÓN EN FRACCIONES PARCIALES DE H(s)\n');
fprintf('=======================================================\n\n');
fprintf('La función de transferencia se expresa como:\n');
fprintf('  H(s) = sum( r_i / (s - p_i) ) + k(s)\n\n');

% Mostrar cada par de residuo y polo
for i = 1:length(r)
    fprintf('Etapa / Término %d:\n', i);
    fprintf('  Residuo (r_%d) = %14.6e + (%14.6ej)\n', i, real(r(i)), imag(r(i)));
    fprintf('  Polo    (p_%d) = %14.6e + (%14.6ej)\n\n', i, real(p(i)), imag(p(i)));
end

% Mostrar término directo (si existe)
if isempty(k)
    fprintf('Término directo k(s) = 0 (Filtro estrictamente propio)\n');
else
    fprintf('Término directo k(s) = %s\n', mat2str(k));
end
fprintf('=======================================================\n\n');

% Conversion a Secciones de Segundo Orden (SOS)
[z, p, k] = butter(N, Wc, 's');
[sos, g] = zp2sos(z, p, k);
num_secciones = size(sos, 1);
H_etapas = cell(num_secciones, 1);

for i = 1:num_secciones
    num = sos(i, 1:3); % Coeficientes [b0, b1, b2]
    den = sos(i, 4:6); % Coeficientes [a0, a1, a2]

    % Función de transferencia de la sección actual
    H_etapas{i} = tf(num, den);
end

% Visualizar las secciones individuales
disp('Sección 1:'); H_etapas{1}
disp('Sección 2:'); H_etapas{2}
disp('Sección 3:'); H_etapas{3}

% Visualizar la respuesta en frecuencia del filtro diseñado
figure;
bode(sys);
grid on;
title('Respuesta en frecuencia del filtro Butterworth');
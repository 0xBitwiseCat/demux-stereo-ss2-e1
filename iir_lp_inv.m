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

% 1. Definir la frecuencia y período de muestreo (160 kHz)
Fs = 160000;
Ts = 1 / Fs;

% 2. Calcular los coeficientes del filtro digital IIR usando invarianza al impulso
[bz, az] = impinvar(b, a, Fs);

% 3. Crear la función de transferencia discreta H(z) especificando Ts
Hz = tf(bz, az, Ts);

% 4. Mostrar el resultado en consola
disp('Función de Transferencia Digital H(z) (Invarianza al Impulso):');
Hz

% DESCOMPOSICIÓN EN FRACCIONES PARCIALES DE H(s)
[r, p, k] = residue(b, a);
fprintf('   DESCOMPOSICIÓN EN FRACCIONES PARCIALES DE H(s)\n');

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

% =========================================================================
% TRANSFORMACIÓN AL DOMINIO Z (MÉTODO DE INVARIANZA AL IMPULSO)
% =========================================================================



% 2. Mapeo de residuos y polos analógicos a discretos
r_d = Ts * r;        % Escalamiento por Ts para mantener la ganancia
p_d = exp(p * Ts);   % Mapeo conformal z = exp(s * Ts)

% 3. Reconstrucción de los coeficientes polinomiales H(z) = B(z) / A(z)
[num_d, den_d] = residue(r_d, p_d, k);

% Eliminar partes imaginarias residuales causadas por imprecisión numérica
num_d = real(num_d);
den_d = real(den_d);

% 4. Crear el objeto de función de transferencia discreta H(z)
Hz_imp = tf(num_d, den_d, Ts);

% 5. Mostrar la función de transferencia discreta en consola
fprintf('=======================================================\n');
fprintf('  FUNCIÓN DE TRANSFERENCIA DISCRETA H(z) - INVARIANZA AL IMPULSO\n');
fprintf('=======================================================\n\n');
Hz_imp

% 6. Comparación gráfica de respuesta en frecuencia
figure;
opts = bodeoptions;
opts.FreqUnits = 'Hz';

bode(sys, opts); hold on;
bode(Hz_imp, opts);
grid on;
legend('Analógico H(s)', 'Digital H(z) - Invarianza al Impulso');
title('Comparación de Respuesta en Frecuencia: H(s) vs H(z)');
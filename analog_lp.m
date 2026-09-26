clc;
format long e
% Parametros de los polos
% calculados manualmente
r = 2*pi*15000;
w = [0, pi/5, 2*pi/5, 3*pi/5, 4*pi/5, pi, 6*pi/5, 7*pi/5, 8*pi/5, 9*pi/5]; 

% Construcción del vector de números complejos: z = r * e^(j*w)
zr = r .* exp(1i * w);

% Para visualizar la respuesta en frecuencia de tus polos definidos:
% Sistema con ganancia 1 y polos en 'z'
% sys = zpk([], zr, 1); 
% pzmap(sys);

% Especificaciones del filtro pasabajos
W1 = 2*pi*15000; 
W2 = 2*pi*23000;
Rp = 3;
As = 15;

% Calcular el orden y la frecuencia del sistema
[N, Wc] = buttord(W1, W2, Rp, As, 's');

% N = 5 Wc = 102.64kHz

% Comparativa del calculo con la ecuacion Wc(W2,N,As)
x0 = 10.^(As/10);
x1 = 2*N;
Wc0 = W2/nthroot(x0 - 1, x1);

diff = Wc - Wc0;
fprintf('Wc: %f\nWc - Wc0: %f\nOrden del filtro: %f\n',Wc, diff, N);

% calculo del filtro
[b, a] = butter(N, Wc, 's');
sys = tf(b, a);
H = tf(b, a)

% Conversion a Secciones de Segundo Orden (SOS)
[z, p, k] = butter(N, Wc, 's');
[sos, g] = zp2sos(z, p, k);

% Matriz SOS de coeficientes
disp('Matriz SOS:');
disp(sos);
disp('Ganancia global g:');
disp(g);

num_secciones = size(sos, 1);
H_etapas = cell(num_secciones, 1); % Guardará cada H_i(s)

% Empezamos la función de transferencia global con la ganancia g
H_total = tf(g, 1); 

for i = 1:num_secciones
    num = sos(i, 1:3); % Coeficientes [b0, b1, b2]
    den = sos(i, 4:6); % Coeficientes [a0, a1, a2]

    % Función de transferencia de la sección actual
    H_etapas{i} = tf(num, den);

    % Multiplicación en cascada
    H_total = H_total * H_etapas{i};
end

% Visualizar las secciones individuales
disp('Sección 1:'); H_etapas{1}
disp('Sección 2:'); H_etapas{2}
disp('Sección 3:'); H_etapas{3}

% Visualizar la respuesta en frecuencia del filtro diseñado
%figure;
%bode(sys);
%grid on;
%title('Respuesta en frecuencia del filtro Butterworth');
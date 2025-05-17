-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS casa_inteligentee;
USE casa_inteligentee;

-- Tabela de ambientes
CREATE TABLE ambientes (
    id_ambiente INT PRIMARY KEY,
    nome_ambiente VARCHAR(50) NOT NULL,
    descricao VARCHAR(100),
    potencia_total_watts DECIMAL(10,2) NOT NULL,
    equipamentos TEXT
);

-- Inserindo os ambientes
INSERT INTO ambientes (id_ambiente, nome_ambiente, descricao, potencia_total_watts, equipamentos) VALUES
(1, 'Quarto 1', 'Quarto principal', 1500, '1 TV, 1 lâmpada, 1 ar-condicionado'),
(2, 'Quarto 2', 'Quarto de hóspedes', 1500, '1 TV, 1 lâmpada, 1 ar-condicionado'),
(3, 'Sala', 'Sala de estar', 50, '1 TV, 5 lâmpadas'),
(4, 'Cozinha', 'Área de preparo de alimentos', 3000, '1 Microondas, 1 máquina de lavar louça, 3 lâmpadas'),
(5, 'Piscina', 'Área externa com piscina', 7000, 'Bomba, Aquecedor');

-- Tabela de sensores
CREATE TABLE sensores (
    id_sensor INT PRIMARY KEY,
    id_ambiente INT NOT NULL,
    tipo_sensor VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_ambiente) REFERENCES ambientes(id_ambiente)
);

-- Inserindo os sensores
INSERT INTO sensores (id_sensor, id_ambiente, tipo_sensor) VALUES
(1, 1, 'Sensor de ambiente (temperatura/umidade/movimento)'),
(2, 2, 'Sensor de ambiente (temperatura/umidade/movimento)'),
(3, 3, 'Sensor de ambiente (temperatura/umidade/movimento)'),
(4, 4, 'Sensor de ambiente (temperatura/umidade/movimento)'),
(5, 5, 'Sensor de ambiente (temperatura/umidade/movimento)');

-- Tabela de leituras dos sensores
CREATE TABLE leituras_sensores (
    id_leitura INT AUTO_INCREMENT PRIMARY KEY,
    id_sensor INT NOT NULL,
    dthCaptura DATETIME NOT NULL,
    temperatura DECIMAL(5,2) NOT NULL,
    umidade DECIMAL(5,2) NOT NULL,
    movimento TINYINT(1) NOT NULL,
    FOREIGN KEY (id_sensor) REFERENCES sensores(id_sensor)
);

-- Tabela de moradores
CREATE TABLE moradores (
    id_morador INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(20),
    senha VARCHAR(100)
);

-- Inserindo os moradores (2 pessoas)
INSERT INTO moradores (nome, email, telefone) VALUES
('Morador 1', 'morador1@email.com', '(00) 0000-0000'),
('Morador 2', 'morador2@email.com', '(00) 0000-0001');

-- Tabela de consumo energético
CREATE TABLE consumo_energetico (
    id_consumo INT AUTO_INCREMENT PRIMARY KEY,
    id_ambiente INT NOT NULL,
    timestamp_inicio DATETIME NOT NULL,
    timestamp_fim DATETIME,
    consumo_watts DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_ambiente) REFERENCES ambientes(id_ambiente)
);

-- Tabela de comandos de controle
CREATE TABLE comandos_controle (
    id_comando INT AUTO_INCREMENT PRIMARY KEY,
    id_ambiente INT NOT NULL,
    tipo_comando VARCHAR(50) NOT NULL,
    descricao VARCHAR(100) NOT NULL,
    estado_padrao TINYINT(1) DEFAULT 0,
    FOREIGN KEY (id_ambiente) REFERENCES ambientes(id_ambiente)
);

-- Tabela de histórico de comandos
CREATE TABLE historico_comandos (
    id_historico INT AUTO_INCREMENT PRIMARY KEY,
    id_comando INT NOT NULL,
    id_morador INT,
    timestamp DATETIME NOT NULL,
    novo_estado TINYINT(1) NOT NULL,
    FOREIGN KEY (id_comando) REFERENCES comandos_controle(id_comando),
    FOREIGN KEY (id_morador) REFERENCES moradores(id_morador)
);

-- Tabela de eventos de movimento
CREATE TABLE eventos_movimento (
    id_evento INT AUTO_INCREMENT PRIMARY KEY,
    id_leitura INT NOT NULL,
    id_morador INT,
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (id_leitura) REFERENCES leituras_sensores(id_leitura),
    FOREIGN KEY (id_morador) REFERENCES moradores(id_morador)
);
select * from eventos_movimento;
-- ------------------------------------------------------
-- CONSULTAS DE EXEMPLO
-- ------------------------------------------------------

-- 1. Ver leituras dos sensores
SELECT 
    DATE_FORMAT(ls.dthCaptura, '%d/%m/%Y') AS data,
    a.nome_ambiente,
    ls.temperatura,
    ls.umidade,
    CASE ls.movimento WHEN 1 THEN 'Sim' ELSE 'Não' END AS movimento_detectado
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
ORDER BY 
    ls.dthCaptura DESC;

-- 2. Consumo energético estimado por ambiente
SELECT 
    a.nome_ambiente,
    COUNT(ls.id_leitura) AS leituras,
    SUM(ls.movimento) AS vezes_com_movimento,
    ROUND(SUM(ls.movimento) * a.potencia_total_watts / 4 / 1000, 2) AS consumo_estimado_kwh
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
GROUP BY 
    a.id_ambiente, a.nome_ambiente, a.potencia_total_watts;

-- 3. Ambientes com maior movimento
SELECT 
    a.nome_ambiente,
    COUNT(ls.id_leitura) AS total_leituras,
    SUM(ls.movimento) AS vezes_com_movimento,
    ROUND((SUM(ls.movimento) / COUNT(ls.id_leitura)) * 100, 2) AS porcentagem_movimento
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
GROUP BY 
    a.id_ambiente, a.nome_ambiente
ORDER BY 
    porcentagem_movimento DESC;

-- 4. Lista de ambientes
SELECT * FROM ambientes;

-- 5. Sensores e seus ambientes
SELECT 
    s.id_sensor,
    a.nome_ambiente,
    s.tipo_sensor
FROM 
    sensores s
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
ORDER BY 
    s.id_sensor;

-- 6. Últimas leituras de sensores
SELECT 
    ls.id_leitura,
    ls.dthCaptura,
    a.nome_ambiente,
    ls.temperatura,
    ls.umidade,
    CASE ls.movimento WHEN 1 THEN 'Sim' ELSE 'Não' END AS movimento_detectado
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
ORDER BY 
    ls.dthCaptura DESC
LIMIT 10;

-- 7. Moradores cadastrados
SELECT * FROM moradores;

-- 8. Comandos de controle por ambiente
SELECT 
    a.nome_ambiente,
    cc.tipo_comando,
    cc.descricao,
    CASE cc.estado_padrao WHEN 1 THEN 'Ligado' ELSE 'Desligado' END AS estado_padrao
FROM 
    comandos_controle cc
JOIN 
    ambientes a ON cc.id_ambiente = a.id_ambiente
ORDER BY 
    a.id_ambiente, cc.tipo_comando;

-- 9. Estatísticas de movimento por ambiente
SELECT 
    a.nome_ambiente,
    COUNT(ls.id_leitura) AS total_leituras,
    SUM(ls.movimento) AS vezes_com_movimento,
    ROUND((SUM(ls.movimento) / COUNT(ls.id_leitura)) * 100, 2) AS porcentagem_movimento
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
GROUP BY 
    a.id_ambiente, a.nome_ambiente
ORDER BY 
    porcentagem_movimento DESC;

-- 10. Temperatura e umidade média por ambiente
SELECT 
    a.nome_ambiente,
    ROUND(AVG(ls.temperatura), 2) AS temperatura_media,
    ROUND(AVG(ls.umidade), 2) AS umidade_media
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
GROUP BY 
    a.id_ambiente, a.nome_ambiente
ORDER BY 
    a.id_ambiente;

-- 11. Consumo energético estimado baseado em movimento
SELECT 
    a.nome_ambiente,
    a.potencia_total_watts,
    SUM(ls.movimento) AS horas_com_movimento,
    ROUND(SUM(ls.movimento) * a.potencia_total_watts / 1000, 2) AS consumo_estimado_kwh
FROM 
    leituras_sensores ls
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
GROUP BY 
    a.id_ambiente, a.nome_ambiente, a.potencia_total_watts;

-- 12. Histórico de comandos (últimos 10)
SELECT 
    hc.timestamp,
    m.nome AS morador,
    a.nome_ambiente,
    cc.tipo_comando,
    CASE hc.novo_estado WHEN 1 THEN 'Ligado' ELSE 'Desligado' END AS acao
FROM 
    historico_comandos hc
JOIN 
    comandos_controle cc ON hc.id_comando = cc.id_comando
JOIN 
    ambientes a ON cc.id_ambiente = a.id_ambiente
LEFT JOIN 
    moradores m ON hc.id_morador = m.id_morador
ORDER BY 
    hc.timestamp DESC
LIMIT 10;

-- 13. Eventos de movimento (últimos 10)
SELECT 
    em.timestamp,
    a.nome_ambiente,
    m.nome AS morador,
    ls.temperatura,
    ls.umidade
FROM 
    eventos_movimento em
JOIN 
    leituras_sensores ls ON em.id_leitura = ls.id_leitura
JOIN 
    sensores s ON ls.id_sensor = s.id_sensor
JOIN 
    ambientes a ON s.id_ambiente = a.id_ambiente
LEFT JOIN 
    moradores m ON em.id_morador = m.id_morador
ORDER BY 
    em.timestamp DESC
LIMIT 10;

-- 14. Checagem de integridade

-- Leituras sem sensor
SELECT ls.* FROM leituras_sensores ls
LEFT JOIN sensores s ON ls.id_sensor = s.id_sensor
WHERE s.id_sensor IS NULL;

-- Sensores sem ambiente
SELECT s.* FROM sensores s
LEFT JOIN ambientes a ON s.id_ambiente = a.id_ambiente
WHERE a.id_ambiente IS NULL;

-- Comandos sem ambiente
SELECT cc.* FROM comandos_controle cc
LEFT JOIN ambientes a ON cc.id_ambiente = a.id_ambiente
WHERE a.id_ambiente IS NULL;


-- select para pegar ultimo mes capturado
-- Seleção de leituras do último mês registrado, agregadas por cômodo
SELECT
    a.nome_ambiente,
    COUNT(ls.id_leitura)            AS total_leituras,
    ROUND(AVG(ls.temperatura), 2)   AS temperatura_media,
    ROUND(AVG(ls.umidade), 2)       AS umidade_media,
    SUM(ls.movimento)               AS total_movimentos
FROM
    leituras_sensores ls
    JOIN sensores s   ON ls.id_sensor   = s.id_sensor
    JOIN ambientes a  ON s.id_ambiente  = a.id_ambiente
WHERE
    DATE_FORMAT(ls.dthCaptura, '%Y-%m') = (
        -- obtém o ano-mês mais recente na tabela
        SELECT DATE_FORMAT(MAX(dthCaptura), '%Y-%m')
        FROM leituras_sensores
    )
GROUP BY
    a.id_ambiente,
    a.nome_ambiente
ORDER BY
    a.nome_ambiente;

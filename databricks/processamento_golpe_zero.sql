-- ============================================================
-- PROJETO GOLPE ZERO
-- BIG DATA ARCHITECTURE & DATA INTEGRATION
--
-- PROCESSAMENTO: BRONZE -> PRATA -> OURO
-- PLATAFORMA: DATABRICKS
-- LINGUAGEM: SQL
--
-- Fontes:
-- 1. SSP-SP - Dados estatísticos de ocorrências
-- 2. IBGE/SIDRA - Dados populacionais
--
-- ============================================================


-- ============================================================
-- 0. ESTRUTURA INICIAL
-- ============================================================

CREATE SCHEMA IF NOT EXISTS golpe_zero;


-- ============================================================
-- 1. PRATA - PREPARAÇÃO DOS DADOS SSP
-- ============================================================

-- Transforma as colunas dos meses em registros individuais.
-- Mantém os valores originais para permitir auditoria e qualidade.

CREATE OR REPLACE TEMP VIEW vw_ssp_tratamento AS

SELECT
    TRIM(natureza) AS natureza,
    mes,
    2026 AS ano,

    TRIM(valor) AS valor_original,

    TRY_CAST(
        REPLACE(TRIM(valor), '.', '') AS INT
    ) AS quantidade

FROM golpe_zero.bronze_ssp_mensal

LATERAL VIEW STACK(
    12,
    'Janeiro', CAST(janeiro AS STRING),
    'Fevereiro', CAST(fevereiro AS STRING),
    'Março', CAST(marco AS STRING),
    'Abril', CAST(abril AS STRING),
    'Maio', CAST(maio AS STRING),
    'Junho', CAST(junho AS STRING),
    'Julho', CAST(julho AS STRING),
    'Agosto', CAST(agosto AS STRING),
    'Setembro', CAST(setembro AS STRING),
    'Outubro', CAST(outubro AS STRING),
    'Novembro', CAST(novembro AS STRING),
    'Dezembro', CAST(dezembro AS STRING)
) meses AS mes, valor;


-- ============================================================
-- 2. PRATA - PREPARAÇÃO DOS DADOS IBGE
-- ============================================================

CREATE OR REPLACE TEMP VIEW vw_ibge_tratamento AS

SELECT
    TRIM(estado) AS estado,

    TRY_CAST(ano AS INT) AS ano,

    TRIM(faixa_etaria) AS faixa_etaria,

    TRY_CAST(
        TRIM(CAST(populacao AS STRING)) AS BIGINT
    ) AS populacao

FROM golpe_zero.bronze_ibge;


-- ============================================================
-- 3. CONTROLE DE QUALIDADE
-- ============================================================

-- São contabilizados os registros que não atendem
-- aos critérios mínimos de qualidade.
--
-- Uma mesma linha pode ser contabilizada em mais de uma regra.
-- Portanto, os totais das regras não devem ser somados
-- como se fossem registros únicos.


CREATE OR REPLACE TABLE golpe_zero.controle_qualidade AS


-- REGRA 1: SSP - Natureza vazia ou nula

SELECT
    'SSP - Natureza vazia ou nula' AS regra,

    COUNT(*) AS registros_barrados,

    CURRENT_TIMESTAMP() AS data_validacao

FROM golpe_zero.bronze_ssp_mensal

WHERE natureza IS NULL
   OR TRIM(natureza) = ''


UNION ALL


-- REGRA 2: SSP - Quantidade ausente

SELECT
    'SSP - Quantidade ausente ou nao informada',

    COUNT(*),

    CURRENT_TIMESTAMP()

FROM vw_ssp_tratamento

WHERE valor_original IS NULL
   OR valor_original = ''
   OR valor_original = '...'


UNION ALL


-- REGRA 3: SSP - Quantidade inválida ou negativa

SELECT
    'SSP - Quantidade invalida ou negativa',

    COUNT(*),

    CURRENT_TIMESTAMP()

FROM vw_ssp_tratamento

WHERE valor_original IS NOT NULL
  AND valor_original <> ''
  AND valor_original <> '...'
  AND (
      quantidade IS NULL
      OR quantidade < 0
  )


UNION ALL


-- REGRA 4: IBGE - Estado vazio

SELECT
    'IBGE - Estado vazio ou nulo',

    COUNT(*),

    CURRENT_TIMESTAMP()

FROM vw_ibge_tratamento

WHERE estado IS NULL
   OR estado = ''


UNION ALL


-- REGRA 5: IBGE - Faixa etária inválida

SELECT
    'IBGE - Faixa etaria vazia ou nula',

    COUNT(*),

    CURRENT_TIMESTAMP()

FROM vw_ibge_tratamento

WHERE faixa_etaria IS NULL
   OR faixa_etaria = ''


UNION ALL


-- REGRA 6: IBGE - Ano inválido

SELECT
    'IBGE - Ano invalido',

    COUNT(*),

    CURRENT_TIMESTAMP()

FROM vw_ibge_tratamento

WHERE ano IS NULL
   OR ano <= 0


UNION ALL


-- REGRA 7: IBGE - População inválida

SELECT
    'IBGE - Populacao nula, invalida ou negativa',

    COUNT(*),

    CURRENT_TIMESTAMP()

FROM vw_ibge_tratamento

WHERE populacao IS NULL
   OR populacao <= 0;


-- ============================================================
-- 4. PRATA - CRIAÇÃO DAS TABELAS
-- ============================================================

-- Mantém a estrutura já utilizada pelo dashboard.

CREATE TABLE IF NOT EXISTS golpe_zero.prata_ssp (

    natureza STRING,
    mes STRING,
    ano INT,
    quantidade INT

)
USING DELTA;


CREATE TABLE IF NOT EXISTS golpe_zero.prata_ibge (

    estado STRING,
    ano INT,
    faixa_etaria STRING,
    populacao BIGINT

)
USING DELTA;


-- ============================================================
-- 5. PRATA - MERGE SSP
-- ============================================================

-- Chave lógica:
-- natureza + mes + ano
--
-- Quando o registro existe, atualiza.
-- Quando não existe, insere.
--
-- DISTINCT evita duplicações idênticas na origem.
-- A fonte deve ter uma única quantidade por natureza/mês/ano.


MERGE INTO golpe_zero.prata_ssp AS destino

USING (

SELECT
    natureza,
    mes,
    ano,
    MAX(quantidade) AS quantidade
FROM vw_ssp_tratamento
WHERE natureza IS NOT NULL
  AND natureza <> ''
  AND valor_original IS NOT NULL
  AND valor_original <> ''
  AND valor_original <> '...'
  AND quantidade IS NOT NULL
  AND quantidade >= 0
GROUP BY natureza, mes, ano

) AS origem

ON destino.natureza = origem.natureza
AND destino.mes = origem.mes
AND destino.ano = origem.ano

WHEN MATCHED THEN UPDATE SET

    destino.quantidade = origem.quantidade

WHEN NOT MATCHED THEN INSERT (

    natureza,
    mes,
    ano,
    quantidade

)

VALUES (

    origem.natureza,
    origem.mes,
    origem.ano,
    origem.quantidade

);


-- ============================================================
-- 6. PRATA - MERGE IBGE
-- ============================================================

-- Chave lógica:
-- estado + ano + faixa_etaria
--
-- O MAX evita múltiplas linhas de origem para a mesma chave
-- durante o MERGE. Duplicidades devem ser investigadas
-- antes de considerar a população definitiva.


MERGE INTO golpe_zero.prata_ibge AS destino

USING (

    SELECT

        estado,
        ano,
        faixa_etaria,
        MAX(populacao) AS populacao

    FROM vw_ibge_tratamento

    WHERE estado IS NOT NULL
      AND estado <> ''

      AND faixa_etaria IS NOT NULL
      AND faixa_etaria <> ''

      AND ano IS NOT NULL
      AND ano > 0

      AND populacao IS NOT NULL
      AND populacao > 0

    GROUP BY
        estado,
        ano,
        faixa_etaria

) AS origem

ON destino.estado = origem.estado
AND destino.ano = origem.ano
AND destino.faixa_etaria = origem.faixa_etaria

WHEN MATCHED THEN UPDATE SET

    destino.populacao = origem.populacao

WHEN NOT MATCHED THEN INSERT (

    estado,
    ano,
    faixa_etaria,
    populacao

)

VALUES (

    origem.estado,
    origem.ano,
    origem.faixa_etaria,
    origem.populacao

);


-- ============================================================
-- 7. OURO - DIMENSÃO TEMPO
-- ============================================================

CREATE OR REPLACE TABLE golpe_zero.dim_tempo AS

SELECT DISTINCT

    ano,

    mes,

    CASE mes

        WHEN 'Janeiro' THEN 1
        WHEN 'Fevereiro' THEN 2
        WHEN 'Março' THEN 3
        WHEN 'Abril' THEN 4
        WHEN 'Maio' THEN 5
        WHEN 'Junho' THEN 6
        WHEN 'Julho' THEN 7
        WHEN 'Agosto' THEN 8
        WHEN 'Setembro' THEN 9
        WHEN 'Outubro' THEN 10
        WHEN 'Novembro' THEN 11
        WHEN 'Dezembro' THEN 12

    END AS numero_mes

FROM golpe_zero.prata_ssp;


-- ============================================================
-- 8. OURO - DIMENSÃO TIPO DE OCORRÊNCIA
-- ============================================================

CREATE OR REPLACE TABLE golpe_zero.dim_tipo_ocorrencia AS

SELECT DISTINCT

    natureza

FROM golpe_zero.prata_ssp

WHERE natureza IS NOT NULL;


-- ============================================================
-- 9. OURO - FATO OCORRÊNCIA
-- ============================================================

CREATE OR REPLACE TABLE golpe_zero.fato_ocorrencia AS

SELECT

    p.natureza,

    p.mes,

    p.ano,

    p.quantidade

FROM golpe_zero.prata_ssp p

INNER JOIN golpe_zero.dim_tempo t

    ON p.mes = t.mes
   AND p.ano = t.ano

INNER JOIN golpe_zero.dim_tipo_ocorrencia d

    ON p.natureza = d.natureza;


-- ============================================================
-- 10. OURO - DIMENSÃO POPULAÇÃO
-- ============================================================

-- Consolida a população idosa por estado e ano.
--
-- IMPORTANTE:
-- A soma pressupõe que a Bronze contém somente faixas
-- etárias distintas da população com 60 anos ou mais.
-- Não inclua simultaneamente uma linha de total 60+
-- e suas respectivas subdivisões, pois haveria duplicidade.


CREATE OR REPLACE TABLE golpe_zero.dim_populacao AS

SELECT

    estado,

    ano,

    SUM(populacao) AS populacao_60_mais

FROM golpe_zero.prata_ibge

GROUP BY

    estado,
    ano;


-- ============================================================
-- 11. OURO - INDICADOR DE IMPACTO
-- ============================================================

-- Indicador contextual de ocorrências de estelionato
-- por 100 mil habitantes idosos.
--
-- A SSP e o IBGE precisam representar a mesma abrangência:
-- neste caso, o estado de São Paulo.
--
-- O indicador não representa uma taxa comprovada de
-- vitimização de idosos.


CREATE OR REPLACE VIEW golpe_zero.vw_indicador_impacto AS

WITH ocorrencias AS (

    SELECT

        ano,

        SUM(quantidade) AS total_estelionato

    FROM golpe_zero.fato_ocorrencia

    WHERE UPPER(natureza) LIKE '%ESTELIONATO%'

    GROUP BY ano

)

SELECT

    o.ano,

    o.total_estelionato,

    p.populacao_60_mais,

    ROUND(

        o.total_estelionato * 100000.0
        / NULLIF(p.populacao_60_mais, 0),

        2

    ) AS ocorrencias_por_100_mil_idosos

FROM ocorrencias o

INNER JOIN golpe_zero.dim_populacao p

    ON o.ano = p.ano

WHERE UPPER(p.estado) IN (
    'SÃO PAULO',
    'SAO PAULO',
    'SP'
);


-- ============================================================
-- 12. CINCO CONSULTAS SQL DO PROJETO
-- ============================================================


-- CONSULTA 1
-- Quais ocorrências tiveram maior quantidade de registros?


SELECT

    natureza,

    SUM(quantidade) AS total_ocorrencias

FROM golpe_zero.fato_ocorrencia

GROUP BY natureza

ORDER BY total_ocorrencias DESC

LIMIT 10;


-- CONSULTA 2
-- Qual mês apresentou mais ocorrências?


SELECT

    mes,

    SUM(quantidade) AS total_ocorrencias

FROM golpe_zero.fato_ocorrencia

GROUP BY mes

ORDER BY total_ocorrencias DESC;


-- CONSULTA 3
-- Qual é o total de ocorrências por mês?


SELECT

    ano,

    mes,

    SUM(quantidade) AS total_ocorrencias

FROM golpe_zero.fato_ocorrencia

GROUP BY
    ano,
    mes

ORDER BY
    ano,

    CASE mes

        WHEN 'Janeiro' THEN 1
        WHEN 'Fevereiro' THEN 2
        WHEN 'Março' THEN 3
        WHEN 'Abril' THEN 4
        WHEN 'Maio' THEN 5
        WHEN 'Junho' THEN 6
        WHEN 'Julho' THEN 7
        WHEN 'Agosto' THEN 8
        WHEN 'Setembro' THEN 9
        WHEN 'Outubro' THEN 10
        WHEN 'Novembro' THEN 11
        WHEN 'Dezembro' THEN 12

    END;


-- CONSULTA 4
-- Quais foram as ocorrências com maior quantidade em cada mês?


SELECT

    ano,

    mes,

    natureza,

    quantidade

FROM (

    SELECT

        ano,

        mes,

        natureza,

        quantidade,

        ROW_NUMBER() OVER (

            PARTITION BY ano, mes

            ORDER BY quantidade DESC

        ) AS posicao

    FROM golpe_zero.fato_ocorrencia

) resultado

WHERE posicao = 1

ORDER BY

    ano,

    CASE mes

        WHEN 'Janeiro' THEN 1
        WHEN 'Fevereiro' THEN 2
        WHEN 'Março' THEN 3
        WHEN 'Abril' THEN 4
        WHEN 'Maio' THEN 5
        WHEN 'Junho' THEN 6
        WHEN 'Julho' THEN 7
        WHEN 'Agosto' THEN 8
        WHEN 'Setembro' THEN 9
        WHEN 'Outubro' THEN 10
        WHEN 'Novembro' THEN 11
        WHEN 'Dezembro' THEN 12

    END;


-- CONSULTA 5
-- Qual a participação percentual de cada natureza
-- no total de ocorrências?


SELECT

    natureza,

    SUM(quantidade) AS total_ocorrencias,

    ROUND(

        SUM(quantidade) * 100.0 /

        NULLIF(

            (SELECT SUM(quantidade)
             FROM golpe_zero.fato_ocorrencia),

            0

        ),

        2

    ) AS percentual

FROM golpe_zero.fato_ocorrencia

GROUP BY natureza

ORDER BY percentual DESC;


-- ============================================================
-- 13. CONSULTA ADICIONAL - IMPACTO
-- ============================================================

SELECT *

FROM golpe_zero.vw_indicador_impacto

ORDER BY ano;


-- ============================================================
-- 14. DISTRIBUIÇÃO DA POPULAÇÃO IDOSA
-- ============================================================

SELECT

    estado,

    ano,

    faixa_etaria,

    populacao,

    ROUND(

        populacao * 100.0 /

        NULLIF(

            SUM(populacao) OVER (
                PARTITION BY estado, ano
            ),

            0

        ),

        2

    ) AS percentual

FROM golpe_zero.prata_ibge

WHERE UPPER(estado) IN (
    'SÃO PAULO',
    'SAO PAULO',
    'SP'
)

ORDER BY

    ano,

    populacao DESC;


-- ============================================================
-- 15. VALIDAÇÃO FINAL DAS CAMADAS
-- ============================================================

SELECT

    'BRONZE - SSP' AS tabela,

    COUNT(*) AS registros

FROM golpe_zero.bronze_ssp_mensal


UNION ALL


SELECT

    'PRATA - SSP',

    COUNT(*)

FROM golpe_zero.prata_ssp


UNION ALL


SELECT

    'BRONZE - IBGE',

    COUNT(*)

FROM golpe_zero.bronze_ibge


UNION ALL


SELECT

    'PRATA - IBGE',

    COUNT(*)

FROM golpe_zero.prata_ibge


UNION ALL


SELECT

    'OURO - DIM TEMPO',

    COUNT(*)

FROM golpe_zero.dim_tempo


UNION ALL


SELECT

    'OURO - DIM TIPO OCORRENCIA',

    COUNT(*)

FROM golpe_zero.dim_tipo_ocorrencia


UNION ALL


SELECT

    'OURO - FATO OCORRENCIA',

    COUNT(*)

FROM golpe_zero.fato_ocorrencia


UNION ALL


SELECT

    'OURO - DIM POPULACAO',

    COUNT(*)

FROM golpe_zero.dim_populacao;


-- ============================================================
-- 16. RESULTADO DO CONTROLE DE QUALIDADE
-- ============================================================

SELECT

    regra,

    registros_barrados,

    data_validacao

FROM golpe_zero.controle_qualidade

ORDER BY regra;


-- ============================================================
-- 17. CONFERÊNCIA DE DUPLICIDADES NA PRATA
-- ============================================================

-- SSP

SELECT

    natureza,

    mes,

    ano,

    COUNT(*) AS quantidade_repeticoes

FROM golpe_zero.prata_ssp

GROUP BY

    natureza,
    mes,
    ano

HAVING COUNT(*) > 1;


-- IBGE

SELECT

    estado,

    ano,

    faixa_etaria,

    COUNT(*) AS quantidade_repeticoes

FROM golpe_zero.prata_ibge

GROUP BY

    estado,
    ano,
    faixa_etaria

HAVING COUNT(*) > 1;


-- ============================================================
-- FIM DO PROCESSAMENTO GOLPE ZERO
-- ============================================================
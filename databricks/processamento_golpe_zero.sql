
-- =====================================================
-- GOLPE ZERO
-- PROCESSAMENTO AUTOMATIZADO - DATABRICKS
-- BRONZE -> PRATA -> OURO
-- =====================================================

CREATE SCHEMA IF NOT EXISTS golpe_zero;

-- =====================================================
-- 1. SSP - BRONZE PARA PRATA
-- =====================================================

CREATE OR REPLACE TABLE golpe_zero.prata_ssp AS

SELECT
    TRIM(natureza) AS natureza,
    mes,
    2026 AS ano,
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
) meses AS mes, valor

WHERE natureza IS NOT NULL
  AND TRIM(natureza) <> ''
  AND valor IS NOT NULL
  AND TRIM(valor) <> ''
  AND valor <> '...'
  AND TRY_CAST(
      REPLACE(TRIM(valor), '.', '') AS INT
  ) IS NOT NULL;


-- =====================================================
-- 2. IBGE - BRONZE PARA PRATA
-- =====================================================

CREATE OR REPLACE TABLE golpe_zero.prata_ibge AS

SELECT
    TRIM(estado) AS estado,
    CAST(ano AS INT) AS ano,
    TRIM(faixa_etaria) AS faixa_etaria,
    TRY_CAST(populacao AS BIGINT) AS populacao

FROM golpe_zero.bronze_ibge

WHERE estado IS NOT NULL
  AND TRIM(estado) <> ''
  AND faixa_etaria IS NOT NULL
  AND TRIM(faixa_etaria) <> ''
  AND TRY_CAST(ano AS INT) > 0
  AND TRY_CAST(populacao AS BIGINT) > 0;


-- =====================================================
-- 3. CONTROLE DE QUALIDADE
-- =====================================================

CREATE OR REPLACE TABLE golpe_zero.controle_qualidade AS

SELECT
    'SSP - Natureza vazia ou nula' AS regra,
    COUNT(*) AS registros_barrados
FROM golpe_zero.bronze_ssp_mensal
WHERE natureza IS NULL OR TRIM(natureza) = ''

UNION ALL

SELECT
    'SSP - Mês sem informação',
    COUNT(*)
FROM golpe_zero.prata_ssp
WHERE mes IS NULL

UNION ALL

SELECT
    'SSP - Quantidade inválida',
    COUNT(*)
FROM golpe_zero.bronze_ssp_mensal
WHERE
    (
        TRIM(janeiro) NOT IN ('...', '')
        AND TRY_CAST(REPLACE(TRIM(janeiro), '.', '') AS INT) IS NULL
    )

UNION ALL

SELECT
    'IBGE - Estado vazio',
    COUNT(*)
FROM golpe_zero.bronze_ibge
WHERE estado IS NULL OR TRIM(estado) = ''

UNION ALL

SELECT
    'IBGE - População inválida',
    COUNT(*)
FROM golpe_zero.bronze_ibge
WHERE TRY_CAST(populacao AS BIGINT) IS NULL
   OR TRY_CAST(populacao AS BIGINT) <= 0;


-- =====================================================
-- 4. OURO - DIMENSÃO TEMPO
-- =====================================================

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


-- =====================================================
-- 5. OURO - DIMENSÃO TIPO DE OCORRÊNCIA
-- =====================================================

CREATE OR REPLACE TABLE golpe_zero.dim_tipo_ocorrencia AS

SELECT DISTINCT
    natureza

FROM golpe_zero.prata_ssp

WHERE natureza IS NOT NULL;


-- =====================================================
-- 6. OURO - FATO OCORRÊNCIA
-- =====================================================

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


-- =====================================================
-- 7. OURO - DIMENSÃO POPULAÇÃO
-- =====================================================

CREATE OR REPLACE TABLE golpe_zero.dim_populacao AS

SELECT
    estado,
    ano,
    SUM(populacao) AS populacao_60_mais

FROM golpe_zero.prata_ibge

GROUP BY
    estado,
    ano;


-- =====================================================
-- 8. VALIDAÇÃO FINAL
-- =====================================================

SELECT
    'bronze_ssp_mensal' AS tabela,
    COUNT(*) AS registros
FROM golpe_zero.bronze_ssp_mensal

UNION ALL

SELECT
    'prata_ssp',
    COUNT(*)
FROM golpe_zero.prata_ssp

UNION ALL

SELECT
    'bronze_ibge',
    COUNT(*)
FROM golpe_zero.bronze_ibge

UNION ALL

SELECT
    'prata_ibge',
    COUNT(*)
FROM golpe_zero.prata_ibge

UNION ALL

SELECT
    'dim_tempo',
    COUNT(*)
FROM golpe_zero.dim_tempo

UNION ALL

SELECT
    'dim_tipo_ocorrencia',
    COUNT(*)
FROM golpe_zero.dim_tipo_ocorrencia

UNION ALL

SELECT
    'fato_ocorrencia',
    COUNT(*)
FROM golpe_zero.fato_ocorrencia

UNION ALL

SELECT
    'dim_populacao',
    COUNT(*)
FROM golpe_zero.dim_populacao;


-- =====================================================
-- 9. RESULTADO DO CONTROLE DE QUALIDADE
-- =====================================================

SELECT *
FROM golpe_zero.controle_qualidade
ORDER BY regra;

SELECT COUNT(*) FROM golpe_zero.bronze_ssp_mensal;
SELECT COUNT(*) FROM golpe_zero.bronze_ibge;
SELECT COUNT(*) FROM golpe_zero.prata_ssp;
SELECT COUNT(*) FROM golpe_zero.prata_ibge;
SELECT COUNT(*) FROM golpe_zero.fato_ocorrencia;

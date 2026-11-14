
# Dashboard — Golpe Zero

O dashboard do **Golpe Zero** foi desenvolvido no Databricks com o objetivo de apresentar visualmente os principais indicadores obtidos por meio do processamento dos dados da SSP-SP e do IBGE.

A ferramenta permite acompanhar informações estatísticas sobre ocorrências, identificar padrões temporais e visualizar dados demográficos relacionados à população idosa.

---

## Objetivo

Transformar dados públicos em informações estratégicas, facilitando a análise de ocorrências e contribuindo para o desenvolvimento de ações de prevenção e conscientização sobre golpes e crimes.

## Fontes de dados

O dashboard utiliza duas fontes principais:

| Fonte | Descrição |
|---|---|
| **SSP-SP** | Dados estatísticos de ocorrências policiais disponibilizados em arquivos CSV. |
| **IBGE (SIDRA)** | Informações populacionais obtidas por meio da API pública do Sistema IBGE de Recuperação Automática. |

## Indicadores apresentados

O dashboard está organizado em cinco áreas principais:

### 01 — Golpe Zero: Inteligência Criminal
Apresenta uma visão geral dos indicadores estatísticos utilizados no projeto.

### 02 — Top 10 ocorrências
Identifica as dez naturezas de ocorrência com maior quantidade de registros.

### 03 — Evolução Mensal
Apresenta a distribuição das ocorrências ao longo dos meses, permitindo acompanhar suas variações.

### 04 — População Idosa
Apresenta informações sobre a população com 60 anos ou mais e sua distribuição por faixa etária, utilizando dados do IBGE.

### 05 — Indicadores de Roubo
Apresenta informações estatísticas relacionadas às ocorrências classificadas como roubo.

## Tecnologias utilizadas

- **Databricks:** processamento, consultas SQL e desenvolvimento do dashboard.
- **Apache Airflow:** orquestração dos processos de dados.
- **Astro:** ambiente de desenvolvimento e deployment do Airflow.
- **SQL:** consultas e transformação de dados.
- **API SIDRA (IBGE):** integração de informações populacionais.
- **SSP-SP:** fonte dos dados estatísticos de ocorrências.

## Acesso ao dashboard

O dashboard foi publicado no ambiente Databricks e pode ser acessado pelo link abaixo:

### [ Acessar Dashboard Golpe Zero](https://dbc-9aea2c4c-7f57.cloud.databricks.com/dashboardsv3/01f1dff5318b1cee851dafd41a32d572/published?o=7474653813850438)

##  Observações sobre os dados

Os indicadores apresentados possuem finalidade estatística e analítica.

Os dados gerais de ocorrências não identificam necessariamente a idade das vítimas. Portanto, as informações relacionadas à população idosa são utilizadas como contextualização demográfica, não representando uma taxa comprovada de vitimização de pessoas com 60 anos ou mais.

##  Sobre o projeto

O dashboard integra o MVP de Big Data do **Golpe Zero**, contribuindo para a análise de informações públicas e o desenvolvimento de estratégias de prevenção e conscientização.

**Golpe Zero — Tecnologia e dados a serviço da prevenção e da proteção das pessoas.**

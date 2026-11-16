
# 🛡️ Golpe Zero
### Big Data Architecture & Data Integration

**Tecnologia e dados a serviço da prevenção e da proteção das pessoas.**

<p align="center">
  <img src="https://img.shields.io/badge/Project-Golpe%20Zero-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Big%20Data-Data%20Integration-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-MVP%20Desenvolvido-success?style=for-the-badge" />
</p>

---

## 📌 Sobre o projeto

O **Golpe Zero** é uma proposta de solução tecnológica voltada à prevenção de golpes digitais contra pessoas idosas, com foco inicial na cidade de São Paulo.

O projeto busca utilizar tecnologia, inteligência de dados e análise de informações públicas para contribuir com a identificação de padrões de ocorrências, conscientização da população e prevenção de fraudes digitais.

A proposta geral do Golpe Zero consiste em permitir que pessoas enviem mensagens suspeitas, imagens ou capturas de tela para receber orientações sobre possíveis tentativas de golpe.

Nesta etapa da Global Solution, o foco está no desenvolvimento da arquitetura de **Big Data e Data Integration**, responsável por integrar fontes públicas, processar informações e disponibilizar indicadores por meio de um dashboard interativo.

## 🎯 Objetivos

- Integrar diferentes fontes públicas de dados.
- Automatizar a obtenção e o processamento de informações.
- Organizar os dados em uma arquitetura estruturada de Big Data.
- Desenvolver consultas SQL para identificar padrões e tendências.
- Analisar a distribuição temporal das ocorrências.
- Integrar dados populacionais do IBGE, com destaque para a população idosa.
- Desenvolver um dashboard para visualização dos indicadores.
- Transformar dados públicos em informações úteis para estratégias de prevenção.

## 🚨 Problema identificado

O crescimento das fraudes digitais representa um problema relevante para a sociedade.

Golpes envolvendo falsas centrais bancárias, mensagens de familiares, links fraudulentos, transferências via Pix e solicitações de informações pessoais podem causar prejuízos financeiros e emocionais.

Pessoas idosas podem enfrentar dificuldades adicionais para identificar essas tentativas, principalmente quando os criminosos utilizam estratégias de urgência, medo ou confiança.

Diante desse cenário, o Golpe Zero busca utilizar a tecnologia para facilitar a prevenção e contribuir para a segurança digital.

## 💡 Solução proposta

O projeto possui duas frentes principais:

### 1. Inteligência e prevenção de golpes

A proposta futura da plataforma é permitir que o cidadão envie uma mensagem suspeita para receber uma análise automatizada, com identificação de possíveis sinais de fraude e orientações de segurança.

### 2. Big Data e inteligência de dados

Frente desenvolvida nesta atividade, responsável por:

- Integrar dados estatísticos da SSP-SP.
- Obter informações populacionais do IBGE.
- Organizar e processar os dados.
- Executar consultas analíticas utilizando SQL.
- Disponibilizar indicadores em um dashboard no Databricks.

---

# 🏗️ Arquitetura do projeto

A arquitetura utiliza ferramentas de integração, orquestração, processamento e visualização de dados.

### Tecnologias utilizadas

| Tecnologia | Aplicação |
|---|---|
| Python | Desenvolvimento e automação dos processos |
| Apache Airflow | Orquestração do pipeline de dados |
| Astro | Ambiente de desenvolvimento e deployment do Airflow |
| Databricks | Processamento, armazenamento e análise |
| SQL | Consultas e transformação de dados |
| API SIDRA (IBGE) | Integração de informações populacionais |
| SSP-SP | Fonte dos dados estatísticos de ocorrências |
| GitHub | Versionamento e documentação do projeto |

## 🔄 Funcionamento do pipeline

O fluxo de processamento foi desenvolvido para organizar a obtenção, transformação e disponibilização das informações.

### Etapas principais

**1. Coleta dos dados**

- Dados estatísticos da SSP-SP são disponibilizados em arquivos CSV e inseridos manualmente nesta versão do MVP.
- Dados populacionais são obtidos por meio da API SIDRA do IBGE.

**2. Orquestração com Airflow**

O Apache Airflow organiza as tarefas do pipeline, controla as dependências entre etapas e permite acompanhar a execução dos processos.

**3. Processamento no Databricks**

Os dados são encaminhados ao ambiente Databricks, onde são realizadas as transformações e consultas SQL.

**4. Organização dos dados**

A arquitetura utiliza o conceito de camadas Bronze, Prata e Ouro:

| Camada | Responsabilidade |
|---|---|
| Bronze | Preservação dos dados originais |
| Prata | Limpeza, tratamento e padronização |
| Ouro | Organização para análises e indicadores |

**5. Análise e visualização**

As informações processadas são utilizadas nas consultas analíticas e disponibilizadas no dashboard desenvolvido no Databricks.

---

# 📊 Fontes de dados

## SSP-SP — Secretaria da Segurança Pública de São Paulo

Fonte responsável pelos dados estatísticos relacionados às ocorrências registradas no estado de São Paulo.

Os arquivos são disponibilizados em formato CSV e utilizados para análises de:

- Naturezas de ocorrência.
- Quantidade de registros.
- Distribuição mensal.
- Participação percentual das categorias.
- Indicadores estatísticos relacionados a roubos.

Portal: https://www.ssp.sp.gov.br/estatistica

## IBGE — API SIDRA

O Sistema IBGE de Recuperação Automática (SIDRA) é utilizado para obter informações demográficas.

A integração permite consultar informações sobre a população idosa, considerando pessoas com 60 anos ou mais, e sua distribuição por faixa etária.

Documentação: https://apisidra.ibge.gov.br/

Portal: https://sidra.ibge.gov.br/

**Observação:** os indicadores que relacionam ocorrências gerais à população idosa possuem finalidade contextual e não comprovam que as vítimas das ocorrências sejam necessariamente pessoas com 60 anos ou mais.

---

# 📈 Consultas SQL desenvolvidas

Foram desenvolvidas cinco consultas principais para análise dos dados estatísticos.

| Consulta | Objetivo |
|---|---|
| 01 | Identificar as ocorrências com maior quantidade de registros |
| 02 | Identificar o mês com maior quantidade de ocorrências |
| 03 | Analisar o total de ocorrências por mês |
| 04 | Identificar as ocorrências mais frequentes em cada mês |
| 05 | Calcular a participação percentual de cada natureza no total |

Essas consultas permitem identificar padrões, acompanhar variações temporais e compreender a distribuição das ocorrências.

---

# 📊 Dashboard — Golpe Zero

Foi desenvolvido um dashboard interativo no Databricks, organizado em cinco áreas de análise.

### 01 — Inteligência Criminal (Dados gerais)

Visão geral dos indicadores estatísticos utilizados no projeto.

### 02 — Top 10 ocorrências

Apresentação das dez naturezas de ocorrência com maior quantidade de registros.

### 03 — Evolução Mensal

Análise da distribuição das ocorrências ao longo dos meses.

### 04 — População Idosa

Visualização dos dados populacionais de pessoas com 60 anos ou mais, obtidos por meio da API SIDRA do IBGE.

### 05 — Indicadores de Roubo

Análise estatística das ocorrências classificadas como roubo.

## 🔗 Acesso ao dashboard

[**Acessar Dashboard Golpe Zero no Databricks**](https://dbc-9aea2c4c-7f57.cloud.databricks.com/dashboardsv3/01f1dff5318b1cee851dafd41a32d572/published?o=7474653813850438)

Documentação específica: [`databricks/dashboard/README.md`](databricks/dashboard/README.md)

---

# ⚙️ Como executar o projeto

Para reproduzir o ambiente de desenvolvimento, são necessárias algumas ferramentas e configurações.

## Pré-requisitos

| Ferramenta | Finalidade |
|---|---|
| Python 3 | Execução dos scripts e desenvolvimento das DAGs |
| Docker | Ambiente de execução do Airflow, caso utilizado na configuração local |
| Astro CLI | Desenvolvimento e execução do projeto Airflow com Astro |
| Apache Airflow | Orquestração dos processos |
| Conta Databricks | Processamento e consultas SQL |
| Acesso à internet | Integração com a API SIDRA do IBGE |
| Git | Controle de versão do projeto |

## 1. Clonar o repositório

```bash
git clone https://github.com/AllanVI9/golpe-zero-database.git
```

Acesse a pasta:

```bash
cd golpe-zero-database
```

## 2. Configurar o ambiente Airflow

Caso o projeto utilize Astro CLI para execução local:

```bash
astro dev start
```

O comando inicia o ambiente local de desenvolvimento do Airflow.

Após a inicialização, acesse a interface disponibilizada pelo Astro CLI para acompanhar as DAGs.

**Importante:** utilize as configurações e dependências definidas nos arquivos do projeto. O comando acima pressupõe que a estrutura necessária do Astro esteja presente no repositório.

## 3. Configurar variáveis de ambiente

As configurações necessárias para execução devem ser definidas no ambiente, conforme os parâmetros utilizados pelas DAGs.

Não publique tokens, senhas, credenciais ou arquivos `.env` contendo informações sensíveis.

Utilize o arquivo `.env.example` apenas como modelo, caso ele esteja disponível no repositório.

## 4. Configurar o Databricks

É necessário possuir acesso a um workspace Databricks com as permissões necessárias para:

- Acessar os dados utilizados no projeto.
- Executar consultas SQL.
- Criar ou consultar tabelas.
- Visualizar o dashboard publicado.

Os notebooks e arquivos SQL exportados devem ser disponibilizados nas pastas correspondentes do repositório.

## 5. Disponibilizar os dados

Os arquivos CSV da SSP-SP devem ser obtidos diretamente na fonte oficial e disponibilizados conforme o fluxo de ingestão configurado.

Os dados populacionais são obtidos por meio da API SIDRA do IBGE.

**Observação:** a obtenção dos arquivos da SSP-SP permanece manual nesta versão do MVP. O processamento posterior está integrado ao pipeline.

---

# 📁 Estrutura do repositório

```text
golpe-zero/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── relatorio-golpe-zero.pdf
│   └── imagens/
│
├── airflow/
│   └── dags/
│       └── golpe_zero_dag.py
│
├── databricks/
│   ├── notebooks/
│   ├── sql/
│   │   ├── consulta_01.sql
│   │   ├── consulta_02.sql
│   │   ├── consulta_03.sql
│   │   ├── consulta_04.sql
│   │   └── consulta_05.sql
│   │
│   └── dashboard/
│       └── README.md
│
└── data/
    └── README.md
```

A estrutura representa a organização planejada para disponibilização dos artefatos do projeto. Os diretórios e arquivos devem ser preenchidos conforme os componentes efetivamente desenvolvidos.

---

# 🔒 Privacidade e LGPD

O projeto considera os princípios da Lei Geral de Proteção de Dados (LGPD).

As análises utilizam principalmente informações estatísticas e públicas, priorizando dados agregados e evitando a exposição de informações pessoais.

Não são necessários nomes, CPFs, telefones ou outros dados pessoais de vítimas para a realização das análises desenvolvidas nesta atividade.

---

# 🚀 Melhorias futuras

Como possibilidades de evolução do Golpe Zero, destacam-se:

- Automatizar a obtenção dos arquivos estatísticos da SSP-SP.
- Ampliar a integração com outras fontes públicas.
- Desenvolver análises geográficas mais detalhadas.
- Implementar inteligência artificial para análise de mensagens suspeitas.
- Incorporar visão computacional e OCR.
- Desenvolver alertas para familiares por meio do Modo Família.
- Criar um mapa de ocorrências com dados anonimizados.
- Integrar o dashboard às demais funcionalidades da plataforma.

---

# 👥 Integrantes

Projeto desenvolvido pelo grupo **4ESPG — Global Solution**.

| Integrante | RM |
|---|---|
| Allan Von Ivanov | 98705 |
| Levy Nascimento Junior | 98655 |
| Luiza Cristina Silva | 99367 |
| Rafael Autieri dos Anjos | 550885 |
| Rafael Carvalho Mattos | 99874 |

---

# 🎓 Disciplina

**Global Solution — 4ESPG**

**Área:** Big Data Architecture & Data Integration

**Projeto:** Golpe Zero

---

# 📚 Referências

- SECRETARIA DA SEGURANÇA PÚBLICA DO ESTADO DE SÃO PAULO (SSP-SP). Estatísticas Criminais. https://www.ssp.sp.gov.br/estatistica
- INSTITUTO BRASILEIRO DE GEOGRAFIA E ESTATÍSTICA (IBGE). Sistema IBGE de Recuperação Automática (SIDRA). https://sidra.ibge.gov.br/
- IBGE. API SIDRA. https://apisidra.ibge.gov.br/
- APACHE AIRFLOW. Documentação oficial. https://airflow.apache.org/docs/
- DATABRICKS. Documentação oficial. https://docs.databricks.com/

---

<p align="center">
  **GOLPE ZERO**
  <br>
  Tecnologia e dados a serviço da prevenção e da proteção das pessoas.
</p>

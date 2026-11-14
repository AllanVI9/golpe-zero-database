
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

import os
import json
import requests
import time
import hashlib

from urllib.parse import quote
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


# =====================================================
# CONFIGURAÇÕES GERAIS
# =====================================================

DATABRICKS_HOST = os.getenv("DATABRICKS_HOST", "").rstrip("/")
DATABRICKS_CLIENT_ID = os.getenv("DATABRICKS_CLIENT_ID")
DATABRICKS_CLIENT_SECRET = os.getenv("DATABRICKS_CLIENT_SECRET")

# ID do Job criado no Databricks
DATABRICKS_JOB_ID = os.getenv("DATABRICKS_JOB_ID")

# Monitoramento do Job
INTERVALO_VERIFICACAO = 20
TEMPO_MAXIMO_EXECUCAO = 2700  # 45 minutos

# Volume Unity Catalog
VOLUME_BASE = "/Volumes/workspace/default/chegada"

VOLUME_IBGE = f"{VOLUME_BASE}/ibge"
VOLUME_SSP = f"{VOLUME_BASE}/ssp"


# =====================================================
# SESSÃO HTTP COM RETRY AUTOMÁTICO
# =====================================================

def criar_sessao():

    session = requests.Session()

    retry = Retry(
        total=5,
        connect=5,
        read=3,
        backoff_factor=2,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET", "HEAD", "PUT", "POST"]
    )

    adapter = HTTPAdapter(max_retries=retry)

    session.mount("https://", adapter)
    session.mount("http://", adapter)

    return session


# =====================================================
# 1. VALIDAÇÃO DAS CREDENCIAIS
# =====================================================

def validar_configuracao():

    if not DATABRICKS_HOST:
        raise ValueError(
            "Variável DATABRICKS_HOST não configurada."
        )

    if not DATABRICKS_CLIENT_ID:
        raise ValueError(
            "Variável DATABRICKS_CLIENT_ID não configurada."
        )

    if not DATABRICKS_CLIENT_SECRET:
        raise ValueError(
            "Variável DATABRICKS_CLIENT_SECRET não configurada."
        )


# =====================================================
# 2. AUTENTICAÇÃO OAUTH
# =====================================================

def obter_token():

    validar_configuracao()

    session = criar_sessao()

    url = f"{DATABRICKS_HOST}/oidc/v1/token"

    print("Solicitando autenticação OAuth...")

    resposta = session.post(
        url,
        auth=(
            DATABRICKS_CLIENT_ID,
            DATABRICKS_CLIENT_SECRET
        ),
        data={
            "grant_type": "client_credentials",
            "scope": "all-apis"
        },
        headers={
            "Content-Type": "application/x-www-form-urlencoded"
        },
        timeout=(20, 60)
    )

    resposta.raise_for_status()

    token = resposta.json().get("access_token")

    if not token:
        raise ValueError(
            "Databricks não retornou access_token."
        )

    print("Autenticação OAuth concluída!")

    return token


# =====================================================
# 3. CRIAÇÃO DE DIRETÓRIOS NO VOLUME
# =====================================================

def criar_diretorio_volume(token, caminho):

    session = criar_sessao()

    caminho_url = quote(caminho, safe="/")

    url = (
        f"{DATABRICKS_HOST}/api/2.0/fs/directories"
        f"{caminho_url}"
    )

    resposta = session.put(
        url,
        headers={
            "Authorization": f"Bearer {token}"
        },
        timeout=(20, 60)
    )

    resposta.raise_for_status()

    print(f"Diretório disponível: {caminho}")


# =====================================================
# 4. ENVIO DE ARQUIVOS AO DATABRICKS
# =====================================================

def enviar_arquivo(token, caminho, conteudo):

    session = criar_sessao()

    caminho_url = quote(caminho, safe="/")

    url = (
        f"{DATABRICKS_HOST}/api/2.0/fs/files"
        f"{caminho_url}"
    )

    resposta = session.put(
        url,
        params={"overwrite": "true"},
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/octet-stream"
        },
        data=conteudo,
        timeout=(30, 180)
    )

    resposta.raise_for_status()

    print("Upload concluído!")
    print(f"Destino: {caminho}")
    print(f"Tamanho: {len(conteudo)} bytes")


# =====================================================
# 5. VERIFICAÇÃO DE ARQUIVO
# =====================================================

def verificar_arquivo(token, caminho):

    session = criar_sessao()

    caminho_url = quote(caminho, safe="/")

    url = (
        f"{DATABRICKS_HOST}/api/2.0/fs/files"
        f"{caminho_url}"
    )

    resposta = session.head(
        url,
        headers={
            "Authorization": f"Bearer {token}"
        },
        timeout=(20, 60)
    )

    resposta.raise_for_status()

    tamanho = resposta.headers.get(
        "Content-Length",
        "não informado"
    )

    print(f"Arquivo encontrado: {caminho}")
    print(f"Tamanho: {tamanho} bytes")

    return True


# =====================================================
# 6. COLETA SSP-SP
# =====================================================

def coletar_ssp(**context):

    data = context["ds"]

    url = "https://www.ssp.sp.gov.br/estatistica/dados-mensais"

    print("Iniciando coleta SSP-SP...")

    session = criar_sessao()

    resposta = session.get(
        url,
        timeout=(20, 120)
    )

    resposta.raise_for_status()

    if not resposta.content.strip():
        raise ValueError("SSP retornou resposta vazia.")

    token = obter_token()

    criar_diretorio_volume(token, VOLUME_SSP)

    nome_arquivo = f"ssp_{data}.html"
    caminho = f"{VOLUME_SSP}/{nome_arquivo}"

    enviar_arquivo(
        token,
        caminho,
        resposta.content
    )

    print("COLETA SSP-SP CONCLUÍDA!")


# =====================================================
# 7. COLETA IBGE - API SIDRA
# =====================================================

def coletar_ibge(**context):

    data = context["ds"]

    url = (
        "https://apisidra.ibge.gov.br/values/"
        "t/9514/n3/35/v/93/p/2022/"
        "c2/6794/c286/113635/"
        "c287/93095,93096,93097,93098,49108,49109,60040,60041,6653"
    )

    print("Iniciando coleta IBGE...")

    session = criar_sessao()

    resposta = session.get(
        url,
        timeout=(20, 60)
    )

    resposta.raise_for_status()

    dados_json = resposta.json()

    if not isinstance(dados_json, list):
        raise ValueError("Formato inválido retornado pelo IBGE.")

    if len(dados_json) < 2:
        raise ValueError("IBGE não retornou registros suficientes.")

    registros = dados_json[1:]

    campos_obrigatorios = ["D1N", "D3N", "D6N", "V"]

    for item in registros:

        if not isinstance(item, dict):
            raise ValueError(f"Registro inválido: {item}")

        for campo in campos_obrigatorios:
            if campo not in item:
                raise ValueError(
                    f"Campo {campo} não encontrado."
                )

        try:
            int(item["D3N"])
            int(item["V"])

        except (ValueError, TypeError) as err:
            raise ValueError(
                f"Valor numérico inválido: {item}"
            ) from err

    print(f"Registros recebidos: {len(registros)}")

    conteudo = json.dumps(
        dados_json,
        ensure_ascii=False,
        indent=2
    ).encode("utf-8")

    token = obter_token()

    criar_diretorio_volume(token, VOLUME_IBGE)

    nome_arquivo = f"ibge_{data}.json"
    caminho = f"{VOLUME_IBGE}/{nome_arquivo}"

    enviar_arquivo(
        token,
        caminho,
        conteudo
    )

    print("COLETA IBGE CONCLUÍDA!")


# =====================================================
# 8. CONFERÊNCIA DOS ARQUIVOS
# =====================================================

def conferir_chegada(**context):

    data = context["ds"]

    print("Iniciando conferência no Databricks...")

    token = obter_token()

    arquivos = [
        f"{VOLUME_SSP}/ssp_{data}.html",
        f"{VOLUME_IBGE}/ibge_{data}.json"
    ]

    for arquivo in arquivos:
        verificar_arquivo(token, arquivo)

    print("CONFERÊNCIA CONCLUÍDA!")


# =====================================================
# 9. DIAGNÓSTICO DOS ARQUIVOS
# =====================================================

def listar_arquivos(**context):

    data = context["ds"]

    print("VERIFICANDO ARQUIVOS NO UNITY CATALOG")

    token = obter_token()

    arquivos = [
        f"{VOLUME_IBGE}/ibge_{data}.json",
        f"{VOLUME_SSP}/ssp_{data}.html"
    ]

    for arquivo in arquivos:

        print(f"Verificando: {arquivo}")

        verificar_arquivo(token, arquivo)

    print("DIAGNÓSTICO CONCLUÍDO!")


# =====================================================
# 10. EXECUÇÃO DO JOB NO DATABRICKS
# =====================================================

def executar_job_databricks(**context):

    if not DATABRICKS_JOB_ID:
        raise ValueError(
            "Variável DATABRICKS_JOB_ID não configurada no Astro."
        )

    token = obter_token()

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    session = criar_sessao()

    # Identificador estável para evitar disparos duplicados
    # em caso de retry da tarefa pelo Airflow.
    identificador = (
        f"{context['dag'].dag_id}|{context['run_id']}"
    )

    idempotency_token = hashlib.sha256(
        identificador.encode("utf-8")
    ).hexdigest()

    # -------------------------------------------------
    # INICIAR JOB
    # -------------------------------------------------

    url_run = (
        f"{DATABRICKS_HOST}/api/2.2/jobs/run-now"
    )

    payload = {
        "job_id": int(DATABRICKS_JOB_ID),
        "idempotency_token": idempotency_token
    }

    print("Iniciando Job no Databricks...")
    print(f"Job ID: {DATABRICKS_JOB_ID}")

    resposta = session.post(
        url_run,
        headers=headers,
        json=payload,
        timeout=(20, 60)
    )

    resposta.raise_for_status()

    run_id = resposta.json().get("run_id")

    if not run_id:
        raise ValueError(
            "Databricks não retornou o run_id."
        )

    print(f"Job iniciado! Run ID: {run_id}")

    # -------------------------------------------------
    # MONITORAR EXECUÇÃO
    # -------------------------------------------------

    url_status = (
        f"{DATABRICKS_HOST}/api/2.2/jobs/runs/get"
    )

    inicio = time.monotonic()

    while True:

        if time.monotonic() - inicio > TEMPO_MAXIMO_EXECUCAO:
            raise TimeoutError(
                "Tempo máximo de 45 minutos excedido. "
                f"Run ID: {run_id}. Verifique o Databricks "
                "antes de tentar iniciar outra execução."
            )

        resposta = session.get(
            url_status,
            headers=headers,
            params={"run_id": run_id},
            timeout=(20, 60)
        )

        resposta.raise_for_status()

        dados = resposta.json()

        estado = dados.get("state", {})

        estado_execucao = estado.get(
            "life_cycle_state",
            "UNKNOWN"
        )

        resultado = estado.get(
            "result_state"
        )

        mensagem = estado.get(
            "state_message",
            ""
        )

        print(
            f"Estado do Job: {estado_execucao} | "
            f"Resultado: {resultado}"
        )

        # Job ainda em execução
        if estado_execucao in [
            "PENDING",
            "QUEUED",
            "RUNNING",
            "TERMINATING",
            "WAITING_FOR_RETRY",
            "BLOCKED"
        ]:
            time.sleep(INTERVALO_VERIFICACAO)
            continue

        # Job concluído
        if estado_execucao == "TERMINATED":

            if resultado == "SUCCESS":

                print("--------------------------------")
                print("JOB DATABRICKS CONCLUÍDO!")
                print(f"Run ID: {run_id}")
                print("Resultado: SUCCESS")
                print("--------------------------------")

                return run_id

            raise RuntimeError(
                f"Job Databricks terminou com resultado "
                f"{resultado}. Detalhes: {mensagem}. "
                f"Run ID: {run_id}"
            )

        # Outros estados terminais
        if estado_execucao in [
            "SKIPPED",
            "INTERNAL_ERROR"
        ]:
            raise RuntimeError(
                f"Job não foi concluído. "
                f"Estado: {estado_execucao}. "
                f"Detalhes: {mensagem}"
            )

        raise RuntimeError(
            f"Estado inesperado do Job: {estado_execucao}. "
            f"Detalhes: {mensagem}"
        )


# =====================================================
# CONFIGURAÇÃO DA DAG
# =====================================================

with DAG(

    dag_id="golpe_zero",

    description=(
        "Pipeline automatizado Golpe Zero: "
        "coleta SSP-SP e IBGE, upload e processamento "
        "SQL no Databricks"
    ),

    start_date=datetime(2026, 10, 1),

    schedule="@daily",

    catchup=False,

    max_active_runs=1,

    default_args={
        "retries": 2,
        "retry_delay": timedelta(minutes=2)
    },

    tags=[
        "golpe-zero",
        "big-data",
        "databricks"
    ]

) as dag:

    # TASK 1 - COLETA SSP
    tarefa_ssp = PythonOperator(
        task_id="coletar_ssp",
        python_callable=coletar_ssp
    )

    # TASK 2 - COLETA IBGE
    tarefa_ibge = PythonOperator(
        task_id="coletar_ibge",
        python_callable=coletar_ibge
    )

    # TASK 3 - CONFERÊNCIA
    tarefa_conferencia = PythonOperator(
        task_id="conferir_arquivos",
        python_callable=conferir_chegada
    )

    # TASK 4 - DIAGNÓSTICO
    tarefa_listar = PythonOperator(
        task_id="listar_arquivos",
        python_callable=listar_arquivos
    )

    # TASK 5 - PROCESSAMENTO SQL
    tarefa_processamento = PythonOperator(
        task_id="executar_processamento_databricks",
        python_callable=executar_job_databricks,
        execution_timeout=timedelta(minutes=50)
    )

    # DEPENDÊNCIAS

    [tarefa_ssp, tarefa_ibge] >> tarefa_conferencia

    tarefa_conferencia >> tarefa_listar

    tarefa_listar >> tarefa_processamento

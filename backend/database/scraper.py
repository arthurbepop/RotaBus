# -----------------------------------------------------------------------------
# Extrai horários de TODAS as linhas listadas para Santa Cruz do Sul no Moovit,
# incluindo sentidos alternativos, e grava em tabelas PostgreSQL
# (uma tabela por linha/sentido) via db.py.
# -----------------------------------------------------------------------------

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from webdriver_manager.chrome import ChromeDriverManager

import pandas as pd
import re, time
import os
from dotenv import load_dotenv
from backend.database.db import PostgresDB

# Carrega variáveis de ambiente do arquivo .env
load_dotenv("senha.env")




# Inicializa Selenium#
def inicializar_driver():
    opts = Options()
    opts.add_argument("--log-level=3")
    opts.add_argument("--start-maximized")
    opts.add_experimental_option("excludeSwitches", ["enable-logging"])

    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=opts
    )
    driver.get(
        "https://moovitapp.com/index/pt-br/"
        "transporte_p%C3%BAblico-lines-Santa_Cruz_do_Sul-4386-937743"
    )
    return driver, WebDriverWait(driver, 15)


def aceitar_cookies(wait):
    try:
        wait.until(
            EC.element_to_be_clickable(
                (By.ID, "onetrust-accept-btn-handler"))
        ).click()
    except TimeoutException:
        pass



# Abre a página de horários (link “Veja a programação completa…”)    #
def abrir_horarios(driver, wait):
    href = wait.until(
        EC.presence_of_element_located(
            (By.CSS_SELECTOR, "a.schedule-view-link.desktop"))
    ).get_attribute("href")
    driver.get(href)
    wait.until(
        EC.presence_of_element_located(
            (By.CSS_SELECTOR, "div.table-wrapper"))
    )



# Extrai toda a grade (tabela virtualizada)                          #
def extrair_tabela(driver, wait):
    wrapper = wait.until(
        EC.presence_of_element_located(
            (By.CSS_SELECTOR, "div.table-wrapper"))
    )
    tabela = wrapper.find_element(By.TAG_NAME, "table")
    headers = [
        th.text.strip()
        for th in tabela.find_elements(By.CSS_SELECTOR, "thead th")
    ]

    header_map, prox = {}, 1
    for h in headers:
        if h.lower().startswith("partida"):
            m = re.search(r"\d+", h)
            num = m.group() if m else str(prox)
            header_map[h] = f"Partida{num}"
            if not m:
                prox += 1
        else:
            header_map[h] = "Estação"

    dados, vistos = [], set()
    top_prev = -1
    while True:
        for tr in tabela.find_elements(By.CSS_SELECTOR, "tbody tr"):
            cels = [
                td.text.strip() for td in tr.find_elements(By.TAG_NAME, "td")
            ]
            if cels:
                est = cels[0]
                if est not in vistos:
                    dados.append(
                        {header_map[h]: v for h, v in zip(headers, cels)}
                    )
                    vistos.add(est)

        driver.execute_script(
            "arguments[0].scrollTop += arguments[0].clientHeight;", wrapper
        )
        time.sleep(0.15)
        top = wrapper.get_property("scrollTop")
        if top == top_prev:
            break
        top_prev = top

    return pd.DataFrame(dados)


# Lê título da página de horários → devolve (sentido, DataFrame)     #
def scraper_tabela(driver, wait):
    title = wait.until(
        EC.presence_of_element_located(
            (By.CSS_SELECTOR, "div.line-title h1.title"))
    ).text  # "01 - Bom Jesus Horários"
    sentido = re.search(r"\d+\s*-\s*(.*?)\s+Horários", title).group(1)
    df = extrair_tabela(driver, wait)
    print(f"  ↳ {sentido}: {len(df)} estações")
    return sentido, df

# Abre horários alternativos (sentidos) e extrai tabela para cada um  #
def abrir_horarios_alternativos(driver, wait, banco, linha_codigo):
    try:
        section = wait.until(
            EC.presence_of_element_located(
                (By.CSS_SELECTOR, "div.info-section.other-directions"))
        )
    except TimeoutException:
        print("  ⚠ Sem bloco de sentidos alternativos.")
        return

    links = []
    for li in section.find_elements(By.CSS_SELECTOR, "li.info-link"):
        anchors = li.find_elements(By.TAG_NAME, "a")
        if len(anchors) >= 2:
            links.append(anchors[1].get_attribute("href"))
    links = list(dict.fromkeys(links))

    if not links:
        print("  ⚠ Nenhum link de horários alternativos.")
        return

    print(f"  → {len(links)} sentidos alternativos encontrados.")
    for href in links:
        driver.get(href)
        aceitar_cookies(wait)
        sentido, df = scraper_tabela(driver, wait)
        banco.save_schedule(linha_codigo, sentido, df)
        driver.back()
        aceitar_cookies(wait)



# Fluxo principal                                                    #
def main():
    
    banco = PostgresDB()
    driver, wait = inicializar_driver()
    aceitar_cookies(wait)

    linhas_url = driver.current_url

    # snapshot (código, href) de TODAS as linhas
    wait.until(EC.presence_of_all_elements_located((By.CSS_SELECTOR, ".line-item a")))
    dados_linhas = [
        (
            el.find_element(
                By.CSS_SELECTOR, "div.mvf-wrapper span.text").text,
            el.get_attribute("href"),
        )
        for el in driver.find_elements(By.CSS_SELECTOR, ".line-item a")
    ]

    # percorre cada linha
    for codigo, href in dados_linhas:
        print(f"\n=== Linha {codigo} ===")
        driver.get(href)
        aceitar_cookies(wait)

        # sentido padrão
        abrir_horarios(driver, wait)
        sentido, df = scraper_tabela(driver, wait)
        banco.save_schedule(codigo, sentido, df)

        # sentidos alternativos
        driver.back()
        aceitar_cookies(wait)
        abrir_horarios_alternativos(driver, wait, banco, codigo)

        # volta à lista de linhas
        driver.get(linhas_url)
        aceitar_cookies(wait)

    print("\nTodas as linhas processadas.")
    input("Pressione Enter para fechar o navegador…")
    driver.quit()


if __name__ == "__main__":
    main()

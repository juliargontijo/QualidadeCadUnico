# Qualidade dos CEPs no CadÚnico – Municípios com +100 mil habitantes

### Descrição
Este projeto avalia a **qualidade dos dados de CEP** na base do **CadÚnico** para municípios brasileiros com mais de **100 mil habitantes**, comparando os CEPs informados pelas famílias com a base oficial de CEPs do **IBGE (CNEFE)**.  
O objetivo é identificar inconsistências, duplicidades, CEPs inexistentes e seu impacto na qualidade da informação por município.

---

## Bases Utilizadas
- **CEP_CNEFE_IBGE.csv** – tabela oficial de CEPs do IBGE  
- **FAMILIAS_ONUS_CEP.csv** – base CadÚnico com famílias e CEPs  
- **mun_100mil_ibge_2022** – municípios com população ≥ 100 mil habitantes  

---

##  Principais Etapas da Análise

### 1. Importação das bases
Leitura das tabelas do CadÚnico, IBGE e municípios com +100 mil habitantes, preservando CEPs como texto.

### 2. Verificação inicial
- Conferência do range populacional para garantir o arquivo correto  
- Verificação de duplicidade de CEPs no CadÚnico  
- Identificação de CEPs associados a múltiplos municípios  

### 3. Filtragem por municípios (>100 mil habitantes)
Separação entre:
- **cadunico_100mil:** famílias residentes em grandes municípios  
- **cadunico_menos:** municípios menores  

### 4. Identificação de CEPs inválidos
- CEPs com menos de 8 dígitos  
- CEPs inexistentes quando comparados ao CNEFE (IBGE)  
- Formatação dos CEPs com padding correto  
- Criação da lista `cep_forabase` contendo CEPs fora da base oficial  

### 5. Cálculo da qualidade por município
Para cada município:
- total de registros  
- total de erros (CEPs inexistentes)  
- **percentual de erro**  

Arquivo exportado: `qualidade_CEPS_porMunicipio.xlsx`

### 6. Erros por famílias
Cálculo da quantidade de famílias afetadas por CEPs inválidos e proporção em relação ao total.


---

## 👩‍💻 Autoria
**Júlia Rodrigues Gontijo**  
Fundação João Pinheiro (FJP) - 27/05/2025
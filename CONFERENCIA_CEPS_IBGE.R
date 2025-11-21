# Fundação João Pinheiro (FJP)
# Autora: Júlia Rodrigues Gontijo
# Data: 27/05/2025

# Objetivo:
# Este script realiza uma análise da qualidade dos dados de CEP na base CadÚnico (municípios com mais de 100 mil habitantes), verificando inconsistências em relação à base de CEPs do IBGE (CNEFE).
-------------------##carregar arquivos##---------------------------
# Definir o caminho da pasta
caminho_base <- "C:/Users/x20305282/Downloads"

ibge <- read.csv(
  file.path(caminho_base, "CEP_CNEFE_IBGE.csv"),
  sep = ";",
  fileEncoding = "latin1",
  colClasses = "character"
  )

# 2. Importar o arquivo onus_renda_CEP_municipios (1).csv
cadunico <- read.csv(
  file.path(caminho_base, "FAMILIAS_ONUS_CEP.csv"),
  sep = ",",
  fileEncoding = "latin1",  # (adicione se houver acentos ou cedilha no arquivo)
  colClasses = "character"
)

#Adicionar também tabela: mun_100mil_ibge_2022


---------------------------## Conferencia das tabelas ceps_m##------------------------
municipio <-mun_100mil_ibge_2022_2_
range(municipio$POP, na.rm = TRUE) # Conferir se é o arquivo certo verificando o range da população: 101041 à 11451999

# Comparar se todos os códigos de CD_MUN estão em CD_IBGE_CADASTRO
todos_presentes <- all(municipio$CD_MUN %in% cadunico$CD_IBGE_CADASTRO)


#vERIFICA SE EXISTEM CEPS DUPLICADOS
any(duplicated(cadunico$NU_CEP_LOGRADOURO_FAM))
sum(duplicated(cadunico$NU_CEP_LOGRADOURO_FAM))

any(duplicated(ibge$CEP))

# Existem 8 ceps duplicados na tabela do cad unico, eles são: 49100000 37655000  6420450 13820000  3559000  3682000  6806030 85580000
duplicados <- cadunico$NU_CEP_LOGRADOURO_FAM[duplicated(cadunico$NU_CEP_LOGRADOURO_FAM)]
unique(duplicados)

# Verificar quantos municípios diferentes estão associados a cada um dos ceps duplicados
library(dplyr)

ceps_multiplos_municipios <- cadunico %>%
  group_by(NU_CEP_LOGRADOURO_FAM) %>%
  summarise(qtd_municipios = n_distinct(CD_IBGE_CADASTRO)) %>%
  filter(qtd_municipios > 1)

# Visualizar os primeiros casos
head(ceps_multiplos_municipios)

# Exemplo para o primeiro CEP da lista acima
cep_exemplo <- ceps_multiplos_municipios$NU_CEP_LOGRADOURO_FAM[1]

cadunico %>%
  filter(NU_CEP_LOGRADOURO_FAM == cep_exemplo) %>%
  distinct(CD_IBGE_CADASTRO)

------------------##filtrar municipios com + de 100 mil habitantes da tabela do cadunico##--------------------
# Municípios com 100 mil ou mais habitantes
cod_municipios_100mil <- municipio$CD_MUN

# Separando as linhas do CadÚnico
cadunico_100mil <- cadunico[cadunico$CD_IBGE_CADASTRO %in% cod_municipios_100mil, ]
cadunico_menos  <- cadunico[!(cadunico$CD_IBGE_CADASTRO %in% cod_municipios_100mil), ]




------------------##filtrar ceps da base do caunico que não aparecem no IBGE--------------------

#Veridicando ceps distorcidos (menos de 8 caracteres)
# Criar uma coluna com o tamanho dos CEPs
familias <- cadunico_100mil %>%
  mutate(tamanho_cep = nchar(NU_CEP_LOGRADOURO_FAM))

# Verificar quantos têm tamanho menor que 8
familias %>%
  filter(tamanho_cep < 8) %>%
  count(tamanho_cep)

# Visualizar os CEPs problemáticos
familias %>%
  filter(tamanho_cep < 8) %>%
  select(NU_CEP_LOGRADOURO_FAM, tamanho_cep)

sum(familias$tamanho_cep < 8) #63311 (sem formatar)/ Formatado = 0 

# 8 ceps possuem 6 caracteres-> provavelmente escrito errado-> Possívelmente mesmo adicionando os 0 vão dar erro  

write_xlsx(familias, path = "cepsdistorcidos.xlsx")


# Formatar os vetores de CEP corretamente
cadunico_100mil[ nchar(as.character(cadunico_100mil$NU_CEP_LOGRADOURO_FAM)) != 8, ]
cadunico_100mil$NU_CEP_LOGRADOURO_FAM <- str_pad(as.character(cadunico_100mil$NU_CEP_LOGRADOURO_FAM), width = 8, side = "right", pad = "0")


# Descobrir os CEPs inválidos
cep_forabase <- setdiff(
  cadunico_100mil$NU_CEP_LOGRADOURO_FAM,
  ibge$CEP
)
# Resultado: quantidade de CEPs únicos fora da bas.Pode ser usada para a conferencia posterior (87665 ceps fora da base do IBGE)


-------------------------------## calculando qualidade dos dados (CEPS) por municipio##---------------------
library(dplyr)

#Criando tabela de erros do cadunico para comparação (Quantidade de familias fora da base)
cadunico_erros <- cadunico_100mil[cadunico_100mil$NU_CEP_LOGRADOURO_FAM %in% cep_forabase, ]

#Criando tabela que soma o total de ceps em cada municipio
tabela_total <- cadunico_100mil %>%
  group_by(CD_IBGE_CADASTRO) %>%
  summarise(total = n())

quali_municipio <- tabela_total %>%
  left_join(cadunico_erros, by = "CD_IBGE_CADASTRO") %>%
  mutate(
    erros = ifelse(is.na(erros), 0, erros),  # Preenche com zero onde não há erro
    pct_erro = round((erros / total) * 100, 2)
  )

# Adicionando o nome dos municipios a tabela 
quali_municipio <- quali_municipio %>%
  mutate(CD_IBGE_CADASTRO = as.character(CD_IBGE_CADASTRO)) %>%
  left_join(
    municipio %>%
      mutate(CD_MUN = as.character(CD_MUN)) %>%
      select(CD_MUN, MUN),
    by = c("CD_IBGE_CADASTRO" = "CD_MUN")
  ) %>%
  select(MUN, CD_IBGE_CADASTRO, total, erros, pct_erro) %>%
  arrange(desc(pct_erro))

-----------------------##Calculado erros por familia##---------------
total_geral_familias_100mil <- sum(as.numeric(cadunico_100mil$total), na.rm = TRUE)

# Total de famílias por município (em CEPs com erro)
familias_erro <- cadunico_erros %>%
  group_by(CD_IBGE_CADASTRO) %>%
  summarise(total_familias = sum(as.numeric(total), na.rm = TRUE)) %>%   # <- conversão aqui
  mutate(pct_erro_familias = round((total_familias / total_geral_familias_100mil) * 100, 2)) %>%
  arrange(desc(total_familias))

# Juntar com nomes dos municípios
familias_erro <- familias_erro %>%
  mutate(CD_IBGE_CADASTRO = as.character(CD_IBGE_CADASTRO)) %>%
  left_join(
    municipio %>%
      mutate(CD_MUN = as.character(CD_MUN)) %>%
      select(CD_MUN, MUN),
    by = c("CD_IBGE_CADASTRO" = "CD_MUN")
  ) %>%
  select(MUN, CD_IBGE_CADASTRO, total_familias, pct_erro_familias) %>%
  arrange(desc(total_familias))

sum(familias_100mil$total_familias, na.rm = TRUE) #2247776


#Total de familias em ceps com erro 
# Total geral de famílias nos municípios com +100 mil habitantes
# Calcular total de famílias com erro + porcentagem por município
familias_erro <- cadunico_erros %>%
  group_by(CD_IBGE_CADASTRO) %>%
  summarise(total_familias = sum(as.numeric(total), na.rm = TRUE)) %>%
  mutate(pct_erro_familias = round((total_familias / total_geral_familias_100mil) * 100, 2)) %>%
  arrange(desc(total_familias))

familias_erro <- familias_erro %>%
  mutate(CD_IBGE_CADASTRO = as.character(CD_IBGE_CADASTRO)) %>%
  left_join(
    municipio %>%
      mutate(CD_MUN = as.character(CD_MUN)) %>%
      select(CD_MUN, MUN),
    by = c("CD_IBGE_CADASTRO" = "CD_MUN")
  ) %>%
  select(MUN, CD_IBGE_CADASTRO, total_familias, pct_erro_familias) %>%
  arrange(desc(total_familias))


sum(familias_erro$total_familias, na.rm = TRUE) #110278 


tabela_erros_municipio_nome <- tabela_erros_municipio_nome %>%
  left_join(
    familias_erro %>%
      select(CD_IBGE_CADASTRO, total_familias, pct_erro_familias),
    by = "CD_IBGE_CADASTRO"
  )

library(writexl)
write_xlsx(quali_municipio, path = "qualidade_CEPS_porMunicipio.xlsx")
write_xlsx(cadunico_100mil, path = "cadunico_100mil.xlsx")
write_xlsx(cadunico_menos, path = "cadunico_menos.xlsx")



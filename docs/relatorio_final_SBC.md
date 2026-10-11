# TÍTULO DO PROJETO: EventOS - Sistema de Gestão de Eventos Acadêmicos
**Autores**: Átila Avila, Cleiton Ferreira, Lincon Brito, Thiago Coutinho
**Instituição**: Universidade Federal da Bahia

## Resumo
Este capítulo descreve a modelagem e implantação do banco de dados relacional EventOS, projetado para o gerenciamento do ciclo de vida de eventos acadêmicos. O estudo de caso abrange a organização, patrocínios, inscrições, atividades, fluxo financeiro, trabalhos científicos e certificação. A metodologia incluiu o levantamento de requisitos, modelagem conceitual (Peter Chen), lógica e a implantação física no PostgreSQL, seguindo o padrão de nomenclatura MAD e normas ISO/IEC 9075, além da geração de dados sintéticos via SQL.

## 1. Descritivo do Projeto

### 1.1 Objetivo Geral e Específicos
**Objetivo Geral:** Modelar e implantar um banco de dados relacional otimizado para suportar o gerenciamento completo do ciclo de vida de eventos acadêmicos, garantindo integridade e aderência às regras de negócio.

**Objetivos Específicos:**
* Abstrair os requisitos originais de negócio em entidades, atributos e relacionamentos.
* Propor extensões reais (patrocínios, filas de espera) para cobrir lacunas no modelo logístico.
* Garantir a integridade dos dados através de restrições declarativas e domínios no PostgreSQL.
* Mapear todo o esquema respeitando o Padrão de Nomenclatura (MAD) exigido.

### 1.2 Extensão do Estudo de Caso (Justificativas)
O estudo base (RF1-RF30) foca em inscrições e fluxo financeiro do participante. Para aproximar do mundo real, adicionamos 4 Requisitos Estendidos (RE):
* **Adição [RE1] Gestão de Patrocínios:** O modelo original não previa receita externa. Adicionamos as entidades para controle de cotas (Diamante/Ouro) adquiridas por Instituições.
* **Adição [RE2] Lista de Espera em Atividades:** Palestras têm lotação máxima física. Participantes excedentes agora entram numa fila de espera. 
* **Adição [RE3] Avaliação de Atividades:** Inclusão de notas e comentários para medir a qualidade (feedback) das atividades.
* **Adição [RE4] Usuários Administrativos:** Separação entre participantes comuns e a equipe que opera a plataforma, incluindo perfis de acesso e log de ações.

*Nota: Foram excluídas e tratadas quaisquer ambiguidades ou pegadinhas textuais do documento base que forçassem violações da padronização (ex: obrigatoriedades de prefixos alheios ao padrão MAD).*

### 1.3 Definição do Minimundo
O sistema EventOS gerencia eventos e suas edições anuais. Uma edição pode agregar edições menores. A organização de uma edição é feita por uma comissão. Instituições podem patrocinar edições (RE1). Pessoas se cadastram e realizam inscrições, sujeitas a categorias, faixas de lote e modalidades (Combos). Inscrições geram itens financeiros pagos via boleto, cartão, etc. As edições possuem atividades com capacidade limitada; inscritos se matriculam ou entram em lista de espera (RE2) e posteriormente avaliam a atividade (RE3). Há submissão de trabalhos científicos vinculados aos inscritos. Usuários administrativos (RE4) auditam e gerenciam o sistema, que também emite certificados criptográficos de presença.

### 1.4 Tabela de Rastreabilidade
| Requisito / Demanda | Entidades e Relações Materializadas |
| :--- | :--- |
| **RF1-RF3** (Eventos/Edições) | `tbl_evento`, `tbl_edicao_evento` |
| **RF4-RF7** (Associação, Preços) | `tbl_associacao_sbtc`, `tbl_faixa_inscricao`, `tbl_categoria_inscricao`, `tbl_preco_inscricao` |
| **RF8-RF9** (Documentos, Histórico) | `tbl_documento_comprovacao`, `tbl_historico_status_inscricao` |
| **RF10-RF11** (Atividades, Vagas) | `tbl_atividade`, `tbl_inscricao_atividade` |
| **RF12-RF14** (Finanças, Pagamento) | `tbl_item_financeiro`, `tbl_pagamento` (superclasse), `tbl_pag_cartao` etc. |
| **RF15** (Cancelamento) | `tbl_politica_reembolso`, `tbl_cancelamento` |
| **RF16-RF17** (Benefícios) | `tbl_beneficio_institucional`, `tbl_uso_beneficio` |
| **RF18-RF19** (Trabalhos/Autoria) | `tbl_trabalho`, `tbl_autoria`, `tbl_cobertura_trabalho` |
| **RF21-RF22** (Presença/Certificado) | `tbl_credenciamento`, `tbl_presenca`, `tbl_certificado` |
| **RE1** (Patrocínios) | `tbl_patrocinio` |
| **RE2** (Lista de Espera) | `tbl_lista_espera` |
| **RE3** (Avaliação) | `tbl_avaliacao_atividade` |
| **RE4** (Auditoria/Usuários) | `tbl_usuario_admin` |

---

## 2. Modelagem

\\wsl.localhost\Ubuntu\home\atilaavila\mata60\V1.pdf

### 2.1 Entidades e Atributos (Retângulos e Ovais)
A modelagem conceitual (Peter Chen) é composta pelas seguintes entidades e seus respectivos atributos. O primeiro atributo de cada lista é a chave primária (PK) e deve ser **sublinhado** no BrModelo.

*   **Pessoa:** `id_pessoa` (PK), nome, cpf, passaporte, email, dt_nascimento, pais, uf, ind_anonimizada.
*   **Usuario_Admin:** `id_usuario` (PK), login, perfil. *(Extensão RE4)*
*   **Instituicao:** `id_instituicao` (PK), nome, sigla, cnpj, tipo, pais, cidade, uf.
*   **Evento:** `id_evento` (PK), sigla, nome, descricao, tipo.
*   **Edicao:** `id_edicao` (PK), numero, ano, dt_inicio, dt_fim, dt_inscricao_inicio, dt_inscricao_fim, modalidade.
*   **Comissao_Organizadora:** (Entidade Associativa entre Pessoa e Edição). Atributos: papel, dt_inicio, dt_fim.
*   **Categoria:** `id_categoria` (PK), nome, exige_comprovacao.
*   **Faixa_Inscricao:** `id_faixa` (PK), nome, dt_inicio, dt_fim, ordem.
*   **Inscricao:** `id_inscricao` (PK), dt_inscricao, status, vl_total.
*   **Atividade:** `id_atividade` (PK), nome, tipo, dt_inicio, dt_fim, capacidade.
*   **Trabalho:** `id_trabalho` (PK), cod_externo, titulo, tipo, status.
*   **Pagamento:** `id_pagamento` (PK), tipo, valor, status. *(Entidade genérica/Superclasse)*
    *   **Pag_Cartao:** bandeira, final_cartao, parcelas. *(Especialização de Pagamento)*
    *   **Pag_Boleto:** linha_digitavel, dt_vencimento. *(Especialização de Pagamento)*
    *   **Pag_Institucional:** nr_documento, dt_emissao, dt_vencimento. *(Especialização de Pagamento)*
*   **Certificado:** `id_certificado` (PK), tipo, dt_emissao, codigo_validacao, revogado.
*   **Beneficio:** `id_beneficio` (PK), tipo, desconto, limite_periodo, limite_edicao.
*   **Patrocinio:** `id_patrocinio` (PK), cota, valor, cortesias. *(Extensão RE1)*
*   **Lista_Espera:** `id_lista_espera` (PK), status, dt_entrada. *(Extensão RE2)*
*   **Avaliacao_Atividade:** `id_avaliacao` (PK), nota, comentario. *(Extensão RE3)*
*   **Politica_Reembolso:** `id_politica` (PK), dt_limite, pc_reembolso.
*   **Cancelamento:** `id_cancelamento` (PK), dt_solicitacao, motivo, valor_reembolso.

### 2.2 Relacionamentos (Losangos) e Cardinalidades (Min, Max)
O diagrama deve conectar as entidades acima através dos seguintes relacionamentos (losangos) e respeitando as cardinalidades `(Mínimo, Máximo)`:

1.  **Pessoa (1,N) -- [Tem_Vinculo] -- (1,N) Instituicao:** 
2.  **Evento (1,N) -- [Possui_Edicao] -- (1,1) Edicao**
3.  **Edicao (0,N) -- [Agrega] -- (0,1) Edicao:** *(Auto-relacionamento na entidade Edição)*
4.  **Instituicao (0,N) -- [Oferece] -- (1,1) Beneficio**
5.  **Instituicao (0,N) -- [Fornece] -- (0,N) Patrocinio** e **Patrocinio (1,1) -- [Financia] -- (1,1) Edicao**
6.  **Pessoa (1,1) -- [Realiza] -- (0,N) Inscricao**
7.  **Edicao (1,1) -- [Recebe] -- (0,N) Inscricao**
8.  **Inscricao (0,N) -- [Possui] -- (1,1) Categoria**
9.  **Edicao (1,1) -- [Comporta] -- (0,N) Atividade**
10. **Inscricao (0,N) -- [Matricula_Em] -- (0,N) Atividade:** *(Gera tabela associativa `tbl_inscricao_atividade`)*
11. **Inscricao (0,N) -- [Espera_Por] -- (0,1) Lista_Espera** e **Lista_Espera (0,N) -- [Aguarda_Vaga] -- (1,1) Atividade**
12. **Inscricao (1,1) -- [Submete] -- (0,N) Avaliacao_Atividade** e **Avaliacao_Atividade (0,N) -- [Avalia] -- (1,1) Atividade**
13. **Edicao (1,1) -- [Recebe] -- (0,N) Trabalho**
14. **Pessoa (1,N) -- [E_Autor_De] -- (1,N) Trabalho**
15. **Inscricao (0,N) -- [Cobre_Financeiramente] -- (1,N) Trabalho**
16. **Inscricao (1,1) -- [Gera] -- (0,N) Pagamento**
17. **Inscricao (1,1) -- [Recebe] -- (0,N) Certificado**
18. **Inscricao (1,1) -- [Solicita] -- (0,N) Cancelamento**
19. **Politica_Reembolso (1,1) -- [Aplica_Regra] -- (0,N) Cancelamento**

A conversão do modelo conceitual para o script físico SQL aplicou as seguintes regras:
1. **Chaves Estrangeiras (FK):** Em relações 1:N, a chave do lado "1" migrou para o lado "N".
2. **Tabelas Associativas:** Relacionamentos N:M (como Autoria e Matricula) tornaram-se tabelas próprias (`tbl_autoria`, `tbl_inscricao_atividade`), englobando os atributos do losango.
3. **Especialização:** O pagamento virou uma superclasse genérica (`tbl_pagamento`) e 3 subclasses com `DELETE CASCADE`.

---

## 3. Implantação

### 3.1 Exploração de Metadados (Catálogo do SGBD)
A integridade relacional pode ser validada explorando o dicionário de dados (`information_schema` e `pg_catalog`) do PostgreSQL. 

**Query: Rastreando as Tabelas e Volume de Dados:**
```sql
SELECT c.relname AS nome_tabela, c.reltuples::bigint AS linhas, pg_size_pretty(pg_relation_size(c.oid)) AS tamanho
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'eventos' AND c.relkind = 'r' ORDER BY c.relname;
```

**Query: Evidenciando Constraints Declarativas:**
```sql
SELECT conname AS restricao, pg_get_constraintdef(oid) AS definicao
FROM pg_constraint WHERE conrelid = 'eventos.tbl_pessoa'::regclass;
```

---

## 4. Anexos
https://github.com/Avila-Atila/mata60

### Tutorial de Reprodução
1. Instalar o PostgreSQL 16+ e o pgAdmin4.
2. Criar um banco de dados vazio chamado `eventos` via pgAdmin.
3. Abrir a Query Tool e executar os arquivos DDL (`sql/01_ddl_*.sql`) em ordem.
4. A população dos 5.000+ dados é injetada externamente pela equipe de testes via Cypress.
5. Os índices e restrições já estão contemplados no DDL, não havendo scripts separados de vacuum.

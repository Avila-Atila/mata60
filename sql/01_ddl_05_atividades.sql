CREATE TABLE tbl_atividade (
    cp_id_atividade         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao               BIGINT NOT NULL,
    nm_atividade            VARCHAR(200) NOT NULL,
    tp_atividade            VARCHAR(20) NOT NULL,
    dt_inicio               TIMESTAMP NOT NULL,
    dt_fim                  TIMESTAMP NOT NULL,
    nr_capacidade           INTEGER,
    nr_vagas_ocupadas       INTEGER NOT NULL DEFAULT 0,
    ind_inscricao_adicional BOOLEAN NOT NULL DEFAULT FALSE,
    vl_atividade            dm_valor NOT NULL DEFAULT 0,
    nr_carga_horaria        SMALLINT,
    CONSTRAINT pk_atividade PRIMARY KEY (cp_id_atividade),
    CONSTRAINT fk_atividade_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_atividade_edicao UNIQUE (cp_id_atividade, ce_edicao),
    CONSTRAINT ck_atividade_tipo CHECK (tp_atividade IN ('PALESTRA','SESSAO_TECNICA','MINICURSO',
        'WORKSHOP','PAINEL','JANTAR','VISITA_TECNICA','SOCIAL','COMPETICAO')),
    CONSTRAINT ck_atividade_periodo CHECK (dt_fim > dt_inicio),
    CONSTRAINT ck_atividade_capacidade CHECK (nr_capacidade IS NULL OR nr_capacidade > 0),
    CONSTRAINT ck_atividade_ocupacao CHECK (nr_vagas_ocupadas >= 0
        AND (nr_capacidade IS NULL OR nr_vagas_ocupadas <= nr_capacidade)),
    CONSTRAINT ck_atividade_preco CHECK (ind_inscricao_adicional OR vl_atividade = 0)
);

CREATE TABLE tbl_atividade_categoria (
    ce_atividade        BIGINT NOT NULL,
    ce_categoria        BIGINT NOT NULL,
    CONSTRAINT pk_atividade_categoria PRIMARY KEY (ce_atividade, ce_categoria),
    CONSTRAINT fk_ativcat_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT fk_ativcat_categoria FOREIGN KEY (ce_categoria) REFERENCES tbl_categoria_inscricao (cp_id_categoria)
);

CREATE TABLE tbl_inscricao_atividade (
    cp_id_inscricao_atividade BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            BIGINT NOT NULL,
    ce_atividade            BIGINT NOT NULL,
    dt_inclusao             TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    vl_cobrado              dm_valor,
    status_item             VARCHAR(10) NOT NULL DEFAULT 'ATIVO',
    dt_cancelamento         TIMESTAMP,
    CONSTRAINT pk_inscricao_atividade PRIMARY KEY (cp_id_inscricao_atividade),
    CONSTRAINT fk_insativ_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_insativ_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT uq_inscricao_atividade UNIQUE (ce_inscricao, ce_atividade),
    CONSTRAINT ck_insativ_status CHECK (status_item IN ('ATIVO','CANCELADO')),
    CONSTRAINT ck_insativ_cancelamento CHECK (
        (status_item = 'CANCELADO' AND dt_cancelamento IS NOT NULL)
        OR (status_item = 'ATIVO' AND dt_cancelamento IS NULL))
);

CREATE TABLE tbl_lista_espera (
    cp_id_lista_espera  BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao        BIGINT NOT NULL,
    ce_atividade        BIGINT NOT NULL,
    dt_entrada          TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    status_espera       VARCHAR(12) NOT NULL DEFAULT 'AGUARDANDO',
    dt_convocacao       TIMESTAMP,
    CONSTRAINT pk_lista_espera PRIMARY KEY (cp_id_lista_espera),
    CONSTRAINT fk_espera_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_espera_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT uq_lista_espera UNIQUE (ce_inscricao, ce_atividade),
    CONSTRAINT ck_espera_status CHECK (status_espera IN ('AGUARDANDO','CONVOCADO','EXPIRADO','DESISTENTE')),
    CONSTRAINT ck_espera_convocacao CHECK (status_espera <> 'CONVOCADO' OR dt_convocacao IS NOT NULL)
);

CREATE TABLE tbl_avaliacao_atividade (
    cp_id_avaliacao             BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao_atividade      BIGINT NOT NULL,
    nr_nota                     SMALLINT NOT NULL,
    ds_comentario               VARCHAR(1000),
    dt_avaliacao                TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT pk_avaliacao_atividade PRIMARY KEY (cp_id_avaliacao),
    CONSTRAINT fk_avaliacao_insativ FOREIGN KEY (ce_inscricao_atividade)
        REFERENCES tbl_inscricao_atividade (cp_id_inscricao_atividade),
    CONSTRAINT uq_avaliacao UNIQUE (ce_inscricao_atividade),
    CONSTRAINT ck_avaliacao_nota CHECK (nr_nota BETWEEN 1 AND 5)
);

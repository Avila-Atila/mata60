CREATE TABLE tbl_trabalho (
    cp_id_trabalho          BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao               BIGINT NOT NULL,
    cd_trabalho_externo     VARCHAR(40) NOT NULL,
    titulo_trabalho         VARCHAR(500) NOT NULL,
    tp_trabalho             VARCHAR(20) NOT NULL,
    status_trabalho         VARCHAR(12) NOT NULL DEFAULT 'ACEITO',
    CONSTRAINT pk_trabalho PRIMARY KEY (cp_id_trabalho),
    CONSTRAINT fk_trabalho_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_trabalho_externo UNIQUE (ce_edicao, cd_trabalho_externo),
    CONSTRAINT uq_trabalho_edicao UNIQUE (cp_id_trabalho, ce_edicao),
    CONSTRAINT ck_trabalho_tipo CHECK (tp_trabalho IN ('ARTIGO_COMPLETO','ARTIGO_CURTO','RESUMO_EXPANDIDO','POSTER','DEMO')),
    CONSTRAINT ck_trabalho_status CHECK (status_trabalho IN ('ACEITO','PUBLICADO','RETIRADO'))
);

CREATE TABLE tbl_autoria (
    ce_trabalho                 BIGINT NOT NULL,
    ce_pessoa                   BIGINT NOT NULL,
    nr_ordem_autoria            SMALLINT NOT NULL,
    ind_autor_correspondente    BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_autoria PRIMARY KEY (ce_trabalho, ce_pessoa),
    CONSTRAINT fk_autoria_trabalho FOREIGN KEY (ce_trabalho) REFERENCES tbl_trabalho (cp_id_trabalho),
    CONSTRAINT fk_autoria_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT uq_autoria_ordem UNIQUE (ce_trabalho, nr_ordem_autoria),
    CONSTRAINT ck_autoria_ordem CHECK (nr_ordem_autoria >= 1)
);

CREATE TABLE tbl_cobertura_trabalho (
    cp_id_cobertura     BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_trabalho         BIGINT NOT NULL,
    ce_inscricao        BIGINT NOT NULL,
    ce_edicao           BIGINT NOT NULL,
    dt_cobertura        TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    ind_excedente       BOOLEAN NOT NULL DEFAULT FALSE,
    status_cobertura    VARCHAR(10) NOT NULL DEFAULT 'ATIVA',
    CONSTRAINT pk_cobertura_trabalho PRIMARY KEY (cp_id_cobertura),
    CONSTRAINT fk_cobertura_trabalho FOREIGN KEY (ce_trabalho, ce_edicao)
        REFERENCES tbl_trabalho (cp_id_trabalho, ce_edicao),
    CONSTRAINT fk_cobertura_inscricao FOREIGN KEY (ce_inscricao, ce_edicao)
        REFERENCES tbl_inscricao (cp_id_inscricao, ce_edicao),
    CONSTRAINT uq_cobertura UNIQUE (ce_trabalho, ce_inscricao),
    CONSTRAINT ck_cobertura_status CHECK (status_cobertura IN ('ATIVA','CANCELADA'))
);

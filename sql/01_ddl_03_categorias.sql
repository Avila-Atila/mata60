CREATE TABLE tbl_categoria_inscricao (
    cp_id_categoria         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao               BIGINT NOT NULL,
    nm_categoria            VARCHAR(100) NOT NULL,
    ds_categoria            TEXT,
    ind_exige_comprovacao   BOOLEAN NOT NULL DEFAULT FALSE,
    ind_categoria_autor     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_categoria_inscricao PRIMARY KEY (cp_id_categoria),
    CONSTRAINT fk_categoria_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_categoria_nome UNIQUE (ce_edicao, nm_categoria),
    CONSTRAINT uq_categoria_edicao UNIQUE (cp_id_categoria, ce_edicao)
);

CREATE TABLE tbl_acesso_categoria_edicao (
    ce_categoria        BIGINT NOT NULL,
    ce_edicao           BIGINT NOT NULL,
    CONSTRAINT pk_acesso_categoria_edicao PRIMARY KEY (ce_categoria, ce_edicao),
    CONSTRAINT fk_acesso_categoria FOREIGN KEY (ce_categoria) REFERENCES tbl_categoria_inscricao (cp_id_categoria),
    CONSTRAINT fk_acesso_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao)
);

CREATE TABLE tbl_faixa_inscricao (
    cp_id_faixa         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao           BIGINT NOT NULL,
    nm_faixa            VARCHAR(60) NOT NULL,
    nr_ordem            SMALLINT NOT NULL,
    dt_inicio_faixa     TIMESTAMP NOT NULL,
    dt_fim_faixa        TIMESTAMP NOT NULL,
    CONSTRAINT pk_faixa_inscricao PRIMARY KEY (cp_id_faixa),
    CONSTRAINT fk_faixa_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_faixa_nome UNIQUE (ce_edicao, nm_faixa),
    CONSTRAINT uq_faixa_ordem UNIQUE (ce_edicao, nr_ordem),
    CONSTRAINT uq_faixa_edicao UNIQUE (cp_id_faixa, ce_edicao),
    CONSTRAINT ck_faixa_periodo CHECK (dt_fim_faixa > dt_inicio_faixa)
);

CREATE TABLE tbl_modalidade_inscricao (
    cp_id_modalidade    SMALLINT GENERATED ALWAYS AS IDENTITY,
    cd_modalidade       VARCHAR(20) NOT NULL,
    nm_modalidade       VARCHAR(100) NOT NULL,
    tp_associacao       VARCHAR(10) NOT NULL,
    CONSTRAINT pk_modalidade_inscricao PRIMARY KEY (cp_id_modalidade),
    CONSTRAINT uq_modalidade_codigo UNIQUE (cd_modalidade),
    CONSTRAINT ck_modalidade_associacao CHECK (tp_associacao IN ('NENHUMA','NOVA','RENOVACAO'))
);

CREATE TABLE tbl_preco_inscricao (
    cp_id_preco         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao           BIGINT NOT NULL,
    ce_categoria        BIGINT NOT NULL,
    ce_faixa            BIGINT NOT NULL,
    ce_modalidade       SMALLINT NOT NULL,
    ind_preco_associado BOOLEAN NOT NULL,
    vl_inscricao        dm_valor NOT NULL,
    vl_associacao       dm_valor NOT NULL DEFAULT 0,
    dt_inicio_vigencia  TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    dt_fim_vigencia     TIMESTAMP,
    CONSTRAINT pk_preco_inscricao PRIMARY KEY (cp_id_preco),
    CONSTRAINT fk_preco_categoria FOREIGN KEY (ce_categoria, ce_edicao)
        REFERENCES tbl_categoria_inscricao (cp_id_categoria, ce_edicao),
    CONSTRAINT fk_preco_faixa FOREIGN KEY (ce_faixa, ce_edicao)
        REFERENCES tbl_faixa_inscricao (cp_id_faixa, ce_edicao),
    CONSTRAINT fk_preco_modalidade FOREIGN KEY (ce_modalidade) REFERENCES tbl_modalidade_inscricao (cp_id_modalidade),
    CONSTRAINT uq_preco_dimensoes UNIQUE (ce_categoria, ce_faixa, ce_modalidade, ind_preco_associado, dt_inicio_vigencia),
    CONSTRAINT uq_preco_categoria UNIQUE (cp_id_preco, ce_categoria),
    CONSTRAINT ck_preco_vigencia CHECK (dt_fim_vigencia IS NULL OR dt_fim_vigencia > dt_inicio_vigencia)
);

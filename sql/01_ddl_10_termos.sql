CREATE TABLE tbl_termo (
    cp_id_termo         BIGINT GENERATED ALWAYS AS IDENTITY,
    nm_termo            VARCHAR(100) NOT NULL,
    nr_versao           VARCHAR(10) NOT NULL,
    ds_termo            TEXT NOT NULL,
    ind_obrigatorio     BOOLEAN NOT NULL DEFAULT FALSE,
    dt_inicio_vigencia  TIMESTAMP NOT NULL,
    dt_fim_vigencia     TIMESTAMP,
    CONSTRAINT pk_termo PRIMARY KEY (cp_id_termo),
    CONSTRAINT uq_termo_versao UNIQUE (nm_termo, nr_versao),
    CONSTRAINT ck_termo_vigencia CHECK (dt_fim_vigencia IS NULL OR dt_fim_vigencia > dt_inicio_vigencia)
);

CREATE TABLE tbl_aceite_termo (
    cp_id_aceite        BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_termo            BIGINT NOT NULL,
    ce_pessoa           BIGINT NOT NULL,
    ce_inscricao        BIGINT,
    ind_aceito          BOOLEAN NOT NULL,
    dt_resposta         TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT pk_aceite_termo PRIMARY KEY (cp_id_aceite),
    CONSTRAINT fk_aceite_termo FOREIGN KEY (ce_termo) REFERENCES tbl_termo (cp_id_termo),
    CONSTRAINT fk_aceite_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_aceite_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT uq_aceite_inscricao UNIQUE (ce_termo, ce_inscricao)
);

CREATE TABLE tbl_credenciamento (
    cp_id_credenciamento    BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            BIGINT NOT NULL,
    dt_credenciamento       TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    ce_usuario_responsavel  BIGINT,
    ds_local                VARCHAR(100),
    CONSTRAINT pk_credenciamento PRIMARY KEY (cp_id_credenciamento),
    CONSTRAINT fk_credenciamento_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_credenciamento_usuario FOREIGN KEY (ce_usuario_responsavel) REFERENCES tbl_usuario_admin (cp_id_usuario),
    CONSTRAINT uq_credenciamento UNIQUE (ce_inscricao)
);

CREATE TABLE tbl_presenca (
    cp_id_presenca          BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            BIGINT NOT NULL,
    ce_atividade            BIGINT,
    dt_registro             TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    tp_origem_registro      VARCHAR(10) NOT NULL DEFAULT 'QRCODE',
    CONSTRAINT pk_presenca PRIMARY KEY (cp_id_presenca),
    CONSTRAINT fk_presenca_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_presenca_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT uq_presenca UNIQUE (ce_inscricao, ce_atividade, dt_registro),
    CONSTRAINT ck_presenca_origem CHECK (tp_origem_registro IN ('QRCODE','RFID','MANUAL'))
);

CREATE TABLE tbl_certificado (
    cp_id_certificado           BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_pessoa                   BIGINT NOT NULL,
    ce_edicao                   BIGINT NOT NULL,
    ce_atividade                BIGINT,
    ce_trabalho                 BIGINT,
    tp_certificado              VARCHAR(25) NOT NULL,
    dt_emissao                  TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    cd_validacao                VARCHAR(36) NOT NULL ,
    nr_emissao                  SMALLINT NOT NULL DEFAULT 1,
    ce_certificado_substituido  BIGINT,
    ds_criterio_aplicado        VARCHAR(300),
    ind_revogado                BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_certificado PRIMARY KEY (cp_id_certificado),
    CONSTRAINT fk_certificado_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_certificado_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT fk_certificado_atividade FOREIGN KEY (ce_atividade, ce_edicao)
        REFERENCES tbl_atividade (cp_id_atividade, ce_edicao),
    CONSTRAINT fk_certificado_trabalho FOREIGN KEY (ce_trabalho, ce_edicao)
        REFERENCES tbl_trabalho (cp_id_trabalho, ce_edicao),
    CONSTRAINT fk_certificado_substituido FOREIGN KEY (ce_certificado_substituido)
        REFERENCES tbl_certificado (cp_id_certificado),
    CONSTRAINT uq_certificado_validacao UNIQUE (cd_validacao),
    CONSTRAINT uq_certificado_finalidade UNIQUE
        (ce_pessoa, ce_edicao, tp_certificado, ce_atividade, ce_trabalho, nr_emissao),
    CONSTRAINT ck_certificado_tipo CHECK (
        (tp_certificado = 'PARTICIPACAO' AND ce_atividade IS NULL AND ce_trabalho IS NULL)
        OR (tp_certificado = 'ATIVIDADE' AND ce_atividade IS NOT NULL AND ce_trabalho IS NULL)
        OR (tp_certificado = 'APRESENTACAO_TRABALHO' AND ce_trabalho IS NOT NULL AND ce_atividade IS NULL)
        OR (tp_certificado = 'ORGANIZACAO' AND ce_atividade IS NULL AND ce_trabalho IS NULL)),
    CONSTRAINT ck_certificado_reemissao CHECK (
        (nr_emissao = 1 AND ce_certificado_substituido IS NULL)
        OR (nr_emissao > 1 AND ce_certificado_substituido IS NOT NULL))
);

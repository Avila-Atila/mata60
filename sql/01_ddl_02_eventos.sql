CREATE TABLE tbl_evento (
    cp_id_evento        BIGINT GENERATED ALWAYS AS IDENTITY,
    sg_evento           VARCHAR(20) NOT NULL,
    nm_evento           VARCHAR(200) NOT NULL,
    ds_evento           TEXT,
    tp_evento           VARCHAR(20) NOT NULL,
    CONSTRAINT pk_evento PRIMARY KEY (cp_id_evento),
    CONSTRAINT uq_evento_sigla UNIQUE (sg_evento),
    CONSTRAINT ck_evento_tipo CHECK (tp_evento IN
        ('CONGRESSO','SIMPOSIO','WORKSHOP','ESCOLA','COMPETICAO','CONFERENCIA','OUTRO'))
);

CREATE TABLE tbl_edicao_evento (
    cp_id_edicao               BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_evento                  BIGINT NOT NULL,
    ce_edicao_agregadora       BIGINT,
    nr_edicao                  INTEGER,
    ano_edicao                 SMALLINT NOT NULL,
    dt_inicio_evento           DATE NOT NULL,
    dt_fim_evento              DATE NOT NULL,
    dt_inicio_inscricao        TIMESTAMP NOT NULL,
    dt_fim_inscricao           TIMESTAMP NOT NULL,
    modalidade_evento          VARCHAR(10) NOT NULL,
    cidade_evento              VARCHAR(100),
    uf_evento                  dm_uf,
    pais_evento                dm_pais NOT NULL DEFAULT 'BR',
    ind_exige_autor_inscrito   BOOLEAN NOT NULL DEFAULT TRUE,
    qt_max_trabalhos_inscricao SMALLINT NOT NULL DEFAULT 1,
    vl_taxa_trabalho_extra     dm_valor NOT NULL DEFAULT 0,
    tp_criterio_certificado    VARCHAR(20) NOT NULL DEFAULT 'CREDENCIAMENTO',
    pc_frequencia_minima       dm_percentual,
    CONSTRAINT pk_edicao_evento PRIMARY KEY (cp_id_edicao),
    CONSTRAINT fk_edicao_evento FOREIGN KEY (ce_evento) REFERENCES tbl_evento (cp_id_evento),
    CONSTRAINT fk_edicao_agregadora FOREIGN KEY (ce_edicao_agregadora) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_edicao_ano UNIQUE (ce_evento, ano_edicao),
    CONSTRAINT uq_edicao_numero UNIQUE (ce_evento, nr_edicao),
    CONSTRAINT ck_edicao_modalidade CHECK (modalidade_evento IN ('PRESENCIAL','REMOTO','HIBRIDO')),
    CONSTRAINT ck_edicao_periodo CHECK (dt_fim_evento >= dt_inicio_evento),
    CONSTRAINT ck_edicao_periodo_inscricao CHECK (dt_fim_inscricao > dt_inicio_inscricao
        AND CAST(dt_inicio_inscricao AS DATE) <= dt_fim_evento),
    CONSTRAINT ck_edicao_ano CHECK (EXTRACT(YEAR FROM dt_inicio_evento) = ano_edicao),
    CONSTRAINT ck_edicao_uf CHECK (uf_evento IS NULL OR pais_evento = 'BR'),
    CONSTRAINT ck_edicao_nao_agrega_si CHECK (ce_edicao_agregadora <> cp_id_edicao),
    CONSTRAINT ck_edicao_max_trabalhos CHECK (qt_max_trabalhos_inscricao >= 0),
    CONSTRAINT ck_edicao_criterio CHECK (
        (tp_criterio_certificado = 'CREDENCIAMENTO')
        OR (tp_criterio_certificado = 'FREQUENCIA_MINIMA' AND pc_frequencia_minima IS NOT NULL))
);

CREATE TABLE tbl_papel_organizacao (
    cp_id_papel         SMALLINT GENERATED ALWAYS AS IDENTITY,
    nm_papel            VARCHAR(60) NOT NULL,
    ds_papel            TEXT,
    CONSTRAINT pk_papel_organizacao PRIMARY KEY (cp_id_papel),
    CONSTRAINT uq_papel_nome UNIQUE (nm_papel)
);

CREATE TABLE tbl_comissao_organizadora (
    ce_edicao           BIGINT NOT NULL,
    ce_pessoa           BIGINT NOT NULL,
    ce_papel            SMALLINT NOT NULL,
    dt_inicio_atuacao   DATE NOT NULL,
    dt_fim_atuacao      DATE,
    CONSTRAINT pk_comissao_organizadora PRIMARY KEY (ce_edicao, ce_pessoa, ce_papel),
    CONSTRAINT fk_comissao_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT fk_comissao_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_comissao_papel FOREIGN KEY (ce_papel) REFERENCES tbl_papel_organizacao (cp_id_papel),
    CONSTRAINT ck_comissao_periodo CHECK (dt_fim_atuacao IS NULL OR dt_fim_atuacao >= dt_inicio_atuacao)
);

CREATE TABLE tbl_patrocinio (
    cp_id_patrocinio        BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao               BIGINT NOT NULL,
    ce_instituicao          BIGINT NOT NULL,
    tp_cota                 VARCHAR(10) NOT NULL,
    vl_patrocinio           dm_valor NOT NULL,
    qt_inscricoes_cortesia  SMALLINT NOT NULL DEFAULT 0,
    dt_contrato             DATE NOT NULL,
    CONSTRAINT pk_patrocinio PRIMARY KEY (cp_id_patrocinio),
    CONSTRAINT fk_patrocinio_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT fk_patrocinio_instituicao FOREIGN KEY (ce_instituicao) REFERENCES tbl_instituicao (cp_id_instituicao),
    CONSTRAINT uq_patrocinio UNIQUE (ce_edicao, ce_instituicao),
    CONSTRAINT ck_patrocinio_cota CHECK (tp_cota IN ('DIAMANTE','OURO','PRATA','BRONZE','APOIO')),
    CONSTRAINT ck_patrocinio_cortesia CHECK (qt_inscricoes_cortesia >= 0)
);

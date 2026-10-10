CREATE TABLE tbl_pessoa (
    cp_id_pessoa        BIGINT GENERATED ALWAYS AS IDENTITY,
    nm_pessoa           VARCHAR(200) NOT NULL,
    cpf_pessoa          CHAR(11),
    passaporte_pessoa   VARCHAR(30),
    email_pessoa        VARCHAR(254) NOT NULL,
    dt_nascimento       DATE,
    pais_pessoa         dm_pais NOT NULL DEFAULT 'BR',
    uf_pessoa           dm_uf,
    dt_cadastro         TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    ind_anonimizada     BOOLEAN NOT NULL DEFAULT FALSE,
    dt_anonimizacao     TIMESTAMP,
    CONSTRAINT pk_pessoa PRIMARY KEY (cp_id_pessoa),
    CONSTRAINT uq_pessoa_cpf UNIQUE (cpf_pessoa),
    CONSTRAINT uq_pessoa_email UNIQUE (email_pessoa),
    CONSTRAINT uq_pessoa_passaporte UNIQUE (pais_pessoa, passaporte_pessoa),
    CONSTRAINT ck_pessoa_documento CHECK (
        ind_anonimizada
        OR (pais_pessoa = 'BR' AND cpf_pessoa IS NOT NULL)
        OR (pais_pessoa <> 'BR' AND (cpf_pessoa IS NOT NULL OR passaporte_pessoa IS NOT NULL))),
    CONSTRAINT ck_pessoa_uf CHECK (uf_pessoa IS NULL OR pais_pessoa = 'BR'),
    CONSTRAINT ck_pessoa_nascimento CHECK (dt_nascimento > DATE '1900-01-01'),
    CONSTRAINT ck_pessoa_anonimizacao CHECK (
        (ind_anonimizada AND dt_anonimizacao IS NOT NULL)
        OR (NOT ind_anonimizada AND dt_anonimizacao IS NULL))
);

CREATE TABLE tbl_usuario_admin (
    cp_id_usuario       BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_pessoa           BIGINT NOT NULL,
    nm_login            VARCHAR(60) NOT NULL,
    tp_perfil           VARCHAR(20) NOT NULL,
    ind_ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    dt_criacao          TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT pk_usuario_admin PRIMARY KEY (cp_id_usuario),
    CONSTRAINT uq_usuario_admin_login UNIQUE (nm_login),
    CONSTRAINT uq_usuario_admin_pessoa UNIQUE (ce_pessoa),
    CONSTRAINT fk_usuario_admin_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT ck_usuario_admin_perfil CHECK (tp_perfil IN
        ('ADMINISTRADOR','SECRETARIA','FINANCEIRO','CREDENCIAMENTO','AUDITOR'))
);

CREATE TABLE tbl_instituicao (
    cp_id_instituicao   BIGINT GENERATED ALWAYS AS IDENTITY,
    nm_instituicao      VARCHAR(200) NOT NULL,
    sg_instituicao      VARCHAR(30) NOT NULL,
    cnpj_instituicao    CHAR(14),
    tp_instituicao      VARCHAR(20) NOT NULL,
    ind_associada_sbtc  BOOLEAN NOT NULL DEFAULT FALSE,
    pais_instituicao    dm_pais NOT NULL DEFAULT 'BR',
    cidade_instituicao  VARCHAR(100),
    uf_instituicao      dm_uf,
    CONSTRAINT pk_instituicao PRIMARY KEY (cp_id_instituicao),
    CONSTRAINT uq_instituicao_cnpj UNIQUE (cnpj_instituicao),
    CONSTRAINT uq_instituicao_nome UNIQUE (nm_instituicao, pais_instituicao),
    CONSTRAINT ck_instituicao_tipo CHECK (tp_instituicao IN
        ('UNIVERSIDADE','INSTITUTO_FEDERAL','EMPRESA','ORGAO_PUBLICO','ONG','OUTRA')),
    CONSTRAINT ck_instituicao_uf CHECK (uf_instituicao IS NULL OR pais_instituicao = 'BR')
);

CREATE TABLE tbl_vinculo_institucional (
    cp_id_vinculo       BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_pessoa           BIGINT NOT NULL,
    ce_instituicao      BIGINT NOT NULL,
    tp_vinculo          VARCHAR(20) NOT NULL,
    dt_inicio_vinculo   DATE NOT NULL,
    dt_fim_vinculo      DATE,
    CONSTRAINT pk_vinculo_institucional PRIMARY KEY (cp_id_vinculo),
    CONSTRAINT fk_vinculo_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_vinculo_instituicao FOREIGN KEY (ce_instituicao) REFERENCES tbl_instituicao (cp_id_instituicao),
    CONSTRAINT uq_vinculo UNIQUE (ce_pessoa, ce_instituicao, dt_inicio_vinculo),
    CONSTRAINT ck_vinculo_tipo CHECK (tp_vinculo IN
        ('DISCENTE_GRADUACAO','DISCENTE_POS','DOCENTE','SERVIDOR','EMPREGADO','PESQUISADOR','OUTRO')),
    CONSTRAINT ck_vinculo_periodo CHECK (dt_fim_vinculo IS NULL OR dt_fim_vinculo >= dt_inicio_vinculo)
);

CREATE TABLE tbl_associacao_sbtc (
    cp_id_associacao    BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_pessoa           BIGINT NOT NULL,
    tp_associacao       VARCHAR(20) NOT NULL,
    dt_inicio_vigencia  DATE NOT NULL,
    dt_fim_vigencia     DATE NOT NULL,
    vl_anuidade         dm_valor NOT NULL,
    ce_inscricao_origem BIGINT,
    dt_registro         TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT pk_associacao_sbtc PRIMARY KEY (cp_id_associacao),
    CONSTRAINT fk_associacao_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT uq_associacao_inicio UNIQUE (ce_pessoa, dt_inicio_vigencia),
    CONSTRAINT ck_associacao_tipo CHECK (tp_associacao IN ('ESTUDANTE','PROFISSIONAL','EFETIVO','HONORARIO')),
    CONSTRAINT ck_associacao_periodo CHECK (dt_fim_vigencia >= dt_inicio_vigencia)
);

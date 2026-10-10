CREATE TABLE tbl_item_financeiro (
    cp_id_item                  BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao                BIGINT NOT NULL,
    tp_item                     VARCHAR(20) NOT NULL,
    ds_item                     VARCHAR(200) NOT NULL,
    vl_item                     NUMERIC(12,2) NOT NULL,
    ce_inscricao_atividade      BIGINT,
    ce_trabalho                 BIGINT,
    ce_uso_beneficio            BIGINT,
    dt_lancamento               TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    ind_estornado               BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_item_financeiro PRIMARY KEY (cp_id_item),
    CONSTRAINT fk_item_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_item_insativ FOREIGN KEY (ce_inscricao_atividade) REFERENCES tbl_inscricao_atividade (cp_id_inscricao_atividade),
    CONSTRAINT fk_item_trabalho FOREIGN KEY (ce_trabalho) REFERENCES tbl_trabalho (cp_id_trabalho),
    CONSTRAINT fk_item_uso_beneficio FOREIGN KEY (ce_uso_beneficio) REFERENCES tbl_uso_beneficio (cp_id_uso_beneficio),
    CONSTRAINT ck_item_tipo CHECK (tp_item IN ('INSCRICAO','ASSOCIACAO','ATIVIDADE','TAXA_PUBLICACAO','DESCONTO_BENEFICIO')),
    CONSTRAINT ck_item_origem CHECK (
        (tp_item IN ('INSCRICAO','ASSOCIACAO') AND ce_inscricao_atividade IS NULL AND ce_trabalho IS NULL AND ce_uso_beneficio IS NULL)
        OR (tp_item = 'ATIVIDADE' AND ce_inscricao_atividade IS NOT NULL AND ce_trabalho IS NULL AND ce_uso_beneficio IS NULL)
        OR (tp_item = 'TAXA_PUBLICACAO' AND ce_trabalho IS NOT NULL AND ce_inscricao_atividade IS NULL AND ce_uso_beneficio IS NULL)
        OR (tp_item = 'DESCONTO_BENEFICIO' AND ce_uso_beneficio IS NOT NULL AND ce_inscricao_atividade IS NULL AND ce_trabalho IS NULL)),
    CONSTRAINT ck_item_sinal CHECK (
        (tp_item = 'DESCONTO_BENEFICIO' AND vl_item <= 0) OR (tp_item <> 'DESCONTO_BENEFICIO' AND vl_item >= 0))
);

CREATE TABLE tbl_pagamento (
    cp_id_pagamento         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            BIGINT NOT NULL,
    tp_pagamento            VARCHAR(15) NOT NULL,
    vl_pagamento            dm_valor NOT NULL,
    dt_criacao              TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    dt_confirmacao          TIMESTAMP,
    status_pagamento        VARCHAR(12) NOT NULL DEFAULT 'CRIADO',
    cd_transacao_externa    VARCHAR(80),
    CONSTRAINT pk_pagamento PRIMARY KEY (cp_id_pagamento),
    CONSTRAINT fk_pagamento_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT uq_pagamento_transacao UNIQUE (tp_pagamento, cd_transacao_externa),
    CONSTRAINT uq_pagamento_tipo UNIQUE (cp_id_pagamento, tp_pagamento),
    CONSTRAINT ck_pagamento_tipo CHECK (tp_pagamento IN ('CARTAO','BOLETO','FATURAMENTO','NOTA_EMPENHO')),
    CONSTRAINT ck_pagamento_status CHECK (status_pagamento IN ('CRIADO','EM_ANALISE','CONFIRMADO',
        'RECUSADO','CANCELADO','EXPIRADO','ESTORNADO')),
    CONSTRAINT ck_pagamento_valor CHECK (vl_pagamento > 0),
    CONSTRAINT ck_pagamento_confirmacao CHECK (
        (status_pagamento IN ('CONFIRMADO','ESTORNADO') AND dt_confirmacao IS NOT NULL AND dt_confirmacao >= dt_criacao)
        OR (status_pagamento NOT IN ('CONFIRMADO','ESTORNADO') AND dt_confirmacao IS NULL))
);

CREATE TABLE tbl_pagamento_cartao (
    ce_pagamento        BIGINT NOT NULL,
    tp_pagamento        VARCHAR(15) NOT NULL DEFAULT 'CARTAO',
    nm_bandeira         VARCHAR(20) NOT NULL,
    nr_final_cartao     CHAR(4) NOT NULL,
    nr_parcelas         SMALLINT NOT NULL DEFAULT 1,
    CONSTRAINT pk_pagamento_cartao PRIMARY KEY (ce_pagamento),
    CONSTRAINT fk_pagcartao_pagamento FOREIGN KEY (ce_pagamento, tp_pagamento)
        REFERENCES tbl_pagamento (cp_id_pagamento, tp_pagamento) ON DELETE CASCADE,
    CONSTRAINT ck_pagcartao_tipo CHECK (tp_pagamento = 'CARTAO'),
    CONSTRAINT ck_pagcartao_parcelas CHECK (nr_parcelas BETWEEN 1 AND 12),
    CONSTRAINT ck_pagcartao_bandeira CHECK (nm_bandeira IN ('VISA','MASTERCARD','ELO','AMEX','HIPERCARD'))
);

CREATE TABLE tbl_pagamento_boleto (
    ce_pagamento        BIGINT NOT NULL,
    tp_pagamento        VARCHAR(15) NOT NULL DEFAULT 'BOLETO',
    cd_linha_digitavel  CHAR(47) NOT NULL,
    dt_vencimento       DATE NOT NULL,
    CONSTRAINT pk_pagamento_boleto PRIMARY KEY (ce_pagamento),
    CONSTRAINT fk_pagboleto_pagamento FOREIGN KEY (ce_pagamento, tp_pagamento)
        REFERENCES tbl_pagamento (cp_id_pagamento, tp_pagamento) ON DELETE CASCADE,
    CONSTRAINT uq_pagboleto_linha UNIQUE (cd_linha_digitavel),
    CONSTRAINT ck_pagboleto_tipo CHECK (tp_pagamento = 'BOLETO')
);

CREATE TABLE tbl_pagamento_institucional (
    ce_pagamento        BIGINT NOT NULL,
    tp_pagamento        VARCHAR(15) NOT NULL,
    ce_instituicao      BIGINT NOT NULL,
    nr_documento        VARCHAR(40) NOT NULL,
    dt_emissao_documento DATE NOT NULL,
    dt_vencimento       DATE NOT NULL,
    CONSTRAINT pk_pagamento_institucional PRIMARY KEY (ce_pagamento),
    CONSTRAINT fk_paginst_pagamento FOREIGN KEY (ce_pagamento, tp_pagamento)
        REFERENCES tbl_pagamento (cp_id_pagamento, tp_pagamento) ON DELETE CASCADE,
    CONSTRAINT fk_paginst_instituicao FOREIGN KEY (ce_instituicao) REFERENCES tbl_instituicao (cp_id_instituicao),
    CONSTRAINT uq_paginst_documento UNIQUE (ce_instituicao, tp_pagamento, nr_documento),
    CONSTRAINT ck_paginst_tipo CHECK (tp_pagamento IN ('FATURAMENTO','NOTA_EMPENHO')),
    CONSTRAINT ck_paginst_datas CHECK (dt_vencimento >= dt_emissao_documento)
);

CREATE TABLE tbl_politica_reembolso (
    cp_id_politica          BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_edicao               BIGINT NOT NULL,
    dt_limite_solicitacao   TIMESTAMP NOT NULL,
    pc_reembolso            dm_percentual NOT NULL,
    CONSTRAINT pk_politica_reembolso PRIMARY KEY (cp_id_politica),
    CONSTRAINT fk_politica_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_politica_limite UNIQUE (ce_edicao, dt_limite_solicitacao)
);

CREATE TABLE tbl_cancelamento (
    cp_id_cancelamento          BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao                BIGINT NOT NULL,
    ce_inscricao_atividade      BIGINT,
    dt_solicitacao              TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    ce_politica                 BIGINT,
    pc_reembolso_aplicado       dm_percentual,
    vl_reembolso                dm_valor,
    ds_motivo                   VARCHAR(500),
    ce_usuario_responsavel      BIGINT,
    CONSTRAINT pk_cancelamento PRIMARY KEY (cp_id_cancelamento),
    CONSTRAINT fk_cancelamento_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_cancelamento_insativ FOREIGN KEY (ce_inscricao_atividade)
        REFERENCES tbl_inscricao_atividade (cp_id_inscricao_atividade),
    CONSTRAINT fk_cancelamento_politica FOREIGN KEY (ce_politica) REFERENCES tbl_politica_reembolso (cp_id_politica),
    CONSTRAINT fk_cancelamento_usuario FOREIGN KEY (ce_usuario_responsavel) REFERENCES tbl_usuario_admin (cp_id_usuario),
    CONSTRAINT uq_cancelamento_item UNIQUE (ce_inscricao, ce_inscricao_atividade)
);

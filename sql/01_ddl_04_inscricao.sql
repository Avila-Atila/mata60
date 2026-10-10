CREATE TABLE tbl_inscricao (
    cp_id_inscricao         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_pessoa               BIGINT NOT NULL,
    ce_edicao               BIGINT NOT NULL,
    ce_categoria            BIGINT NOT NULL,
    ce_preco                BIGINT NOT NULL,
    dt_inscricao            TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    status_inscricao        VARCHAR(25) NOT NULL DEFAULT 'INICIADA',
    vl_total_inscricao      dm_valor NOT NULL DEFAULT 0,
    dt_confirmacao          TIMESTAMP,
    dt_cancelamento         TIMESTAMP,
    dt_ultima_atualizacao   TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT pk_inscricao PRIMARY KEY (cp_id_inscricao),
    CONSTRAINT fk_inscricao_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_inscricao_categoria FOREIGN KEY (ce_categoria, ce_edicao)
        REFERENCES tbl_categoria_inscricao (cp_id_categoria, ce_edicao),
    CONSTRAINT fk_inscricao_preco FOREIGN KEY (ce_preco, ce_categoria)
        REFERENCES tbl_preco_inscricao (cp_id_preco, ce_categoria),
    CONSTRAINT uq_inscricao_edicao UNIQUE (cp_id_inscricao, ce_edicao),
    CONSTRAINT ck_inscricao_status CHECK (status_inscricao IN ('INICIADA','AGUARDANDO_VALIDACAO',
        'AGUARDANDO_PAGAMENTO','PAGA','CANCELADA','CONCLUIDA')),
    CONSTRAINT ck_inscricao_confirmacao CHECK (
        (status_inscricao IN ('PAGA','CONCLUIDA') AND dt_confirmacao IS NOT NULL)
        OR status_inscricao NOT IN ('PAGA','CONCLUIDA')),
    CONSTRAINT ck_inscricao_cancelamento CHECK (
        (status_inscricao = 'CANCELADA' AND dt_cancelamento IS NOT NULL)
        OR (status_inscricao <> 'CANCELADA' AND dt_cancelamento IS NULL)),
    CONSTRAINT ck_inscricao_datas CHECK (
        (dt_confirmacao IS NULL OR dt_confirmacao >= dt_inscricao)
        AND (dt_cancelamento IS NULL OR dt_cancelamento >= dt_inscricao))
);

ALTER TABLE tbl_associacao_sbtc ADD CONSTRAINT fk_associacao_inscricao_origem
    FOREIGN KEY (ce_inscricao_origem) REFERENCES tbl_inscricao (cp_id_inscricao);

CREATE TABLE tbl_historico_status_inscricao (
    cp_id_historico         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            BIGINT NOT NULL,
    status_anterior         VARCHAR(25),
    status_novo             VARCHAR(25) NOT NULL,
    dt_alteracao            TIMESTAMP NOT NULL,
    ce_usuario_responsavel  BIGINT,
    CONSTRAINT pk_historico_status_inscricao PRIMARY KEY (cp_id_historico),
    CONSTRAINT fk_historico_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_historico_usuario FOREIGN KEY (ce_usuario_responsavel) REFERENCES tbl_usuario_admin (cp_id_usuario),
    CONSTRAINT ck_historico_status CHECK (status_anterior IS DISTINCT FROM status_novo)
);

CREATE TABLE tbl_documento_comprovacao (
    cp_id_documento         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            BIGINT NOT NULL,
    tp_documento            VARCHAR(30) NOT NULL,
    ds_caminho_arquivo      VARCHAR(500) NOT NULL,
    cd_hash_arquivo         CHAR(64) NOT NULL,
    dt_envio                TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    status_documento        VARCHAR(10) NOT NULL DEFAULT 'PENDENTE',
    dt_analise              TIMESTAMP,
    ce_usuario_analise      BIGINT,
    ds_motivo_rejeicao      VARCHAR(500),
    CONSTRAINT pk_documento_comprovacao PRIMARY KEY (cp_id_documento),
    CONSTRAINT fk_documento_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_documento_usuario FOREIGN KEY (ce_usuario_analise) REFERENCES tbl_usuario_admin (cp_id_usuario),
    CONSTRAINT uq_documento_hash UNIQUE (ce_inscricao, cd_hash_arquivo),
    CONSTRAINT ck_documento_tipo CHECK (tp_documento IN ('COMPROVANTE_MATRICULA','DECLARACAO_VINCULO',
        'CARTEIRA_ESTUDANTIL','CONTRACHEQUE','OUTRO')),
    CONSTRAINT ck_documento_status CHECK (status_documento IN ('PENDENTE','APROVADO','REJEITADO')),
    CONSTRAINT ck_documento_analise CHECK (
        (status_documento = 'PENDENTE' AND dt_analise IS NULL AND ce_usuario_analise IS NULL)
        OR (status_documento <> 'PENDENTE' AND dt_analise IS NOT NULL AND ce_usuario_analise IS NOT NULL
            AND dt_analise >= dt_envio)),
    CONSTRAINT ck_documento_rejeicao CHECK (status_documento <> 'REJEITADO' OR ds_motivo_rejeicao IS NOT NULL)
);

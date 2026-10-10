CREATE TABLE tbl_auditoria (
    cp_id_auditoria     BIGINT GENERATED ALWAYS AS IDENTITY,
    nm_tabela           VARCHAR(63) NOT NULL,
    cd_registro         VARCHAR(40) NOT NULL,
    tp_operacao         VARCHAR(6) NOT NULL,
    dt_operacao         TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    ce_usuario          BIGINT,
    nm_usuario_banco    VARCHAR(63) NOT NULL DEFAULT CURRENT_USER,
    ds_dados_anteriores JSONB,
    ds_dados_novos      JSONB,
    CONSTRAINT pk_auditoria PRIMARY KEY (cp_id_auditoria),
    CONSTRAINT ck_auditoria_operacao CHECK (tp_operacao IN ('INSERT','UPDATE','DELETE'))
);

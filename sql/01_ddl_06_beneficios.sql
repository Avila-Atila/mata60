CREATE TABLE tbl_beneficio_institucional (
    cp_id_beneficio         BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_instituicao          BIGINT NOT NULL,
    ce_evento               BIGINT,
    tp_beneficio            VARCHAR(20) NOT NULL,
    pc_desconto             dm_percentual,
    dt_inicio_vigencia      DATE NOT NULL,
    dt_fim_vigencia         DATE NOT NULL,
    qt_limite_periodo       INTEGER NOT NULL,
    qt_limite_por_edicao    INTEGER NOT NULL,
    CONSTRAINT pk_beneficio_institucional PRIMARY KEY (cp_id_beneficio),
    CONSTRAINT fk_beneficio_instituicao FOREIGN KEY (ce_instituicao) REFERENCES tbl_instituicao (cp_id_instituicao),
    CONSTRAINT fk_beneficio_evento FOREIGN KEY (ce_evento) REFERENCES tbl_evento (cp_id_evento),
    CONSTRAINT ck_beneficio_tipo CHECK (
        (tp_beneficio = 'GRATUIDADE' AND pc_desconto IS NULL)
        OR (tp_beneficio = 'DESCONTO_PERCENTUAL' AND pc_desconto > 0)),
    CONSTRAINT ck_beneficio_periodo CHECK (dt_fim_vigencia >= dt_inicio_vigencia),
    CONSTRAINT ck_beneficio_limites CHECK (qt_limite_periodo > 0 AND qt_limite_por_edicao > 0
        AND qt_limite_por_edicao <= qt_limite_periodo)
);

CREATE TABLE tbl_uso_beneficio (
    cp_id_uso_beneficio     BIGINT GENERATED ALWAYS AS IDENTITY,
    ce_beneficio            BIGINT NOT NULL,
    ce_inscricao            BIGINT NOT NULL,
    dt_utilizacao           TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    vl_desconto_aplicado    dm_valor,
    ce_usuario_concessao    BIGINT,
    CONSTRAINT pk_uso_beneficio PRIMARY KEY (cp_id_uso_beneficio),
    CONSTRAINT fk_uso_beneficio FOREIGN KEY (ce_beneficio) REFERENCES tbl_beneficio_institucional (cp_id_beneficio),
    CONSTRAINT fk_uso_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_uso_usuario FOREIGN KEY (ce_usuario_concessao) REFERENCES tbl_usuario_admin (cp_id_usuario),
    CONSTRAINT uq_uso_inscricao UNIQUE (ce_inscricao)
);

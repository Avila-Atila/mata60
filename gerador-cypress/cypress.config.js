const { defineConfig } = require('cypress')
const { Pool } = require('pg')
const { fakerPT_BR: faker } = require('@faker-js/faker')

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'eventOs',
  password: 'admin',
  port: 5432,
})

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      on('task', {
        async seedDatabase({ 
          quantidade = 50, 
          proporcaoEstrangeiros = 10, 
          proporcaoSbtc = 5, 
          proporcaoVinculo = 3, 
          proporcaoBeneficio = 4, 
          tipoPagamento = 'CARTAO' 
        } = {}) {
          const client = await pool.connect()
          try {
            await client.query('BEGIN')
            await client.query('SET search_path TO eventos;')

            // Limpa todas as tabelas principais em cascata no início
            await client.query('TRUNCATE TABLE eventos.tbl_pessoa, eventos.tbl_instituicao, eventos.tbl_evento CASCADE;')

            // Tabela 8: tbl_papel_organizacao (Papel padrão base)[cite: 12]
            const papelRes = await client.query(
              `INSERT INTO tbl_papel_organizacao (nm_papel, ds_papel) 
               VALUES ('Coordenador Geral', 'Responsável geral pela organização') 
               ON CONFLICT (nm_papel) DO UPDATE SET ds_papel = EXCLUDED.ds_papel 
               RETURNING cp_id_papel`
            )
            const idPapel = papelRes.rows[0].cp_id_papel

            for (let i = 1; i <= quantidade; i++) {
              const nomePessoa = `${faker.person.fullName()} ${i}`
              const emailPessoa = `usuario_${i}_${faker.internet.email()}`
              const dtNascimento = faker.date.birthdate({ min: 18, max: 60, mode: 'age' }).toISOString().split('T')[0]

              const temPassaporte = (i % proporcaoEstrangeiros === 0)
              const paisPessoa = temPassaporte ? 'US' : 'BR'
              const ufPessoa = temPassaporte ? null : 'BA'
              const cpfPessoa = temPassaporte ? null : faker.string.numeric(11)
              const passaportePessoa = temPassaporte ? `PASS${i}-${faker.string.alphanumeric(4)}` : null

              const nomeInstituicao = `${faker.company.name()} University ${i}`
              const siglaInstituicao = `U${i}`.slice(0, 30)
              const cnpjInstituicao = faker.string.numeric(14)

              const siglaEvento = `SIMP-${i}-${faker.string.alphanumeric(3)}`.toUpperCase()
              const nomeEvento = `${faker.commerce.productName()} ${i}`

              // 1. Tabela: tbl_pessoa[cite: 11]
              const pessoaRes = await client.query(
                `INSERT INTO tbl_pessoa (nm_pessoa, cpf_pessoa, passaporte_pessoa, email_pessoa, dt_nascimento, pais_pessoa, uf_pessoa) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7) 
                 RETURNING cp_id_pessoa`,
                [nomePessoa, cpfPessoa, passaportePessoa, emailPessoa, dtNascimento, paisPessoa, ufPessoa]
              )
              const idPessoa = pessoaRes.rows[0].cp_id_pessoa

              // 2. Tabela: tbl_usuario_admin (O primeiro utilizador é Administrador)[cite: 11]
              if (i === 1) {
                await client.query(
                  `INSERT INTO tbl_usuario_admin (ce_pessoa, nm_login, tp_perfil, ind_ativo)
                   VALUES ($1, 'admin_master', 'ADMINISTRADOR', true)
                   ON CONFLICT (nm_login) DO NOTHING`,
                  [idPessoa]
                )
              }

              // 3. Tabela: tbl_instituicao[cite: 11]
              const instRes = await client.query(
                `INSERT INTO tbl_instituicao (nm_instituicao, sg_instituicao, cnpj_instituicao, tp_instituicao, pais_instituicao, cidade_instituicao, uf_instituicao)
                 VALUES ($1, $2, $3, 'UNIVERSIDADE', 'BR', 'Salvador', 'BA') 
                 RETURNING cp_id_instituicao`,
                [nomeInstituicao, siglaInstituicao, cnpjInstituicao]
              )
              const idInstituicao = instRes.rows[0].cp_id_instituicao

              // 4. Tabela: tbl_vinculo_institucional (Adicionado periodicamente)[cite: 11]
              if (i % proporcaoVinculo === 0) {
                await client.query(
                  `INSERT INTO tbl_vinculo_institucional (ce_pessoa, ce_instituicao, tp_vinculo, dt_inicio_vinculo)
                   VALUES ($1, $2, 'DOCENTE', '2026-02-01')
                   ON CONFLICT DO NOTHING`,
                  [idPessoa, idInstituicao]
                )
              }

              // 6. Tabela: tbl_evento[cite: 12]
              const eventoRes = await client.query(
                `INSERT INTO tbl_evento (sg_evento, nm_evento, ds_evento, tp_evento)
                 VALUES ($1, $2, 'Simpósio anual de tecnologia', 'SIMPOSIO') 
                 RETURNING cp_id_evento`,
                [siglaEvento, nomeEvento]
              )
              const idEvento = eventoRes.rows[0].cp_id_evento

              // 7. Tabela: tbl_edicao_evento[cite: 12]
              const edicaoRes = await client.query(
                `INSERT INTO tbl_edicao_evento (ce_evento, nr_edicao, ano_edicao, dt_inicio_evento, dt_fim_evento, dt_inicio_inscricao, dt_fim_inscricao, modalidade_evento, cidade_evento, uf_evento)
                 VALUES ($1, 1, 2026, '2026-11-10', '2026-11-12', '2026-10-01 00:00:00', '2026-11-05 23:59:59', 'PRESENCIAL', 'Salvador', 'BA') 
                 RETURNING cp_id_edicao`,
                [idEvento]
              )
              const idEdicao = edicaoRes.rows[0].cp_id_edicao

              // 9. Tabela: tbl_comissao_organizadora[cite: 12]
              await client.query(
                `INSERT INTO tbl_comissao_organizadora (ce_edicao, ce_pessoa, ce_papel, dt_inicio_atuacao)
                 VALUES ($1, $2, $3, '2026-03-01')
                 ON CONFLICT DO NOTHING`,
                [idEdicao, idPessoa, idPapel]
              )

              // 10. Tabela: tbl_patrocinio[cite: 12]
              await client.query(
                `INSERT INTO tbl_patrocinio (ce_edicao, ce_instituicao, tp_cota, vl_patrocinio, dt_contrato)
                 VALUES ($1, $2, 'OURO', 5000.00, '2026-03-01')
                 ON CONFLICT DO NOTHING`,
                [idEdicao, idInstituicao]
              )

              // 11. Tabela: tbl_categoria_inscricao[cite: 13]
              const catRes = await client.query(
                `INSERT INTO tbl_categoria_inscricao (ce_edicao, nm_categoria, ds_categoria, ind_exige_comprovacao, ind_categoria_autor)
                 VALUES ($1, 'Estudante de Graduação', 'Categoria para estudantes', true, false) 
                 RETURNING cp_id_categoria`,
                [idEdicao]
              )
              const idCategoria = catRes.rows[0].cp_id_categoria

              // 12. Tabela: tbl_acesso_categoria_edicao[cite: 13]
              await client.query(
                `INSERT INTO tbl_acesso_categoria_edicao (ce_categoria, ce_edicao)
                 VALUES ($1, $2) ON CONFLICT DO NOTHING`,
                [idCategoria, idEdicao]
              )

              // 13. Tabela: tbl_faixa_inscricao[cite: 13]
              const faixaRes = await client.query(
                `INSERT INTO tbl_faixa_inscricao (ce_edicao, nm_faixa, nr_ordem, dt_inicio_faixa, dt_fim_faixa)
                 VALUES ($1, 'Primeiro Lote', 1, '2026-10-01 00:00:00', '2026-10-20 23:59:59') 
                 RETURNING cp_id_faixa`,
                [idEdicao]
              )
              const idFaixa = faixaRes.rows[0].cp_id_faixa

              // 14. Tabela: tbl_modalidade_inscricao[cite: 13]
              const cdModalidade = `GERAL_${i}_${faker.string.alphanumeric(4)}`
              const modRes = await client.query(
                `INSERT INTO tbl_modalidade_inscricao (cd_modalidade, nm_modalidade, tp_associacao)
                 VALUES ($1, 'Geral Presencial', 'NENHUMA') 
                 ON CONFLICT (cd_modalidade) DO UPDATE SET nm_modalidade = EXCLUDED.nm_modalidade 
                 RETURNING cp_id_modalidade`,
                [cdModalidade]
              )
              const idModalidade = modRes.rows[0].cp_id_modalidade

              // 15. Tabela: tbl_preco_inscricao[cite: 13]
              const precoRes = await client.query(
                `INSERT INTO tbl_preco_inscricao (ce_edicao, ce_categoria, ce_faixa, ce_modalidade, ind_preco_associado, vl_inscricao, vl_associacao)
                 VALUES ($1, $2, $3, $4, false, 150.00, 0.00) 
                 RETURNING cp_id_preco`,
                [idEdicao, idCategoria, idFaixa, idModalidade]
              )
              const idPreco = precoRes.rows[0].cp_id_preco

              // 16. Tabela: tbl_inscricao[cite: 14]
              const inscRes = await client.query(
                `INSERT INTO tbl_inscricao (ce_pessoa, ce_edicao, ce_categoria, ce_preco, status_inscricao, vl_total_inscricao, dt_confirmacao)
                 VALUES ($1, $2, $3, $4, 'PAGA', 150.00, LOCALTIMESTAMP)
                 RETURNING cp_id_inscricao`,
                [idPessoa, idEdicao, idCategoria, idPreco]
              )
              const idInscricao = inscRes.rows[0].cp_id_inscricao

              // 5. Tabela: tbl_associacao_sbtc (Configurável por proporção, com FK opcional para tbl_inscricao)[cite: 11, 14]
              if (i % proporcaoSbtc === 0) {
                await client.query(
                  `INSERT INTO tbl_associacao_sbtc (ce_pessoa, tp_associacao, dt_inicio_vigencia, dt_fim_vigencia, vl_anuidade, ce_inscricao_origem)
                   VALUES ($1, 'PROFISSIONAL', '2026-01-01', '2026-12-31', 150.00, $2)
                   ON CONFLICT DO NOTHING`,
                  [idPessoa, idInscricao]
                )
              }

              // 17. Tabela: tbl_historico_status_inscricao[cite: 14]
              await client.query(
                `INSERT INTO tbl_historico_status_inscricao (ce_inscricao, status_anterior, status_novo, dt_alteracao)
                 VALUES ($1, 'INICIADA', 'PAGA', LOCALTIMESTAMP)`,
                [idInscricao]
              )

              // 18. Tabela: tbl_documento_comprovacao[cite: 14]
              await client.query(
                `INSERT INTO tbl_documento_comprovacao (ce_inscricao, tp_documento, ds_caminho_arquivo, cd_hash_arquivo, status_documento)
                 VALUES ($1, 'COMPROVANTE_MATRICULA', '/uploads/doc.pdf', $2, 'PENDENTE')
                 ON CONFLICT DO NOTHING`,
                [idInscricao, faker.string.alphanumeric(64)]
              )

              // 19. Tabela: tbl_atividade[cite: 15]
              const ativRes = await client.query(
                `INSERT INTO tbl_atividade (ce_edicao, nm_atividade, tp_atividade, dt_inicio, dt_fim, nr_capacidade, vl_atividade)
                 VALUES ($1, 'Palestra Principal de Abertura', 'PALESTRA', '2026-11-10 09:00:00', '2026-11-10 11:00:00', 100, 0.00)
                 RETURNING cp_id_atividade`,
                [idEdicao]
              )
              const idAtividade = ativRes.rows[0].cp_id_atividade

              // 20. Tabela: tbl_atividade_categoria[cite: 15]
              await client.query(
                `INSERT INTO tbl_atividade_categoria (ce_atividade, ce_categoria)
                 VALUES ($1, $2) ON CONFLICT DO NOTHING`,
                [idAtividade, idCategoria]
              )

              // 21. Tabela: tbl_inscricao_atividade[cite: 15]
              const insAtivRes = await client.query(
                `INSERT INTO tbl_inscricao_atividade (ce_inscricao, ce_atividade, status_item)
                 VALUES ($1, $2, 'ATIVO')
                 RETURNING cp_id_inscricao_atividade`,
                [idInscricao, idAtividade]
              )
              const idInsAtiv = insAtivRes.rows[0].cp_id_inscricao_atividade

              // 22. Tabela: tbl_lista_espera[cite: 15]
              if (i % 3 === 0) {
                await client.query(
                  `INSERT INTO tbl_lista_espera (ce_inscricao, ce_atividade, status_espera)
                   VALUES ($1, $2, 'AGUARDANDO') ON CONFLICT DO NOTHING`,
                  [idInscricao, idAtividade]
                )
              }

              // 23. Tabela: tbl_avaliacao_atividade[cite: 15]
              await client.query(
                `INSERT INTO tbl_avaliacao_atividade (ce_inscricao_atividade, nr_nota, ds_comentario)
                 VALUES ($1, 5, 'Excelente palestra!')
                 ON CONFLICT DO NOTHING`,
                [idInsAtiv]
              )

              // 24. Tabela: tbl_beneficio_institucional[cite: 16]
              const benRes = await client.query(
                `INSERT INTO tbl_beneficio_institucional (ce_instituicao, ce_evento, tp_beneficio, pc_desconto, dt_inicio_vigencia, dt_fim_vigencia, qt_limite_periodo, qt_limite_por_edicao)
                 VALUES ($1, $2, 'DESCONTO_PERCENTUAL', 10.00, '2026-01-01', '2026-12-31', 50, 10)
                 RETURNING cp_id_beneficio`,
                [idInstituicao, idEvento]
              )
              const idBeneficio = benRes.rows[0].cp_id_beneficio

              // 25. Tabela: tbl_uso_beneficio (Adicionado sazonalmente conforme proporção)[cite: 16]
              if (i % proporcaoBeneficio === 0) {
                await client.query(
                  `INSERT INTO tbl_uso_beneficio (ce_beneficio, ce_inscricao, vl_desconto_aplicado)
                   VALUES ($1, $2, 15.00)
                   ON CONFLICT DO NOTHING`,
                  [idBeneficio, idInscricao]
                )
              }

              // 26. Tabela: tbl_trabalho[cite: 17]
              const trabRes = await client.query(
                `INSERT INTO tbl_trabalho (ce_edicao, cd_trabalho_externo, titulo_trabalho, tp_trabalho, status_trabalho)
                 VALUES ($1, $2, $3, 'ARTIGO_COMPLETO', 'ACEITO')
                 RETURNING cp_id_trabalho`,
                [idEdicao, `EXT-${i}`, faker.lorem.words(5)]
              )
              const idTrabalho = trabRes.rows[0].cp_id_trabalho

              // 27. Tabela: tbl_autoria[cite: 17]
              await client.query(
                `INSERT INTO tbl_autoria (ce_trabalho, ce_pessoa, nr_ordem_autoria, ind_autor_correspondente)
                 VALUES ($1, $2, 1, true)
                 ON CONFLICT DO NOTHING`,
                [idTrabalho, idPessoa]
              )

              // 28. Tabela: tbl_cobertura_trabalho[cite: 17]
              await client.query(
                `INSERT INTO tbl_cobertura_trabalho (ce_trabalho, ce_inscricao, ce_edicao, status_cobertura)
                 VALUES ($1, $2, $3, 'ATIVA')
                 ON CONFLICT DO NOTHING`,
                [idTrabalho, idInscricao, idEdicao]
              )

              // 29. Tabela: tbl_item_financeiro[cite: 18]
              await client.query(
                `INSERT INTO tbl_item_financeiro (ce_inscricao, tp_item, ds_item, vl_item)
                 VALUES ($1, 'INSCRICAO', 'Taxa de Inscrição Geral', 150.00)`,
                [idInscricao]
              )

              // 30. Tabela: tbl_pagamento[cite: 18]
              const pagRes = await client.query(
                `INSERT INTO tbl_pagamento (ce_inscricao, tp_pagamento, vl_pagamento, status_pagamento, cd_transacao_externa, dt_confirmacao)
                 VALUES ($1, $2, 150.00, 'CONFIRMADO', $3, LOCALTIMESTAMP)
                 RETURNING cp_id_pagamento`,
                [idInscricao, tipoPagamento, `TX-${i}-${faker.string.alphanumeric(6)}`]
              )
              const idPagamento = pagRes.rows[0].cp_id_pagamento

              // 31, 32, 33. Tabelas de Pagamento Específicas (`tbl_pagamento_cartao`, `tbl_pagamento_boleto`, `tbl_pagamento_institucional`)[cite: 18]
              if (tipoPagamento === 'CARTAO') {
                await client.query(
                  `INSERT INTO tbl_pagamento_cartao (ce_pagamento, tp_pagamento, nm_bandeira, nr_final_cartao, nr_parcelas)
                   VALUES ($1, 'CARTAO', 'VISA', '1234', 1) ON CONFLICT DO NOTHING`,
                  [idPagamento]
                )
              } else if (tipoPagamento === 'BOLETO') {
                await client.query(
                  `INSERT INTO tbl_pagamento_boleto (ce_pagamento, tp_pagamento, cd_linha_digitavel, dt_vencimento)
                   VALUES ($1, 'BOLETO', $2, '2026-11-01') ON CONFLICT DO NOTHING`,
                  [idPagamento, faker.string.numeric(47)]
                )
              } else {
                await client.query(
                  `INSERT INTO tbl_pagamento_institucional (ce_pagamento, tp_pagamento, ce_instituicao, nr_documento, dt_emissao_documento, dt_vencimento)
                   VALUES ($1, 'FATURAMENTO', $2, $3, '2026-03-01', '2026-11-01') ON CONFLICT DO NOTHING`,
                  [idPagamento, idInstituicao, `FAT-${i}`]
                )
              }

              // 34. Tabela: tbl_politica_reembolso[cite: 18]
              const polRes = await client.query(
                `INSERT INTO tbl_politica_reembolso (ce_edicao, dt_limite_solicitacao, pc_reembolso)
                 VALUES ($1, '2026-10-30 23:59:59', 80.00)
                 ON CONFLICT DO NOTHING
                 RETURNING cp_id_politica`,
                [idEdicao]
              )
              const idPolitica = polRes.rows[0]?.cp_id_politica

              // 35. Tabela: tbl_cancelamento (Opcional condicional)[cite: 18]
              if (i % 7 === 0 && idPolitica) {
                await client.query(
                  `INSERT INTO tbl_cancelamento (ce_inscricao, dt_solicitacao, ce_politica, pc_reembolso_aplicado, vl_reembolso, ds_motivo)
                   VALUES ($1, LOCALTIMESTAMP, $2, 80.00, 120.00, 'Desistência pessoal')
                   ON CONFLICT DO NOTHING`,
                  [idInscricao, idPolitica]
                )
              }

              // 36. Tabela: tbl_credenciamento[cite: 29]
              await client.query(
                `INSERT INTO tbl_credenciamento (ce_inscricao, ds_local)
                 VALUES ($1, 'Credenciamento Principal') ON CONFLICT DO NOTHING`,
                [idInscricao]
              )

              // 37. Tabela: tbl_presenca[cite: 29]
              await client.query(
                `INSERT INTO tbl_presenca (ce_inscricao, ce_atividade, tp_origem_registro)
                 VALUES ($1, $2, 'QRCODE') ON CONFLICT DO NOTHING`,
                [idInscricao, idAtividade]
              )

              // 38. Tabela: tbl_certificado[cite: 29]
              await client.query(
                `INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, tp_certificado, cd_validacao, nr_emissao)
                 VALUES ($1, $2, 'PARTICIPACAO', $3, 1) ON CONFLICT DO NOTHING`,
                [idPessoa, idEdicao, faker.string.uuid()]
              )

              // 39. Tabela: tbl_termo[cite: 30]
              const termoRes = await client.query(
                `INSERT INTO tbl_termo (nm_termo, nr_versao, ds_termo, ind_obrigatorio, dt_inicio_vigencia)
                 VALUES ($1, '1.0', 'Termos e condições gerais de participação no evento.', true, '2026-01-01 00:00:00')
                 ON CONFLICT (nm_termo, nr_versao) DO UPDATE SET ds_termo = EXCLUDED.ds_termo
                 RETURNING cp_id_termo`,
                [`Termo de Privacidade ${i}`]
              )
              const idTermo = termoRes.rows[0].cp_id_termo

              // 40. Tabela: tbl_aceite_termo[cite: 30]
              await client.query(
                `INSERT INTO tbl_aceite_termo (ce_termo, ce_pessoa, ce_inscricao, ind_aceito)
                 VALUES ($1, $2, $3, true) ON CONFLICT DO NOTHING`,
                [idTermo, idPessoa, idInscricao]
              )

              // 41. Tabela: tbl_auditoria[cite: 31]
              await client.query(
                `INSERT INTO tbl_auditoria (nm_tabela, cd_registro, tp_operacao, ds_dados_novos)
                 VALUES ('tbl_pessoa', $1, 'INSERT', $2)`,
                [String(i), JSON.stringify({ nm_pessoa: nomePessoa, email_pessoa: emailPession = emailPessoa })]
              )
            }

            await client.query('COMMIT')
            return `Sucesso absoluto! Todas as 41 tabelas foram populadas com ${quantidade} registos.`
          } catch (error) {
            await client.query('ROLLBACK')
            console.error('Erro na seed:', error)
            throw error
          } finally {
            client.release()
          }
        },

        async limparBanco() {
          const client = await pool.connect()
          try {
            await client.query('SET search_path TO eventos;')
            const res = await client.query(`
              SELECT tablename FROM pg_tables WHERE schemaname = 'eventos';
            `)
            for (let row of res.rows) {
              await client.query(`TRUNCATE TABLE eventos.${row.tablename} RESTART IDENTITY CASCADE;`)
            }
            return 'Todas as tabelas foram limpas com sucesso!'
          } catch (error) {
            console.error('Erro ao limpar o banco:', error)
            throw error
          } finally {
            client.release()
          }
        }
      })
    },
  },
})
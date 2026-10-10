describe('População Avançada e Completa da Base de Dados', () => {
    const configGeracao = {
        quantidade: 10000,                // Número de registos gerados
        proporcaoEstrangeiros: 10,     // 1 estrangeiro gerado a cada 10 pessoas
        proporcaoSbtc: 5,              // 1 associação SBTC gerada a cada 5 pessoas[cite: 11]
        proporcaoVinculo: 3,           // 1 vínculo institucional gerado a cada 3 pessoas[cite: 11]
        proporcaoBeneficio: 4,         // 1 uso de benefício sazonal gerado a cada 4 pessoas[cite: 16]
        tipoPagamento: 'CARTAO'        // Opções: 'CARTAO', 'BOLETO' ou 'FATURAMENTO'[cite: 18]
    }

    it(`Deve gerar ${configGeracao.quantidade} registos`, () => {
        cy.task('seedDatabase', configGeracao, { timeout: 1200000000 }).then((mensagem) => {
            cy.log(mensagem)
        })
    })


    it(`Limpar Banco`, () => {
        //cy.task('limparBanco').then((msg) => cy.log(msg))
    })
})
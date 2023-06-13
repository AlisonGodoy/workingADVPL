#INCLUDE "rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"
#Include "TOTVS.ch"

/*--------------------------------------------------------------------------------------------------------------------+
| Descricao    : Responsável por inserir (BROW) e popular (GRAVA) nova coluna na tela de compensação entre carteiras  |
| Data Criacao : 06/04/2023																							  |
| Desenvolvedor: Alison Godoy                                                                                         |
| Data Alt.    | Descricao                                                                                            |
|   /  /       |                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------*/

//Cria nova campo e coluna no Browse de compensação entre carteiras
User Function F450BROW()
 
    Local aCampos := PARAMIXB[1]
    Local aCpoBro := PARAMIXB[2]
    Local aOfuscar := PARAMIXB[3]
    
    AADD(aCampos,{"HIST"     ,"C",40,0} )
    
    AADD(aCpoBro,{"HIST"    ,, 'Histórico',"@X"} )
    
    AADD(aOfuscar, .F. ) // Ofuscar Histórico
    
Return {aCampos,aCpoBro,aOfuscar}

//Grava as informações do novo campo HIST que foi criado
User Function F450GRAVA()

    Local cTabela := PARAMIXB[1]
    Local cPrefixo      := SubStr(TITULO, 0, 2)
    Local cDoc          := SubStr(TITULO, 5, 9)
    Local nParcela      := SubStr(TITULO, 15, 1)
    Local cTipo         := SubStr(TITULO, 19, 2)
    Local cPoupulaHist  

    IF cTabela == "SE1"

        dbSelectArea("SE1")
		dbSetOrder(1)
        Posicione("SE1",1,xFilial("SE1")+PadR(cPrefixo,3,' ')+cDoc+PadR(nParcela,3,'  ')+cTipo,"E1_HIST")

        cPoupulaHist := SE1->E1_HIST

        DBCLOSEAREA()

        TRB->HIST := cPoupulaHist //poupula tabela temporaria para apresentação ao usuário

    ELSEIF cTabela == "SE2"

        dbSelectArea("SE2")
		dbSetOrder(1)
        Posicione("SE2",1,xFilial("SE2")+PadR(cPrefixo,3,' ')+cDoc+PadR(nParcela,3,'  ')+PadR(cTipo,3,' '),"E2_HIST")

        cPoupulaHist := SE2->E2_HIST

        DBCLOSEAREA()     

        TRB->HIST := cPoupulaHist

    ENDIF

Return


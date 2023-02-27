#Include "rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"        
#Include "TOTVS.ch"

/*--------------------------------------------------------------------------------------------------------------------+
| Descricao    : PE para limpar o histórico de aprovação do pedido de venda que foi estornado pelos Doc. Saida        |
| Data Criacao : 08/02/2023											      											  |
| Desenvolvedor: Alison Godoy                                                                                         |
| Data Alt.    | Descricao                                                                                            |
|   /  /       |                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------*/

User Function M460DEL()

    	RecLock("SC5",.F.)
            SC5->C5_APROVA2 := .F.
            SC5->C5_USRAPR2 := ""   
            SC5->C5_DTAPRV2 := CTOD(SPACE(8)) 
        MsUnLock()

RETURN

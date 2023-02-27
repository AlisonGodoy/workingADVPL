#Include "rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"        
#Include "TOTVS.ch"

/*--------------------------------------------------------------------------------------------------------------------------------------------------+
| Descricao    : PE para validar a data de exclusão do Doc., pois a SEFAZ não permite exclusão de documentos que foram autorizados a mais de 7 dias |
| Data Criacao : 20/02/2023											        										                                |
| Desenvolvedor: Alison Godoy                                                                                                                       |
| Data Alt.    | Descricao                                                                                                                          |
|   /  /       |                                                                                                                                    |
+--------------------------------------------------------------------------------------------------------------------------------------------------*/

User Function MS520VLD()

    Local dDataAutNfe := SF2->F2_DAUTNFE
    Local cHoraAutNfe := SF2->F2_HAUTNFE
    Local lValido

    IF dDataAutNfe == CTOD(SPACE(8)) .OR. (dDataAutNfe + 7) > DATE()
    	
        lValido := .T.
    
    ELSEIF (dDataAutNfe + 7) == DATE() .AND. cHoraAutNfe > (SUBSTR(TIME(), 1, 5))

        lValido := .T.
    
    ELSE

        MSGALERT( "Não foi possível realizar a exclusão do documento '" + SF2->F2_DOC + "' pois o prazo SEFAZ (7 dias) foi excedido"  , "Aviso!" )
        lValido := .F.

    ENDIF

RETURN lValido

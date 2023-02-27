#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"        
#Include "TOTVS.ch"

/*--------------------------------------------------------------------------------------------------------------------+
| Descricao    : Arquivo (PE) para gravar os dados bancários do título original após gerado título de Fatura          |
| Data Criacao : 10/02/2023																							  |
| Desenvolvedor: Alison Godoy                                                                                         |
| Data Alt.    | Descricao                                                                                            |
|   /  /       |                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------*/

User Function FA290()

    _cQuery := ""
    _cQuery += "SELECT E2_FORBCO, E2_FORAGE, E2_FORCTA, E2_FCTADV, E2_FAGEDV " +CRLF
    _cQuery += " FROM SE2010 " +CRLF
    _cQuery += " WHERE E2_NUM = "+"'"+cnumero+"'" +CRLF
    _cQuery += " AND E2_FORNECE = "+"'"+cforn+"'" +CRLF
    _cQuery += " AND E2_LOJA = "+"'"+cloja+"'"

    _aServE2  := U_Qry2Array(_cQuery)
    
    if len(_aServE2) > 0

        RecLock('SE2',.F.)
            SE2->E2_FORBCO := _aServE2[1][1]
            SE2->E2_FORAGE := _aServE2[1][2]
            SE2->E2_FORCTA := _aServE2[1][3]
            SE2->E2_FCTADV := _aServE2[1][4]
            SE2->E2_FAGEDV := _aServE2[1][5]
        MsUnlock()

    ENDIF
       
RETURN



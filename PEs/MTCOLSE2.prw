#INCLUDE "rwmake.ch"
#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"
#Include "TOTVS.ch"

/*----------------------------------------------------------------------------------------------------------------------------------+
| Descricao    : Responsável por ajustar nas duplicatas do Doc. Entrada as parcelas de acordo com as previsões do Pedido de Compra  |
| Data Criacao : 13/02/2023																							  				|
| Desenvolvedor: Alison Godoy                                                                                         				|
| Data Alt.    | Descricao                                                                                            				|
|   /  /       |                                                                                                      				|
+----------------------------------------------------------------------------------------------------------------------------------*/

User Function MTCOLSE2()

    Local aColsE2           := PARAMIXB[1] //aCols de duplicatas
    Local nOpc              := PARAMIXB[2] //0-Tela de visualização / 1-Inclusão ou Classificação
    Local nNumPedCompras
    Local _x
    
    IF nOpc <> 1 .OR. len(ACOLS[1]) < 27 .OR. AllTrim(Posicione('SC7',1,xFilial('SC7')+ACOLS[1][27], 'C7_COND')) <> CCondicao .OR. dNewVenc <> CTOD(SPACE(8))

        Return Nil
        
    else
        
        nNumPedCompras    := ACOLS[1][27]
        //Percorre o aCols para verificar se existe outro numero de pedido
        FOR _x := 1 TO len(aCols)
            if nNumPedCompras <> aCols[_x][27]
                RETURN NIL
            ENDIF
        NEXT _x

        _cQryE2 := ""
        _cQryE2 += " SELECT E2_PARCELA, E2_VENCTO "              + CRLF
        _cQryE2 += " FROM SE2010     "                           + CRLF
        _cQryE2 += " WHERE E2_NUM  = '"  + nNumPedCompras + "'"  + CRLF
        _cQryE2 += " AND E2_FILIAL = '"  + CFILFIE + "'"         + CRLF
        _cQryE2 += " AND E2_FORNECE = '" + CA100FOR + "'"        + CRLF
        _cQryE2 += " AND E2_LOJA = '"    + CLOJA + "'"           + CRLF
        _cQryE2 += " AND D_E_L_E_T_ = ''   "

        _aServE2  := U_Qry2Array(_cQryE2)

        if len(_aServE2) > 0 

            for _x := 1 to len(_aServE2)
                PARAMIXB[1][_x][2] = _aServE2[_x][2] 
            next _x
                    
        Else

            //MSGINFO( "Datas de vencimento para o titulo '" + nNumPedCompras + "' não econtrada, ajustar duplicatas!" , "Aviso!" )
            Return NIL

        endif
        
    ENDIF

Return aColsE2


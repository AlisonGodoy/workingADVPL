
/*--------------------------------------------------------------------------------------------------------------------+
| Descricao    : Arquivo para validar faturamento de notas de servi�o quando a data base n�o bate com a data atual    |
| Data Criacao : 31/03/2023																							  |
| Desenvolvedor: Alison Godoy                                                                                         |
| Data Alt.    | Descricao                                                                                            |
|   /  /       |                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------*/

//executa ap�s selecionar op��o Prep. Doc Saida em Outras A��es do Pedido de Venda
User Function M410PVNF()

    Local dData := dDataBase
    Local dHoje := Date()
    Local codPedido := SC5->C5_NUM
    Local x := 0
    Local lRet := .T.

    cQuery := "SELECT C6_PRODUTO, C6_TIPOMAT, C6_QTDLIB FROM SC6010 WHERE D_E_L_E_T_ = '' AND C6_NUM = '"+codPedido+"'""
    aQuery := U_Qry2Array(cQuery)

    cQueryC9 := "SELECT C9_PEDIDO, C9_PRODUTO FROM SC9010 s WHERE D_E_L_E_T_ = '' AND C9_PEDIDO = '"+codPedido+"'""
    aQueryC9 := U_Qry2Array(cQueryC9)

    FOR x := 1 TO LEN(aQuery)
        IF LEN(aQuery) > 1 .AND. LEN(aQueryC9) > 0
            
                if aQuery[x][2] == 'SV' .AND. aQueryC9[1][2] == aQuery[x][1] .AND. dData <> dHoje 
                                                
                    MSGALERT( "N�o ser� poss�vel gerar notas de SERVI�O (NFSE) pois a Data Base do sistema n�o corresponde a Data Atual", "ATEN��O" )
                    lRet := .F.
    
                endif
            
        ELSEIF LEN(aQuery) > 1 .AND. LEN(aQueryC9) == 0 .AND. aQuery[x][2] == 'SV' .AND. dData <> dHoje 
            
            MSGALERT( "N�o ser� poss�vel gerar notas de SERVI�O (NFSE) pois a Data Base do sistema n�o corresponde a Data Atual", "ATEN��O" )
            lRet := .F.

        ELSEIF LEN(aQuery) == 1 .AND. aQuery[x][2] == 'SV' .AND. dData <> dHoje

            MSGALERT( "N�o ser� poss�vel gerar notas de SERVI�O (NFSE) pois a Data Base do sistema n�o corresponde a Data Atual", "ATEN��O" )
            lRet := .F.

        ELSE 

            lRet := .T.

        ENDIF
    NEXT x

Return lRet

//Executa ap�s selecionar a s�rie na rotina Documentos de Sa�da
User Function M460MARK()

    Local lRet := .T.
    Local dData := dDataBase
    Local dHoje := Date()

    IF PARAMIXB[3] == "T  " .AND. dData <> dHoje
            MSGALERT( "N�o ser� poss�vel gerar notas de SERVI�O (NFSE) pois a Data Base do sistema n�o corresponde a Data Atual", "ATEN��O" )
            lRet     := .F.         
    ENDIF

Return lRet 

//Op��o n�o utilizada - este ponto � permitido desabilitar as S�ries para que o usu�rio n�o possa selecionar.
/*
//remove a s�rie = T de acordo com a condi��o
User Function SX5NOTA()

    Local dData := dDataBase
    Local dHoje := Date() 
    Local _cChave   := Paramixb[3]  //Chave da Tabela na SX5
    Local _lRet     := .T.
    
    If Alltrim(_cChave) == "T" .AND. dData <> dHoje //.Or. Alltrim(_cChave) == "B"
        MSGALERT( "N�o ser� poss�vel gerar notas de SERVI�O (NFSE) pois a Data Base do sistema n�o corresponde a Data Atual", "ATEN��O" )
        _lRet     := .F.         
    Endif
 
Return _lRet
*/

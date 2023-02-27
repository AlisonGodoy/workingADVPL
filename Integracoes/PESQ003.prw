
#INCLUDE "Totvs.ch"
#INCLUDE "Tbiconn.ch"
#INCLUDE "topconn.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RPTDEF.CH"  
#INCLUDE "FWPrintSetup.ch"

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Descricao    : Arquivo onde estão as rotinas de gravação no Banco de dados das respostas das pesquisas geradas no (*outro sistema*) e enviadas aos clientes  |
|				 e envio de e-mail informando vendedor  																			  						   |
| Data Criacao : 31/01/2023																							  				  						   |
| Desenvolvedor: Alison Godoy                                                                                         				  						   |
| Data Alt.    | Descricao                                                                                            				  						   |
|   /  /       |                                                                                                      				  						   |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------------------------------------*
| Func:  CHAMRESP()                                                     							 	  |
| Desc:  Declara as surveys (id das respostas no *outro sistema*) e chama a função enviando por parametro |
*--------------------------------------------------------------------------------------------------------*/
User Function CHAMRESP()
	
    RPCSetType(3)
	PREPARE ENVIRONMENT EMPRESA '01' FILIAL "0101" MODULO "SIGAFAT"

    Public _cProducao   := GETMV("MV_PRODUC") //retorna paramentro se ambiente é produção ou "N"

    //Abaixo deve ser declarado as surveys que serão utilizadas


    Public _cIdPesq := "xxxx"
    U_RETRESP(_cIdPesq)
    

    RESET ENVIRONMENT

RETURN

/*---------------------------------------------------------------------------------------------------------------------*
| Func:  RETRESP()                                                     							             		   |
| Desc:  Responsável por consumir a API do *outro sistema*, gravar no BD as respostas e chamar func de envio do e-mail |
*---------------------------------------------------------------------------------------------------------------------*/
User Function RETRESP(_cSurvey)

    Local oRestClient as object
    Local cUser     := "xxxx"
    Local cPass     := "xxxx"
    Local aHeadOut  := {}
    Local cRetorno
    Local jRetorno
    Local _x  
    Local dataTemp := DaySub(ddatabase,1)

    Public _documento 

    aAdd(aHeadOut,"Content-Type: application/json")
	aAdd(aHeadOut, "Authorization: Basic "+Encode64(cUser+":"+cPass ) )

    oRestClient := FWRest():New("xxxx")
    oRestClient:setPath("/surveys/"+_cSurvey+"/responses?startDate="+Year2Str(dataTemp)+"-"+Month2Str(dataTemp)+"-"+Day2Str(dataTemp)+"T00:00:00.000Z") //Informa qual survey utilizar
    
    IF oRestClient:Get(aHeadOut)

        cRetorno    := oRestClient:GetResult()
        _jsonResult := '{"resultado":'+cRetorno+'}' //acrescenta a chave "resultado" no Json, pois o retorno estava vindo como array '[]'
        jRetorno    := JsonObject():new()
        jRetorno:fromJson(_jsonResult)
        
        FOR _x := 1 TO len(jRetorno['resultado'])

            _documento      := jRetorno['resultado'][_x]['metadata']['documento']                           
            _nota           := jRetorno['resultado'][_x]['responses'][1]['response']
            _dataRespJson   := jRetorno['resultado'][_x]['responses'][1]['createdAt']
            _dataResp       := SUBSTR(_dataRespJson,1,4)+SUBSTR(_dataRespJson,6,2)+SUBSTR(_dataRespJson,9,2)
            _horaResp       := SUBSTR(_dataRespJson,12,8)

            //Se houver comentário na resposta, a API acrescenta mais uma chave "responses"
            if len(jRetorno['resultado'][_x]['responses']) > 1 
                _comentario := jRetorno['resultado'][_x]['responses'][2]['response']
            else
                _comentario := "Não informado"
            endif

            //Query para documentos que populam SC5
            _cQryC5 := ""
            _cQryC5 += " SELECT C5_NUM, C5_CLIENTE, C5_CLINOME, C5_PESQRES, C5_PESQNOT, C5_PESQCOM, C5_PESQDTR, C5_PESQHRR, R_E_C_N_O_ "
            _cQryC5 += " FROM SC5010 SC5  "  + CRLF
            _cQryC5 += " WHERE C5_NUM = '" + _documento  +"'"+ CRLF
            _cQryC5 += " AND C5_PESQRES <> 'S' " + CRLF
            _cQryC5 += " AND C5_PESQENV = 'S' "

            //Query para documentos que populam AB9
            _cQryB9 := ""
            _cQryB9 += " SELECT AB9_NUMOS, AB9_CODCLI, AB9_CLINOM, AB9_PESRES, AB9_PESNOT, AB9_PESCOM, AB9_PESDTR, AB9_PESHRR, R_E_C_N_O_  "
            _cQryB9 += " FROM AB9010 AB9  "  + CRLF
            _cQryB9 += " WHERE AB9_NUMOS LIKE '" + _documento  +"%'"+ CRLF
            _cQryB9 += " AND AB9_PESRES <> 'S' " + CRLF
            _cQryB9 += " AND AB9_PESENV = 'S' "

            _aServC5  := U_Qry2Array(_cQryC5)
            _aServB9  := U_Qry2Array(_cQryB9)

            if len(_aServC5) > 0   

                dbSelectArea("SC5")
                SC5->(dbGoTo(_aServC5[1][9]))
                RecLock("SC5",.F.)

                SC5->C5_PESQRES     := "S"
                SC5->C5_PESQNOT     := VAL(_nota)
                SC5->C5_PESQCOM     := DecodeUTF8(Alltrim(_comentario),"iso8859-1")
                SC5->C5_PESQDTR     := STOD(_dataResp)
                SC5->C5_PESQHRR     := _horaResp

                MsUnLock()
                SC5->(DBCLOSEAREA())

                _GeraLog("=== Resposta de pesquisa gravada para o documento "+ cValTochar(_documento) +" com sucesso!", "respostas.log")
                _cMsg      := "Pesquisa Respondida pelo Cliente!"
                _cEmailEnv := "xxxx"
                U_MAILRESP(_aServC5[1][2], _aServC5[1][3],VAL(_nota),DecodeUTF8(Alltrim(_comentario),"iso8859-1"),STOD(_dataResp),_horaResp, _cMsg, _cEmailEnv)
                
            else
                if len(_aServB9) > 0 

                    for _x := 1 to len(_aServB9)
                        dbSelectArea("AB9")
                        AB9->(dbGoTo(_aServB9[_x][9]))
                        RecLock("AB9",.F.)

                        AB9->AB9_PESRES     := "S"
                        AB9->AB9_PESNOT     := VAL(_nota)
                        AB9->AB9_PESCOM     := DecodeUTF8(Alltrim(_comentario),"iso8859-1")
                        AB9->AB9_PESDTR     := STOD(_dataResp)
                        AB9->AB9_PESHRR     := _horaResp

                        MsUnLock()
                        AB9->(DBCLOSEAREA())

                        _GeraLog("=== Resposta de pesquisa gravada para o documento "+ cValTochar(_documento) +" com sucesso!", "respostas.log")
                        _cMsg      := "Pesquisa Respondida pelo Cliente!"
                        _cEmailEnv := "xxxx"
                        U_MAILRESP(_aServB9[1][2], _aServB9[1][3],VAL(_nota),DecodeUTF8(Alltrim(_comentario),"iso8859-1"),STOD(_dataResp),_horaResp, _cMsg, _cEmailEnv)

                    next _x
                endif
            endif 

        NEXT _x
        _GeraLog("=== Não possui registros para serem gravados no momento", "respostas.log")    

    ENDIF

RETURN

/*---------------------------------------------------------------------------------------------------*
| Func:  _GeraLog()                                                     							 |
| Desc:  Função para gravação de logs																 |
*---------------------------------------------------------------------------------------------------*/
Static Function _GeraLog(_sTexto,_cArquivo)
	
    Local _nHdl := 0 
   	Local _sArqLog := "F:\TOTVS\ERP\PROTHEUS12_PRODUCAO\protheus_data\Integracao_pesquisas\"+_cArquivo 
        
    if _cProducao == "N"
        _sArqLog := "F:\TOTVS\ERP\PROTHEUS12_PROTOTIPO\protheus_data\Integracao_pesquisas\"+_cArquivo 
    endif
    
    If file(_sArqLog) 
        _nHdl = fOpen(_sArqLog, 1) //indica que será aberto como escrita e retorna o handle
    Else 
        _nHdl = fCreate(_sArqLog, 0) //0 padrão de atributos do arquivo e retorna o handle
    Endif 
    
    fSeek(_nHdl, 0, 2) //posiciona o ponteiro no final do arquivo     
    fWrite(_nHdl, DTOS(Date())+" - "+Time()+" - " + _sTexto + chr (13) + chr (10)) //escreve a string no incio da linha(chr(13)) e depois pula para proxima linha (chr(10))
    fClose(_nHdl)

Return

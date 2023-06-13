#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"          
#Include "FWPrintSetup.ch"
#Include "Rptdef.ch"
#Include "Rwmake.ch"

/*--------------------------------------------------------------------------------------------------------------------+
| Descricao    : Responsável pela rotina de importação de produtos em massa via arquivo na rotina de Outra Ações      |
| Data Criacao : 11/04/2023																							  |
| Desenvolvedor: Alison Godoy                                                                                         |
| Data Alt.    | Descricao                                                                                            |
|   /  /       |                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------*/

//Faz a importação do arquivo e chama IMPPROD
User Function IP011EST()
    
    Local cArq          := "importarProdutos.csv"
    //Private lAutoErrNoFile        := .T.
    
    cArq:= cGetFile( "Arquivo CSV (*.CSV) | *.CSV", "Selecione a planilha padrão",,'C:\'/*'F:\TOTVS\ERP\PROTHEUS12_PROTOTIPO\protheus_data\temp'*/,.F., )

    Processa({|lEnd| IMPPROD(cArq), "Importando Produtos... Aguarde."})

Return

//Le o arquivo e gera os produtos
Static Function IMPPROD(cArq)

    Local cErro
    Local aLog
    Local aVetor        := {}
    Local aSucess       := {}
    Local aErro         := {}
    Local aCodProd      := {}
    Local nTotProdutos  := 0
    Local nZ            := 0
    Local nW            := 0
    Local oExcel        := FWMsExcelEx():New()
    Private lMsErroAuto := .F.

    IF !File(cArq)
        MsgStop("O arquivo " +cArq + " não foi encontrado. A importação será abortada!","ATENCAO")
        Return
    ENDIF

    FT_FUSE(cArq)
    ProcRegua(FT_FLASTREC())
    FT_FGOTOP()

    //PREPARE ENVIRONMENT EMPRESA '01' FILIAL "0201" MODULO "SIGAEST" TABLES "SB1"  //--testes descomentar
    WHILE !FT_FEOF()

        IncProc("Lendo arquivo CSV...")

        aLinha := StrTokArr(FT_FREADLN(),',') //insere linha do arquivo em array

        IF !empty(aLinha)

            If upper(alltrim(aLinha[1])) <> "DESCRICAO" // Não considera a primeira linha pois é cabeçalho
    
                cDescricao  := aLinha[1]
                cTipo       := aLinha[2]
                cUnMedida   := aLinha[3]
                cArmazem    := aLinha[4]
                cNCM        := aLinha[5]
                nOrigem     := aLinha[6]

                AADD(aVetor, {"B1_DESC"  , cDescricao, NIL})
                AADD(aVetor, {"B1_TIPO"  , cTipo     , NIL})
                AADD(aVetor, {"B1_UM"    , cUnMedida , NIL})
                AADD(aVetor, {"B1_LOCPAD", cArmazem  , NIL}) //Não pode vir do documento desconsiderando o 0 antes do número, EX: 1->01 
                AADD(aVetor, {"B1_POSIPI", cNCM      , NIL}) //Não pode vir caractéres além de números
                AADD(aVetor, {"B1_ORIGEM", nOrigem   , NIL})

                lMsErroAuto := .F.

                MSExecAuto({|x, y| Mata010(x, y)}, aVetor, 3)

                 
                if lMsErroAuto
                    aLog    := MostraErro("\logs\import_produtos", "MostraErroIP011EST.log") //cria um arquivo com o erro

                    if !Empty(aLog)
                            //Obtem 9 caracteres após encontrar a frase Id do campo de erro
                            cCampoErro := SUBSTR(RTRIM(StrTokArr2(aLog,"Id do campo de erro: ")[LEN(StrTokArr2(aLog,"Id do campo de erro: "))]),2,9) 

                            //validações dos possíveis erros
                            DO CASE
                            CASE cCampoErro = "B1_LOCPAD" 
                                cErro := "Erro no campo Armazem, verifique o cadastro de Armazem para filial informada!!"

                            CASE cCampoErro = "B1_POSIPI"
                                cErro := "Erro no campo NCM, verifique o cadastro de NCM para filial informada!!"  

                            CASE cCampoErro = "B1_ORIGEM"
                                cErro := "Erro no campo Origem, verifique o cadastro de Origem para filial informada!!"

                            CASE cCampoErro = "B1_CONTA]" 
                                cErro := "Conta Contabil não foi preenchido automaticamente, verifique o vinculo entre TIPO e CC!!"

                            OTHERWISE
                                cErro := "Não foi possível identificar o erro!"

                            ENDCASE

                    else
                        cErro := "Não foi possível identificar o erro!"
                        
                    endif
                    AADD( aErro, {cDescricao,cErro} )
                    aLog := {}
                    aVetor := {}
                    cErro := ''

                else
                    CONOUT("Produto Incluido")
                    AADD( aSucess, cDescricao )
                    aVetor := {}

                endif

            Endif

        ENDIF

    FT_FSKIP()      
    ENDDO
    FT_FUSE()

    //trativa para enviar resultado por e-mail
    nTotProdutos := (LEN(aErro)+LEN(aSucess))

    cHtml := " <p style='font-size:130%'>Olá, segue resultado da importação: </p>" 
    cHtml += " <b><p style='font-size:130%'>Total de Produtos: "+CVALTOCHAR(nTotProdutos)+"</p></b>"
    cHtml += " <b><p style='font-size:130%'>Integrados: "+CVALTOCHAR(LEN(aSucess))+"</p></b>"
    cHtml += " <b><p style='font-size:130%'>Erros: "+CVALTOCHAR(LEN(aErro))+"</p></b>"
    cHtml += " <p style='font-size:130%'>Detalhamento em anexo.</p>"

    //geração do arquivo .xlsx de detalhamento para inserir no anexo
    oExcel:AddworkSheet("Detalhe_Import_Prod")//nome da planilha
    oExcel:AddTable("Detalhe_Import_Prod","Detalhe",.F.)//nome da tabela
    oExcel:AddColumn("Detalhe_Import_Prod","Detalhe","Código",1,2)//planilha,tabela,nome da coluna,1=esquerda-2=direita-3centralizado,tipo de dado
    oExcel:AddColumn("Detalhe_Import_Prod","Detalhe","Descrição",1,1)
    oExcel:AddColumn("Detalhe_Import_Prod","Detalhe","Situação",1,1)

    FOR nZ := 1 TO LEN(aSucess)
        dbSelectArea("SB1")
        cQuery := "SELECT B1_COD FROM SB1010 WHERE D_E_L_E_T_ = '' AND B1_DESC LIKE ('%"+aSucess[nZ]+"%') AND B1_UREV = '"+DTOS(DATE())+"'"
        aCodProd := U_Qry2Array(cQuery)

        oExcel:AddRow("Detalhe_Import_Prod","Detalhe",{aCodProd[1][1],aSucess[nZ],"Sucesso"})

    NEXT nZ
    
    FOR nW := 1 TO LEN(aErro)
        oExcel:AddRow("Detalhe_Import_Prod","Detalhe",{"ERRO",aErro[nW][1],aErro[nW][2]})

    NEXT nW

    oExcel:Activate()
    oExcel:GetXMLFile("\logs\import_produtos\importProdutos.xlsx")//gera Excel

    //Envia e-mail         
    oProcess:= nil
    oProcess:= TWFProcess():New("Emailpro", "E-mail Imp. Produtos")
    oProcess:NewTask ( "Email Imp. Prod.", "\workflow\envia_ImpProdutos.htm")            
    oHTML := oProcess:oHTML   
            
    oHTML:ValByName("TAB_IMPPROD", cHtml)	
    oHTML:ValByName("LOGO", "****")                
    oProcess:cFromName	    := "*****"
    oProcess:cSubject		:= "Importação de Produtos " 
    oProcess:cTo			:= usrRetMail(__cUserId)
    oProcess:cCc			:= "*****"

    oProcess:attachFile("\logs\import_produtos\importProdutos.xlsx")       
    oProcess:Start()

    MSGINFO( "Importação executada com sucesso, resultado enviado por e-mail", "Aviso" )
    //RESET ENVIRONMENT //--testes descomentar
Return()

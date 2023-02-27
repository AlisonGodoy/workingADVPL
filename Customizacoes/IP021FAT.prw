#INCLUDE "Totvs.ch"
#INCLUDE "Tbiconn.ch"
#INCLUDE "topconn.ch"

/*------------------------------------------------------------------------------------------------------------------------------------------------------+
| Descricao    : Tela customizada de envio de DANFE aos clientes e possibilita o usuário escolher anexos, mensagens e destinatários que serão enviadas  |
| Data Criacao : 07/02/2023																							  							  		|
| Desenvolvedor: Alison Godoy                                                                                         							  		|
| Data Alt.    | Descricao                                                                                            							  		|
|   /  /       |                                                                                                      							  		|
+------------------------------------------------------------------------------------------------------------------------------------------------------*/

User Function IP021FAT() 
 
    Processa({|lEnd| U_MailDNF(), "Preparando o envio da Danfe. Aguarde."})
   
Return

USER Function MailDNF()
    
    Local oAnexarArquivos
    Local oDelArquivos
    Local oCCemail
    Local oCCgetEmail
    Local oCustomObs
    Local oListaArquivos
    Local oMensagemEmail
    Local oConfirmar
    Local oCancelar

    Static oAnexo1
    Static oAnexo2
    Static oAnexo3
    Static oAnexo4
    Static oAnexo5
    Static oAnexo6
    Static oAnexo7
    Static oDlg
    Static oFont
    Static oList1
    Static aItens   := { ' '+space(200), 'Boleto com vencimento em  XXXXX'+space(100),'Gentileza considerar NF apenas para escrituração fiscal.'+space(100),'Pagamento já recebido, gentileza considerar NF apenas para escrituração fiscal.'+space(100) }
    Static nList    := 1
    Static cCpyMail := SPACE( 200 )
    Static aDiret   := {}
    Static aDiret1  := {}
    Static cObserv

    DEFINE MSDIALOG oDlg TITLE "Confirmações de Envio Danfe" FROM 000, 000  TO 500, 600 COLORS 0, 16777215 PIXEL

    @ 030, 016 SAY oListaArquivos PROMPT "Lista Arquivos:" SIZE 049, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 016, 156 SAY oMensagemEmail PROMPT "Mensagem E-mail" SIZE 069, 010 OF oDlg COLORS 0, 16777215 PIXEL
    oList1 := TListBox():New(045,155,{|u|if(Pcount()>0,nList:=u,nList)},aItens,110,100,{|| oCustomObs:SetFocus(),cObserv := oList1:GetSelText()},oDlg,,,,.T.)                                   
    @ 027, 155 MSGET oCustomObs VAR cObserv SIZE 112, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 016, 016 BUTTON oAnexarArquivos PROMPT "Anexar Arquivos" ACTION {|| U_AnexoArq()} SIZE 058, 011 OF oDlg PIXEL
    @ 017, 077 BUTTON oDelArquivos PROMPT "Limpar" ACTION {|| U_DelAnexo()} SIZE 032, 009 OF oDlg PIXEL
    @ 045, 016 SAY oAnexo1 PROMPT aDiret1 SIZE 075, 015 OF oDlg COLORS 0, 16777215 PIXEL
    @ 155, 051 SAY oCCemail PROMPT "CC e-mail" SIZE 034, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 155, 092 MSGET oCCgetEmail VAR cCpyMail SIZE 124, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 233, 174 BUTTON oCancelar PROMPT "Cancelar" ACTION {|| U_cleanInf()} SIZE 047, 011 OF oDlg PIXEL
    @ 233, 232 BUTTON oConfirmar PROMPT "Confirmar" ACTION {|| U_envDNF()} SIZE 047, 011 OF oDlg PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

Return

//Inclui os anexos
User Function AnexoArq()
    
    Static cObjTSay := "oAnexo"
    Local nLinha
    _x := len(aDiret)

    IF len(aDiret1) = 0

        aDiret1  := cGetFile('Arquivo *|*.*|Arquivo PDF|*.PDF',	'Selecione arquivo', 0, 'C:\',.F.,, .T.)
        Aadd(aDiret, aDiret1)
        _GeraLog("Anexo: "+aDiret1)

    ELSE

        _x += 1
        aDiretMore  := cGetFile('Arquivo *|*.*|Arquivo PDF|*.PDF',	'Selecione arquivo', 0, 'C:\',.F.,, .T.)
        Aadd(aDiret, aDiretMore) 
        //_GeraLog("Anexo: "+aDiretMore)
        
        //valida qual o número da linha que deve ser utilizado
        DO CASE
            CASE _x = 2
                nLinha := 060
            CASE _x = 3 
                nLinha := 075
            CASE _x = 4
                nLinha := 090
            CASE _x = 5 
                nLinha := 105
            CASE _x = 6
                nLinha := 120
            CASE _x = 7 
                nLinha := 135
            OTHERWISE 
                MSGALERT( "Você excedeu o número de anexos. Não foi possível adicionar!", "Atenção" )
                Return
        ENDCASE 

        //cria os TSay
        &(cObjTSay + CVALTOCHAR(_x)) := TSay():New(nLinha, 016, {|| }, oDlg, , oFont, , , , .T., CLR_BLACK, , 075, 015, , , , , , .T.)
        &(cObjTSay + CVALTOCHAR(_x)):SetText(aDiret[_x])

    ENDIF

Return

//Deleta os anexos
User Function DelAnexo()
    
    Local nX

    IF (len(aDiret) > 0)

        for nX := 1 to len(aDiret)

            &(cObjTSay + CVALTOCHAR(nX)):SetText("")

        next nX

    ENDIF

    aSize(aDiret, 0)
    aDiret1 := {}

Return

//Limpa todos os campos e finaliza Msdialog
User Function cleanInf()

    cCpyMail    := SPACE( 200 )
    cObserv     := ""
    U_DelAnexo()
    oDlg:End()

Return

//Inicia o tratamento para envio do e-mail
User Function envDNF()

    Local nT := 0
    Local cNota := AllTrim(SF2->F2_DOC)
    Local cSerie := alltrim(SF2->F2_SERIE)
    Local cPasta := "\danfes\"        
    Local cPastLoc := "C:\Temp\danfes\" 
    Local _sFilial := Alltrim(cfilant)
    Local cRecno := SF2->(Recno())
    Local cNForClie := ''
    Local cNForCli1 := ''
    Local cHtml := ''
    Local cDanfePDF := ''
    Local aArqDir := {}
    Local aArqDir1 := {} 
    Local cEmail := AllTrim(GetMV("MV_MAILDNF"))
    Local cMailcli:= ""
    Local cNamUser := Alltrim(UsrRetName(__CUSERID))

    Static cObserv := ""

    IF SF2->F2_TIPO $ "D|B"

        cNForClie := Posicione('SA2',1,xFilial('SA2')+SF2->F2_CLIENTE+SF2->F2_LOJA, 'A2_NOME')
        cNForCli1 := AllTrim(cNForClie)
        cMailCli := AllTrim(Posicione('SA2',1,xFilial('SA2')+SF2->F2_CLIENTE+SF2->F2_LOJA, 'A2_EMAIL'))+";"
        cMailCli += AllTrim(Posicione('SA2',1,xFilial('SA2')+SF2->F2_CLIENTE+SF2->F2_LOJA, 'A2_EMAIL2'))

    ELSE

        cNForClie := SA1->A1_NOME
        cNForCli1 := AllTrim(cNForClie)
        cMailCli := AllTrim(Lower(SA1->A1_EMAIL))+";"+AllTrim(Lower(SA1->A1_EMAILCO))

    ENDIF 

    cNForCli1 := U_DelCarac(cNForCli1)      
    cDanfePDF := Alltrim(cfilant)+"_"+cNota+"_"+cSerie+"_"+cNForCli1+".pdf" 

    //GRAVAÇÃO DE LOGS - START
    _GeraLog( "INÍCIO -----------" +DTOC(Date())+" - "+Time() + " - Usuário: "+cNamUser)
    _GeraLog("Nota fiscal nº "+cNota+ " || " +"Cliente "+cNForCli1)
    
    IF (Len(aDiret) > 0)

        for nT := 1 to len(aDiret)
            _GeraLog("Anexo: "+aDiret[nT])
        next nT

    ENDIF

    IF !Empty(cCpyMail)

        _GeraLog("Inserido em cópia o(s) e-mail(s): "+ cCpyMail )

    ENDIF

    IF cObserv != ""

        _GeraLog( "Inserida a observação: "+ cObserv)

    ENDIF
    //GRAVAÇÃO DE LOGS - END 

    IF MSGYESNO("Confirmar o envio para o cliente "+Alltrim(cNForClie)+"? ", "Confirmação!")          
            
        If !File(cPasta + cDanfePDF) 

            if !(ExistDir(cPastLoc))

                MakeDir(cPastLoc)

            endif      
			
            U_IMPINT12(cNota, cSerie, cPastLoc, cRecno,_sFilial, cNForCli1) //função em outro arquivo, responsável por criar e colocar no diretório correto a DANFE

            // copia a danfe da pasta local do usuario para o servidor
            Sleep(8000)     
            CpyT2S("C:\Temp\danfes\" + cDanfePDF, cPasta)
            Sleep(3000)           

        EndIf 

        If !File(cPasta + cDanfePDF)

            MsgAlert("Não foi possivel gerar a danfe!","Envio finalizado")
            return

        Else                   
        
            cHtml := " <p style='font-size:130%'>Olá, prezado cliente "+AllTrim(cNForClie)+".</p>" 
            cHtml += " <p style='font-size:130%'>Segue nota fiscal nº "+cNota+" para programação de pagamento.</p>"

            if !Empty(cObserv)

                cHtml += " <p style='font-size:110%'><b>"+cObserv+"</b></p>"

            endif

            cHtml += " <p style='font-size:130%'>Havendo dúvidas, estamos à disposição.</p>"            
            cHtml += " <br><br><div>Atenção! Este é um e-mail automático e não deve ser respondido.</div>
            cHtml += " <div>Caso necessite entrar em contato, por gentileza, encaminhar para:</div>"
            cHtml += " <div>---</div>" 
            cHtml += " <div>--</div>" 
            cHtml += " <hr>"
            cHtml += " <p>Atenciosamente,</p>"
            cHtml += " <div>---</div>"
            cHtml += " <div>---</div>"
            cHtml += " <div>Santa Cruz do Sul | RS - Brasil</div>"
            cHtml += " <div>Fone: ---</div>"
                        
            oProcess:= nil
            oProcess:= TWFProcess():New("Emaidanf", "E-mail Danfe")
            oProcess:NewTask ( "Email Danfe", "\workflow\faturamento\envia_danfe.htm")            
            oHTML := oProcess:oHTML   
            
            oHTML:ValByName("TAB_DANFE", cHtml)	
            oHTML:ValByName("LOGO", ---")                
            oProcess:cFromName	    := "---"
            oProcess:cSubject		:= "---" - CLIENTE "+AllTrim(cNForClie)+" 
            oProcess:cTo			:= cMailCli
            oProcess:cCc			:= cEmail + cCpyMail

            if (Len(aDiret) > 0)

                for nT:=1 To Len(aDiret)

                    if (aDiret[nT]<>"")

                        aArqDir1 := DIRECTORY(aDiret[nT])
                        Aadd(aArqDir,aArqDir1)
                        CpyT2S(aDiret[nT], cPasta )
                        oProcess:attachFile(cPasta + aArqDir1[1,1])

                    endif

                next nT

            endIf

            oProcess:attachFile(cPasta + cDanfePDF )       
            oProcess:Start()

            if File(cPastLoc + cDanfePDF)

                FErase(cPastLoc + cDanfePDF) 

            endif
        
            MsgInfo("Danfe enviada com sucesso","Envio!")
            _GeraLog( "FIM-------- Danfe enviada com sucesso ---------------" + chr (13) + chr (10))

            U_cleanInf()

        EndIf     
    ELSE

        MsgAlert("Envio do e-mail cancelado","Cancelamento!")

        If File(cPastLoc + cDanfePDF)

            FErase(cPastLoc + cDanfePDF)

        EndIf

        _GeraLog("FIM---- Envio do e-mail cancelado pelo usuário -----" + chr (13) + chr (10) )
        // MsgAlert("Não foi possível encontrar a Danfe!","Atenção!")
    ENDIF

Return 

//Remove caracteres especiais do nome para melhor confiabilidade do sistema.
User Function DelCarac (cNome, lSpace)

    Local cNForCl:= AllTrim(cNome)

    Default lSpace := .T.
   
    cNForCl := StrTran(cNForCl, "'", "")
    cNForCl := StrTran(cNForCl, "#", "")
    cNForCl := StrTran(cNForCl, "%", "")
    cNForCl := StrTran(cNForCl, "*", "")
    cNForCl := StrTran(cNForCl, "&", "")
    cNForCl := StrTran(cNForCl, ">", "")
    cNForCl := StrTran(cNForCl, "<", "")
    cNForCl := StrTran(cNForCl, "!", "")
    cNForCl := StrTran(cNForCl, "@", "")
    cNForCl := StrTran(cNForCl, "$", "")
    cNForCl := StrTran(cNForCl, "(", "")
    cNForCl := StrTran(cNForCl, ")", "")
    cNForCl := StrTran(cNForCl, "_", "")
    cNForCl := StrTran(cNForCl, "=", "")
    cNForCl := StrTran(cNForCl, "+", "")
    cNForCl := StrTran(cNForCl, "{", "")
    cNForCl := StrTran(cNForCl, "}", "")
    cNForCl := StrTran(cNForCl, "[", "")
    cNForCl := StrTran(cNForCl, "]", "")
    cNForCl := StrTran(cNForCl, "/", "")
    cNForCl := StrTran(cNForCl, "?", "")
    cNForCl := StrTran(cNForCl, ".", "")
    cNForCl := StrTran(cNForCl, "\", "")
    cNForCl := StrTran(cNForCl, "|", "")
    cNForCl := StrTran(cNForCl, ":", "")
    cNForCl := StrTran(cNForCl, ";", "")
    cNForCl := StrTran(cNForCl, ",", "")
    cNForCl := StrTran(cNForCl, '"', '')
    cNForCl := StrTran(cNForCl, '°', '')
    cNForCl := StrTran(cNForCl, 'ª', '')
    cNForCl := StrTran(cNForCl, '-', '')

    If lSpace
        cNForCl := StrTran(cNForCl, '     ', '_') //alguns clientes têm muitos espaços entre sobrenomes
        cNForCl := StrTran(cNForCl, '    ', '_')
        cNForCl := StrTran(cNForCl, '   ', '_')
        cNForCl := StrTran(cNForCl, '  ', '_')
        cNForCl := StrTran(cNForCl, ' ', '_')
    Else 
        cNForCl := StrTran(cNForCl, ' ', '')
        cNForCl := StrTran(cNForCl, '  ', '')
    EndIf    
        
Return cNForCl

Static Function _GeraLog(_sTexto)

    Local _nHdl := 0 
    Local _sArqLog := "\logs\danfe_mail\danfe_mail.log"    

    If file(_sArqLog) 
        _nHdl = fOpen(_sArqLog, 1) 
    Else 
        _nHdl = fCreate(_sArqLog, 0) 
    Endif 
    
    // Conout(_sTexto)
    fSeek(_nHdl, 0, 2) // Encontra final do arquivo     
    fWrite(_nHdl, _sTexto + chr (13) + chr (10)) 
    fClose(_nHdl)

Return
 

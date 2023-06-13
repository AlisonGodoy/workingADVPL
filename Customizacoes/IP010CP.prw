#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
 
/*--------------------------------------------------------------------------------------------------------------------+
| Descricao    : Responsável por replicar os pedidos de compras entre filiais pela rotina em Outras Ações do MATA121  |
| Data Criacao : 05/04/2023																							  |
| Desenvolvedor: Alison Godoy                                                                                         |
| Data Alt.    | Descricao                                                                                            |
|   /  /       |                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------*/
User Function IP010CP()

   Local cQuant := 0 
   Local lPosic := .F. 
   Local aFilial    := ''
   Local cFilAux    := ''  

   aFilial := FwListBranches(.F., .T., .T.,{'FLAG','SM0_EMPRESA','SM0_CODFIL','SM0_NOMRED'})
   cFilAux := cFilAnt
   //cFilAnt := aFilial[1][3]

   lPosic := MsgYesNo("Você está posicionado em algum dos pedidos que serão replicados?","Confirma?")

   If lPosic

      cQuant := FWInputBox("Informe quantas vezes deseja replicar esse pedido:", "")

      If cQuant <>''
      
         If MsgYesNo("Replicar pedidos "+cQuant+" vez(es)?")

            If !Empty(cQuant) .AND. Type(cQuant)=="N" 
         
               Processa({|| ReplPed(cQuant,aFilial)}, "Aguarde!", "Gerando Pedidos de Compra",.F.)

               cFilAnt := cFilAux

            Else

               MsgAlert("Informe um número válido." ,"Atenção!")

            EndIf

         EndIf
      
      EndIf

   EndIf
   
Return

Static Function ReplPed(cQuant,aFilial) 
  
   Local nX             := 0
   Local nY             := 0
   Local nW             := 0
   Local nZ             := 0 
   Local nU             := 0
   Local nV             := 0
   Local _nQP           := 0
   Local _nQF           := 0
   Local aItens         := {}
   Local aAuxRat        := {}
   Local aCabec         := {} 
   Local aItemRat       := {}
   Local aItensRat      := {}
   Local aProdPedido    := {}
   Local cNamUser       := AllTrim(UsrRetName(__CUSERID))  
   Local cPedOrig       := SC7->C7_NUM
   Local cFilialOrig    := SC7->C7_FILIAL
   Local cLocal         := SC7->C7_LOCAL
   Local cIdRepl        := Replace(Dtoc(Date()),'/','')+Replace(Time(),':','')
  

   Private lMSHelpAuto     := .T. // variável de controle interno da rotina automatica que informa se houve erro durante o processamento
   Private lAutoErrNoFile  := .T. // variável que define que o help deve ser gravado no arquivo de log e que as informações estão vindo à partir da rotina automática.
   Private lMsErroAuto     := .F. // força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário 

   GeraLog( chr (13) + chr (10) + "INÍCIO... " +DTOC(Date())+" - "+Time() + " - Usuário: "+cNamUser+" - Ident: "+cIdRepl)
   GeraLog("Pedido "+cPedOrig+" será replicado "+cQuant+" vezes.")

    FOR _nQF := 1 TO LEN(aFilial)
        cFilAnt := aFilial[_nQF][3]
        _nQP    := 0

        For _nQP := 1 to Val(cQuant) // quantas vezes vai replicar
            //Declara variaveis novamente para atribuir seu valor original
            nW          := 0
            nX          := 0
            nY          := 0
            nW          := 0
            nZ          := 0 
            nU          := 0
            nV          := 0
            aItens      := {}
            aCabec      := {}  
            aLinha      := {}
            aCab        := {}
            aItem       := {}
            aAuxRat     := {}
            aItemRat    := {}
            aItensRat   := {}
            aProdPedido := {}
            aQueryProd  := {}
            aQueryLocal := {}

            aCab:={{"C7_EMISSAO"  ,dDataBase       ,Nil},; // Data de Emissao
                    {"C7_FORNECE" ,SC7->C7_FORNECE ,Nil},; // Fornecedor
                    {"C7_LOJA"    ,SC7->C7_LOJA    ,Nil},; // Loja do Fornecedor
                    {"C7_CONTATO" ,SC7->C7_CONTATO ,Nil},; // Contaâto
                    {"C7_COND"    ,SC7->C7_COND    ,Nil},; // Condicao de pagamento
                    {"C7_FILENT"  ,cFilAnt         ,Nil}}  // Filial Entrega

            //Monta Query e Array para os itens do pedido
            cQueryItens := "SELECT C7_ITEM, C7_PRODUTO, C7_QUANT, C7_PRECO, C7_DATPRF, C7_TES, C7_FLUXO, C7_OBS, C7_OBSERVA, C7_CC, C7_CONTA, C7_ITEMCTA, C7_CLVL, C7_TXMOEDA, C7_OPER2, C7_LOCAL FROM SC7010 WHERE D_E_L_E_T_ = '' AND C7_NUM = '"+SC7->C7_NUM+"' AND C7_FILIAL = '"+SC7->C7_FILIAL+"'"
            aQueryItens  := U_Qry2Array(cQueryItens)

            FOR nX = 1 TO LEN(aQueryItens)
            aItem    :={{"C7_ITEM"    ,aQueryItens[nX][1]   ,Nil},; //Numero do Item
                        {"C7_PRODUTO" ,aQueryItens[nX][2]   ,Nil},; //Codigo do Produto
                        {"C7_QUANT"   ,aQueryItens[nX][3]   ,Nil},; //Quantidade
                        {"C7_PRECO"   ,aQueryItens[nX][4]   ,Nil},; //Preco
                        {"C7_DATPRF"  ,aQueryItens[nX][5]   ,Nil},; //Previsão de Faturamento
                        {"C7_TES"     ,aQueryItens[nX][6]   ,Nil},; //Tes
                        {"C7_FLUXO"   ,aQueryItens[nX][7]   ,Nil},; //Fluxo de Caixa (S/N)
                        {"C7_OBS"     ,aQueryItens[nX][8]   ,Nil},; //Observação
                        {"C7_OBSERVA" ,aQueryItens[nX][9]   ,Nil},; //Observação
                        {"C7_CC"      ,aQueryItens[nX][10]  ,Nil},; //Centro de Custo
                        {"C7_CONTA"   ,aQueryItens[nX][11]  ,Nil},; //Conta Contabil
                        {"C7_ITEMCTA" ,aQueryItens[nX][12]  ,Nil},; //Item Conta
                        {"C7_CLVL"    ,aQueryItens[nX][13]  ,Nil},; //Classe Valor
                        {"C7_TXMOEDA" ,aQueryItens[nX][14]  ,Nil},; //Taxa de Moeda
                        {"C7_OPER2"   ,aQueryItens[nX][15]  ,Nil},; //Operação
                        {"C7_LOCAL"   ,aQueryItens[nX][16]  ,Nil}}  //Localizacao
            aadd(aItens, aItem)            

            NEXT nX

            //Verifica se possui e monta Query e Array para o rateio do pedido
            cQueryRateio := "SELECT CH_ITEMPD, CH_ITEM, CH_PERC, CH_CC, CH_CONTA, CH_ITEMCTA, CH_CLVL, CH_CUSTO1, CH_CUSTO2, CH_CUSTO3, CH_CUSTO4, CH_CUSTO5  FROM SCH010 WHERE D_E_L_E_T_ = '' AND CH_PEDIDO = '"+SC7->C7_NUM+"' AND CH_FILIAL = '"+SC7->C7_FILIAL+"'"
            aQueryRateio := U_Qry2Array(cQueryRateio)

            IF LEN(aQueryRateio) > 0

                aAdd(aItensRat,{aQueryRateio[1][1],{ }})

                FOR nY = 1 TO LEN(aQueryRateio)         

                aItemRat:={{"CH_ITEM"       ,aQueryRateio[nY][2]    ,Nil},; //Numero de sequencia do rateio
                            {"CH_PERC"      ,aQueryRateio[nY][3]    ,Nil},; //Percentual
                            {"CH_CC"        ,aQueryRateio[nY][4]    ,Nil},; //Centro de Custo
                            {"CH_CONTA"     ,aQueryRateio[nY][5]    ,Nil},; //Conta Contabil
                            {"CH_ITEMCTA"   ,aQueryRateio[nY][6]    ,Nil},; //Item Conta
                            {"CH_CLVL"      ,aQueryRateio[nY][7]    ,Nil},; //Classe Valor
                            {"CH_CUSTO1"    ,aQueryRateio[nY][8]    ,Nil},; //Custos
                            {"CH_CUSTO2"    ,aQueryRateio[nY][9]    ,Nil},;
                            {"CH_CUSTO3"    ,aQueryRateio[nY][10]   ,Nil},;
                            {"CH_CUSTO4"    ,aQueryRateio[nY][11]   ,Nil},;
                            {"CH_CUSTO5"    ,aQueryRateio[nY][12]   ,Nil}}
                            
                aadd(aAuxRat, aItemRat)

                if aItensRat[LEN(aItensRat)][1] <> aQueryRateio[nY][1]//se for o mesmo itempdd do primeiro array cadastra nivel abaixo se não cria novo nível

                    aAdd(aItensRat,{aQueryRateio[nY][1],{ }})                     
                    aAdd(aItensRat[LEN(aItensRat)][2],aItemRat)

                else

                    aAdd(aItensRat[LEN(aItensRat)][2],aItemRat)

                endif 
                
                NEXT nY

                lMsErroAuto := .F.
                MSExecAuto({|k,v,x,y,z,w| MATA120(k,v,x,y,z,w)},1,aCab,aItens,3,.F.,aItensRat)

            ELSE

                lMsErroAuto := .F.
                MSExecAuto({|k,v,x,y,z,w| MATA120(k,v,x,y,z,w)},1,aCab,aItens,3)

            ENDIF
        
            If !lMsErroAuto

            ConOut("Incluido com sucesso! ")

            Else

            ConOut("Erro na inclusao!")
            
            //tratamento para mostrar ao usuário o que ocasionou o erro, pois o MostraErro() normalmente não traz a informação.
            cQueryProd      := "SELECT DISTINCT B1_COD FROM SB1010 WHERE D_E_L_E_T_ = '' AND B1_COD IN (SELECT DISTINCT C7_PRODUTO FROM SC7010 WHERE D_E_L_E_T_ = '' AND C7_NUM = '"+cPedOrig+"' AND C7_FILIAL = '"+cFilialOrig+"') AND B1_FILIAL = '"+cFilAnt+"'"
            cQueryLocal     := "SELECT NNR_CODIGO FROM NNR010 WHERE D_E_L_E_T_ = '' AND NNR_CODIGO = '"+cLocal+"' AND NNR_FILIAL = '"+cFilAnt+"'"

            aQueryProd := U_Qry2Array(cQueryProd)
            aQueryLocal := U_Qry2Array(cQueryLocal)
            
            DO CASE

                CASE LEN(aQueryProd) > 0 .AND. LEN(aQueryLocal) > 0 .AND. LEN(aQueryProd) < LEN(aItens) 
                    FOR nZ := 1 TO LEN(aItens)
                        cContem := .F.
                        for nU := 1 TO LEN(aQueryProd)
                            if aItens[nZ][2][2] == aQueryProd[nU][1]
                            cContem := .T.
                            elseif nU == LEN(aQueryProd) .AND. cContem = .F.          
                                aadd(aProdPedido, aItens[nZ][2])
                            endif
                        next nU
                    NEXT nZ

                    MSGALERT( "Não foi possível gerar o pedido de compra. O(s) seguinte(s) produto(s) não está(ão) cadastrado(s) na filial de destino", "Atenção" )
                    FOR nV := 1 TO LEN(aProdPedido)
                        MSGINFO( aProdPedido[nV], "Aviso" )
                    NEXT nV

                CASE LEN(aQueryProd) == 0

                    MSGALERT( "Não foi possível gerar o pedido de compra. OS PRODUTOS não estão cadastrados na Filial: " + cFilAnt, "Atenção" )  

                CASE LEN(aQueryLocal) == 0

                    MSGALERT( "Não foi possível gerar o pedido de compra. O LOCAL DE ESTOQUE não está cadastrado na Filial: " + cFilAnt, "Atenção" )

                OTHERWISE

                    MSGALERT( "Não foi possível gerar o pedido de compra. Verifique os cadastros na Filial que irá receber o pedido", "Atenção" )

            ENDCASE
            
            EndIf
        
        Next _nQP
        
        //Verifica e traz os códigos dos pedidos gerados para mostrar ao usuário
        nTopQry := (_nQP-1)
        cQryNvo := " SELECT DISTINCT TOP "+CVALTOCHAR(nTopQry)+" C7_NUM FROM SC7010 WHERE D_E_L_E_T_='' AND C7_FORNECE = '"+SC7->C7_FORNECE+"' AND C7_FILIAL = '"+SC7->C7_FILIAL+"' ORDER BY C7_NUM DESC"
        aPCNvo  := U_Qry2Array(cQryNvo)

        IF !lMsErroAuto .AND. LEN(aPCNvo) > 0 

            FOR nW := 1 TO LEN(aPCNvo)
                MSGINFO( "Pedido de Compra Gerado: "+ aPCNvo[nW][1], "Atenção" )
            NEXT nW

        ENDIF
    
    NEXT _nQF

Return


Static Function GeraLog(_sTexto)
    Local _nHdl := 0 
    Local _sArqLog := "\logs\replica_pc\replica_pc.log"    

    If file(_sArqLog) 
        _nHdl = fOpen(_sArqLog, 1) 
    Else 
        _nHdl = fCreate(_sArqLog, 0) 
    Endif 

    fSeek(_nHdl, 0, 2) // Encontra final do arquivo     
    fWrite(_nHdl, _sTexto + chr (13) + chr (10)) 
    fClose(_nHdl)
    
Return



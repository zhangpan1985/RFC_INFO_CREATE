*&---------------------------------------------------------------------*
*&  包含                LZMM_RFC_INFOF01
*&---------------------------------------------------------------------*
FORM check_info_record USING ls_rfclog TYPE zmmt_info_rfclog
                       CHANGING p_action TYPE c.
  DATA: h_meico LIKE meico, "82403 Anfang
        h_eina  LIKE  eina.
  h_meico-ekorg = ls_rfclog-ekorg.
  h_meico-werks = ls_rfclog-werks.
  h_meico-lifnr = ls_rfclog-lifnr.
  h_meico-matnr = ls_rfclog-matnr.
  CALL FUNCTION 'ME_READ_INFORECORD'
    EXPORTING
      incom     = h_meico
    IMPORTING
      einadaten = h_eina
    EXCEPTIONS
      OTHERS    = 1.
  IF sy-subrc EQ 0 AND NOT h_eina-infnr IS INITIAL.
    SELECT SINGLE infnr INTO h_eina-infnr FROM eine
     WHERE infnr = h_eina-infnr
       AND ekorg = ls_rfclog-ekorg
       AND werks = ls_rfclog-werks
       AND esokz = ls_rfclog-esokz.
    IF sy-subrc = 0.
      p_action = 'U'."已经存在信息记录了需要修改.
    ELSE.
      p_action = 'A'."不存在信息记录时需要创建.
    ENDIF.
  ELSE.
    p_action = 'A'."不存在信息记录时需要创建.
  ENDIF.

ENDFORM.


FORM frm_check_data TABLES lt_input lt_rfclog.
  DATA: ls_input  TYPE zmms_info_input,
        ls_rfclog TYPE zmmt_info_rfclog.
  DATA: l_mara TYPE mara,
        l_marm TYPE marm,
        l_marc TYPE marc.
  DATA: l_mkal TYPE mkal.
  DATA: l_lfa1 TYPE lfa1.
  DATA: l_lfm1 TYPE lfm1.

  LOOP AT lt_input INTO ls_input.
    CLEAR: ls_rfclog.
    MOVE-CORRESPONDING ls_input TO ls_rfclog.
    IF ls_rfclog-lifnr IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '供应商必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_rfclog-lifnr
        IMPORTING
          output = ls_rfclog-lifnr.
      SELECT SINGLE * INTO l_lfa1 FROM lfa1 WHERE lifnr = ls_rfclog-lifnr.
      IF sy-subrc <> 0.
        ls_rfclog-errchk = 'X'.
        ls_rfclog-mark = icon_led_red.
        ls_rfclog-errmsg  = '供应商(' && ls_rfclog-lifnr &&  ')不存在'.
        APPEND ls_rfclog TO lt_rfclog.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF ls_rfclog-matnr IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '物料必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          input        = ls_rfclog-matnr
        IMPORTING
          output       = ls_rfclog-matnr
        EXCEPTIONS
          length_error = 1
          OTHERS       = 2.
    ENDIF.

    IF ls_rfclog-ekorg IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '采购组织必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    IF ls_rfclog-werks IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '工厂必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    IF NOT ( ls_rfclog-esokz0 = 'X' OR ls_rfclog-esokz2 = 'X' OR ls_rfclog-esokz3 = 'X' ).
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '信息类别必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    IF ls_rfclog-mwskz IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '税码必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

*    IF ls_rfclog-esokz3 = 'X'.
*      IF ls_rfclog-verid is initial.
*        ls_rfclog-errchk = 'X'.
*        ls_rfclog-mark = icon_led_red.
*        ls_rfclog-errmsg  = 'BOM版本必填'.
*        APPEND ls_rfclog TO lt_rfclog.
*        CONTINUE.
*      ELSE.
*        SELECT SINGLE * INTO l_mkal FROM mkal WHERE matnr = ls_rfclog-matnr
*                                              AND   werks = ls_rfclog-werks
*                                              AND   verid = ls_rfclog-verid.
*        IF sy-subrc <> 0.
*          ls_rfclog-errchk = 'X'.
*          ls_rfclog-mark = icon_led_red.
*          ls_rfclog-errmsg  = '工厂(' && ls_rfclog-werks && ')下不存在物料(' && ls_rfclog-matnr && ')的BOM版本'.
*          APPEND ls_rfclog TO lt_rfclog.
*          CONTINUE.
*        ENDIF.
*      ENDIF.
*    ENDIF.

    IF ls_rfclog-datab IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '价格有效开始日期必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    IF ls_rfclog-datbi IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '价格有效结束日期必填'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.


    IF ls_rfclog-aplfz IS INITIAL OR ls_rfclog-aplfz = '0'.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '交货日必填且不能为0'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.


    IF ls_rfclog-netpr IS INITIAL OR ls_rfclog-netpr = '0'.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '价格必输且不能为0'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.


    IF ls_rfclog-konwa IS NOT INITIAL.
      SELECT COUNT( * ) FROM tcurc WHERE waers = ls_rfclog-konwa.
      IF sy-subrc NE 0.
        ls_rfclog-errchk = 'X'.
        ls_rfclog-mark = icon_led_red.
        ls_rfclog-errmsg  = '货币单位不存在'.
        APPEND ls_rfclog TO lt_rfclog.
        CONTINUE.
      ENDIF.
    ENDIF.


    CLEAR l_mara.
    SELECT SINGLE * INTO l_mara FROM mara WHERE matnr = ls_rfclog-matnr.
    IF sy-subrc = 0.
      ls_rfclog-bstme = l_mara-bstme.
      ls_rfclog-meins = l_mara-meins.
*      IF l_mara-mtart = 'HA03' OR l_mara-mtart = 'HA04' OR l_mara-mtart = 'HA05' OR l_mara-mtart = 'HA06'.
*        ls_rfclog-meprf = '2'."HA03:材料/HA04:原材料/HA05:包装材料/HA06:辅助材料 采用2-交货日期控制;
*      ELSE."if l_mara-mtart = 'HA07' or l_mara-mtart = 'HA08'.
*        ls_rfclog-meprf = '1'."HA07:备品备件/HA08:助销物料 使用1-订单日期控制
*      ENDIF.
    ELSE.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '物料不存在或没有激活'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.
    ls_rfclog-meprf = '1'.

    CLEAR l_marc.
    SELECT SINGLE * INTO l_marc FROM marc WHERE matnr = ls_rfclog-matnr
                                          AND   werks = ls_rfclog-werks.
    IF sy-subrc = 0.
      IF l_marc-ekgrp IS NOT INITIAL.
        ls_rfclog-ekgrp = l_marc-ekgrp.
      ENDIF.
    ELSE.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '工厂(' && ls_rfclog-werks && ')下不存在物料(' && ls_rfclog-matnr && ')'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    IF ls_rfclog-bstme IS NOT INITIAL.
      CLEAR l_marm.
      SELECT SINGLE * INTO l_marm FROM marm WHERE matnr = ls_rfclog-matnr
                                              AND meinh = ls_rfclog-bstme.
      IF sy-subrc = 0.
        ls_rfclog-umren = l_marm-umren.
        ls_rfclog-umrez = l_marm-umrez.
      ENDIF.
    ENDIF.

    IF ls_rfclog-ekgrp IS INITIAL.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '采购组不存在'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    SELECT SINGLE * INTO l_lfm1 FROM lfm1 WHERE lifnr = ls_rfclog-lifnr
                                          AND   ekorg = ls_rfclog-ekorg.
    IF sy-subrc <> 0.
      ls_rfclog-errchk = 'X'.
      ls_rfclog-mark = icon_led_red.
      ls_rfclog-errmsg  = '供应商(' && ls_rfclog-lifnr && ')与采购组织(' && ls_rfclog-ekorg && ')不匹配'.
      APPEND ls_rfclog TO lt_rfclog.
      CONTINUE.
    ENDIF.

    IF ls_rfclog-zterm IS NOT INITIAL.
      SELECT COUNT( * ) FROM t052 WHERE zterm = ls_rfclog-zterm.
      IF sy-subrc NE 0.
        ls_rfclog-errchk = 'X'.
        ls_rfclog-mark = icon_led_red.
        ls_rfclog-errmsg  = '付款条件不存在'.
        APPEND ls_rfclog TO lt_rfclog.
        CONTINUE.
      ENDIF.
    ENDIF.


    CLEAR: ls_rfclog-infnr0,ls_rfclog-infnr2,ls_rfclog-infnr3.
    IF ls_rfclog-mark IS INITIAL.
      ls_rfclog-mark = icon_led_yellow.
    ENDIF.
    APPEND ls_rfclog TO lt_rfclog.

  ENDLOOP.

  SORT lt_rfclog.
  DELETE ADJACENT DUPLICATES FROM lt_rfclog COMPARING ALL FIELDS.

ENDFORM.


FORM bdc_dynpro TABLES it_bdcdata USING p_program p_dynpro.
  DATA: lw_bdcdata TYPE bdcdata.
  lw_bdcdata-program = p_program.
  lw_bdcdata-dynpro  = p_dynpro.
  lw_bdcdata-dynbegin = 'X'.
  APPEND lw_bdcdata TO it_bdcdata.
ENDFORM.


FORM bdc_field TABLES it_bdcdata USING p_fnam p_fval.
  DATA: lw_bdcdata TYPE bdcdata.
  lw_bdcdata-fnam = p_fnam.
  lw_bdcdata-fval = p_fval.
  APPEND lw_bdcdata TO it_bdcdata.
ENDFORM.


FORM frm_bdcset_data TABLES it_bdcdata
                      USING p_action TYPE c
                   CHANGING ls_rfclog TYPE zmmt_info_rfclog.
  DATA:lv_datab TYPE char10.
  DATA:lv_datbi TYPE char10.
  DATA:lv_netpr TYPE char15.


  WRITE ls_rfclog-datab TO lv_datab.
  WRITE ls_rfclog-datbi TO lv_datbi.
  WRITE ls_rfclog-netpr TO lv_netpr.

  DATA:l_popup TYPE c.
  IF p_action = 'A'.
****创建采购信息记录
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0100'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_CURSOR' 'EINA-LIFNR'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '/00'.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINA-LIFNR' ls_rfclog-lifnr.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINA-MATNR' ls_rfclog-matnr.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-EKORG' ls_rfclog-ekorg.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-WERKS' ls_rfclog-werks.
    CASE ls_rfclog-esokz.
      WHEN gc_esokz0."信息类别: 0-标准
        PERFORM bdc_field TABLES it_bdcdata USING 'RM06I-NORMB' 'X'.
      WHEN gc_esokz2. "信息类别: 2-寄售
        PERFORM bdc_field TABLES it_bdcdata USING 'RM06I-KONSI' 'X'.
      WHEN gc_esokz3."信息类别: 3-委外
        PERFORM bdc_field TABLES it_bdcdata USING 'RM06I-LOHNB' 'X'.
    ENDCASE.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0101'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=EINE'.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0102'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '/00'.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-APLFZ' ls_rfclog-aplfz.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-EKGRP' ls_rfclog-ekgrp.
    "IF ls_rfclog-esokz = gc_esokz3."信息类别: 3-委外
    "  perform bdc_field TABLES it_bdcdata USING 'EINE-VERID' ls_rfclog-verid.
    "ENDIF.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-MEPRF' ls_rfclog-meprf.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-NETPR' lv_netpr.
*{   DELETE         DS4K901757                                        1
*\    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-INCO1' ls_rfclog-inco_key.
*\    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-INCO2' ls_rfclog-inco_loc.
*}   DELETE
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-WAERS' ls_rfclog-konwa.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-PEINH' ls_rfclog-kpein.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-MWSKZ' ls_rfclog-mwskz.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0105'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=KO'.
    PERFORM frm_get_popupx USING ls_rfclog-lifnr ls_rfclog-ekorg CHANGING l_popup.
    IF l_popup = 'X'.
      PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPLMEKO' '0501'.
      PERFORM bdc_field TABLES it_bdcdata USING 'BDC_CURSOR' 'T685-KSCHL(01)'.
      PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=PICK'.
    ENDIF.

    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMV13A' '0201'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=PDAT'.
*    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=SICH'.
    PERFORM bdc_field TABLES it_bdcdata USING 'RV13A-DATAB' lv_datab.
    PERFORM bdc_field TABLES it_bdcdata USING 'RV13A-DATBI' lv_datbi.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-KBETR(01)' lv_netpr.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-KPEIN(01)' ls_rfclog-kpein.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-KONWA(01)' ls_rfclog-konwa.
    PERFORM bdc_field TABLES it_bdcdata USING 'RV130-SELKZ(01)' 'X'.

    "采购信息记录增强屏幕
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMV13A' '0300'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=PDZV'.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-ZZCGHTH' ls_rfclog-zzcghth.
    ls_rfclog-zbname = sy-uname.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-ZBNAME' ls_rfclog-zbname.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMV13A' '0305'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=SICH'.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-ZTERM' ls_rfclog-zterm.


  ELSE.
****修改采购信息记录
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0100'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_CURSOR' 'EINA-LIFNR'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '/00'.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINA-LIFNR' ls_rfclog-lifnr.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINA-MATNR' ls_rfclog-matnr.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-EKORG' ls_rfclog-ekorg.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-WERKS' ls_rfclog-werks.

    CASE ls_rfclog-esokz.
      WHEN gc_esokz0."信息类别: 0-标准
        PERFORM bdc_field TABLES it_bdcdata USING 'RM06I-NORMB' 'X'.
      WHEN gc_esokz2. "信息类别: 2-寄售
        PERFORM bdc_field TABLES it_bdcdata USING 'RM06I-KONSI' 'X'.
      WHEN gc_esokz3."信息类别: 3-委外
        PERFORM bdc_field TABLES it_bdcdata USING 'RM06I-LOHNB' 'X'.
    ENDCASE.

    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0101'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=EINE'.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0102'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_CURSOR' 'EINE-NETPR'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '/00'.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-APLFZ' ls_rfclog-aplfz.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-EKGRP' ls_rfclog-ekgrp.
    "IF ls_rfclog-esokz = gc_esokz3."信息类别: 3-委外
    "  perform bdc_field TABLES it_bdcdata USING 'EINE-VERID' ls_rfclog-verid.
    "ENDIF.
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-MEPRF' ls_rfclog-meprf.
*{   DELETE         DS4K901766                                        2
*\    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-INCO1' ls_rfclog-inco_key.
*\    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-INCO2' ls_rfclog-inco_loc.
*}   DELETE
    PERFORM bdc_field TABLES it_bdcdata USING 'EINE-MWSKZ' ls_rfclog-mwskz.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMM06I' '0105'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=KO'.
    PERFORM frm_get_popupx USING ls_rfclog-lifnr ls_rfclog-ekorg CHANGING l_popup.
    IF l_popup = 'X'.
      PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPLMEKO' '0501'.
      PERFORM bdc_field TABLES it_bdcdata USING 'BDC_CURSOR' 'T685-KSCHL(01)'.
      PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=PICK'.
    ENDIF.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPLV14A' '0102'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=NEWD'.

    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMV13A' '0201'.
*    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=SICH'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=PDAT'.
    PERFORM bdc_field TABLES it_bdcdata USING 'RV13A-DATAB' lv_datab.
    PERFORM bdc_field TABLES it_bdcdata USING 'RV13A-DATBI' lv_datbi.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-KBETR(01)' lv_netpr.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-KPEIN(01)' ls_rfclog-kpein.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-KONWA(01)' ls_rfclog-konwa.
    PERFORM bdc_field TABLES it_bdcdata USING 'RV130-SELKZ(01)' 'X'.

    "采购信息记录增强屏幕
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMV13A' '0300'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=PDZV'.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-ZZCGHTH' ls_rfclog-zzcghth.
    ls_rfclog-zbname = sy-uname.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-ZBNAME' ls_rfclog-zbname.
    PERFORM bdc_dynpro TABLES it_bdcdata USING 'SAPMV13A' '0305'.
    PERFORM bdc_field TABLES it_bdcdata USING 'BDC_OKCODE' '=SICH'.
    PERFORM bdc_field TABLES it_bdcdata USING 'KONP-ZTERM' ls_rfclog-zterm.

  ENDIF.

ENDFORM.


FORM frm_bdcset_insert TABLES it_bdcdata
                        USING p_action TYPE c
                     CHANGING ls_rfclog TYPE zmmt_info_rfclog.


  EXPORT gm_zbname = 'W' TO MEMORY ID 'GM_ZBNAME'.

  DATA:it_mesg    LIKE bdcmsgcoll OCCURS 0 WITH HEADER LINE.
  DATA:l_mode TYPE c VALUE 'N'."mode=A,可以弹出前台界面.
  DATA:lv_action TYPE string.
  IF p_action = 'A'."创建信息记录
    lv_action = '创建'.
    CALL TRANSACTION 'ME11' USING it_bdcdata
                            MODE l_mode UPDATE 'S'
                            MESSAGES INTO it_mesg.
    CALL FUNCTION 'DEQUEUE_ALL'
      EXPORTING
        _synchron = 'X'.

*    IF SY-SUBRC = 0.
    COMMIT WORK AND WAIT.
*    WAIT UP TO 3 SECONDS.
**    ELSE.
**      ROLLBACK WORK.
*    ENDIF.
  ELSE."修改信息记录
    lv_action = '更新'.
    CALL TRANSACTION 'ME12' USING it_bdcdata
                            MODE l_mode UPDATE 'S'
                            MESSAGES INTO it_mesg.

    CALL FUNCTION 'DEQUEUE_ALL'
      EXPORTING
        _synchron = 'X'.

*    IF SY-SUBRC = 0.
    COMMIT WORK AND WAIT.
*    WAIT UP TO 2 SECONDS.
**    ELSE.
**      ROLLBACK WORK.
*    ENDIF.
  ENDIF.


  DATA: l_message TYPE  bapireturn-message.
  READ TABLE it_mesg WITH KEY msgtyp = 'E'.
  IF sy-subrc = 0.
    ls_rfclog-errchk = 'X'.
    ls_rfclog-mark = icon_led_red.
    MESSAGE ID        it_mesg-msgid
               TYPE   it_mesg-msgtyp
               NUMBER it_mesg-msgnr
               WITH   it_mesg-msgv1
                      it_mesg-msgv2
                      it_mesg-msgv3
                      it_mesg-msgv4
                   INTO l_message.
    CONCATENATE lv_action '失败' INTO ls_rfclog-status.
    CONCATENATE 'E:' l_message INTO ls_rfclog-errmsg.
  ELSE.
    READ TABLE it_mesg WITH KEY msgtyp = 'S'.
    IF sy-subrc = 0.
      CLEAR: ls_rfclog-errchk.
      ls_rfclog-mark = icon_led_green.
      MESSAGE ID     it_mesg-msgid
          TYPE         it_mesg-msgtyp
          NUMBER       it_mesg-msgnr
          WITH         it_mesg-msgv1
                       it_mesg-msgv2
                       it_mesg-msgv3
                       it_mesg-msgv4
              INTO l_message.
      ls_rfclog-infnr = it_mesg-msgv1."信息记录号
      CONCATENATE lv_action '成功' INTO ls_rfclog-status.
      CONCATENATE 'S:' l_message INTO ls_rfclog-errmsg.
    ENDIF.
  ENDIF.
  ls_rfclog-crdat = sy-datum.
  ls_rfclog-crtim = sy-uzeit.
ENDFORM.


FORM frm_get_popupx  USING    p_l_lifnr
                              p_l_ekorg
                     CHANGING p_l_popup.
  DATA:ls_lfm1 TYPE lfm1.
  CLEAR:p_l_popup.
  SELECT SINGLE * INTO ls_lfm1 FROM lfm1 WHERE lifnr = p_l_lifnr AND ekorg = p_l_ekorg.
  IF ls_lfm1 IS NOT INITIAL.
    IF ls_lfm1-kalsk = 'Z2' OR ls_lfm1-kalsk = '11'.
      p_l_popup = 'X'.
    ENDIF.
  ENDIF.
ENDFORM.


FORM update_planym USING ls_rfclog TYPE zmmt_info_rfclog.
  DATA: l_count TYPE i VALUE 0.
  DATA: l_knumh TYPE konh-knumh.
  DATA: l_planym TYPE konh-planmonths.
  IF ls_rfclog-planym IS NOT INITIAL.
    SELECT SINGLE
           konh~knumh      "条件记录号
           konh~planmonths INTO (l_knumh,l_planym)
      FROM konh
        INNER JOIN a017 ON a017~knumh = konh~knumh
        INNER JOIN eine ON a017~ekorg = eine~ekorg AND a017~esokz = eine~esokz AND a017~werks = eine~werks
        INNER JOIN eina ON eine~infnr = eina~infnr
      WHERE    a017~lifnr = ls_rfclog-lifnr    "供应商
           AND a017~matnr = ls_rfclog-matnr    "物料
           AND a017~ekorg = ls_rfclog-ekorg    "采购组织
           AND a017~werks = ls_rfclog-werks    "工厂
           AND a017~esokz = ls_rfclog-esokz    "信息类别
           AND konh~datab = ls_rfclog-datab    "价格有效期间开始
           AND konh~datbi = ls_rfclog-datbi.   "价格有效期间结束
    IF l_knumh IS NOT INITIAL. "如果找到条件记录号则更新计划月份.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = l_knumh
        IMPORTING
          output = l_knumh.
      IF l_planym <> ls_rfclog-planym.
        l_count = l_count + 1.
        UPDATE konh SET planmonths = ls_rfclog-planym WHERE knumh = l_knumh.
        COMMIT WORK AND WAIT. "如果有更新则提交数据;
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.


FORM frm_test.
  DATA: lt_input  TYPE zmmt_info_input,
        ls_input  TYPE zmms_info_input,
        lt_output TYPE zmmt_info_output,
        ls_output TYPE zmms_info_output.

****1.1.创建信息记录
  CLEAR: ls_input.
  ls_input-quot_id = '0000000001'."RFx应答凭证号
  ls_input-lifnr = '0061000002'."供应商编号
  ls_input-matnr = 'DBAAAA0011'."物料编号
  ls_input-ekorg = '6101'."采购组织
  ls_input-werks = 'H010'."工厂
  ls_input-esokz = '0'."信息类别
  ls_input-esokz0 = 'X'."信息类别/0标准
  ls_input-esokz2 = ''."信息类别/2寄售
  ls_input-esokz3 = ''."信息类别/3委外
  ls_input-datab = '20170601'."开始日期
  ls_input-datbi = '20171231'."结束日期
  ls_input-netpr = '12.00'."价格
  ls_input-kpein = '1'."条件定价单位
  ls_input-konwa = 'CNY'."货币单位
  ls_input-mwskz = 'J1'."税码
  ls_input-inco_key = 'FOB'."贸易条款代码
  ls_input-inco_loc = '2015072307'."贸易条款
  ls_input-sysid = 'SRM'."系统标识
  ls_input-aplfz = '10'."交货日
  ls_input-ekgrp = 'F16'."交货日
  APPEND ls_input TO lt_input.

****1.2.修改信息记录
  CLEAR: ls_input.
  ls_input-quot_id = '0000000001'."RFx应答凭证号
  ls_input-lifnr = '0061000002'."供应商编号
  ls_input-matnr = 'DBAAAA0011'."物料编号
  ls_input-ekorg = '6101'."采购组织
  ls_input-werks = 'H010'."工厂
  ls_input-esokz = '0'."信息类别
  ls_input-esokz0 = 'X'."需要创建0-标准类的信息记录时赋值X,否则为空.
  ls_input-esokz2 = ''."需要创建2-寄售类的信息记录时赋值X,否则为空.
  ls_input-esokz3 = ''."需要创建3-委外类的信息记录时赋值X,否则为空.
  ls_input-datab = '20170901'."开始日期
  ls_input-datbi = '20171231'."结束日期
  ls_input-netpr = '13.00'."价格
  ls_input-kpein = '1'."条件定价单位
  ls_input-konwa = 'CNY'."货币单位
  ls_input-mwskz = 'J1'."税码
  ls_input-inco_key = 'FOB'."贸易条款代码
  ls_input-inco_loc = '2015072307'."贸易条款
  ls_input-sysid = 'SRM'."系统标识
  ls_input-aplfz = '10'."交货日
  ls_input-ekgrp = 'F16'."交货日
  APPEND ls_input TO lt_input.

  CALL FUNCTION 'ZMM_RFC_INFO_CREATE'
    EXPORTING
      it_input  = lt_input
    IMPORTING
      et_output = lt_output.
  WRITE: /, 'OK'.
ENDFORM.

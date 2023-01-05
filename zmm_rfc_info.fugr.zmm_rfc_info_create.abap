function zmm_rfc_info_create.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IT_INPUT) TYPE  ZMMT_INFO_INPUT
*"  EXPORTING
*"     VALUE(ET_OUTPUT) TYPE  ZMMT_INFO_OUTPUT
*"----------------------------------------------------------------------

************************************************************************
*重要提醒: zmmt_info_rfclog表的APLFZ,KPEIN,NETPR等字段必须定义为CHAR类型!
*         否则会出现提示字段EINE-APLFZ.输入值比屏幕字段长
************************************************************************
  data: ls_input type zmms_info_input,
        ls_output type  zmms_info_output.
  data: lt_rfclog type standard table of zmmt_info_rfclog,
        ls_rfclog type zmmt_info_rfclog,
        ls_log0 type zmmt_info_rfclog,
        ls_log2 type zmmt_info_rfclog,
        ls_log3 type zmmt_info_rfclog,
        lt_rfclog_keep type standard table of zmmt_info_rfclog,
        ls_rfclog_keep type zmmt_info_rfclog.
  data: it_bdcdata like bdcdata occurs 0 with header line,
        it_mesg like bdcmsgcoll occurs 0 with header line.
  data: l_idx type sy-tabix .
  data: lv_action type c.
  data: lv_status type string.
  data: lv_errmsg type string.
  data: begin of lt_ekorg occurs 0,
        werks type werks_d,
        ekorg type ekorg,
      end of lt_ekorg.


****1.检查RFC输入数据的完整性.
  perform frm_check_data tables it_input lt_rfclog.
  if lt_rfclog[] is initial.
    exit."没有数据传入时直接退出.
  endif.

  move lt_rfclog to lt_rfclog_keep.

****SRM系统调用接口创建信息记录时，如果是寄售的，需要用工厂对应的标准采购组织替换SRM传输的采购组织，再创建信息记录
  select t001w~werks t001w~ekorg into corresponding fields of table lt_ekorg
    from t001w for all entries in lt_rfclog where t001w~werks = lt_rfclog-werks.
  sort lt_ekorg by werks.
  loop at lt_rfclog into ls_rfclog where errchk <> 'X'.
    l_idx = sy-tabix .
    if ls_rfclog-esokz2 = 'X'."2-寄售 类别的采购信息记录
      clear: lt_ekorg.
      read table lt_ekorg with key werks = ls_rfclog-werks binary search.
      if lt_ekorg is not initial.
        ls_rfclog-ekorg = lt_ekorg-ekorg.
        modify lt_rfclog from ls_rfclog index l_idx .
      endif.
   endif.
  endloop .


****2.循环更新条件价格及创建或更新信息记录
  loop at lt_rfclog into ls_rfclog where errchk <> 'X'.
    l_idx = sy-tabix .
    clear: ls_log0, ls_log2, ls_log3, lv_action, lv_status, lv_errmsg.

    if ls_rfclog-esokz0 = 'X'.
****2.1.创建或更新 0-标准 类别的采购信息记录
      free: it_bdcdata.
      clear: it_bdcdata, it_bdcdata[].
      ls_rfclog-esokz = gc_esokz0."信息类别: 0-标准
      perform check_info_record using ls_rfclog changing lv_action."判断新增或修改
      perform frm_bdcset_data tables it_bdcdata using lv_action changing ls_rfclog.
      perform frm_bdcset_insert tables it_bdcdata using lv_action changing ls_rfclog.
      perform update_planym using ls_rfclog."更新计划月份
      if ls_rfclog-infnr is not initial.
        ls_rfclog-infnr0 = ls_rfclog-infnr."信息类别: 0-标准 创建或更新成功
      endif.
      concatenate lv_status '|标准0:' ls_rfclog-status into lv_status.
      concatenate lv_errmsg '|标准0:' ls_rfclog-errmsg into lv_errmsg.
      clear: ls_rfclog-infnr.
      move ls_rfclog to ls_log0.
    endif.


    if ls_rfclog-esokz2 = 'X'.
****2.2.创建或更新 2-寄售 类别的采购信息记录
      free: it_bdcdata.
      clear: it_bdcdata, it_bdcdata[].
      ls_rfclog-esokz = gc_esokz2."信息类别: 2-寄售
      perform check_info_record using ls_rfclog changing lv_action."判断新增或修改
      perform frm_bdcset_data tables it_bdcdata using lv_action changing ls_rfclog.
      perform frm_bdcset_insert tables it_bdcdata using lv_action changing ls_rfclog.
      perform update_planym using ls_rfclog."更新计划月份
      if ls_rfclog-infnr is not initial.
        ls_rfclog-infnr2 = ls_rfclog-infnr."信息类别: 2-寄售 创建或更新成功
      endif.
      concatenate lv_status '|寄售2:' ls_rfclog-status into lv_status.
      concatenate lv_errmsg '|寄售2:' ls_rfclog-errmsg into lv_errmsg.
      clear: ls_rfclog-infnr.
      move ls_rfclog to ls_log2.
    endif.


    if ls_rfclog-esokz3 = 'X'.
****2.3.创建或更新 3-委外 类别的采购信息记录
      free: it_bdcdata.
      clear: it_bdcdata, it_bdcdata[].
      ls_rfclog-esokz = gc_esokz3."信息类别: 3-委外
      perform check_info_record using ls_rfclog changing lv_action."判断新增或修改
      perform frm_bdcset_data tables it_bdcdata using lv_action changing ls_rfclog.
      perform frm_bdcset_insert tables it_bdcdata using lv_action changing ls_rfclog.
      perform update_planym using ls_rfclog."更新计划月份
      if ls_rfclog-infnr is not initial.
        ls_rfclog-infnr3 = ls_rfclog-infnr."信息类别: 3-委外 创建或更新成功
      endif.
      concatenate lv_status '|委外3:' ls_rfclog-status into lv_status.
      concatenate lv_errmsg '|委外3:' ls_rfclog-errmsg into lv_errmsg.
      clear: ls_rfclog-infnr.
      move ls_rfclog to ls_log3.
    endif.


****2.4.处理状态及错误提示信息
    if ( ls_log0 is initial or ls_log0-mark = icon_led_green )
      and ( ls_log2 is initial or ls_log2-mark = icon_led_green )
      and ( ls_log3 is initial or ls_log3-mark = icon_led_green ).
      ls_rfclog-mark = icon_led_green."状态: 全部成功
    elseif ( ls_log0 is initial or ls_log0-mark = icon_led_red )
      and ( ls_log2 is initial or ls_log2-mark = icon_led_red )
      and ( ls_log3 is initial or ls_log3-mark = icon_led_red ).
      ls_rfclog-mark = icon_led_red."状态: 全部失败
    else.
      ls_rfclog-mark = icon_led_yellow."状态: 部分成功部分失败
    endif.
    shift lv_status left deleting leading '|'.
    ls_rfclog-status = lv_status.
    shift lv_errmsg left deleting leading '|'.
    ls_rfclog-errmsg = lv_errmsg.

    modify lt_rfclog from ls_rfclog index l_idx .
  endloop .


****还原被替换掉的采购组织
  loop at lt_rfclog into ls_rfclog where errchk <> 'X'.
    l_idx = sy-tabix .
    read table lt_rfclog_keep into ls_rfclog_keep index l_idx.
    ls_rfclog-ekorg = ls_rfclog_keep-ekorg.
    modify lt_rfclog from ls_rfclog index l_idx .
  endloop .


****3.保存数据的RFC调用日志表.
  modify zmmt_info_rfclog from table lt_rfclog .
  if sy-subrc = 0.
    commit work and wait.
  endif .


****4.处理RFC调用的返回数据信息
  loop at lt_rfclog into ls_rfclog.
    move-corresponding ls_rfclog to ls_output.
    append ls_output to et_output.
  endloop .



endfunction.

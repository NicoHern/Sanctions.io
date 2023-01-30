*&---------------------------------------------------------------------*
*&   _____  ______ __  __ ______ _______     ___   _ ______
*&  |  __ \|  ____|  \/  |  ____|  __ \ \   / / \ | |  ____|
*&  | |__) | |__  | \  / | |__  | |  | \ \_/ /|  \| | |__
*&  |  _  /|  __| | |\/| |  __| | |  | |\   / | . ` |  __|
*&  | | \ \| |____| |  | | |____| |__| | | |  | |\  | |____
*&  |_|  \_\______|_|  |_|______|_____/  |_|  |_| \_|______|
*&
*&   _____                  _   _                   _
*&  / ____|                | | (_)                 (_)
*& | (___   __ _ _ __   ___| |_ _  ___  _ __  ___   _  ___
*&  \___ \ / _` | '_ \ / __| __| |/ _ \| '_ \/ __| | |/ _ \
*&  ____) | (_| | | | | (__| |_| | (_) | | | \__ \_| | (_) |
*& |_____/ \__,_|_| |_|\___|\__|_|\___/|_| |_|___(_)_|\___/
*&
*&  Author: Rodrigo Giner de la Vega
*&---------------------------------------------------------------------*

REPORT  zsanctionsio.

* Declarations
TYPE-POOLS: vrm.

DATA: name          TYPE vrm_id,
      list          TYPE vrm_values,
      value         LIKE LINE OF list,
      lv_name(120)  TYPE c,
      lv_index      TYPE i,
      gv_matches    TYPE i,
      gv_entities   TYPE i.

DATA: docking         TYPE REF TO cl_gui_docking_container,
      lo_html_viewer  TYPE REF TO cl_gui_html_viewer.
DATA: lt_dfies_tab TYPE STANDARD TABLE OF dfies,
      lv_table     TYPE ddobjname.
DATA: v_path TYPE string,
      lo_http_client TYPE REF TO if_http_client,
      lv_response TYPE string,
      lt_responsetable TYPE TABLE OF string,
      lv_count TYPE i,
      lv_lines TYPE i.
DATA gt_key_fields TYPE STANDARD TABLE OF dfies.
DATA: BEGIN OF gt_data OCCURS 0,
        name TYPE char120,
      END OF gt_data.
DATA: gs_data LIKE LINE OF gt_data.
FIELD-SYMBOLS <fs_data> TYPE ANY.
TYPES: BEGIN OF t_alv,
        source_list TYPE string,
        entity_num  TYPE char20,
        search      TYPE char120,
        name        TYPE char120,
        name_alt1   TYPE char120,
        name_alt2   TYPE char120,
        name_alt3   TYPE char120,
        name_alt4   TYPE char120,
        name_alt5   TYPE char120,
        countries   TYPE char120,
        programs    TYPE char120,
        start_date  TYPE char50,
        dates_of_birth TYPE char100,
        citizenships TYPE char20,
        source_list_url TYPE char100,
        field1      TYPE char100,
        field2      TYPE char100,
        field3      TYPE char100,
        field4      TYPE char100,
        field5      TYPE char100,
        confidence  TYPE char20,
      END OF t_alv.
DATA: gt_alv TYPE TABLE OF t_alv.
DATA: gs_alv LIKE LINE OF gt_alv.

FIELD-SYMBOLS: <gs_data> TYPE ANY,
               <gt_data> TYPE STANDARD TABLE.
FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
* Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
PARAMETERS: p_api TYPE string OBLIGATORY LOWER CASE,
            p_dest(20) OBLIGATORY.
SELECTION-SCREEN SKIP.
PARAMETERS: r_v20 RADIOBUTTON GROUP rad1 DEFAULT 'X' USER-COMMAND act,
            r_v12 RADIOBUTTON GROUP rad1,
            r_v10 RADIOBUTTON GROUP rad1.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
PARAMETERS: p_table TYPE string,
            p_field TYPE string.
SELECT-OPTIONS: so_name FOR lv_name NO-EXTENSION NO INTERVALS LOWER CASE.
PARAMETERS: p_list(10) AS LISTBOX VISIBLE LENGTH 50.
SELECTION-SCREEN END OF BLOCK b2.

AT SELECTION-SCREEN OUTPUT.
  name = 'P_LIST'.
  value-key = 'ALL'.  value-text = 'All sources'.                                                       APPEND value TO list.
  value-key = 'CFSP'. value-text = 'Consolidated list of sanctions (CFSP)'.                             APPEND value TO list.
  value-key = 'UN'.   value-text = 'Consolidated United Nations Security Council Sanctions List (UN)'.  APPEND value TO list.
  value-key = 'HMT'.  value-text = 'Consolidated list of targets (HMT)'.                                APPEND value TO list.
  value-key = 'DPL'.  value-text = 'Denied Persons List (DPL)'.                                         APPEND value TO list.
  value-key = 'UL'.   value-text = 'Unverified List (UL)'.                                              APPEND value TO list.
  value-key = 'EL'.   value-text = 'Entity List (EL)'.                                                  APPEND value TO list.
  value-key = 'ISN'.  value-text = 'Nonproliferation Sanctions (ISN)'.                                  APPEND value TO list.
  value-key = 'DTC'.  value-text = 'ITAR Debarred (DTC)'.                                               APPEND value TO list.
  value-key = 'SDN'.  value-text = 'Specially Designated Nationals List (SDN)'.                         APPEND value TO list.
  value-key = 'FSE'.  value-text = 'Foreign Sanctions Evaders List (FSE)'.                              APPEND value TO list.
  value-key = 'SSI'.  value-text = 'Sectoral Sanctions Identifications List (SSI)'.                     APPEND value TO list.
  value-key = 'PLC'.  value-text = 'Non-SDN Palestinian Legislative Council List (PLC)'.                APPEND value TO list.
  value-key = '561'.  value-text = 'Foreign Financial Institutions Subject to Part 561 (561)'.          APPEND value TO list.
  value-key = 'NS-ISA'. value-text = 'Non-SDN Iranian Sanctions Act List (NS-ISA)'.                     APPEND value TO list.
  value-key = 'INTERPOL'. value-text = 'Interpol Red Flag (INTERPOL) '.                                 APPEND value TO list.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = name
      values = list.

  PERFORM show_web_page.

AT SELECTION-SCREEN.
  IF p_table IS INITIAL AND so_name[] IS INITIAL.
    MESSAGE 'Please enter Table and Field or Name to search' TYPE 'E'.
  ENDIF.

  IF p_table IS INITIAL AND p_field IS NOT INITIAL AND so_name[] IS INITIAL.
    MESSAGE 'Please enter a table' TYPE 'E'.
  ELSE.
    IF p_field IS INITIAL AND so_name[] IS INITIAL.
      MESSAGE 'Please enter a field of table entered' TYPE 'E'.
    ELSE.


      lv_table = p_table.
      CALL FUNCTION 'DDIF_FIELDINFO_GET'
        EXPORTING
          tabname        = lv_table
        TABLES
          dfies_tab      = lt_dfies_tab
        EXCEPTIONS
          not_found      = 1
          internal_error = 2
          OTHERS         = 3.
      IF sy-subrc <> 0 AND so_name[] IS INITIAL.
        MESSAGE 'Please enter a valid table' TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF p_list = 'INTERPOL' AND r_v10 = 'X'.
    MESSAGE 'Interpol is only available in v1.0' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
* Select Data (if table and field used)
  PERFORM get_data.

  IF <lt_data> IS ASSIGNED.
    DESCRIBE TABLE <lt_data> LINES lv_lines.
    LOOP AT <lt_data> ASSIGNING <fs_data>.

      lv_index = lv_index + 1.
      PERFORM call_api CHANGING <fs_data>
                                p_list
                                gt_alv.

      PERFORM progress_bar USING 'Processing data...'(001)
                                 lv_index
                                 lv_lines.
    ENDLOOP.
  ENDIF.
  SORT gt_alv BY source_list entity_num search name.

  LOOP AT gt_alv INTO gs_alv.
    AT NEW entity_num.
      gv_entities = gv_entities + 1.
    ENDAT.
  ENDLOOP.

*  DELETE ADJACENT DUPLICATES FROM gt_alv COMPARING ALL FIELDS.
*  LOOP AT gt_alv INTO gs_alv.
*    AT NEW entity_num.
*      gv_matches = gv_matches + 1.
*    ENDAT.
*  ENDLOOP.

END-OF-SELECTION.

* Show ALV
  PERFORM show_alv.
  CLEAR: p_table, p_field.
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data .
  DATA: lo_type_desc    TYPE REF TO cl_abap_typedescr, "cl_abap_elemdescr,
        lo_field_type   TYPE REF TO cl_abap_elemdescr,
        lv_field_aux    TYPE string,
        ls_field_descr  TYPE abap_componentdescr, "cl_abap_structdescr=>component,
        lt_field_descr  TYPE abap_component_tab,
        lt_key_descr    TYPE abap_component_tab,
        lo_field_struct TYPE REF TO cl_abap_structdescr,
        lo_field_ref    TYPE REF TO data,
        lo_tabledescr   TYPE REF TO cl_abap_tabledescr,
        lo_table_ref    TYPE REF TO data.
  DATA: lt_data TYPE REF TO data.
  DATA: lr_name          TYPE RANGE OF char120,
        ls_name          LIKE LINE OF lr_name,
        lv_where         TYPE string,
        lv_aux(120).

  lr_name[] = so_name[].
  LOOP AT lr_name INTO ls_name.
    ls_name-option = 'CP'.
    lv_aux = ls_name-low.
    CONCATENATE '*' lv_aux '*' INTO ls_name-low.
    MODIFY lr_name FROM ls_name.
  ENDLOOP.

  IF p_table = ' ' OR
     p_table = '  ' OR
     p_table = '   '.
    CLEAR p_table.
  ENDIF.
  IF p_field = ' ' OR
     p_field = '  ' OR
     p_field = '   '.
    CLEAR p_field.
  ENDIF.

  IF p_table IS NOT INITIAL AND p_field IS NOT INITIAL.
*    SELECT (p_field)
*      FROM (p_table)
*      INTO TABLE gt_data.

    CREATE DATA lt_data TYPE STANDARD TABLE OF (p_table).
    ASSIGN lt_data->* TO <lt_data>.

    CONCATENATE p_field 'IN LR_NAME' INTO lv_where SEPARATED BY space.
    SELECT * FROM (p_table)
      INTO TABLE <lt_data>
      WHERE (lv_where).
    DELETE gt_data WHERE name NOT IN lr_name.

    SORT <lt_data>.
    DELETE ADJACENT DUPLICATES FROM <lt_data>.
  ELSE.
    gs_data-name = so_name-low.
    p_field = 'NAME'.
    APPEND gs_data TO gt_data.

    ASSIGN gt_data[]  TO <lt_data>.
  ENDIF.


  gt_key_fields[] = lt_dfies_tab[].
  DELETE gt_key_fields WHERE keyflag NE 'X'.
  DELETE gt_key_fields WHERE  fieldname EQ 'MANDT'.


ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  CALL_API
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_DATA_NAME  text
*      <--P_GT_ALV  text
*----------------------------------------------------------------------*
FORM call_api  CHANGING ps_data
                        p_list
                        t_alv.

  DATA lv_count_api TYPE i.
  DATA lv_fuzzy TYPE string.
  DATA: lv_text_aux TYPE string.
  DATA: result_tab TYPE match_result_tab.
  DATA: result_tab_entity TYPE match_result_tab.
  DATA: result_tab_alt_names TYPE match_result_tab.
  DATA: result_tab_names TYPE match_result_tab.
  DATA: result_sources TYPE match_result_tab.
  DATA: result_tab_programs TYPE match_result_tab.
  DATA: result_tab_natio TYPE match_result_tab.
  DATA: ls_result_tab LIKE LINE OF result_tab.
  DATA: BEGIN OF ls_matches,
          offset TYPE i,
          length TYPE i,
        END OF ls_matches.
  DATA: lv_accept TYPE string.
  DATA lv_tab_field TYPE string.
  DATA lv_field_val TYPE string.
  DATA: lv_aux TYPE string.
  DATA: p_name_original TYPE string.
  DATA lv_id(1) TYPE c.
  DATA lv_field TYPE string.
  DATA lv_alt_id(1) TYPE c.
  FIELD-SYMBOLS <fs_name> TYPE ANY .
  FIELD-SYMBOLS <fs_key_fields> LIKE LINE OF gt_key_fields.
  FIELD-SYMBOLS <fs_field> TYPE ANY.
  FIELD-SYMBOLS <fs_field2> TYPE ANY.
  FIELD-SYMBOLS <fs_alt_field> TYPE ANY.
  CONCATENATE 'PS_DATA-' p_field INTO lv_field_val.
  ASSIGN (lv_field_val) TO <fs_name>.
  CHECK <fs_name> IS ASSIGNED.

  CLEAR: lo_http_client, gs_alv.

  cl_http_client=>create_by_destination(
    EXPORTING
      destination              = p_dest
    IMPORTING
      client                   = lo_http_client
    EXCEPTIONS
      argument_not_found       = 1
      destination_not_found    = 2
      destination_no_authority = 3
      plugin_not_active        = 4
      internal_error           = 5
      OTHERS                   = 6 ).
  IF sy-subrc <> 0.
    WRITE: 'create error', sy-subrc.
  ENDIF.

  DATA: emptybuffer TYPE xstring.
  emptybuffer = ''.
  CALL METHOD lo_http_client->request->set_data
    EXPORTING
      data = emptybuffer.

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = '~request_method'
      value = 'GET'.

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'text/xml; charset=utf-8'.

  IF r_v10 IS NOT INITIAL.
    lv_accept = 'application/json;version=1.0'.
  ELSEIF r_v12 IS NOT INITIAL.
    lv_accept = 'application/json;version=1.2'.
  ELSEIF r_v20 IS NOT INITIAL.
    lv_accept = 'application/json;version=2.0'.
  ENDIF.

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Accept'
      value = lv_accept.
*
*  IF <fs_name> CS '*'.
*    lv_fuzzy = '&fuzzy_name=true'.
*  ENDIF.

*  TRANSLATE p_name USING ' +'.
*  SHIFT p_name RIGHT DELETING TRAILING `+`.
*  TRANSLATE p_name USING '*+'.
*  CONDENSE p_name NO-GAPS.




  lv_aux = <fs_name>.
  p_name_original = <fs_name>.
  lv_aux = cl_http_utility=>escape_url( lv_aux ).
  <fs_name> = lv_aux.
*  REPLACE ALL OCCURRENCES OF '%20' IN <fs_name> WITH `+`.
*  REPLACE ALL OCCURRENCES OF '%2a' IN <fs_name> WITH `+`.
  CONDENSE <fs_name> NO-GAPS.

  IF p_list = 'ALL'.
    CONCATENATE '/search/?api_key=' p_api `&name=` <fs_name> lv_fuzzy INTO v_path.
  ELSE.
    CONCATENATE '/search/?api_key=' p_api `&name=` <fs_name> lv_fuzzy `&sources=` p_list INTO v_path.
  ENDIF.

  cl_http_utility=>set_request_uri( request = lo_http_client->request
                                     uri    = v_path ).

  lo_http_client->request->set_method(
                     if_http_request=>co_request_method_get ).

  lo_http_client->send(
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      http_invalid_timeout       = 4
      OTHERS                     = 5 ).

  IF sy-subrc <> 0.
    WRITE: 'send error', sy-subrc.
  ENDIF.

  lo_http_client->receive(
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4 ).
  DATA: subrc LIKE sy-subrc.

  IF sy-subrc <> 0.
    WRITE: 'receive error', sy-subrc.
    CALL METHOD lo_http_client->get_last_error
      IMPORTING
        code    = subrc
        MESSAGE = lv_response.
    WRITE: / 'communication_error( receive )',
           / 'code: ', subrc, 'message: ', lv_response.
    CLEAR lv_response.
  ENDIF.

  lv_response = lo_http_client->response->get_cdata( ).

  lo_http_client->close( ).

*Check Count
  FIND REGEX `"count":([0-9]+)` IN lv_response RESULTS result_tab.

  LOOP AT result_tab INTO ls_result_tab.
    LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
      lv_count_api = lv_response+ls_matches-offset(ls_matches-length).
    ENDLOOP.
  ENDLOOP.
*  IF sy-subrc <> 0.
**    MESSAGE 'Could not connect to the API, check you API Key and try again.' TYPE 'I'.
**    SUBMIT ZSANCTIONSIO VIA SELECTION-SCREEN WITH p_table = p_table
**                                             WITH p_field = p_field
**                                             WITH p_api   = p_api
**                                             WITH p_dest  = p_dest.
*                                             "WITH so_name = so_name-low.
*    gs_alv-search = p_name_original.
*    gs_alv-name = 'Characters not allowed'.
*    APPEND gs_alv TO gt_alv.
*    EXIT.
*  ENDIF.

  IF NOT lv_count_api > 0.
    EXIT.
  ENDIF.

*Entity_number
  FIND ALL OCCURRENCES OF REGEX `"entity_number":([0-9]+)` IN lv_response RESULTS result_tab_entity.

  DATA gv_index TYPE i.
  LOOP AT result_tab_entity INTO ls_result_tab.
    CLEAR gs_alv.
    gv_index = gv_index + 1.
    LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
      gs_alv-entity_num = lv_response+ls_matches-offset(ls_matches-length).
    ENDLOOP.

*  Sources
    FIND ALL OCCURRENCES OF REGEX `"data_source":."name":"(\\"|[^"]*).` IN lv_response RESULTS result_sources.

    LOOP AT result_sources INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-source_list = lv_response+ls_matches-offset(ls_matches-length).
        REPLACE ALL OCCURRENCES OF '"' IN gs_alv-source_list WITH ' '.
        CONDENSE gs_alv-source_list.
        "        gs_alv-source_list = lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

*start_date
    FIND ALL OCCURRENCES OF REGEX `"start_date"[ :]+((?=\[)\[[^]]*\]|(?=\{)\{[^\}]*\}|\"[^"]*\")` IN lv_response RESULTS result_sources.

    LOOP AT result_sources INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-start_date = lv_response+ls_matches-offset(ls_matches-length).
        REPLACE ALL OCCURRENCES OF '"' IN gs_alv-start_date WITH ' '.
        CONDENSE gs_alv-source_list.
        "        gs_alv-source_list = lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

*dates of birth
    FIND ALL OCCURRENCES OF REGEX `"dates_of_birth":\["([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)")?)?)?)?` IN lv_response RESULTS result_sources.

    LOOP AT result_sources INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-dates_of_birth = lv_response+ls_matches-offset(ls_matches-length).
        REPLACE ALL OCCURRENCES OF '"' IN gs_alv-source_list WITH ' '.
        CONDENSE gs_alv-source_list.
        "        gs_alv-source_list = lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

*citizenships
    FIND ALL OCCURRENCES OF REGEX `"citizenships":\["([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)")?)?)?)?` IN lv_response RESULTS result_sources.

    LOOP AT result_sources INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-citizenships = lv_response+ls_matches-offset(ls_matches-length).
        REPLACE ALL OCCURRENCES OF '"' IN gs_alv-source_list WITH ' '.
        CONDENSE gs_alv-source_list.
        "        gs_alv-source_list = lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

*citizenships
    FIND ALL OCCURRENCES OF REGEX `"source_list_url"[ :]+((?=\[)\[[^]]*\]|(?=\{)\{[^\}]*\}|\"[^"]*\")`  IN lv_response RESULTS result_sources.

    LOOP AT result_sources INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-source_list_url = lv_response+ls_matches-offset(ls_matches-length).
        REPLACE ALL OCCURRENCES OF '"' IN gs_alv-source_list_url WITH ' '.
        CONDENSE gs_alv-source_list.
        "        gs_alv-source_list = lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

    FIND ALL OCCURRENCES OF REGEX `"nationalities":\["([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)")?)?)?)?` IN lv_response RESULTS result_tab_natio.

    LOOP AT result_tab_natio INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
*        ls_rem_chkdata-field2 = <fs_name>.
        gs_alv-countries   = lv_response+ls_matches-offset(ls_matches-length).


*        APPEND gs_alv TO gt_alv.
*        APPEND ls_rem_chkdata TO lt_rem_chkdata.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

    FIND ALL OCCURRENCES OF REGEX `"confidence_score":([0-9].[0-9]+)` IN lv_response RESULTS result_tab_names.


    LOOP AT result_tab_names INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
*        ls_r9em_chkdata-field2 = <fs_name>.
        gs_alv-confidence   = lv_response+ls_matches-offset(ls_matches-length).


*        APPEND gs_alv TO gt_alv.
*        APPEND ls_rem_chkdata TO lt_rem_chkdata.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.

    FIND ALL OCCURRENCES OF REGEX `"programs":\["([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)")?)?)?)?` IN lv_response RESULTS result_tab_programs.

    LOOP AT result_tab_programs INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
*        ls_rem_chkdata-field2 = <fs_name>.
        gs_alv-programs   = lv_response+ls_matches-offset(ls_matches-length).


*        APPEND gs_alv TO gt_alv.
*        APPEND ls_rem_chkdata TO lt_rem_chkdata.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.


    gs_alv-field1 = p_name_original.
    lv_id = '2'.
    LOOP AT gt_key_fields  ASSIGNING <fs_key_fields>.
      IF lv_id > 5.
        EXIT.
      ENDIF.
      CONCATENATE 'GS_ALV-FIELD' lv_id INTO lv_field_val.
      ASSIGN (lv_field_val) TO <fs_field>.

      IF <fs_field> IS ASSIGNED.
        CONCATENATE 'PS_DATA-' <fs_key_fields>-fieldname INTO lv_field_val.
        ASSIGN (lv_field_val) TO <fs_field2>.
        IF <fs_field2> IS  ASSIGNED.
          <fs_field> = <fs_field2>.
        ENDIF.
        UNASSIGN <fs_field>.
      ENDIF.

      ADD 1 TO lv_id.
    ENDLOOP.

*  Alternative names
    FIND ALL OCCURRENCES OF REGEX `"alt_names":\["([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)"(?:,"([^"]*)")?)?)?)?` IN lv_response RESULTS result_tab_alt_names.
    lv_alt_id = 1.
    LOOP AT result_tab_alt_names INTO ls_result_tab FROM gv_index TO gv_index.

      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-search = <fs_name>.

        CONCATENATE 'GS_ALV-NAME_ALT' lv_alt_id INTO lv_field.
        ASSIGN (lv_field) TO <fs_alt_field>.

        IF <fs_alt_field> IS ASSIGNED.
          <fs_alt_field> = lv_response+ls_matches-offset(ls_matches-length).
*        APPEND gs_alv TO gt_alv.

          gv_matches = gv_matches + 1.
        ELSE.
          EXIT.
        ENDIF.
        ADD 1 TO lv_alt_id.

        IF lv_alt_id GE 6.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF lv_alt_id GE 6.
        EXIT.
      ENDIF.
    ENDLOOP.

*  Name
    FIND ALL OCCURRENCES OF REGEX `"name":"(\\"|[^"]*)","ent` IN lv_response RESULTS result_tab_names.
    IF sy-subrc IS NOT INITIAL.

      FIND ALL OCCURRENCES OF REGEX `"name":"(\\"|[^"]*)","alt` IN lv_response RESULTS result_tab_names.
    ENDIF.
    LOOP AT result_tab_names INTO ls_result_tab FROM gv_index TO gv_index.
      LOOP AT ls_result_tab-submatches INTO ls_matches WHERE offset >= 0.
*        ls_rem_chkdata-field2 = <fs_name>.
        gs_alv-name  = lv_response+ls_matches-offset(ls_matches-length).
*        lv_len = ls_matches-length - 5.

*        APPEND gs_alv TO gt_alv.
*        APPEND ls_rem_chkdata TO lt_rem_chkdata.
        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
        gs_alv-search = <fs_name>.

        APPEND gs_alv TO gt_alv.

        gv_matches = gv_matches + 1.

        "WRITE: /, lv_response+ls_matches-offset(ls_matches-length).
      ENDLOOP.
    ENDLOOP.


  ENDLOOP.

ENDFORM.                    " CALL_API
*&---------------------------------------------------------------------*
*&      Form  SHOW_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_alv .

*ALV reference
  DATA: o_alv TYPE REF TO cl_salv_table.
  DATA: lx_msg TYPE REF TO cx_salv_msg.
  DATA ls_dfies LIKE LINE OF lt_dfies_tab.
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = o_alv
        CHANGING
          t_table      = gt_alv ).
    CATCH cx_salv_msg INTO lx_msg.
  ENDTRY.

  DATA: lo_header  TYPE REF TO cl_salv_form_layout_grid,
        lo_h_label TYPE REF TO cl_salv_form_label,
        lo_h_flow  TYPE REF TO cl_salv_form_layout_flow.

*Header
  CREATE OBJECT lo_header.

*  lo_h_label = lo_header->create_label( row = 1 column = 1 ).
*  lo_h_label->set_text( 'Searches Found' ).
*  lo_h_label = lo_header->create_label( row = 1 column = 2 ).
*  lo_h_label->set_text( gv_matches ).

  lo_h_label = lo_header->create_label( row = 1 column = 1 ).
  lo_h_label->set_text( 'Total Names Entries:' ).
  lo_h_label = lo_header->create_label( row = 1 column = 2 ).
  lo_h_label->set_text( gv_matches ).

  lo_h_label = lo_header->create_label( row = 2 column = 1 ).
  lo_h_label->set_text( 'Total Distinct Entity Number:' ).
  lo_h_label = lo_header->create_label( row = 2 column = 2 ).
  lo_h_label->set_text( gv_entities ).

  o_alv->set_top_of_list( lo_header ).

* Status
  DATA: lo_functions TYPE REF TO cl_salv_functions_list.

  lo_functions = o_alv->get_functions( ).
  lo_functions->set_all( abap_true ).

* Display
  DATA: lo_display TYPE REF TO cl_salv_display_settings.

  lo_display = o_alv->get_display_settings( ).
  lo_display->set_striped_pattern( 'X' ).
  lo_display->set_list_header( 'SANCTIONS.IO - Matches found' ).

* Layout
  DATA: lo_layout  TYPE REF TO cl_salv_layout,
        lf_variant TYPE slis_vari,
        ls_key    TYPE salv_s_layout_key.

  DATA lv_id(1) TYPE c.
  FIELD-SYMBOLS <fs_key_fields> LIKE LINE OF gt_key_fields.
  DATA lv_field TYPE string.
  DATA lv_field_val TYPE char30.
  FIELD-SYMBOLS <fs_field> TYPE ANY.

  lo_layout = o_alv->get_layout( ).

  ls_key-report = sy-repid.
  lo_layout->set_key( ls_key ).
  lo_layout->set_save_restriction( if_salv_c_layout=>restrict_user_dependant ).

  lf_variant = 'DEFAULT'.
  lo_layout->set_initial_layout( lf_variant ).

* Catalog
  DATA: lo_cols TYPE REF TO cl_salv_columns_table.

  lo_cols = o_alv->get_columns( ).
  lo_cols->set_optimize( ).
  lo_cols->set_key_fixation( ).

  DATA: lo_column TYPE REF TO cl_salv_column_table.
  TRY.
      lo_column ?= lo_cols->get_column( 'SOURCE_LIST' ).
      lo_column->set_short_text( 'Source' ).
      lo_column->set_medium_text( 'Source List' ).
      lo_column->set_long_text( 'Source List' ).

      lo_column ?= lo_cols->get_column( 'PROGRAMS' ).
      lo_column->set_short_text( 'Programs' ).
      lo_column->set_medium_text( 'Programs' ).
      lo_column->set_long_text( 'Programs' ).

      lo_column ?= lo_cols->get_column( 'COUNTRIES' ).
      lo_column->set_short_text( 'Nation' ).
      lo_column->set_medium_text( 'Nationalities' ).
      lo_column->set_long_text( 'Nationalities' ).

      lo_column ?= lo_cols->get_column( 'CONFIDENCE' ).
      lo_column->set_short_text( 'Confid.' ).
      lo_column->set_medium_text( 'Confidence Score' ).
      lo_column->set_long_text( 'Confidence Score' ).


      lo_column ?= lo_cols->get_column( 'ENTITY_NUM' ).
      lo_column->set_short_text( 'Ent.Number' ).
      lo_column->set_medium_text( 'Ent. Number' ).
      lo_column->set_long_text( 'Entity Number' ).
      lo_column->set_alignment( if_salv_c_alignment=>right ).

      lo_column ?= lo_cols->get_column( 'SEARCH' ).
      lo_column->set_key_presence_required( ).
      lo_column->set_short_text( 'Search' ).
      lo_column->set_medium_text( 'Search' ).
      lo_column->set_long_text( 'Search' ).

      lo_column ?= lo_cols->get_column( 'NAME' ).
      lo_column->set_short_text( 'Names' ).
      lo_column->set_medium_text( 'Names' ).
      lo_column->set_long_text( 'Names' ).

      lo_column ?= lo_cols->get_column( 'START_DATE' ).
      lo_column->set_short_text( 'Start date' ).
      lo_column->set_medium_text( 'Start date' ).
      lo_column->set_long_text( 'Start date' ).

      lo_column ?= lo_cols->get_column( 'DATES_OF_BIRTH' ).
      lo_column->set_short_text( 'Birthdate' ).
      lo_column->set_medium_text( 'Dates of birth' ).
      lo_column->set_long_text( 'Dates of birth' ).

      lo_column ?= lo_cols->get_column( 'CITIZENSHIPS' ).
      lo_column->set_short_text( 'Citizen.' ).
      lo_column->set_medium_text( 'Citizenships' ).
      lo_column->set_long_text( 'Citizenships' ).

      lo_column ?= lo_cols->get_column( 'SOURCE_LIST_URL' ).
      lo_column->set_short_text( 'List' ).
      lo_column->set_medium_text( 'Source list URL' ).
      lo_column->set_long_text( 'Source list URL' ).

      lo_column ?= lo_cols->get_column( 'NAME_ALT1' ).
      lo_column->set_short_text( 'Alt.Name 1' ).
      lo_column->set_medium_text( 'Alternative Name 1' ).
      lo_column->set_long_text( 'Alternative Name 1' ).

      lo_column ?= lo_cols->get_column( 'NAME_ALT2' ).
      lo_column->set_short_text( 'Alt.Name 2' ).
      lo_column->set_medium_text( 'Alternative Name 2' ).
      lo_column->set_long_text( 'Alternative Name 2' ).

      lo_column ?= lo_cols->get_column( 'NAME_ALT3' ).
      lo_column->set_short_text( 'Alt.Name 3' ).
      lo_column->set_medium_text( 'Alternative Name 3' ).
      lo_column->set_long_text( 'Alternative Name 3' ).

      lo_column ?= lo_cols->get_column( 'NAME_ALT4' ).
      lo_column->set_short_text( 'Alt.Name 4' ).
      lo_column->set_medium_text( 'Alternative Name 4' ).
      lo_column->set_long_text( 'Alternative Name 4' ).

      lo_column ?= lo_cols->get_column( 'NAME_ALT5' ).
      lo_column->set_short_text( 'Alt.Name 5' ).
      lo_column->set_medium_text( 'Alternative Name 5' ).
      lo_column->set_long_text( 'Alternative Name 5' ).


      lo_column ?= lo_cols->get_column( 'FIELD1' ).

      READ TABLE lt_dfies_tab INTO ls_dfies WITH KEY fieldname = p_field.
      IF sy-subrc IS INITIAL.
        lo_column->set_short_text( ls_dfies-scrtext_s ).
        lo_column->set_medium_text( ls_dfies-scrtext_m ).
        lo_column->set_long_text( ls_dfies-scrtext_l ).
      ELSE.
        lo_column->set_visible( '' ).
      ENDIF.


      lv_id = '2'.
      LOOP AT gt_key_fields  ASSIGNING <fs_key_fields>.

        CONCATENATE 'FIELD' lv_id INTO lv_field_val.

        lo_column ?= lo_cols->get_column( lv_field_val ).
        lo_column->set_short_text( <fs_key_fields>-scrtext_s ).
        lo_column->set_medium_text( <fs_key_fields>-scrtext_m ).
        lo_column->set_long_text( <fs_key_fields>-scrtext_l ).


        ADD 1 TO lv_id.
      ENDLOOP.

      WHILE lv_id < 6.
        CONCATENATE 'FIELD' lv_id INTO lv_field_val.

        lo_column ?= lo_cols->get_column( lv_field_val ).
        lo_column->set_visible( '' ).
        ADD 1 TO lv_id.
      ENDWHILE.
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  o_alv->display( ).

ENDFORM.                    " SHOW_ALV
*&---------------------------------------------------------------------*
*&      Form  PROGRESS_BAR
*&---------------------------------------------------------------------*
FORM progress_bar USING    p_value
                           p_tabix
                           p_nlines.
  DATA: w_text(40),
        w_percentage TYPE p,
        gd_percent TYPE p,
        w_percent_char(3).
  w_percentage = ( p_tabix / p_nlines ) * 100.
  w_percent_char = w_percentage.
  SHIFT w_percent_char LEFT DELETING LEADING ' '.
  CONCATENATE p_value w_percent_char '% Complete'(002) INTO w_text.

  IF w_percentage GT gd_percent OR p_tabix EQ 1.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = w_percentage
        text       = w_text.
    gd_percent = w_percentage.
  ENDIF.
ENDFORM.                    " PROGRESS_BAR
*&---------------------------------------------------------------------*
*& Form show_web_page
*&---------------------------------------------------------------------*
FORM show_web_page.

  DATA: repid LIKE sy-repid.
  repid = sy-repid.
  DATA: lt_html TYPE TABLE OF w3_html,
        ls_html LIKE LINE OF lt_html.
  DATA: lv_url(80).
  CHECK sy-batch IS INITIAL.
  IF docking IS INITIAL .
*  Create objects for the reference variables
    CREATE OBJECT docking
      EXPORTING
        repid                       = repid
        dynnr                       = sy-dynnr
        side                        = cl_gui_docking_container=>dock_at_right
        ratio                       = 60
      EXCEPTIONS
        cntl_error                  = 1    "extension = '600'
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.


    CREATE OBJECT lo_html_viewer
      EXPORTING
        parent = docking.
    CHECK sy-subrc = 0.

    ls_html = '<html><body><div>ZSANCTIONSIO is a template SAP ABAP report that implements the <a href="http://sanctions.io" target="_blank">sanctions.io</a>'.
    APPEND ls_html TO lt_html.
    ls_html = ` (<a href="https://sanctions.io" target="_blank">https://sanctions.io</a>) API to check persons and organizations against sanction lists.</div><div><br></div>`.
    APPEND ls_html TO lt_html.
    ls_html = `<div>To learn more about supported sanction lists and the API, visit <a href="https://sanctions.io" target="_blank">https://sanctions.io</a></div><div>`.
    APPEND ls_html TO lt_html.
    ls_html = `This report does not implement advanced features of the API like fuzzy search, matching country or date of birth, etc.</div><div><br></div>`.
    APPEND ls_html TO lt_html.
    ls_html = `<div>This report is provided as is and with no warranty under the 3-clause-BSD license, see&nbsp;<a href="https://opensource.org/licenses/BSD-3-Clause"`.
    APPEND ls_html TO lt_html.
    ls_html = `target="_blank">https://opensource.org/<wbr>licenses/BSD-3-Clause</a>.</div><div>Redistribution and use, with or without modification, is permitted.</div>`.
    APPEND ls_html TO lt_html.
    ls_html = `<div>Copyright 2021 sanctions.io LLC.</div><div><br></div><div>Before using this report:</div>`.
    APPEND ls_html TO lt_html.
    ls_html = `<div>1. Create an RFC destination as described here:</div><div><a href="https://remedyne.de/knowledge-base/setup-for-sanction-list-screening/"`.
    APPEND ls_html TO lt_html.
    ls_html = `target="_blank">https://remedyne.de/<wbr>knowledge-base/setup-for-sanction-list-screening/</a></div><div>2. Sign-up for an API key on`.
    APPEND ls_html TO lt_html.
    ls_html = `<a href="https://sanctions.io" target="_blank">https://sanctions.io</a>. A free trial is available.</div><div>`.
    APPEND ls_html TO lt_html.
    ls_html = `3. This report does not perform an AUTHORITY-CHECK when executed: make sure you apply appropriate security mechanisms before deploying this.</div><div>`.
    APPEND ls_html TO lt_html.
    ls_html = `4. This template report comes with no warranty. It has been used in several environments without problems, but running this check against large sets of data`.
    APPEND ls_html TO lt_html.
    ls_html = `can have an impact on the performance of your SAP system.</div><div><br></div><div>To use this report:</div><div>Enter a table name and field name that`.
    APPEND ls_html TO lt_html.
    ls_html = `contains names, e.g. business partner names such as LFA1:NAME1, and select the sanction list against which you want to run the check.</div>`.
    APPEND ls_html TO lt_html.
    ls_html = `<div>You can also enter a name and check whether the name is on a list.</div><div><br></div><div>In case of questions, contact`.
    APPEND ls_html TO lt_html.
    ls_html = `<a href="mailto:info@sanctions.io" target="_blank">info@sanctions.io</a></div><div><br></div><div><br></div>`.
    APPEND ls_html TO lt_html.
    ls_html = `<div><br></div><div><img id="image" src="https://github.com/REMEDYNE/Sanctions.io/blob/master/sanctions.io_transparent_small.png?raw=true" data-image-whitelisted=""></div>`.
    APPEND ls_html TO lt_html.
    ls_html = `</body></html>`.
    APPEND ls_html TO lt_html.

    CALL METHOD lo_html_viewer->load_data
      IMPORTING
        assigned_url = lv_url
      CHANGING
        data_table   = lt_html.
* Load Web Page using url from selection screen.
    IF sy-subrc = 0.
      CALL METHOD lo_html_viewer->show_url
        EXPORTING
          url = lv_url.
    ENDIF.
  ENDIF .

ENDFORM.                    "show_web_page

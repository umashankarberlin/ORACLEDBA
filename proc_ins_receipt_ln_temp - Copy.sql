/*

Revision History
--------------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                       |
|         |                   |                  |                              | 
--------------------------------------------------------------------------------
|1        |Rangarajan         | 23-Jan-2006      |Coding and development        |
|         |                   |                  |                              |
--------------------------------------------------------------------------------
|2	  |Selvaganapathy     | 24-MAY-2007      |Modified the cursor c1 with   |
|         |                   |                  |the condition poh_type	|
|	  |		      |			 |NOT IN('BL','TS')		|
--------------------------------------------------------------------------------




Description of the Procedure:

  THIS PROCEDEDURE IS USED TO INSERT RECORD FROM  PUR_ORDER_HD,PUR_ORDER_LN AND PUR_ORD_LN_SCHEDULE  
  TO  PUR_ORD_RECEIPT_LN_TMP TABLE
  AND FOR GIVEN RECEIPT PFX , NO, SESSION AND SELECTED LINES ONLY.

The procedures takes the parameters like bu, p_receipt_pfx, p_receipt_no,
p_user,p_session

Referenced by  :

References     :
*/


CREATE OR REPLACE PROCEDURE proc_ins_receipt_ln_temp(
     p_bu                       VARCHAR2,
     p_plnt   			VARCHAR2,
     p_order_pfx                VARCHAR2,
     p_order_no                 VARCHAR2,
     p_suplr_id                 VARCHAR2,
     p_receipt_type             VARCHAR2,
     p_receipt_date             date,
     p_poh_mode                 VARCHAR2,
     p_ses                      VARCHAR2,
     p_result           OUT     VARCHAR2,
     p_type			VARCHAR2  DEFAULT NULL
) IS 
     p_seq_no     NUMBER := 0;
    
     
         /*
             BELOW CURSOR IS USED TO FETCH ALL THE PENDING ORDER RECORD FOR GIVEN SUPPLIER (SUPPLIER WISE).
        */
     --supplier based lines take purchase order not with the type BL(Blanket Order)
     CURSOR c1 IS
          SELECT   *
              FROM pur_order_hd,
                   pur_order_ln,
                   pur_ord_ln_schedule
             WHERE poh_bu = p_bu
               AND poh_bu = pol_bu
               AND poh_order_pfx = pol_order_pfx
               AND pol_bu = pols_bu
               AND pol_order_pfx = pols_order_pfx
               AND poh_order_no = pol_order_no
               AND pols_order_no = pol_order_no
               AND pol_seq_no = pols_seq_no
               AND poh_suplr_id = p_suplr_id
               AND pol_status IN('P', 'A')
               AND poh_status IN('P', 'A')
               AND pols_ordered_qty <> pols_receipt_qty
               AND pols_ordered_qty > pols_receipt_qty
               --AND pols_ordered_qty > NVL(pols_qc_temp_qty, 0)
               AND poh_mode = p_poh_mode
               AND poh_type NOT IN('BL','TS')
               AND trunc(poh_order_date) < p_receipt_date
               AND (poh_type = p_type OR p_type IS NULL)
               AND pols_plnt=p_plnt
          ORDER BY pols_bu,
                   pols_order_pfx,
                   pols_order_no,
                   pols_seq_no,
                   pols_sub_seq_no;

        /*
             BELOW CURSOR IS USED TO FETCH ALL THE PENDING ORDER RECORD FOR GIVEN ORDER NO (ORDER WISE).
        */
     --order based lines       
     CURSOR c2 IS
          SELECT   *
              FROM pur_order_hd,
                   pur_order_ln,
                   pur_ord_ln_schedule
             WHERE poh_bu = p_bu
               AND poh_order_pfx = p_order_pfx
               AND poh_order_no = p_order_no
               AND poh_mode = p_poh_mode
               AND poh_bu = pol_bu
               AND poh_order_pfx = pol_order_pfx
               AND poh_order_no = pol_order_no
               AND pols_bu = pol_bu
               AND pols_order_pfx = pol_order_pfx
               AND pols_order_no = pol_order_no
               AND pols_seq_no = pol_seq_no
               AND pol_status IN('P', 'A')
               AND pol_ordered_qty <> pol_received_qty
               AND pols_ordered_qty <> pols_receipt_qty
               AND pols_ordered_qty > pols_receipt_qty
               AND pols_plnt=p_plnt
               --AND pols_ordered_qty >= NVL(pols_qc_temp_qty, 0)
          ORDER BY pols_bu,
                   pols_order_pfx,
                   pols_order_no,
                   pols_seq_no,
                   pols_sub_seq_no;
BEGIN
     p_result := 'FALSE';
     /*
          BELOW STATEMENT IS USED TO DELETE  ALL  RECORD FROM PUR_ORD_RECEIPT_LN_TMP FOR GIVEN SESSION ID.
     */
     DELETE      pur_ord_receipt_ln_tmp
           WHERE porlt_session_id = p_ses;

     --DELETE pur_ord_receipt_ln_tmp;
     IF p_receipt_type IN  ('P','R') THEN
          /*
               P_RECEIPT_TYPE : 'P' - ORDER WISE, 'S' - SUPPLIER WISE
                  BELOW CURSOR IS USED TO FETCH ALL THE PENDING ORDER RECORD FOR GIVEN ORDER NO (ORDER WISE).
          */
          FOR cr2 IN c2
          LOOP
         
                    
               SELECT NVL(MAX(porlt_seq_no), 0) + 1
                 INTO p_seq_no
                 FROM pur_ord_receipt_ln_tmp
                WHERE porlt_bu = p_bu
                AND porlt_session_id=p_ses;
               /*
                           BELOW STATEMENT IS USED TO INSERT RECORD IN PUR_ORD_RECEIPT_LN_TMP TABLE.
                */
               INSERT INTO pur_ord_receipt_ln_tmp
                           (
                           porlt_bu,
                           porlt_po_pfx,
                           porlt_seq_no,
                           porlt_po_no,
                           porlt_po_seq_no,
                           porlt_po_sub_seq_no,
                           porlt_sc_unit_cost,
                           porlt_scon_lbr_unit_cost,
                           porlt_disc_pct,
                           porlt_qc_required,
                           porlt_scon_mat_unit_cost,
                           porlt_order_qty,
                           porlt_receipt_qty,
                           porlt_qc_temp_qty,
                           porlt_net_disc_flag,
                           porlt_status,
                           porlt_select_flag,
                           porlt_cre_by,
                           porlt_cre_date,
                           porlt_session_id,
                           porlt_bom_no,
                           porlt_plnt,
                           porlt_storage_store_id,
                           porlt_storage_store_name,
                           porlt_conv_factor,
                           porlt_sc_suplr_flag,
                           porlt_commodity_code
                           )
                    VALUES (
                           p_bu,
                           p_order_pfx,
                           p_seq_no,
                           cr2.pols_order_no,
                           cr2.pols_seq_no,
                           cr2.pols_sub_seq_no,
                           NVL(cr2.pol_sc_unit_cost, 0),
                           NVL(cr2.pol_scon_lbr_unit_cost, 0),
                           NVL(cr2.pol_disc_pct, 0),
                           DECODE(cr2.pols_sc_suplr_flag,'N',cr2.pol_qc_required,'Y','N',NULL,cr2.pol_qc_required),
                           0,
                           cr2.pols_ordered_qty,
                           cr2.pols_receipt_qty,
                           cr2.pols_qc_temp_qty,
                           cr2.pol_net_disc_flag,
                           cr2.pol_status,
                           'N',
                           USER,
                           trunc(SYSDATE),
                           p_ses,
                           cr2.pols_bom_no,
                           DECODE(cr2.pols_sc_suplr_flag,'N',cr2.pols_plnt,'Y',cr2.pols_plnt,NULL,cr2.pols_plnt),
                           cr2.pols_store_id,
                           cr2.pols_store_name,
                           cr2.pol_conv_factor,
                           cr2.pols_sc_suplr_flag,
                           func_find_commodity_code(p_bu,cr2.pol_prod_id,cr2.pol_prod_rev)
                           );

               p_result := 'TRUE';
          END LOOP;
          
                    
     ELSIF p_receipt_type = 'S' THEN
          FOR cr1 IN c1
          LOOP
               SELECT NVL(MAX(porlt_seq_no), 0) + 1
                 INTO p_seq_no
                 FROM pur_ord_receipt_ln_tmp
                WHERE porlt_bu = p_bu;
               /*
                            BELOW STATEMENT IS USED TO INSERT RECORD IN PUR_ORD_RECEIPT_LN_TMP TABLE.
                 */
               INSERT INTO pur_ord_receipt_ln_tmp
                           (
                           porlt_bu,
                           porlt_po_pfx,
                           porlt_seq_no,
                           porlt_po_no,
                           porlt_po_seq_no,
                           porlt_po_sub_seq_no,
                           porlt_sc_unit_cost,
                           porlt_scon_lbr_unit_cost,
                           porlt_disc_pct,
                           porlt_qc_required,
                           porlt_scon_mat_unit_cost,
                           porlt_order_qty,
                           porlt_receipt_qty,
                           porlt_qc_temp_qty,
                           porlt_net_disc_flag,
                           porlt_status,
                           porlt_select_flag,
                           porlt_cre_by,
                           porlt_cre_date,
                           porlt_session_id,
                           porlt_bom_no,
                           porlt_plnt,
                           porlt_storage_store_id,
                           porlt_storage_store_name,
                           porlt_conv_factor,
                           porlt_sc_suplr_flag,
                           porlt_commodity_code,
                           porlt_ord_stk_qty
                           )
                    VALUES (
                           p_bu,
                           cr1.pols_order_pfx,
                           p_seq_no,
                           cr1.pols_order_no,
                           cr1.pols_seq_no,
                           cr1.pols_sub_seq_no,
                           NVL(cr1.pol_sc_unit_cost, 0),
                           NVL(cr1.pol_scon_lbr_unit_cost, 0),
                           cr1.pol_disc_pct,
                           cr1.pol_qc_required,
                           0,
                           cr1.pols_ordered_qty,
                           cr1.pols_receipt_qty,
                           cr1.pols_qc_temp_qty,
                           cr1.pol_net_disc_flag,
                           cr1.pol_status,
                           'N',
                           USER,
                           trunc(SYSDATE),
                           p_ses,
                           cr1.pols_bom_no,
                           DECODE(cr1.pols_sc_suplr_flag,'N',cr1.pols_plnt,'Y',cr1.pols_plnt,NULL,cr1.pols_plnt),
                           cr1.pols_store_id,
                           cr1.pols_store_name,
                           cr1.pol_conv_factor,
                           cr1.pols_sc_suplr_flag,
                           func_find_commodity_code(p_bu,cr1.pol_prod_id,cr1.pol_prod_rev),
                           cr1.pols_ord_stk_qty
                           );

               p_result := 'TRUE';
          END LOOP;
     END IF;

     COMMIT;
END;
/

SHOW ERRORS;

/*
Revision History
-------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                |
|         |                   |                  |                       |
--------------------------------------------------------------------------
|1        |Sivaram            | 04-Dec-2007      |Coding and development |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|2        |Sivaram            | 04-Dec-2007      |Documentation          |
|         |                   |                  |                       |
-------------------------------------------------------------------------
Description of the Procedure:
1 This procedure is used to apply the landed cost charged and non charged amount to
  purchase receipt line wise.
 */
 
CREATE OR REPLACE PROCEDURE proc_convert_por_land_tax (
   var_bu            VARCHAR2,
   var_receipt_pfx   VARCHAR2,
   var_receipt_no    VARCHAR2,
   var_ex_rate	     NUMBER
)
IS 
   CURSOR c9 (var_prod_cls VARCHAR2)
   IS
      SELECT SUM (((porl_sc_unit_cost - (porl_sc_unit_cost * porl_disc_pct / 100)) - 
      		   porl_sc_lm_disc_amt) * var_ex_rate * porl_receipt_qty) sum_of_cls_porl_amt
        FROM pur_ord_receipt_ln, pur_order_ln
       WHERE porl_bu = var_bu
         AND porl_receipt_pfx = var_receipt_pfx
         AND porl_receipt_no = var_receipt_no
         AND pol_bu = porl_bu
         AND pol_order_pfx = porl_po_pfx
         AND pol_order_no = porl_po_no
         AND pol_seq_no = porl_po_seq_no
         AND pol_prod_cls = var_prod_cls;

   CURSOR c10
   IS
      SELECT SUM (((porl_sc_unit_cost - (porl_sc_unit_cost * porl_disc_pct / 100)) - 
      		   porl_sc_lm_disc_amt) * var_ex_rate * porl_receipt_qty) sum_of_porl_amt
        FROM pur_ord_receipt_ln
       WHERE porl_bu = var_bu
         AND porl_receipt_pfx = var_receipt_pfx
         AND porl_receipt_no = var_receipt_no;

   cr10                     c10%ROWTYPE;
   cr9                      c9%ROWTYPE;
   var_aportion_cls_amt     NUMBER (17, 5);
   var_aportion_order_amt   NUMBER (17, 5);
   tax_asset_value          NUMBER (17, 5) := 0;
   tax_expense_value        NUMBER (17, 5) := 0;
   discount_value           NUMBER (17, 5) := 0;
BEGIN
   -- This cursor is used to navigate the purchase receipts line by line.

   	DELETE por_tax_charges
         WHERE portc_bu = var_bu
           AND portc_receipt_pfx = var_receipt_pfx
           AND portc_receipt_no = var_receipt_no
           AND portc_type='L';

   FOR cr1 IN (SELECT porl_bu, porl_receipt_pfx, porl_receipt_no,porl_seq_no, porl_po_pfx,porl_po_no,
                      porl_po_seq_no, porl_po_sub_seq_no, porl_sc_unit_cost,porl_disc_pct,
                      porl_sc_lm_disc_amt,
                      porl_receipt_qty, porl_accepted_qty, porl_rejected_qty,
                      porl_cre_by, porl_cre_date, porl_upd_by, porl_upd_date,
                      (SELECT pol_prod_cls
                         FROM pur_order_ln
                        WHERE pol_bu = var_bu
                          AND pol_order_pfx = porl_po_pfx
                          AND pol_order_no = porl_po_no
                          AND pol_seq_no = porl_po_seq_no)
                            pol_prod_cls
                 FROM pur_ord_receipt_ln
                WHERE porl_bu = var_bu
                  AND porl_receipt_pfx = var_receipt_pfx
                  AND porl_receipt_no = var_receipt_no)
   LOOP
      FOR cr4 IN (SELECT *
                    FROM po_receipt_tax_charges
                   WHERE porectc_bu = var_bu
                     AND porectc_receipt_pfx = var_receipt_pfx
                     AND porectc_receipt_no = var_receipt_no
                     AND porectc_type='L')
      LOOP
         OPEN c10;
         FETCH c10 INTO cr10;

         IF c10%NOTFOUND
         THEN
            raise_application_error (
               -20303,
               'The total value of purchase receipts not found'
            );
         END IF;

         CLOSE c10;
         var_aportion_order_amt :=   (  (cr4.porectc_tc_amt)
                                      * (  ((cr1.porl_sc_unit_cost - (cr1.porl_sc_unit_cost * cr1.porl_disc_pct / 100)) - 
      		   cr1.porl_sc_lm_disc_amt) * var_ex_rate * cr1.porl_receipt_qty
                                        )
                                      / cr10.sum_of_porl_amt
                                     )
                                   / cr1.porl_receipt_qty;
								   
		--raise_application_error(-20999,'var_aportion_order_amt'||var_aportion_order_amt);						   

         INSERT INTO por_tax_charges
                     (portc_bu, portc_receipt_pfx, portc_receipt_no,
                      portc_po_pfx,portc_po_no, portc_seq_no,
                      portc_sub_seq_no, portc_tc_id, portc_charge_flag,
                      portc_tc_unit_amt, portc_cre_by,
                      portc_cre_date,portc_type,portc_receipt_seq_no)
              VALUES (cr1.porl_bu, cr1.porl_receipt_pfx, cr1.porl_receipt_no,
                      cr1.porl_po_pfx,cr1.porl_po_no, cr1.porl_po_seq_no,
                      cr1.porl_po_sub_seq_no, cr4.porectc_tc_id, cr4.porectc_charge_flag,
                      var_aportion_order_amt, cr1.porl_cre_by,
                      cr1.porl_cre_date,'L',cr1.porl_seq_no);
      END LOOP;
   --END LOOP;
----------------------------------------------------------------------
FOR cr2 IN (SELECT *
                    FROM por_prod_tax_charges
                   WHERE porptc_bu = cr1.porl_bu
                     AND porptc_receipt_pfx = cr1.porl_receipt_pfx
                     AND porptc_receipt_no = cr1.porl_receipt_no
		     AND porptc_po_pfx = cr1.porl_po_pfx
                     AND porptc_po_no = cr1.porl_po_no
                     AND porptc_seq_no = cr1.porl_po_seq_no
                     AND porptc_sub_seq_no = cr1.porl_po_sub_seq_no
                     AND porptc_type = 'L')
      LOOP
         INSERT INTO por_tax_charges
                     (portc_bu, portc_receipt_pfx,
                      portc_receipt_no, portc_po_pfx,portc_po_no,
                      portc_seq_no, portc_sub_seq_no,
                      portc_tc_id, portc_charge_flag,
                      portc_tc_unit_amt,
                      portc_cre_by, portc_cre_date,portc_type,portc_receipt_seq_no)
              VALUES (cr2.porptc_bu, cr2.porptc_receipt_pfx,
                      cr2.porptc_receipt_no, cr2.porptc_po_pfx,cr2.porptc_po_no,
                      cr2.porptc_seq_no, cr2.porptc_sub_seq_no,
                      cr2.porptc_tc_id, cr2.porptc_charge_flag,
                      (cr2.porptc_tc_amt) / cr1.porl_receipt_qty,
                      cr2.porptc_cre_by, cr2.porptc_cre_date,'L',cr2.porptc_receipt_seq_no);
      END LOOP;
 END LOOP;
----------------------------------------------------------------------
   FOR cr5 IN (SELECT porh_exchange_rate, porl_bu, porl_receipt_pfx,
                      porl_receipt_no, porl_po_pfx,porl_po_no, porl_po_seq_no,
                      porl_po_sub_seq_no, porl_sc_unit_cost, porl_receipt_qty,
                      porl_accepted_qty, porl_rejected_qty, 
                      porl_cre_by,
                      porl_cre_date, porl_upd_by, porl_upd_date
                 FROM pur_ord_receipt_hd, pur_ord_receipt_ln
                WHERE porh_bu = var_bu
                  AND porh_receipt_pfx = var_receipt_pfx
		  AND porh_receipt_no = var_receipt_no
                  AND porh_bu = porl_bu
                  AND porh_receipt_pfx = porl_receipt_pfx                  
                  AND porh_receipt_no = porl_receipt_no
	       )
   LOOP
     
      SELECT NVL (SUM (portc_tc_unit_amt), 0)
        INTO tax_expense_value
        FROM por_tax_charges, tax_charges
       WHERE portc_bu = cr5.porl_bu
         AND portc_receipt_pfx = cr5.porl_receipt_pfx
         AND portc_receipt_no = cr5.porl_receipt_no
	 AND portc_po_pfx = cr5.porl_po_pfx
         AND portc_po_no = cr5.porl_po_no
         AND portc_seq_no = cr5.porl_po_seq_no
         AND portc_sub_seq_no = cr5.porl_po_sub_seq_no
         AND portc_type='L'
         AND portc_bu = tc_bu
         AND portc_tc_id = tc_tc_id
         AND tc_prod_chargeable = 'N';		 		
        
      SELECT NVL (SUM (portc_tc_unit_amt), 0)
        INTO tax_asset_value
        FROM por_tax_charges, tax_charges
       WHERE portc_bu = cr5.porl_bu
         AND portc_receipt_pfx = cr5.porl_receipt_pfx
         AND portc_receipt_no = cr5.porl_receipt_no
	 AND portc_po_pfx = cr5.porl_po_pfx
         AND portc_po_no = cr5.porl_po_no
         AND portc_seq_no = cr5.porl_po_seq_no
         AND portc_sub_seq_no = cr5.porl_po_sub_seq_no
         AND portc_type='L'
         AND portc_bu = tc_bu
         AND portc_tc_id = tc_tc_id
         AND tc_prod_chargeable <> 'N'
         AND tc_charge_flag <> 'D';		
                  

      SELECT NVL (SUM (portc_tc_unit_amt), 0)
        INTO discount_value
        FROM por_tax_charges, tax_charges
       WHERE portc_bu = cr5.porl_bu
         AND portc_receipt_pfx = cr5.porl_receipt_pfx
         AND portc_receipt_no = cr5.porl_receipt_no
	 AND portc_po_pfx = cr5.porl_po_pfx
         AND portc_po_no = cr5.porl_po_no
         AND portc_seq_no = cr5.porl_po_seq_no
         AND portc_sub_seq_no = cr5.porl_po_sub_seq_no
         AND portc_type='L'
         AND portc_bu = tc_bu
         AND portc_tc_id = tc_tc_id
         AND tc_charge_flag = 'D';

      UPDATE pur_ord_receipt_ln
         SET porl_bc_land_cost = tax_asset_value,
             porl_bc_nchrg_land_cost = tax_expense_value,
             porl_sc_lm_disc_amt = discount_value
       WHERE porl_bu = cr5.porl_bu
         AND porl_receipt_pfx = cr5.porl_receipt_pfx
         AND porl_receipt_no = cr5.porl_receipt_no
	 AND porl_po_pfx = cr5.porl_po_pfx
         AND porl_po_no = cr5.porl_po_no
         AND porl_po_seq_no = cr5.porl_po_seq_no
         AND porl_po_sub_seq_no = cr5.porl_po_sub_seq_no;
   END LOOP;

  UPDATE pur_ord_receipt_hd
      SET porh_lc_chk_acc_flag = 'Y'
    WHERE porh_bu = var_bu
      AND porh_receipt_pfx = var_receipt_pfx
      AND porh_receipt_no = var_receipt_no;

   COMMIT;
END;
/

SHOW ERRORS;


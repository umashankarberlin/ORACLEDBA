CREATE OR REPLACE TRIGGER trg_aufer_pur_cont_price_rev
     INSTEAD OF UPDATE
     ON pur_contr_batch_view
     FOR EACH ROW
DECLARE
     var_status     VARCHAR2(10);
BEGIN
     IF :NEW.pcdhd_date_to <> :OLD.pcdhd_date_to THEN
          /* 1. This procedure will check if there are any pending
               Purchase Orders of order date between to date of contract
               price and sysdate while updating To date of contract price
           2. It checks only contract price basis Purchase orders
               and status only in 'New' or 'Partial' Or
              'Approve' or 'Amendment' or 'Receipt'
         */
        /*  proc_cont_price_rev(
               :NEW.pcdhd_bu,
               :NEW.pcdhd_suplr_id,
               :NEW.pcdhd_date_to,
               :NEW.pcdhd_prod_id,
               :NEW.pcdhd_prod_rev
          );*/

          /* Query to select the status of the document*/
          SELECT pcb_status
            INTO var_status
            FROM pur_contr_batch
           WHERE pcb_bu = :NEW.pcdhd_bu
             AND pcb_batch_no = :NEW.pcdhd_batch_no
             AND pcb_plnt = :NEW.pcdhd_plnt;

          IF var_status NOT IN('A') THEN
          	raise_application_error (-20999, 'Not In Approved Status');
          ELSIF var_status IN('A') THEN
               /* Query to update the to date if the status is in 'Approve'*/
               UPDATE pur_contr_details_hd
                  SET pcdhd_date_to = :NEW.pcdhd_date_to
                WHERE pcdhd_bu = :NEW.pcdhd_bu
                  AND pcdhd_batch_no = :NEW.pcdhd_batch_no
                  AND pcdhd_suplr_id = :NEW.pcdhd_suplr_id
                  AND pcdhd_prod_id = :NEW.pcdhd_prod_id
                  AND pcdhd_prod_rev = :NEW.pcdhd_prod_rev
                  AND pcdhd_plnt = :NEW.pcdhd_plnt;
          END IF;
     END IF;
     IF :NEW.pcdhd_status <> :OLD.pcdhd_status THEN
     IF :NEW.pcdhd_status='C' AND :OLD.pcdhd_status = 'A' THEN
     		UPDATE pur_contr_details_hd
     		  SET pcdhd_status = :NEW.pcdhd_status,
     		      pcdhd_upd_by = :NEW.pcdhd_upd_by,
     		      pcdhd_upd_date = :NEW.pcdhd_upd_date
     		WHERE pcdhd_bu = :NEW.pcdhd_bu
     		  AND pcdhd_batch_no = :NEW.pcdhd_batch_no
     		  AND pcdhd_suplr_id = :NEW.pcdhd_suplr_id
     		  AND pcdhd_prod_id = :NEW.pcdhd_prod_id
                       AND pcdhd_prod_rev = :NEW.pcdhd_prod_rev;
     END IF;
     END IF;

/*IF :NEW.pcdhd_date_to > :OLD.pcdhd_date_to THEN
raise_application_error (-20194, 'Refer Error Table');
END IF;*/
END;
/

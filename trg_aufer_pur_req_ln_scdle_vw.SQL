/*

 Revision History
 -------------------------------------------------------------------------
 |Revision |Last Update By     | Last Update Date |Purpose                |
 |         |                   |                  |                       |
 -------------------------------------------------------------------------
 |1        |k.kathir           | 15-Feb-2007      |Coding and development |
 |         |                   |                  |                       |
 -------------------------------------------------------------------------
 |3        |k.kathir           | 05-May-2007      |Documentation          |
 |         |                   |                  |                       |
 -------------------------------------------------------------------------

 Description of the Trigger:
 
 	This Instead of trigger will allow you to update purchase order
    schedule select flag,processor id rfq mode whenever updating select flag in the view
    pur_req_ln_scdle_view.
	
*/

CREATE OR REPLACE TRIGGER trg_aufer_pur_req_ln_scdle_vw
   INSTEAD OF UPDATE
   ON pur_req_ln_scdle_view
   FOR EACH ROW
BEGIN
  
   IF (:NEW.prls_select_flag <> :OLD.prls_select_flag 
   OR :NEW.prls_rfq<>:OLD.prls_rfq 
   OR :NEW.prls_select_flag = :OLD.prls_select_flag
   OR :NEW.prls_buyer_id <> :OLD.prls_buyer_id) 
   THEN  
      UPDATE pur_req_ln_schedule
       
         SET prls_select_flag = :NEW.prls_select_flag,
             prls_procr_id = :NEW.prls_procr_id,
             prls_rfq =:NEW.prls_rfq,
             prls_buyer_id=:NEW.prls_buyer_id,
             prls_upd_by = :NEW.prls_upd_by,
             prls_upd_date = :NEW.prls_upd_date
       WHERE prls_bu = :NEW.prls_bu
         AND prls_rqst_pfx = :NEW.prls_rqst_pfx
         AND prls_rqst_no = :NEW.prls_rqst_no
         AND prls_seq_no = :NEW.prls_seq_no
         AND prls_sub_seq_no = :NEW.prls_sub_seq_no;
                  
   END IF;
 
END;
/
.
SHOW ERROR;

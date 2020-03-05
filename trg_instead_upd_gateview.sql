-- Created By : Rangarajan.J
-- Created On : 28-Nov-2007 03:20 PM
-- Instead of trigger for Gate Entry To MIN 
CREATE OR REPLACE TRIGGER trg_instead_upd_gateview
     INSTEAD OF UPDATE
     ON gate_entry_view
     FOR EACH ROW
BEGIN
     IF UPDATING THEN
 --raise_application_error(-20999,'sel'||:NEW.gedl_sel_rec||' sel rec'|| :OLD.gedl_sel_rec );
          IF :OLD.gedl_sel_rec <> :NEW.gedl_sel_rec THEN

                UPDATE gate_entry_details
                  SET gedl_sel_rec = :NEW.gedl_sel_rec                      
                WHERE gedl_bu = :NEW.gedl_bu
                  AND gedl_doc_no = :NEW.gedl_doc_no
                  AND gedl_seq_no = :NEW.gedl_seq_no
                  AND gedl_sub_seq_no = :NEW.gedl_sub_seq_no;

          END IF;
     END IF;
END;
/
show err;

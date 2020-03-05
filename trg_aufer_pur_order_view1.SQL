-- U.SELVAGANAPATHY
-- 07.08.2007

CREATE OR REPLACE TRIGGER trg_aufer_pur_order_view1 INSTEAD OF UPDATE
ON pur_order_view1 FOR EACH ROW
BEGIN
  IF (:NEW.pols_promise_date <> :OLD.pols_promise_date) OR (:OLD.pols_promise_date IS NULL) THEN
	UPDATE pur_ord_ln_schedule
	   SET pols_promise_date = :NEW.pols_promise_date
	 WHERE pols_bu = :NEW.pols_bu
	   AND pols_order_pfx = :NEW.pols_order_pfx
	   AND pols_order_no = :NEW.pols_order_no
	   AND pols_seq_no = :NEW.pols_seq_no
	   AND pols_sub_seq_no = :NEW.pols_sub_seq_no;
  END IF;	  
END;
/

SHOW ERRORS;
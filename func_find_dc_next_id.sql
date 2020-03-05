/*
  Revision History
  -------------------------------------------------------------------------
  |Revision |Last Update By     | Last Update Date |Purpose                |
  |         |                   |                  |                       |
  -------------------------------------------------------------------------
  |1        |Rajesh S.          | 31-May-2005      |Coding and development |
  |         |                   |                  |                       |
  -------------------------------------------------------------------------

  Description of the Function:
	
	This function is used to get the dc no and update the next no in yearly dc nos
	
	This function takes the parameter are bu, year, user, document.
	
	This function return the document next no

  Referenced by  :
	proc_material_issue
  References     :  	
*/
CREATE OR REPLACE FUNCTION func_find_dc_next_id(
     p_bu       VARCHAR2,
     p_year     NUMBER,
     p_doc      VARCHAR2,
     p_user     VARCHAR2,
     p_plnt	VARCHAR2
)
     RETURN VARCHAR2 IS
     CURSOR c1 IS
          SELECT ydn_doc_next_no next_no
            FROM yearly_dc_nos
           WHERE ydn_bu = p_bu
             AND ydn_year = p_year
             AND ydn_doc_type = p_doc
             AND ydn_plnt = p_plnt;

     cr1             c1%ROWTYPE;
     v_document_no     VARCHAR2(15);
     v_after_str       VARCHAR2(20);
BEGIN
     OPEN c1;
     FETCH c1 INTO cr1;

     IF c1%NOTFOUND THEN
          raise_application_error(-20254, 'Refer Error Table');
          CLOSE c1;
     ELSE
          v_document_no := cr1.next_no;
     END IF;

     v_after_str := func_find_next_id(v_document_no);

     UPDATE yearly_dc_nos
        SET ydn_doc_next_no = v_after_str,
            ydn_use_flag = 'Y',
            ydn_upd_by = p_user,
            ydn_upd_date = SYSDATE
      WHERE ydn_bu = p_bu
        AND ydn_year = p_year
        AND ydn_doc_type = p_doc
        AND ydn_plnt = p_plnt;

     RETURN v_document_no;
END;
/

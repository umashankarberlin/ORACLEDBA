/*
Revision History
-------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|1        |M.Sivaprakash      | 09-Aug-2004      |Coding and development |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|2        |M.Sivaprakash      | 11-Apr-2005      |   updated             |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|3        |Suresh             | 07-May-2007      |Documentation          |
|         |                   |                  |                       |
-------------------------------------------------------------------------
Description of the Functions:
  1. This Function is used to find the purchase next no.

  2. This function takes the parameters like bu,document no,year,user.

  3. This function  return the value purchase next no  */


CREATE OR REPLACE FUNCTION func_find_pom_next_id(
     p_bu       VARCHAR2,
     p_doc      VARCHAR2,
     p_year     NUMBER,
     p_user     VARCHAR2,
     p_plnt     VARCHAR2
)
     RETURN VARCHAR2 IS
     /* cursor fetches the purchase yearly document next no from pom_yearly_doc_nos table for given parameter*/
     CURSOR c1 IS
          SELECT pydn_doc_next_no
            FROM pom_yearly_doc_nos
           WHERE pydn_bu = p_bu
             AND pydn_doc_type = p_doc
             AND pydn_year = p_year
             AND pydn_plnt = p_plnt;

     after_str       VARCHAR2(20);
     cr1             c1%ROWTYPE;
     document_no     VARCHAR2(15);
BEGIN
     OPEN c1;
     FETCH c1 INTO cr1;
       /* Raises error if no data found*/
     IF c1%NOTFOUND THEN
          raise_application_error(-20327, 'Application No not found');
          CLOSE c1;
     ELSE
          document_no := cr1.pydn_doc_next_no;
     END IF;

     after_str := func_find_next_id(document_no);

     /*yearly document not exist,to find next no and update the value in pom_yearly_doc_nos table*/
     IF     document_no IS NOT NULL
        AND after_str IS NOT NULL THEN
          UPDATE pom_yearly_doc_nos
             SET pydn_doc_next_no = after_str,
                 pydn_upd_by = p_user
           WHERE pydn_bu = p_bu
             AND pydn_doc_type = p_doc
             AND pydn_year = p_year
             AND pydn_plnt = p_plnt;
     END IF;
       /* Returns next document no. */
     RETURN document_no;
END;
/

SHOW ERRORS;

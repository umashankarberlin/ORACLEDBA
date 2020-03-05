/*

Revision History
-------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|1        |Kathir             | 15-Dec-2005      |Coding and development |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|2        |Sivaprakash        | 05-May-2007      |Documentation          |
|         |                   |                  |                       |
-------------------------------------------------------------------------

Description of the Procedure:

     1. This Trigger is used to check the date range intersection.
     2. It also checks if the same product and revision exists 
        with intersected date,when it will raise the error.

Referenced by  :

References     :

*/

CREATE OR REPLACE TRIGGER trg_aiufs_pur_deflt_suplr
     AFTER INSERT OR UPDATE
     ON prod_deflt_suplr_hd
DECLARE
    /*
        Cursor c1 will fetch all the records with rowid from 
        prod_deflt_suplr_hd table.
    */

     CURSOR c1 IS
          SELECT ROWID,
                 pdshd_bu,
                 pdshd_prod_id,
                 pdshd_prod_rev,
                 pdshd_plnt,
                 pdshd_eff_from,
                 pdshd_eff_to
            FROM prod_deflt_suplr_hd
           WHERE pdshd_status <> 'C';
            -- AND pdshd_status <> 'R';
      /*
         Cursor c2 will fetch records based on a specific product id
         and revision except one rowid.
      */
     
     CURSOR c2(
          rid          VARCHAR2,
          bu           VARCHAR2,
          plnt	       VARCHAR2,
          prod_id      VARCHAR2,
          prod_rev     NUMBER
     ) IS
          SELECT pdshd_eff_from,
                 pdshd_eff_to
            FROM prod_deflt_suplr_hd
           WHERE ROWID <> rid
             AND pdshd_bu = bu
             AND pdshd_plnt = plnt
             AND pdshd_prod_id = prod_id
             AND pdshd_prod_rev = prod_rev
             AND pdshd_status <> 'C';
             --AND pdshd_status <> 'R';
BEGIN
     FOR cr1 IN c1
     LOOP
          FOR cr2 IN c2(
                          cr1.ROWID,
                          cr1.pdshd_bu,
                          cr1.pdshd_plnt,
                          cr1.pdshd_prod_id,
                          cr1.pdshd_prod_rev
                     )
          LOOP
   /* 
       If condition will check for intersection from each row date from and date to
       of cursor c2 with cursor c1 date from and date to, if date range
       intersects ,it will raise the error.
    */
           IF cr2.pdshd_eff_from BETWEEN cr1.pdshd_eff_from
                                         AND cr1.pdshd_eff_to THEN
                    raise_application_error(-20047, 'Refer Error Table');
               END IF;

               IF cr2.pdshd_eff_to BETWEEN cr1.pdshd_eff_from AND cr1.pdshd_eff_to THEN
                    raise_application_error(-20047, 'Refer Error Table');
               END IF;

               IF     cr2.pdshd_eff_from <= cr1.pdshd_eff_from
                  AND cr2.pdshd_eff_to >= cr1.pdshd_eff_to THEN
                    raise_application_error(-20047, 'Refer Error Table');
               END IF;
          END LOOP;
     END LOOP;
END;
/

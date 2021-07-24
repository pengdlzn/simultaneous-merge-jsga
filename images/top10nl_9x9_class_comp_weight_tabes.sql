DROP TABLE IF EXISTS public.class_weights;
CREATE TABLE public.class_weights (
  code INTEGER,
  weight FLOAT
);

DROP TABLE IF EXISTS public.class_comp_matrix;
CREATE TABLE public.class_comp_matrix (
  code_from INTEGER,
  code_to INTEGER,
  code_dis FLOAT,
  comp_value FLOAT
);


CREATE OR REPLACE FUNCTION 
  populate_class_weights(class_codes INTEGER[]) RETURNS void AS
  $$
  DECLARE  
    class_code INTEGER;   
  BEGIN
    FOREACH class_code IN ARRAY class_codes    
    LOOP
      EXECUTE format(
        'INSERT INTO %s (code, weight) 
         VALUES ($1, $2);', 'class_weights')
      USING class_code, 1; 
    END LOOP;
  END;
  $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION 
  populate_class_comp_matrix(class_codes INTEGER[]) RETURNS void AS
  $$
  DECLARE   
    code_fr INTEGER;
    code_to INTEGER;
    division_fr INTEGER;     
    division_to INTEGER; 
    code_dis FLOAT;
    dis_max FLOAT := 10;
    comp_value FLOAT;
    code_dis_test INTEGER[];
    code_dis_test_arr INTEGER[] := ARRAY[[1000,8], [100,6], [10,4], [1,2]];      
  BEGIN
    FOREACH code_fr IN ARRAY class_codes
    LOOP      
      FOREACH code_to IN ARRAY class_codes      
      LOOP
        code_dis := 0;
        IF code_fr != code_to THEN
          -- code_dis_test is the inner array of code_dis_test_arr
          FOREACH code_dis_test SLICE 1 IN ARRAY code_dis_test_arr      
          LOOP
            division_fr := code_fr / code_dis_test[1];
            division_to := code_to / code_dis_test[1];
            IF division_fr != division_to THEN
              code_dis := code_dis_test[2];
              EXIT;
            END IF;
          END LOOP;
        END IF;
      
        comp_value := (dis_max - code_dis) / dis_max;
        EXECUTE format(
          'INSERT INTO %s (code_from, code_to, code_dis, comp_value)
          VALUES ($1, $2, $3, $4);', 'class_comp_matrix')
        USING code_fr, code_to, code_dis, comp_value;        
      END LOOP;
    END LOOP;
  END;
  $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION 
  populate_tables() RETURNS void AS 
  $$
  DECLARE
    total_cost FLOAT := 0;
    class_codes INTEGER[] := ARRAY[10310, 10311, 10410, 10411, 10510, 10600, 
  			10700, 10710, 10720, 10730, 10740, 10741, 10750, 10760, 10780, 
  			12400, 12500, 13000, 14010, 14030, 14040, 14050, 14060, 14080, 
  			14090, 14100, 14120, 14130, 14140, 14160, 14162, 14170, 14180];
  BEGIN
    EXECUTE populate_class_weights(class_codes);
    EXECUTE populate_class_comp_matrix(class_codes);    
  END;
  $$ LANGUAGE plpgsql;


SELECT populate_tables();
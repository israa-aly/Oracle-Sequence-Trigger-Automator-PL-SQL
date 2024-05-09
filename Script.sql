declare
   v_table_name  varchar2 (70);
   v_pk_name  varchar2 (70);
   v_sql  varchar2 (5000);
   v_max_id  number;
  cursor  tablee IS
    select t.table_name, col.column_name
    from user_tables t
    join user_tab_columns col on t.table_name = col.table_name
    join user_cons_columns c on col.column_name = c.column_name and col.table_name = c.table_name
    join user_constraints con on c.constraint_name = con.constraint_name
    where con.constraint_type = 'P' 
    and col.data_type = 'NUMBER' and con.constraint_name not in
    (select constraint_name 
      from user_cons_columns 
      group by constraint_name 
      having count(*) > 1);


begin
   for rec in tablee
   loop
      v_table_name := rec.table_name;
      v_pk_name :=rec.column_name;
      -- 1) drop sequnces
      begin
         v_sql := 'drop sequence ' || v_table_name || '_seq';
         execute immediate v_sql;
      end;
      
 -- 2) max id for pk
      v_sql := 'select nvl (max('|| v_pk_name|| '), 1) from '|| v_table_name;
      execute immediate v_sql into v_max_id;

   -- 3)Create sequences
      v_sql := 'create sequence '|| v_table_name|| '_seq start with '|| v_max_id|| ' increment by 1 nocache nocycle'; 
      execute immediate v_sql;
      --4) Create or replace triggeres
      v_sql :='create or replace trigger  '|| v_table_name || '_trg 
      before insert on '|| v_table_name|| ' for each row
          begin 
          :new.'|| v_pk_name || ' := '|| v_table_name|| '_seq.nextval; 
          end;';
      execute immediate v_sql;
   end loop;
end;
show errors

create or replace trigger hello
after insert
on emp10
declare
begin
  dbms_output.put_line('�ɹ������¼');
end;
/

create or replace trigger checkSalary
  before update on emp10  
  for each row
declare
  -- local variables here
begin
  if :old.sal>:new.sal then
    raise_application_error(-20002,'工资只能增加，不能降低');
  end if;
end checkSalary;
/

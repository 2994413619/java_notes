create or replace trigger checkSalary
  before update on emp10  
  for each row
declare
  -- local variables here
begin
  if :old.sal>:new.sal then
    raise_application_error(-20002,'����ֻ�����ӣ����ܽ���');
  end if;
end checkSalary;
/

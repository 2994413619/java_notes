create or replace trigger securityEmp10
before insert on emp10
declare
begin
  if to_char(sysdate,'day') in('������','������') or
    to_number(sysdate,'hh24') not between 9 and 17 then
    raise_application_error(-20001,'��ֹ�ڷǹ���ʱ���������');
  end if;
end; 
/

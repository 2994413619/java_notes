rem PL/SQL Developer Test Script

set feedback off
set autoprint off

rem Execute PL/SQL Block
-- if��� 
--����num:��һ����ֵַ���ڸõ�ַ�ϱ����������ֵ
accept num prompt '������һ������';

declare
       --�������������������֣����﷢������ʽת����
       pnum number := &num;
begin
       if mod(pnum,2) = 0 then dbms_output.put_line('���������ż��'||pnum);
          elsif mod(pnum,2) != 0 then dbms_output.put_line('�������������'||pnum);
          else dbms_output.put_line('�����߲�������');
       end if;
end;
/

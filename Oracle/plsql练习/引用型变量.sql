PL/SQL Developer Test script 3.0
8
-- �����ͱ��� ��ѯ����ӡ7839��������нˮ
declare
  pename emp.ename%type;
  psal emp.sal%type;
begin
  select ename,sal into pename,psal from emp where empno=7839;
  dbms_output.put_line(pename||'��нˮ��'||psal);
end;
0
0

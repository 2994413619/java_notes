PL/SQL Developer Test script 3.0
7
-- ��¼�ͱ��� ��ѯԱ����Ϊ7839��Ա����������нˮ
declare
   emp_rec emp%rowtype;
begin
   select * into emp_rec from emp where empno=7839;
   dbms_output.put_line(emp_rec.ename||'��нˮ��'||emp_rec.sal);
end;
0
0

PL/SQL Developer Test script 3.0
8
-- 引用型变量 查询并打印7839的姓名和薪水
declare
  pename emp.ename%type;
  psal emp.sal%type;
begin
  select ename,sal into pename,psal from emp where empno=7839;
  dbms_output.put_line(pename||'的薪水是'||psal);
end;
0
0

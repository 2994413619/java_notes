PL/SQL Developer Test script 3.0
7
-- 记录型变量 查询员工号为7839的员工的姓名和薪水
declare
   emp_rec emp%rowtype;
begin
   select * into emp_rec from emp where empno=7839;
   dbms_output.put_line(emp_rec.ename||'的薪水是'||emp_rec.sal);
end;
0
0

rem PL/SQL Developer Test Script

set feedback off
set autoprint off

rem Execute PL/SQL Block
-- 打印hello world
declare
--说明部分（变量定义必须在这里）
begin
   dbms_output.put_line('Hello World');
end;
/

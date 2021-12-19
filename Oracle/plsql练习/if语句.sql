rem PL/SQL Developer Test Script

set feedback off
set autoprint off

rem Execute PL/SQL Block
-- if语句 
--变量num:是一个地址值，在该地址上保存了输入的值
accept num prompt '请输入一个数字';

declare
       --定义变量保存输入的数字（这里发生了隐式转换）
       pnum number := &num;
begin
       if mod(pnum,2) = 0 then dbms_output.put_line('您输入的是偶数'||pnum);
          elsif mod(pnum,2) != 0 then dbms_output.put_line('您输入的是奇数'||pnum);
          else dbms_output.put_line('程序走不到这里');
       end if;
end;
/

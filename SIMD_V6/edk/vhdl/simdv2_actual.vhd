----------------------------------------------------------------------------------
-- Company: 	UNCC
-- Engineer:	Sumanth Kumar Bandi 
-- 	
-- Create Date:    18:34:19 06/23/2014 
-- Design Name: 
-- Module Name:    simd_v2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library simdv2_v1_00_a;
use simdv2_v1_00_a.generic_values_pe.all;
use simdv2_v1_00_a.sm_v2;
use simdv2_v1_00_a.pe; 
use simdv2_v1_00_a.bram_code; 



entity simdv2_actual is
	generic (N : Integer := 4);
	port(
		clk,rst 	:in std_logic;
		start		: in std_logic;

		T_reg, T_mem_w, T_mem_r:in std_logic;	--control signals to s/w access register file(rd only) and memory(rd/wr)
		--For register file read
		slvreg_1,slvreg_2,slvreg_3,slvreg_4:out std_logic_vector(0 to 31);
		--For memory operation {read(addr only) and write(addr & data)}
		slvreg_5,slvreg_6,slvreg_7: in std_logic_vector(0 to 31);
		slvreg_8	: out std_logic_vector(0 to 31);

		stop		: out std_logic				 
		);

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of clk      : signal is "CLK";
  attribute SIGIS of rst      : signal is "RST";
end simdv2_actual;

architecture Behavioral of simdv2_actual is
	
	--Signal declarations
	signal mem_ce, ready_mem, done, sm_select, sm_ce : std_logic;
	signal data		: std_logic_vector(0 to (mneumonic_size)-1);
	signal addr		: std_logic_vector(0 to (code_req_addr)-1);
	signal opcode	: std_logic_vector(0 to mneumonic_opcode-1);
	signal op_1		: std_logic_vector(0 to mneumonic_op1-1);
	signal op_23	: std_logic_vector(0 to mneumonic_op23-1);
	signal pcr		: std_logic_vector(0 to 3);

BEGIN
	--Instantiating components
	uut: entity simdv2_v1_00_a.sm_v2 PORT MAP (
          clk 	=> clk,
          rst 	=> rst,
          ce 	=> sm_ce,
          ready_mem => ready_mem,
          data 	=> data,
          addr 	=> addr,
          mem_ce 	=> mem_ce,
          pcr 		=> pcr,
          opcode 	=> opcode,
          op_1 	=> op_1,
          op_23 	=> op_23,
          done 	=> done
        );
	uut1:entity simdv2_v1_00_a.bram_code 
		port map(
			clk =>clk,	
			ce	=>mem_ce, 	
			ready => ready_mem,
         data => data,
         addr => addr		
			);
	uut_pe: for I in 0 to N-1 generate proc_ele:
		entity simd2_v2_00_a.pe PORT MAP(
			clk	=> clk,
			rst	=> rst,
			slv_1	=> slvreg_1(I*word_size to (I*word_size)+word_size-1 ),
			slv_2 => slvreg_2(I*word_size to (I*word_size)+word_size-1 ),
			slv_3 => slvreg_3(I*word_size to (I*word_size)+word_size-1 ),
			slv_4 => slvreg_4(I*word_size to (I*word_size)+word_size-1 ),
			mem5_wr_addr	=> slvreg_5( (I*word_size)+word_size-ram_req_addr to (I*word_size)+word_size-1 ), --slv_regs5-8
			mem6_wr_data	=> slvreg_6( I*word_size to (I*word_size)+word_size-1 ),
			mem7_rd_addr	=> slvreg_7( (I*word_size)+word_size-ram_req_addr to (I*word_size)+word_size-1 ),
			mem8_rd_data	=> slvreg_8( I*word_size to (I*word_size)+word_size-1 ),
			T_reg 	=> T_reg,
			T_mem_w	=> T_mem_w,
			T_mem_r	=> T_mem_r,
			pcr	=> pcr,
			opcode=> opcode,
			op1	=> op_1,
			op2_3	=> op_23
			);
		end generate uut_pe;

	

----External operation control
	process(T_reg,T_mem_w,T_mem_r, sm_select)
	begin
		if(T_reg = '1' or T_mem_w='1' or T_mem_r='1') then
			sm_ce<='0';
		else
			sm_ce<=sm_select;
		end if;
	end process;

----
	process(start,done,rst)
	begin
		if(rst='1') then
			sm_select<='0';
			stop		<='0';
		elsif(start='1' and done /= '1' and rst='0') then
			sm_select<='1';
		elsif(done='1' and rst='0') then
			stop		<='1';
			sm_select<='0';
		else
			sm_select<='0';
		end if;
	end process;


END Behavioral;


-------------------------------------------------------------------------------
-- Title      : Shift Rows
-- Project    : AES-GCM
-------------------------------------------------------------------------------
-- File       : shift_rows_ea.vhd
-- Author     : Bill MacDowell  <bill@bill-macdowell-laptop>
-- Company    : 
-- Created    : 2017-03-20
-- Last update: 2017-03-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Implementation of the shift-rows portion of the AES cipher as
-- described in the FIPS 197 AES Spec. This module takes a 128-bit input block,
-- and shifts the rows of the matrix as depicted below.
--
-- Input Matrix:     Output Matrix:
-- | 0 4  8 12 |     |  0  4  8 12 | no shift
-- | 1 5  9 13 |  -> |  5  9 13  1 | 1 shift left
-- | 2 6 10 14 |     | 10 14  2  6 | 2 shifts left
-- | 3 7 11 15 |     | 15  3  7 11 | 3 shifts left
-- * where the numbers in the matrix indicate byte indicies of the 128-bit block
-- 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-20  1.0      bill    Created
-------------------------------------------------------------------------------

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.gcm_pkg.all;

entity shift_rows is

  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    block_in  : in  std_logic_vector(127 downto 0);
    block_out : out std_logic_vector(127 downto 0));

end entity shift_rows;

architecture rtl of shift_rows is

  -- These are for converting the 128-bit vectors to 4x4 byte matricies
  signal matrix_in  : t_matrix;
  signal matrix_out : t_matrix;
  
begin

  -- Convert between 128-bit vector and 4x4 byte matrix here. No added logic,
  -- just some type conversions to make VHDL happy
  v2m : process (block_in) is
  begin
    matrix_in <= vector_to_matrix(block_in);
  end process v2m;
  m2v : process (matrix_out) is
  begin
    block_out <= matrix_to_vector(matrix_out);
  end process m2v;
  
  -- This process shifts the rows of the matrix as shown in the header comment
  shift_rows_proc : process (clk) is
  begin
    if clk'event and clk = '1' then

      -- row 0 - 0 shift
      matrix_out(0)  <= matrix_in(0);
      matrix_out(4)  <= matrix_in(4);
      matrix_out(8)  <= matrix_in(8);
      matrix_out(12) <= matrix_in(12);

      -- row 1 - 1 shift left
      matrix_out(1)  <= matrix_in(5);
      matrix_out(5)  <= matrix_in(9);
      matrix_out(9)  <= matrix_in(13);
      matrix_out(13) <= matrix_in(1);

      -- row 2 - 2 shifts left
      matrix_out(2)  <= matrix_in(10);
      matrix_out(6)  <= matrix_in(14);
      matrix_out(10) <= matrix_in(2);
      matrix_out(14) <= matrix_in(6);

      -- row 3 - 3 shifts left
      matrix_out(3)  <= matrix_in(15);
      matrix_out(7)  <= matrix_in(3);
      matrix_out(11) <= matrix_in(7);
      matrix_out(15) <= matrix_in(11);

      if rst = '1' then
        matrix_out <= (others => (others => '0'));
      end if;
    end if;
  end process shift_rows_proc;
  
end rtl;

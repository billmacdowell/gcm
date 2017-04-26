-------------------------------------------------------------------------------
-- Title      : Mix Columns
-- Project    : AES-GCM
-------------------------------------------------------------------------------
-- File       : mix_columns_ea.vhd
-- Author     : Bill MacDowell  <bill@bill-macdowell-laptop>
-- Company    : 
-- Created    : 2017-03-20
-- Last update: 2017-04-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This block implements the MixColumns transformation per the AES
-- Spec in FIPS 197. This transformation treats the 128-bit input block like a
-- 4x4 byte matrix. Each column is operated on individually with the following
-- matrix multiplication:
--
-- Input column:                      Output column:
-- | S0,c |      | 02 03 01 01 |      |S'0,c|
-- | S1,c |   x  | 01 02 03 01 |   =  |S'1,c|
-- | S2,c |      | 01 01 02 03 |      |S'2,c|
-- | S3,c |      | 03 01 01 02 |      |S'3,c|
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
use work.gcm_pkg.all;

entity mix_columns is
  
  port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    block_in  : in  std_logic_vector(127 downto 0);
    block_out : out std_logic_vector(127 downto 0));

end entity mix_columns;

architecture rtl of mix_columns is

  -- These are for converting the 128-bit vectors to 4x4 byte matricies
  signal matrix_in  : t_matrix;
  signal matrix_out : t_matrix;

  -- These are for multiplying the matrix by 2 and 3
  type t_shft_matrix is array (15 downto 0) of std_logic_vector(8 downto 0);
  signal shift2        : t_shft_matrix;
  signal shift3        : t_shft_matrix;
  signal matrix_in_x_2 : t_matrix;
  signal matrix_in_x_3 : t_matrix;
  
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

  -- This process handles the multiplication by 2 and 3 of each of the elements
  -- of the matrix. It also takes care of the mix-columns transformation
  mix_columns_proc : process (clk) is
  begin
    if clk'event and clk = '1' then

      -- loop through all the bytes in the matrix
      for byte_idx in 15 downto 0 loop
        -- 1 shift left covers the multiply by 2. The XOR with matrix_in
        -- coveres the multiply by 3 because all we are doing is multiplying by
        -- 2 then adding 1. Addition in the finite field is done with XOR
        shift2(byte_idx) <= matrix_in(byte_idx) & '0';
        shift3(byte_idx) <= (matrix_in(byte_idx) & '0') xor ('0' & matrix_in(byte_idx));

        -- Now we need to do conditional XORs by reducing the results above
        -- modulo m(x). This only needs to apply to results with MSb = '1'
        if shift2(byte_idx)(shift2(byte_idx)'high) = '1' then
          matrix_in_x_2(byte_idx) <= shift2(byte_idx)(7 downto 0) xor c_irreducible_polynomial;
        else
          matrix_in_x_2(byte_idx) <= shift2(byte_idx)(7 downto 0);
        end if;
        if shift3(byte_idx)(shift3(byte_idx)'high) = '1' then
          matrix_in_x_3(byte_idx) <= shift3(byte_idx)(7 downto 0) xor c_irreducible_polynomial;
        else
          matrix_in_x_3(byte_idx) <= shift3(byte_idx)(7 downto 0);
        end if;
      end loop;

      -- Here just doing matrix multiplication
      --row one
      matrix_out(0)  <= matrix_in_x_2(0) xor matrix_in_x_3(1) xor matrix_in(2) xor matrix_in(3);
      matrix_out(4)  <= matrix_in_x_2(4) xor matrix_in_x_3(5) xor matrix_in(6) xor matrix_in(7);
      matrix_out(8)  <= matrix_in_x_2(8) xor matrix_in_x_3(9) xor matrix_in(10) xor matrix_in(11);
      matrix_out(12) <= matrix_in_x_2(12) xor matrix_in_x_3(13) xor matrix_in(14) xor matrix_in(15);
      --row two
      matrix_out(1)  <= matrix_in(0) xor matrix_in_x_2(1) xor matrix_in_x_3(2) xor matrix_in(3);
      matrix_out(5)  <= matrix_in(4) xor matrix_in_x_2(5) xor matrix_in_x_3(6) xor matrix_in(7);
      matrix_out(9)  <= matrix_in(8) xor matrix_in_x_2(9) xor matrix_in_x_3(10) xor matrix_in(11);
      matrix_out(13) <= matrix_in(12) xor matrix_in_x_2(13) xor matrix_in_x_3(14) xor matrix_in(15);
      --row three
      matrix_out(2)  <= matrix_in(0) xor matrix_in(1) xor matrix_in_x_2(2) xor matrix_in_x_3(3);
      matrix_out(6)  <= matrix_in(4) xor matrix_in(5) xor matrix_in_x_2(6) xor matrix_in_x_3(7);
      matrix_out(10) <= matrix_in(8) xor matrix_in(9) xor matrix_in_x_2(10) xor matrix_in_x_3(11);
      matrix_out(14) <= matrix_in(12) xor matrix_in(13) xor matrix_in_x_2(14) xor matrix_in_x_3(15);
      --row four
      matrix_out(3)  <= matrix_in_x_3(0) xor matrix_in(1) xor matrix_in(2) xor matrix_in_x_2(3);
      matrix_out(7)  <= matrix_in_x_3(4) xor matrix_in(5) xor matrix_in(6) xor matrix_in_x_2(7);
      matrix_out(11) <= matrix_in_x_3(8) xor matrix_in(9) xor matrix_in(10) xor matrix_in_x_2(11);
      matrix_out(15) <= matrix_in_x_3(12) xor matrix_in(13) xor matrix_in(14) xor matrix_in_x_2(15);

      if rst = '1' then
        matrix_out    <= (others => (others => '0'));
        shift2        <= (others => (others => '0'));
        shift3        <= (others => (others => '0'));
        matrix_in_x_2 <= (others => (others => '0'));
        matrix_in_x_3 <= (others => (others => '0'));
      end if;
    end if;
  end process;
  
end rtl;

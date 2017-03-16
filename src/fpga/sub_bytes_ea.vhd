----------      ---------------------------------------------------------------------
-- Title      : Sub Bytes
-- Project    : AES-GCM
-------------------------------------------------------------------------------
-- File       : sub_bytes_ea.vhd
-- Author     : Bill MacDowell  <bill@bill-macdowell-laptop>
-- Company    : 
-- Created    : 2017-03-15
-- Last update: 2017-03-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This is a wrapper around 16 s-box instantiations. There is one
-- s-box instantiated for each byte in the 4x4 matrix that makes up a block.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-15  1.0      bill    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sub_bytes is
  
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    block_in  : in  std_logic_vector(127 downto 0);
    block_out : out std_logic_vector(127 downto 0));

end entity sub_bytes;

architecture struct of sub_bytes is

  component s_box is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      byte_in  : in  std_logic_vector(7 downto 0);
      byte_out : out std_logic_vector(7 downto 0));
  end component s_box;
  
begin  -- architecture rtl

  GEN_SBOXES: for byte_idx in 0 to 15 generate
    s_box_0: s_box
      port map (
        clk      => clk,
        rst      => rst,
        byte_in  => block_in(8*byte_idx+7 downto 8*byte_idx),
        byte_out => block_out(8*byte_idx+7 downto 8*byte_idx));
  end generate GEN_SBOXES;

end struct;

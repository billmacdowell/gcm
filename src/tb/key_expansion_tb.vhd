-------------------------------------------------------------------------------
-- Title      : Testbench for design "key_expansion"
-- Project    : AES-GCM
-------------------------------------------------------------------------------
-- File       : key_expansion_tb.vhd
-- Author     : Bill MacDowell  <bill@bill-macdowell-laptop>
-- Company    : 
-- Created    : 2017-04-10
-- Last update: 2017-04-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Stimulates the key expansion block and verifies the output
-- against test vectors in the FIPS spec
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-04-10  1.0      bill    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity key_expansion_tb is

end entity key_expansion_tb;

-------------------------------------------------------------------------------

architecture tb of key_expansion_tb is

  -- component ports
  signal clk        : std_logic := '1';
  signal rst        : std_logic;
  signal key_in     : std_logic_vector(255 downto 0);
  signal round      : std_logic_vector(3 downto 0);
  signal en_key_gen : std_logic;
  signal key_out    : std_logic_vector(128 downto 0);
  

begin  -- architecture tb

  -- component instantiation
  DUT : entity work.key_expansion
    port map (
      clk        => clk,
      rst        => rst,
      key_in     => key_in,
      round      => round,
      en_key_gen => en_key_gen,
      key_out    => key_out);

  -- clock generation
  clk <= not clk after 1 ns;

  -- waveform generation
  WaveGen_Proc : process
  begin

    -- hold it in reset for 2 ns
    wait for 2 ns;
    rst        <= '1';
    en_key_gen <= '0';
    key_in     <= (others => '0');
    wait for 4 ns;
    rst        <= '0';

    wait for 4 ns;

    -- set up the input
    en_key_gen <= '1';
    key_in     <= x"0914dff42d9810a33b6108d71f352c07857d77812b73aef015ca71be603deb10";

    -- kill the sim after some time
    wait for 10 us;
    assert false report "Done!" severity failure;
    
  end process WaveGen_Proc;

  

end architecture tb;

-------------------------------------------------------------------------------

configuration key_expansion_tb_tb_cfg of key_expansion_tb is
  for tb
  end for;
end key_expansion_tb_tb_cfg;

-------------------------------------------------------------------------------

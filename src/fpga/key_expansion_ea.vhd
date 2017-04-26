-------------------------------------------------------------------------------
-- Title      : Key Expansion
-- Project    : AES-GCM
-------------------------------------------------------------------------------
-- File       : key_expansion_ea.vhd
-- Author     : Bill MacDowell  <bill@bill-macdowell-laptop>
-- Company    : 
-- Created    : 2017-03-21
-- Last update: 2017-04-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This block expands a 256-bit AES key into a full key schedule
-- for each round. An input to this block specified the round, and 1 clock
-- later, the round key is provided as an output. The key schedule is stored in
-- a small memory, which is refreshed anytime the go bit goes high.
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
use ieee.numeric_std.all;
use work.gcm_pkg.all;

entity key_expansion is

  port(
    clk        : in  std_logic;
    rst        : in  std_logic;
    key_in     : in  std_logic_vector(255 downto 0);
    round      : in  std_logic_vector(3 downto 0);
    en_key_gen : in  std_logic;
    key_out    : out std_logic_vector(128 downto 0));
end entity key_expansion;

architecture rtl of key_expansion is

  component s_box is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      byte_in  : in  std_logic_vector(7 downto 0);
      byte_out : out std_logic_vector(7 downto 0));
  end component s_box;
  
  type t_key_expansion_state is (
    idle,
    working,
    rot_and_sub_wrd,
    sub_wrd,
    simple_xor
    );
  signal state : t_key_expansion_state;

  type t_keystore is array (63 downto 0) of std_logic_vector(31 downto 0);
  signal keystore     : t_keystore;
  signal i            : unsigned(7 downto 0);
  signal last_i       : unsigned(7 downto 0);
  signal i_minus_8    : unsigned(7 downto 0);
  signal rot_word_out : std_logic_vector(31 downto 0);
  signal sub_word_out : std_logic_vector(31 downto 0);
  signal round_const  : std_logic_vector(31 downto 0);
  signal sub_word_in  : std_logic_vector(31 downto 0);
  
begin

  GEN_SBOXES_WORD : for byte_idx in 0 to 3 generate
    s_box_0 : s_box
      port map (
        clk      => clk,
        rst      => rst,
        byte_in  => sub_word_in(8*byte_idx+7 downto 8*byte_idx),
        byte_out => sub_word_out(8*byte_idx+7 downto 8*byte_idx));
  end generate GEN_SBOXES_WORD;

  key_expansion_proc : process (clk) is
  begin
    if clk'event and clk = '1' then

      case state is
        when idle =>
          
          if en_key_gen = '1' then
            -- First 7 words are just the key
            for word_idx in 7 downto 0 loop
              keystore(word_idx) <= key_in(32*word_idx+31 downto 32*word_idx);
            end loop;
            i           <= x"08";
            round_const <= x"01000000";
            state       <= working;
          end if;
          
        when working =>
          i <= i + 1;
          if i = 60 then
            state <= idle;
          elsif i(2 downto 0) = "000" then
            state <= rot_and_sub_wrd;
          elsif i(1 downto 0) = "00" then
            state <= sub_wrd;
          else
            state <= simple_xor;
          end if;
          
        when rot_and_sub_wrd =>
          keystore(to_integer(i)) <= sub_word_out xor round_const xor keystore(to_integer(i_minus_8));
          round_const             <= round_const(31 downto 1) & "0";
          state                   <= working;

        when sub_wrd =>
          keystore(to_integer(i)) <= sub_word_out xor keystore(to_integer(i_minus_8));
          state                   <= working;

        when simple_xor =>
          keystore(to_integer(i)) <= keystore(to_integer(last_i)) xor keystore(to_integer(i_minus_8));
          state                   <= working;

        when others => null;
      end case;

      if rst = '1' then
        state       <= idle;
        keystore    <= (others => (others => '0'));
        i           <= (others => '0');
        round_const <= (others => '0');
      end if;
    end if;
  end process;


  comb_proc : process (i) is
  begin
    last_i    <= i - 1;
    i_minus_8 <= i - 8;
    if last_i < 64 then
      rot_word_out(31 downto 24) <= keystore(to_integer(last_i))(23 downto 16);
      rot_word_out(23 downto 16) <= keystore(to_integer(last_i))(15 downto 8);
      rot_word_out(15 downto 8)  <= keystore(to_integer(last_i))(7 downto 0);
      rot_word_out(7 downto 0)   <= keystore(to_integer(last_i))(31 downto 24);
    else
      rot_word_out <= (others => '0');
    end if;

    -- TODO
    if i(2 downto 0) = "000" then
      sub_word_in <= rot_word_out;
    elsif i(1 downto 0) = "00" then
      sub_word_in <= keystore(to_integer(i));
    end if;
    
  end process;

end rtl;

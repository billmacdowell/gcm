-------------------------------------------------------------------------------
-- Title      : GCM Package File
-- Project    : AES-GCM
-------------------------------------------------------------------------------
-- File       : gcm_pkg.vhd
-- Author     : Bill MacDowell  <bill@bill-macdowell-laptop>
-- Company    : 
-- Created    : 2017-03-20
-- Last update: 2017-04-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: A Package file containing common constants, functions, and
-- types used throughout this project.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-20  1.0      bill	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package gcm_pkg is
  
  -- A matrix of bytes commonly used in the AES cipher for transformations of
  -- 128-bit blocks
  type t_matrix is array (15 downto 0) of std_logic_vector(7 downto 0);

  -- m(x) = x^8 + x^4 + x^3 + x + 1
  -- Can be subtracted (XOR'ed in the finite field) from the result of x*b(x)
  -- to reduce the resulting polynomial by modulo m(x)
  constant c_irreducible_polynomial : std_logic_vector := x"1b";
  
  -- Functions to convert back and fourth between vectors and matricies
  function vector_to_matrix (in_vec : std_logic_vector) return t_matrix;
  function matrix_to_vector (in_matrix : t_matrix) return std_logic_vector;
  
end package gcm_pkg;

package body gcm_pkg is

  -- These two functions just perform the conversion of types (between
  -- vector and matrix). It won't result in any actual logic, but is necessary
  -- to satisfy VHDL's strong typing requirements
  function vector_to_matrix(in_vec : std_logic_vector) return t_matrix is
    variable out_matrix: t_matrix;
    begin
      for byte_idx in 15 downto 0 loop
        out_matrix(15-byte_idx) := in_vec(8*byte_idx+7 downto 8*byte_idx);
      end loop;
      return out_matrix;
    end function;

  function matrix_to_vector(in_matrix : t_matrix) return std_logic_vector is
    variable out_vector : std_logic_vector(127 downto 0);
    begin
      for byte_idx in 15 downto 0 loop
        out_vector(8*byte_idx+7 downto 8*byte_idx) := in_matrix(15-byte_idx);
      end loop;
      return out_vector;
    end function;
    
end package body gcm_pkg;

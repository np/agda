-- {-# OPTIONS --sized-types #-} Option obsolete since 2014-04-12.

module SizedTypesLeqInfty where

postulate
  Size : Set
  _^   : Size -> Size
  ∞    : Size

{-# BUILTIN SIZE Size  #-}
{-# BUILTIN SIZESUC _^ #-}
{-# BUILTIN SIZEINF ∞  #-}

data Nat : {size : Size} -> Set where
  zero : {size : Size} -> Nat {size ^}
  suc  : {size : Size} -> Nat {size} -> Nat {size ^}

weak : {i : Size} -> Nat {i} -> Nat {∞}
weak x = x

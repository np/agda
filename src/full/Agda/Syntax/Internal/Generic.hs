{-# OPTIONS_GHC -fwarn-missing-signatures #-}

{-# LANGUAGE CPP                  #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE TypeSynonymInstances #-}

module Agda.Syntax.Internal.Generic where

import Control.Applicative
import Data.Traversable
import Data.Monoid
import Data.Foldable
import Agda.Syntax.Internal

import Agda.Utils.Impossible
#include "undefined.h"

class TermLike a where
  traverseTerm  :: (Term -> Term) -> a -> a
  traverseTermM :: (Monad m, Applicative m) => (Term -> m Term) -> a -> m a
  foldTerm      :: Monoid m => (Term -> m) -> a -> m

-- * Constants

instance TermLike Bool where
  traverseTerm  _ = id
  traverseTermM _ = pure
  foldTerm _      = mempty

instance TermLike Int where
  traverseTerm  _ = id
  traverseTermM _ = pure
  foldTerm _      = mempty

instance TermLike Integer where
  traverseTerm  _ = id
  traverseTermM _ = pure
  foldTerm _      = mempty

instance TermLike Char where
  traverseTerm  _ = id
  traverseTermM _ = pure
  foldTerm _      = mempty

instance TermLike QName where
  traverseTerm  _ = id
  traverseTermM _ = pure
  foldTerm _      = mempty

-- * Functors

instance TermLike a => TermLike (Elim' a) where
  traverseTerm  f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

instance TermLike a => TermLike (Arg a) where
  traverseTerm  f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

instance TermLike a => TermLike (Dom a) where
  traverseTerm  f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

instance TermLike a => TermLike [a] where
  traverseTerm f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

instance TermLike a => TermLike (Maybe a) where
  traverseTerm f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

instance (TermLike a, TermLike b) => TermLike (a, b) where
  traverseTerm f (x, y) = (traverseTerm f x, traverseTerm f y)
  traverseTermM f (x, y) = (,) <$> traverseTermM f x <*> traverseTermM f y
  foldTerm f (x, y) = foldTerm f x `mappend` foldTerm f y

instance (TermLike a, TermLike b, TermLike c) => TermLike (a, b, c) where
  traverseTerm f (x, y, z) = (traverseTerm f x, traverseTerm f y, traverseTerm f z)
  traverseTermM f (x, y, z) = (,,) <$> traverseTermM f x <*> traverseTermM f y <*> traverseTermM f z
  foldTerm f (x, y, z) = mconcat [foldTerm f x, foldTerm f y, foldTerm f z]

instance (TermLike a, TermLike b, TermLike c, TermLike d) => TermLike (a, b, c, d) where
  traverseTerm f (x, y, z, u) = (traverseTerm f x, traverseTerm f y, traverseTerm f z, traverseTerm f u)
  traverseTermM f (x, y, z, u) = (,,,) <$> traverseTermM f x <*> traverseTermM f y <*> traverseTermM f z <*> traverseTermM f u
  foldTerm f (x, y, z, u) = mconcat [foldTerm f x, foldTerm f y, foldTerm f z, foldTerm f u]

instance TermLike a => TermLike (Abs a) where
  traverseTerm f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

instance TermLike a => TermLike (Ptr a) where
  traverseTerm f = fmap (traverseTerm f)
  traverseTermM f = traverse (traverseTermM f)
  foldTerm f = foldMap (foldTerm f)

-- * Real terms

instance TermLike Term where
  traverseTerm f t = case t of
    Var i xs    -> f $ Var i $ traverseTerm f xs
    Def c xs    -> f $ Def c $ traverseTerm f xs
    Con c xs    -> f $ Con c $ traverseTerm f xs
    Lam h b     -> f $ Lam h $ traverseTerm f b
    Pi a b      -> f $ uncurry Pi $ traverseTerm f (a, b)
    MetaV m xs  -> f $ MetaV m $ traverseTerm f xs
    Level l     -> f $ Level $ traverseTerm f l
    Lit _       -> f t
    Sort _      -> f t
    DontCare mv -> f $ DontCare $ traverseTerm f mv
    Shared p    -> f $ Shared $ traverseTerm f p
    ExtLam{}    -> __IMPOSSIBLE__

  traverseTermM f t = case t of
    Var i xs    -> f =<< Var i <$> traverseTermM f xs
    Def c xs    -> f =<< Def c <$> traverseTermM f xs
    Con c xs    -> f =<< Con c <$> traverseTermM f xs
    Lam h b     -> f =<< Lam h <$> traverseTermM f b
    Pi a b      -> f =<< uncurry Pi <$> traverseTermM f (a, b)
    MetaV m xs  -> f =<< MetaV m <$> traverseTermM f xs
    Level l     -> f =<< Level <$> traverseTermM f l
    Lit _       -> f t
    Sort _      -> f t
    DontCare mv -> f =<< DontCare <$> traverseTermM f mv
    Shared p    -> f =<< Shared <$> traverseTermM f p
    ExtLam{}    -> __IMPOSSIBLE__

  foldTerm f t = f t `mappend` case t of
    Var i xs    -> foldTerm f xs
    Def c xs    -> foldTerm f xs
    Con c xs    -> foldTerm f xs
    Lam h b     -> foldTerm f b
    Pi a b      -> foldTerm f (a, b)
    MetaV m xs  -> foldTerm f xs
    Level l     -> foldTerm f l
    Lit _       -> mempty
    Sort _      -> mempty
    DontCare mv -> foldTerm f mv
    Shared p    -> foldTerm f p
    ExtLam{}    -> __IMPOSSIBLE__

instance TermLike Level where
  traverseTerm f  (Max as) = Max $ traverseTerm f as
  traverseTermM f (Max as) = Max <$> traverseTermM f as
  foldTerm f      (Max as) = foldTerm f as

instance TermLike PlusLevel where
  traverseTerm f l = case l of
    ClosedLevel{} -> l
    Plus n l      -> Plus n $ traverseTerm f l
  traverseTermM f l = case l of
    ClosedLevel{} -> return l
    Plus n l      -> Plus n <$> traverseTermM f l
  foldTerm f ClosedLevel{} = mempty
  foldTerm f (Plus _ l)    = foldTerm f l

instance TermLike LevelAtom where
  traverseTerm f l = case l of
    MetaLevel m vs   -> MetaLevel m $ traverseTerm f vs
    NeutralLevel v   -> NeutralLevel $ traverseTerm f v
    BlockedLevel m v -> BlockedLevel m $ traverseTerm f v
    UnreducedLevel v -> UnreducedLevel $ traverseTerm f v
  traverseTermM f l = case l of
    MetaLevel m vs   -> MetaLevel m <$> traverseTermM f vs
    NeutralLevel v   -> NeutralLevel <$> traverseTermM f v
    BlockedLevel m v -> BlockedLevel m <$> traverseTermM f v
    UnreducedLevel v -> UnreducedLevel <$> traverseTermM f v
  foldTerm f l = case l of
    MetaLevel m vs   -> foldTerm f vs
    NeutralLevel v   -> foldTerm f v
    BlockedLevel _ v -> foldTerm f v
    UnreducedLevel v -> foldTerm f v

instance TermLike Type where
  traverseTerm f (El s t) = El s $ traverseTerm f t
  traverseTermM f (El s t) = El s <$> traverseTermM f t
  foldTerm f (El s t) = foldTerm f t

-- | Put it in a monad to make it possible to do strictly.
copyTerm :: (TermLike a, Applicative m, Monad m) => a -> m a
copyTerm = traverseTermM return

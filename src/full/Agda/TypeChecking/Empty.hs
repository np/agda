{-# OPTIONS_GHC -fwarn-missing-signatures #-}

-- {-# LANGUAGE CPP #-}

module Agda.TypeChecking.Empty where

import Control.Applicative
import Control.Monad

import Agda.Syntax.Common
import Agda.Syntax.Internal
import Agda.Syntax.Position

import Agda.TypeChecking.Monad
import Agda.TypeChecking.Coverage
import Agda.TypeChecking.Constraints
import Agda.TypeChecking.Reduce
import Agda.TypeChecking.Substitute

{- UNUSED
-- | Make sure that a type is empty.
isReallyEmptyType :: Range -> Type -> TCM ()
isReallyEmptyType r t = noConstraints $ isEmptyType r t
-}

-- | Check whether a type is empty.  Maybe postponed as emptyness constraint.
isEmptyType :: Range -> Type -> TCM ()
isEmptyType r t = do
  tb <- reduceB t
  let t = ignoreBlocking tb
      postpone = addConstraint (IsEmpty r t)
  case ignoreSharing . unEl <$> tb of
    -- if t is blocked or a meta, we cannot decide emptyness now. postpone
    NotBlocked MetaV{} -> postpone
    Blocked{}          -> postpone
    _                  -> do
    -- from the current context xs:ts, create a pattern list
    -- xs _ : ts t and try to split on _ (the last variable)
      tel0 <- getContextTelescope
      let gamma = telToList tel0 ++ [domFromArg $ defaultArg (underscore, t)]
          ps    = [ Arg info $ namedVarP x | Dom info (x, _) <- gamma ]
          tel   = telFromList gamma

      dontAssignMetas $ do
      r <- splitLast Inductive tel ps

      case r of
        Left err  -> case err of
          CantSplit c tel us vs _ -> postpone
          -- Andreas, 2012-03-15: allow postponement of emptyness check
          -- OLD CODE: traceCall (CheckIsEmpty t) $ typeError $ CoverageCantSplitOn c tel us vs
          _                       -> typeError $ ShouldBeEmpty t []
        Right cov -> do
          let cs = splitClauses cov
          unless (null cs) $
            typeError $ ShouldBeEmpty t $ map (namedArg . last . scPats) $ cs

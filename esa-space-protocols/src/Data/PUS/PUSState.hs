{-# LANGUAGE OverloadedStrings
    , TemplateHaskell
    , NoImplicitPrelude
    , BangPatterns
#-}
module Data.PUS.PUSState
  ( PUSState (..)
  , defaultPUSState
  , newState
  , nextADCnt
  )
where

import           RIO

import           Control.Lens                   ( makeLenses )



-- | This is the internal state of the PUS library.
data PUSState = PUSState {
    _pusStADCounter :: !Word8
}

makeLenses ''PUSState



newState :: Monad m => m PUSState
newState = do
  let state =
        PUSState { _pusStADCounter = 0 }
  pure state


defaultPUSState :: Monad m => m PUSState
defaultPUSState = do
  let state =
        PUSState { _pusStADCounter = 0 }
  pure state



nextADCnt :: PUSState -> (PUSState, Word8)
nextADCnt st =
  let cnt    = st ^. pusStADCounter
      !newSt = over pusStADCounter (+ 1) st
  in  (newSt, cnt)

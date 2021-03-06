{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE ScopedTypeVariables #-}

module FTL where

import           Control.Monad
import qualified Data.Map      as Map
import qualified Data.Set      as Set
import           Hydra.Prelude

import qualified Hydra.Domain  as D
import qualified Hydra.FTL     as FTL
import qualified Hydra.Runtime as R
import           Types

import           Hydra.FTLI    ()

getRandomMeteor :: FTL.RandomL m => m Meteor
getRandomMeteor = Meteor <$> FTL.getRandomInt (1, 100)

getRandomRegion :: FTL.RandomL m => m Region
getRandomRegion = toRegion <$> FTL.getRandomInt (1, 4)
  where
    toRegion 1 = NorthWest
    toRegion 2 = NorthEast
    toRegion 3 = SouthWest
    toRegion _ = SouthEast

createMeteor :: FTL.LangL m => m (Meteor, Region)
createMeteor = do
  meteor <- getRandomMeteor
  region <- getRandomRegion
  pure (meteor, region)

meteorStorm :: FTL.LangL m => m ()
meteorStorm = do
  (meteor, region) <- createMeteor
  FTL.logInfo $ "[MS] " <> " a new meteor appeared at " <> show region <> ": " <> show meteor

-- Tail-rec
meteorStormRec :: FTL.LangL m => Int -> m ()
meteorStormRec 0 = pure ()
meteorStormRec n = do
  meteorStorm
  meteorStormRec (n - 1)

-- Not tail-rec
meteorStormRec2 :: FTL.LangL m => Int -> m ()
meteorStormRec2 0 = pure ()
meteorStormRec2 n = do
  meteorStormRec2 (n - 1)
  meteorStorm

scenario1, scenario2, scenario3 :: Int -> R.CoreRuntime -> IO ()
scenario1 ops coreRt = void $ runReaderT (meteorStormRec ops) coreRt
scenario2 ops coreRt = void $ runReaderT (meteorStormRec2 ops) coreRt
scenario3 ops coreRt = void $ runReaderT actions coreRt
  where
    actions = replicateM ops meteorStorm

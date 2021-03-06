{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Free where

import           Control.Monad
import qualified Data.Map       as Map
import qualified Data.Set       as Set
import           Hydra.Prelude

import qualified Hydra.Domain   as D
import qualified Hydra.Language as L
import qualified Hydra.Runtime  as R
import           Types


getRandomMeteor :: L.RandomL Meteor
getRandomMeteor = Meteor <$> L.getRandomInt (1, 100)

getRandomRegion :: L.RandomL Region
getRandomRegion = toRegion <$> L.getRandomInt (1, 4)
  where
    toRegion 1 = NorthWest
    toRegion 2 = NorthEast
    toRegion 3 = SouthWest
    toRegion _ = SouthEast

createMeteor :: L.LangL (Meteor, Region)
createMeteor = do
  meteor <- L.evalRandom getRandomMeteor
  region <- L.evalRandom getRandomRegion
  pure (meteor, region)

meteorStorm :: L.AppL ()
meteorStorm = do
  (meteor, region) <- L.scenario createMeteor
  L.logInfo $ "[MS] " <> " a new meteor appeared at " <> show region <> ": " <> show meteor

-- Tail-rec
meteorStormRec :: Int -> L.AppL ()
meteorStormRec 0 = pure ()
meteorStormRec n = do
  meteorStorm
  meteorStormRec (n - 1)

-- Not tail-rec
meteorStormRec2 :: Int -> L.AppL ()
meteorStormRec2 0 = pure ()
meteorStormRec2 n = do
  meteorStormRec2 (n - 1)
  meteorStorm

scenario1, scenario2, scenario3 :: Int -> R.AppRuntime -> IO ()
scenario1 ops appRt = void $ R.startApp appRt (meteorStormRec ops)
scenario2 ops appRt = void $ R.startApp appRt (meteorStormRec2 ops)
scenario3 ops appRt = void $ R.startApp appRt actions
  where
    actions = replicateM ops meteorStorm

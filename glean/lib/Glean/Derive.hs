-- Copyright (c) Facebook, Inc. and its affiliates.

module Glean.Derive
  ( derivePredicate
  ) where

import Control.Concurrent
import Data.Default
import Data.Int
import qualified Data.Text as Text

import Glean.Angle.Types
import Glean.Query.Thrift.Internal
import Glean.Types
import Glean hiding (derivePredicate)
import Glean.Schema.Util (showSourceRef)
import Util.Log

-- | Compute and store the specified derived predicate
derivePredicate
  :: Glean.Backend b
  => b
  -> Repo
  -> Maybe Int64  -- ^ page size (bytes)
  -> Maybe Int64  -- ^ page size (results)
  -> SourceRef    -- ^ predicate to derive
  -> IO ()

derivePredicate backend repo maxBytes maxResults s = loop
  where
    loop = do
      result <- Glean.deriveStored backend (const mempty) repo query
      case result of
        DerivationStatus_complete{} -> reportComplete
        DerivationStatus_ongoing x -> do
          reportProgress $ derivationOngoing_stats x
          retry loop

    query = def
      { derivePredicateQuery_predicate = name
      , derivePredicateQuery_predicate_version = version
      , derivePredicateQuery_options = Just def
        { derivePredicateOptions_max_results_per_query = maxResults
        , derivePredicateOptions_max_bytes_per_query = maxBytes
        }
      }

    SourceRef name version = s

    predicate = unwords [Glean.showRepo repo, Text.unpack $ showSourceRef s]

    reportComplete = vlog 1 $ unwords
      ["derivation complete:", predicate]

    reportProgress stats = do
      putStrLn $ unwords
        [ Text.unpack $ showSourceRef s
        , ":"
        , show $ userQueryStats_num_facts stats
        , "facts"
        ]
      vlog 1 $ unwords
        ["derivation progress:", predicate, showUserQueryStats stats]

    retry :: IO a -> IO a
    retry action = do
      let sec = 1000000
      threadDelay $ 1 * sec
      action


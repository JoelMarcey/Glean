module Glean.Regression.Driver.DeriveDeclByName (main) where

import Derive.Types (DerivePass(..))
import Glean.Clang.Test.DerivePass (driver)
import Glean.Regression.Test (testMain)

main :: IO ()
main = testMain $ driver [DeriveGeneric "cxx1.DeclByName"]

module Test.Main where

import Prelude

import Effect (Effect)
import Test.HTTPure.Contrib.Biscotti.SessionManagerTest as SessionManagerTest
import Test.Unit.Main (runTest)

main :: Effect Unit
main = runTest do
  SessionManagerTest.testSuite

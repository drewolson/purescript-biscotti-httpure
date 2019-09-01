module Test.Main where

import Prelude

import Effect (Effect)
import Test.Biscotti.HTTPureTest as HTTPureTest
import Test.Unit.Main (runTest)

main :: Effect Unit
main = runTest do
  HTTPureTest.testSuite

module Test.Main where

import Prelude

import Effect (Effect)
import Test.HTTPure.BiscottiTest as BiscottiTest
import Test.Unit.Main (runTest)

main :: Effect Unit
main = runTest do
  BiscottiTest.testSuite

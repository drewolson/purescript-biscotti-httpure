module Test.HTTPure.Contrib.Biscotti.SessionContainerTest
  ( testSuite
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import HTTPure.Contrib.Biscotti.SessionContainer as SessionContainer
import Test.Unit (TestSuite, suite, test)
import Test.Unit.Assert (shouldEqual)

testSuite :: TestSuite
testSuite = do
  suite "HTTPure.Contrib.Biscotti.SessionContainer" do
    suite "getSession" do
      test "works with the appropriate record" do
        let result = SessionContainer.getSession { session: Just 1 }

        result `shouldEqual` Just 1

    suite "setSession" do
      test "works with the appropriate record" do
        let result = SessionContainer.setSession (Just 1) { session: Nothing }

        result `shouldEqual` { session: Just 1 }

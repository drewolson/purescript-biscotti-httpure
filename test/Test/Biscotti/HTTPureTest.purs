module Test.Biscotti.HTTPureTest
  ( testSuite
  ) where

import Prelude

import Biscotti.Cookie (Cookie)
import Biscotti.Cookie as Cookie
import Biscotti.HTTPure as Biscotti.HTTPure
import Biscotti.Session (SessionStore)
import Biscotti.Session as Session
import Data.Argonaut (class DecodeJson)
import Data.Either (Either(..), fromRight)
import Data.Maybe (fromJust)
import Effect.Aff.Class (class MonadAff)
import Foreign.Object as Object
import HTTPure as HTTPure
import HTTPure.Headers as Headers
import HTTPure.Lookup as Lookup
import HTTPure.Method as Method
import HTTPure.Status as Status
import HTTPure.Version (Version(..))
import Partial.Unsafe (unsafePartial)
import Test.Unit (TestSuite, suite, test)
import Test.Unit.Assert (shouldEqual)

mockResponse :: HTTPure.Response
mockResponse =
  { status: Status.ok
  , headers: Headers.empty
  , writeBody: const $ pure unit
  }

mockRequest :: Cookie -> HTTPure.Request
mockRequest cookie =
  { method: Method.Get
  , path: ["/"]
  , query: Object.empty
  , headers: Headers.header "Cookie" (Cookie.stringify cookie)
  , body: ""
  , httpVersion: HTTP2_0
  }

responseCookie :: HTTPure.Response -> Cookie
responseCookie { headers } =
  let cookieString = unsafePartial $ fromJust $ Lookup.lookup headers "Set-Cookie"
   in unsafePartial $ fromRight $ Cookie.parse cookieString

responseSession :: forall m a. MonadAff m => DecodeJson a => SessionStore m a -> HTTPure.Response -> m a
responseSession store response =
   unsafePartial $ fromRight <$> Session.get store (responseCookie response)

testSuite :: TestSuite
testSuite = do
  suite "Biscotti.HTTPure" do
    suite "createSession" do
      test "creates a session cookie" do
        store <- Session.memoryStore "_my_app"
        response <- unsafePartial $ fromRight <$> Biscotti.HTTPure.createSession store { message: "hello" } mockResponse
        session <- responseSession store response

        session `shouldEqual` { message: "hello" }

    suite "destroySession" do
      test "destroys the sesion and sets an empty cookie" do
        store <- Session.memoryStore "_my_app"
        cookie <- unsafePartial $ fromRight <$> Session.create store { message: "hello" }
        response <- unsafePartial $ fromRight <$> Biscotti.HTTPure.destroySession store (mockRequest cookie) mockResponse
        let cookie' = responseCookie response

        cookie' `shouldEqual` Cookie.empty

        found <- Session.get store cookie

        found `shouldEqual` Left "session not found"

    suite "getSession" do
      test "retrieves the session" do
        store <- Session.memoryStore "_my_app"
        cookie <- unsafePartial $ fromRight <$> Session.create store { message: "hello" }
        let request = mockRequest cookie
        session <- unsafePartial $ fromRight <$> Biscotti.HTTPure.getSession store request

        session `shouldEqual` { message: "hello" }

    suite "setSession" do
      test "sets a session with new data" do
        store <- Session.memoryStore "_my_app"
        cookie <- unsafePartial $ fromRight <$> Session.create store { message: "hello" }
        let request = mockRequest cookie
        response <- unsafePartial $ fromRight <$> Biscotti.HTTPure.setSession store { message: "goodbye" } request mockResponse

        session <- responseSession store response

        session `shouldEqual` { message: "goodbye" }

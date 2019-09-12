module Test.HTTPure.Contrib.Biscotti.SessionManagerTest
  ( testSuite
  ) where

import Prelude

import Biscotti.Cookie as Cookie
import Biscotti.Cookie.Types (Cookie(..))
import Biscotti.Session (SessionStore)
import Biscotti.Session as Session
import Data.Argonaut (class DecodeJson)
import Data.Either (Either(..), fromRight)
import Data.Maybe (Maybe(..), fromJust)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Foreign.Object as Object
import HTTPure as HTTPure
import HTTPure.Contrib.Biscotti.SessionManager as SessionManager
import HTTPure.Headers as Headers
import HTTPure.Lookup as Lookup
import HTTPure.Method as Method
import HTTPure.Status as Status
import HTTPure.Version (Version(..))
import Partial.Unsafe (unsafePartial)
import Test.Unit (TestSuite, suite, test)
import Test.Unit.Assert (assert, shouldEqual)

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

responseSession :: forall m a. MonadAff m => DecodeJson a => SessionStore a -> HTTPure.Response -> m a
responseSession store response = do
  result <- liftAff $ Session.get store (responseCookie response)

  pure $ unsafePartial $ fromRight $ result

testSuite :: TestSuite
testSuite = do
  suite "HTTPure.Contrib.Biscotti.SessionManager" do
    suite "createSession" do
      test "creates a session cookie" do
        store <- liftEffect $ Session.memoryStore "_my_app"
        response <- unsafePartial $ fromRight <$> SessionManager.createSession store { message: "hello" } mockResponse
        session <- responseSession store response

        session `shouldEqual` { message: "hello" }

    suite "destroySession" do
      test "destroys the sesion and sets an expired cookie" do
        store <- liftEffect $ Session.memoryStore "_my_app"
        cookie <- unsafePartial $ fromRight <$> Session.create store { message: "hello" }
        response <- unsafePartial $ fromRight <$> SessionManager.destroySession "_my_app" store (mockRequest cookie) mockResponse
        let Cookie { expires } = responseCookie response

        assert "expected an expires date" $ expires /= Nothing

        found <- Session.get store cookie

        found `shouldEqual` Left "session not found"

    suite "getSession" do
      test "retrieves the session" do
        store <- liftEffect $ Session.memoryStore "_my_app"
        cookie <- unsafePartial $ fromRight <$> Session.create store { message: "hello" }
        let request = mockRequest cookie
        session <- unsafePartial $ fromRight <$> SessionManager.getSession "_my_app" store request

        session `shouldEqual` { message: "hello" }

    suite "setSession" do
      test "sets a session with new data" do
        store <- liftEffect $ Session.memoryStore "_my_app"
        cookie <- unsafePartial $ fromRight <$> Session.create store { message: "hello" }
        let request = mockRequest cookie
        response <- unsafePartial $ fromRight <$> SessionManager.setSession "_my_app" store { message: "goodbye" } request mockResponse

        session <- responseSession store response

        session `shouldEqual` { message: "goodbye" }

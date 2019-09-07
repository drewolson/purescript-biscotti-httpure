module Test.HTTPure.Contrib.Biscotti.MiddlewareTest
  ( testSuite
  ) where

import Prelude

import Biscotti.Cookie (Cookie)
import Biscotti.Cookie as Cookie
import Biscotti.Session (SessionStore)
import Biscotti.Session as Session
import Data.Either (Either(..), fromRight)
import Data.Maybe (Maybe(..), fromJust)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Foreign.Object as Object
import HTTPure as HTTPure
import HTTPure.Contrib.Biscotti.Middleware as Middleware
import HTTPure.Lookup as Lookup
import HTTPure.Version as Version
import Partial.Unsafe (unsafePartial)
import Test.Unit (TestSuite, suite, test)
import Test.Unit.Assert (shouldEqual)

type Session = { currentUser :: String }

mockRequest :: Maybe Cookie -> HTTPure.Method -> HTTPure.Path -> HTTPure.Request
mockRequest maybeCookie method path =
  { method
  , path
  , query: Object.empty
  , headers
  , body: ""
  , httpVersion: Version.HTTP2_0
  }
  where
    headers :: HTTPure.Headers
    headers =
      case maybeCookie of
        Nothing ->
          HTTPure.empty

        Just cookie ->
          HTTPure.header "Cookie" (Cookie.stringify cookie)

makeRouter :: SessionStore Session -> HTTPure.Request -> HTTPure.ResponseM
makeRouter store = Middleware.new store router
  where
    router :: Maybe Session -> HTTPure.Request -> Aff (Tuple HTTPure.Response (Maybe Session))
    router session req = do
      case req of
        { path: ["login"] } -> do
          response <- HTTPure.ok "login"
          pure $ Tuple response (Just { currentUser: "Drew" })

        { path: ["logout"] } -> do
          response <- HTTPure.ok "logout"
          pure $ Tuple response Nothing

        _ -> do
          response <- HTTPure.ok "hello"
          pure $ Tuple response session

testSuite :: TestSuite
testSuite = do
  suite "HTTPure.Contrib.Biscotti.Middleware" do
    suite "new" do
      test "login creates a session" do
        store <- liftEffect $ Session.memoryStore "_test"
        let router = makeRouter store
        let reqCookie = Nothing
        let request = mockRequest reqCookie HTTPure.Get ["login"]

        response <- router request

        let cookieHeader = unsafePartial $ fromJust $ Lookup.lookup response.headers "Set-Cookie"
        let cookie = unsafePartial $ fromRight $ Cookie.parse cookieHeader
        session <- Session.get store cookie

        session `shouldEqual` Right { currentUser: "Drew" }

      test "logout destroys the session" do
        store <- liftEffect $ Session.memoryStore "_test"
        reqCookie <- unsafePartial $ fromRight <$> Session.create store { currentUser: "Drew" }
        let router = makeRouter store
        let request = mockRequest (Just reqCookie) HTTPure.Get ["logout"]

        response <- router request

        let cookieHeader = unsafePartial $ fromJust $ Lookup.lookup response.headers "Set-Cookie"
        let cookie = unsafePartial $ fromRight $ Cookie.parse cookieHeader
        session <- Session.get store cookie

        session `shouldEqual` Left "session not found"

module HTTPure.Biscotti
  ( createSession
  , destroySession
  , getSession
  , setSession
  ) where

import Prelude

import Biscotti.Cookie (Cookie)
import Biscotti.Cookie as Cookie
import Biscotti.Session as Session
import Biscotti.Session.Store (SessionStore)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Data.Bifunctor (lmap)
import Data.Either (Either(..), note)
import Data.Lens (Lens', lens)
import Data.Lens as Lens
import Data.Lens.At (at)
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Maybe (Maybe)
import Data.String.CaseInsensitive (CaseInsensitiveString(..))
import Effect.Aff.Class (class MonadAff)
import HTTPure (Headers)
import HTTPure as HTTPure

createSession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore m a
  -> a
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
createSession store session response = do
  result <- Session.create store session

  pure $ setSessionCookie response <$> result

destroySession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore m a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
destroySession store request response =
  case getSessionCookie request of
    Left e ->
      pure $ Left e

    Right cookie -> do
      cookie' <- Session.destroy store cookie
      pure $ setSessionCookie response <$> cookie'

getSession
  :: forall m a
   . MonadAff m
  => DecodeJson a
  => SessionStore m a
  -> HTTPure.Request
  -> m (Either String a)
getSession store request =
  case getSessionCookie request of
    Left a ->
      pure $ Left a

    Right cookie ->
      Session.get store cookie

setSession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore m a
  -> a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
setSession store session request response =
  case getSessionCookie request of
    Left e ->
      pure $ Left e

    Right cookie -> do
      cookie' <- Session.set store session cookie
      pure $ setSessionCookie response <$> cookie'

requestCookieTag :: String
requestCookieTag = "Cookie"

responseCookieTag :: String
responseCookieTag = "Set-Cookie"

setSessionCookie :: HTTPure.Response -> Cookie -> HTTPure.Response
setSessionCookie response cookie =
  Lens.setJust (_headers <<< _Newtype <<< at (CaseInsensitiveString responseCookieTag)) (Cookie.stringify cookie) response

getSessionCookie :: HTTPure.Request -> Either String Cookie
getSessionCookie request = do
  cookie <- note "cookie not found" $ findCookie request
  lmap show $ Cookie.parse cookie
  where
    findCookie :: HTTPure.Request -> Maybe String
    findCookie = Lens.view (_headers <<< _Newtype <<< at (CaseInsensitiveString requestCookieTag))

_headers :: forall r. Lens' { headers :: Headers | r } Headers
_headers = lens _.headers $ _ { headers = _ }

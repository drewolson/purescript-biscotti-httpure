module HTTPure.Contrib.Biscotti.SessionManager
  ( createSession
  , createSession'
  , destroySession
  , getSession
  , setSession
  , setSession'
  ) where

import Prelude

import Biscotti.Cookie (Cookie)
import Biscotti.Cookie as Cookie
import Biscotti.Session as Session
import Biscotti.Session.Store (SessionStore)
import Control.Monad.Except (ExceptT(..), except, runExceptT)
import Control.Monad.Trans.Class (lift)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Data.Bifunctor (lmap)
import Data.Either (Either, note)
import Data.Lens (Lens', lens)
import Data.Lens as Lens
import Data.Lens.At (at)
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Maybe (Maybe)
import Data.String.CaseInsensitive (CaseInsensitiveString(..))
import Effect.Aff.Class (class MonadAff, liftAff)
import HTTPure (Headers)
import HTTPure as HTTPure

createSession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore a
  -> a
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
createSession store = createSession' store pure

createSession'
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore a
  -> (Cookie -> m Cookie)
  -> a
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
createSession' store cookieUpdater session response = runExceptT do
  cookie <- ExceptT $ liftAff $ Session.create store session
  cookie' <- lift $ cookieUpdater cookie

  pure $ setSessionCookie response cookie'

destroySession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
destroySession store request response = runExceptT do
  cookie <- except $ getSessionCookie request
  cookie' <- ExceptT $ liftAff $ Session.destroy store cookie

  pure $ setSessionCookie response cookie'

getSession
  :: forall m a
   . MonadAff m
  => DecodeJson a
  => SessionStore a
  -> HTTPure.Request
  -> m (Either String a)
getSession store request = runExceptT do
  cookie <- except $ getSessionCookie request

  ExceptT $ liftAff $ Session.get store cookie

setSession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore a
  -> a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
setSession store = setSession' store pure

setSession'
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => SessionStore a
  -> (Cookie -> m Cookie)
  -> a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
setSession' store cookieUpdater session request response = runExceptT do
  cookie <- except $ getSessionCookie request
  cookie' <- ExceptT $ liftAff $ Session.set store session cookie
  cookie'' <- lift $ cookieUpdater cookie'

  pure $ setSessionCookie response cookie''

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

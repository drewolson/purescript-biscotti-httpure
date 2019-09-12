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
import Data.Array (find)
import Data.Bifunctor (lmap)
import Data.Either (Either, note)
import Data.Lens (Lens', lens)
import Data.Lens as Lens
import Data.Lens.At (at)
import Data.Lens.Iso.Newtype (_Newtype)
import Data.List (List)
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
  => String
  -> SessionStore a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
destroySession name store request response = runExceptT do
  cookie <- except $ getSessionCookie name request
  cookie' <- ExceptT $ liftAff $ Session.destroy store cookie

  pure $ setSessionCookie response cookie'

getSession
  :: forall m a
   . MonadAff m
  => DecodeJson a
  => String
  -> SessionStore a
  -> HTTPure.Request
  -> m (Either String a)
getSession name store request = runExceptT do
  cookie <- except $ getSessionCookie name request

  ExceptT $ liftAff $ Session.get store cookie

setSession
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => String
  -> SessionStore a
  -> a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
setSession name store = setSession' name store pure

setSession'
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => String
  -> SessionStore a
  -> (Cookie -> m Cookie)
  -> a
  -> HTTPure.Request
  -> HTTPure.Response
  -> m (Either String HTTPure.Response)
setSession' name store cookieUpdater session request response = runExceptT do
  cookie <- except $ getSessionCookie name request
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

getSessionCookie :: String -> HTTPure.Request -> Either String Cookie
getSessionCookie name request = do
  cookieHeader <- note "cookie header not found" $ findCookieHeader request
  cookies <- lmap show $ Cookie.parseMany cookieHeader

  findCookie cookies
  where
    findCookieHeader :: HTTPure.Request -> Maybe String
    findCookieHeader = Lens.view (_headers <<< _Newtype <<< at (CaseInsensitiveString requestCookieTag))

    findCookie :: List Cookie -> Either String Cookie
    findCookie = note "cookie not found" <<< find ((_ == name) <<< Cookie.getName)

_headers :: forall r. Lens' { headers :: Headers | r } Headers
_headers = lens _.headers $ _ { headers = _ }

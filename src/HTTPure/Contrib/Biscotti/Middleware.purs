module HTTPure.Contrib.Biscotti.Middleware
  ( CookieUpdater
  , ErrorHandler
  , SessionError(..)
  , defaultCookieUpdater
  , defaultErrorHandler
  , new
  , new'
  ) where

import Prelude

import Biscotti.Cookie (Cookie)
import Biscotti.Session.Store (SessionStore)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Data.Either (either, hush)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple)
import Data.Tuple.Nested ((/\))
import Effect.Aff.Class (class MonadAff, liftAff)
import HTTPure as HTTPure
import HTTPure.Contrib.Biscotti.SessionManager as SessionManager

data SessionError
  = CreateError String
  | DestroyError String
  | SetError String

derive instance genericSessionError :: Generic SessionError _

instance showSessionError :: Show SessionError where
  show :: SessionError -> String
  show = genericShow

type ErrorHandler m =
  HTTPure.Response -> SessionError -> m HTTPure.Response

type CookieUpdater m =
  Cookie -> m Cookie

new
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => DecodeJson a
  => String
  -> SessionStore a
  -> (Maybe a -> HTTPure.Request -> m (Tuple HTTPure.Response (Maybe a)))
  -> HTTPure.Request
  -> m HTTPure.Response
new name store = new' name store defaultErrorHandler defaultCookieUpdater

new'
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => DecodeJson a
  => String
  -> SessionStore a
  -> ErrorHandler m
  -> CookieUpdater m
  -> (Maybe a -> HTTPure.Request -> m (Tuple HTTPure.Response (Maybe a)))
  -> HTTPure.Request
  -> m HTTPure.Response
new' name store errorHandler cookieUpdater next req = do
  beforeSession <- hush <$> SessionManager.getSession name store req

  response /\ afterSession <- next beforeSession req

  case beforeSession, afterSession of
    Nothing, Nothing ->
      pure response

    Just _, Nothing -> do
      result <- SessionManager.destroySession name store req response

      either (errorHandler response <<< DestroyError) pure result

    Nothing, Just session -> do
      result <- SessionManager.createSession' store cookieUpdater session response

      either (errorHandler response <<< CreateError) pure result

    Just _, Just session -> do
      result <- SessionManager.setSession' name store cookieUpdater session req response

      either (errorHandler response <<< SetError) pure result

defaultCookieUpdater :: forall m. MonadAff m => CookieUpdater m
defaultCookieUpdater = pure

defaultErrorHandler :: forall m. MonadAff m => ErrorHandler m
defaultErrorHandler _ _ = liftAff $ HTTPure.internalServerError "error"

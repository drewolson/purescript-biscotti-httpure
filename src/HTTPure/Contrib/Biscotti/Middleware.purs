module HTTPure.Contrib.Biscotti.Middleware
  ( CookieUpdater
  , ErrorHandler
  , SessionError
  , new
  , new'
  ) where

import Prelude

import Biscotti.Cookie (Cookie)
import Biscotti.Session.Store (SessionStore)
import Control.Monad.State (class MonadState, gets, modify_)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Data.Either (either, hush)
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Effect.Aff.Class (class MonadAff, liftAff)
import HTTPure as HTTPure
import HTTPure.Contrib.Biscotti.SessionContainer (class SessionContainer)
import HTTPure.Contrib.Biscotti.SessionContainer as SessionContainer
import HTTPure.Contrib.Biscotti.SessionManager as SessionManager

data SessionError
  = CreateError String
  | DestroyError String
  | SetError String

type ErrorHandler m =
  HTTPure.Response -> SessionError -> m HTTPure.Response

type CookieUpdater m =
  Cookie -> m Cookie

new
  :: forall m a b
   . MonadAff m
  => MonadState a m
  => EncodeJson b
  => DecodeJson b
  => SessionContainer a b
  => SessionStore b
  -> (HTTPure.Request -> m HTTPure.Response)
  -> HTTPure.Request
  -> m HTTPure.Response
new store = new' store defaultErrorHandler defaultCookieUpdater
  where
    defaultErrorHandler :: ErrorHandler m
    defaultErrorHandler _ _ = liftAff $ HTTPure.internalServerError "error"

    defaultCookieUpdater :: CookieUpdater m
    defaultCookieUpdater = pure

new'
  :: forall m a b
   . MonadAff m
  => MonadState a m
  => EncodeJson b
  => DecodeJson b
  => SessionContainer a b
  => SessionStore b
  -> ErrorHandler m
  -> CookieUpdater m
  -> (HTTPure.Request -> m HTTPure.Response)
  -> HTTPure.Request
  -> m HTTPure.Response
new' store errorHandler cookieUpdater next req = do
  beforeSession <- hush <$> SessionManager.getSession store req
  modify_ $ SessionContainer.setSession beforeSession

  response <- next req

  afterSession <- gets $ SessionContainer.getSession

  case beforeSession /\ afterSession of
    Nothing /\ Nothing ->
      pure response

    Just _ /\ Nothing -> do
      result <- SessionManager.destroySession store req response

      either (errorHandler response <<< DestroyError) pure result

    Nothing /\ Just session -> do
      result <- SessionManager.createSession' store cookieUpdater session response

      either (errorHandler response <<< CreateError) pure result

    Just _ /\ Just session -> do
      result <- SessionManager.setSession' store cookieUpdater session req response

      either (errorHandler response <<< SetError) pure result

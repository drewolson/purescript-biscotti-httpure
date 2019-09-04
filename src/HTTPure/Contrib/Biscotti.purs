module HTTPure.Contrib.Biscotti
  ( module HTTPure.Contrib.Biscotti.SessionManager
  , module HTTPure.Contrib.Biscotti.SessionContainer
  , middleware
  , middleware'
  ) where

import Biscotti.Session (SessionStore)
import Control.Monad.State (class MonadState)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Effect.Aff.Class (class MonadAff)
import HTTPure as HTTPure
import HTTPure.Contrib.Biscotti.Middleware (ErrorHandler, CookieUpdater)
import HTTPure.Contrib.Biscotti.Middleware as Middleware
import HTTPure.Contrib.Biscotti.SessionContainer (class SessionContainer)
import HTTPure.Contrib.Biscotti.SessionManager (createSession, destroySession, getSession, setSession)

middleware
  :: forall m a b
   . MonadAff m
  => MonadState a m
  => EncodeJson b
  => DecodeJson b
  => SessionContainer a b
  => SessionStore m b
  -> (HTTPure.Request -> m HTTPure.Response)
  -> HTTPure.Request
  -> m HTTPure.Response
middleware = Middleware.new

middleware'
  :: forall m a b
   . MonadAff m
  => MonadState a m
  => EncodeJson b
  => DecodeJson b
  => SessionContainer a b
  => SessionStore m b
  -> ErrorHandler m
  -> CookieUpdater m
  -> (HTTPure.Request -> m HTTPure.Response)
  -> HTTPure.Request
  -> m HTTPure.Response
middleware' = Middleware.new'

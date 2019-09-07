module HTTPure.Contrib.Biscotti
  ( middleware
  , middleware'
  ) where

import Biscotti.Session (SessionStore)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Data.Maybe (Maybe)
import Data.Tuple (Tuple)
import Effect.Aff.Class (class MonadAff)
import HTTPure as HTTPure
import HTTPure.Contrib.Biscotti.Middleware (ErrorHandler, CookieUpdater)
import HTTPure.Contrib.Biscotti.Middleware as Middleware

middleware
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => DecodeJson a
  => SessionStore a
  -> (Maybe a -> HTTPure.Request -> m (Tuple HTTPure.Response (Maybe a)))
  -> HTTPure.Request
  -> m HTTPure.Response
middleware = Middleware.new

middleware'
  :: forall m a
   . MonadAff m
  => EncodeJson a
  => DecodeJson a
  => SessionStore a
  -> ErrorHandler m
  -> CookieUpdater m
  -> (Maybe a -> HTTPure.Request -> m (Tuple HTTPure.Response (Maybe a)))
  -> HTTPure.Request
  -> m HTTPure.Response
middleware' = Middleware.new'

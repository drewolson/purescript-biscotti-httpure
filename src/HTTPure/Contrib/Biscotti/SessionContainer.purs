module HTTPure.Contrib.Biscotti.SessionContainer
  ( class SessionContainer
  , getSession
  , setSession
  ) where

import Prelude

import Data.Maybe (Maybe)
import Type.Equality (class TypeEquals)
import Type.Equality as TE

class SessionContainer a b | a -> b where
  getSession :: a -> Maybe b

  setSession :: Maybe b -> a -> a

instance sessionContainerRecord :: TypeEquals t { session :: (Maybe a) | r } => SessionContainer t a where
  getSession :: t -> Maybe a
  getSession = _.session <<< TE.to

  setSession :: Maybe a -> t -> t
  setSession session = TE.from <<< _ { session = session } <<< TE.to

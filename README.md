# purescript-httpure-contrib-biscotti

Documentation is on
[Pursuit](https://pursuit.purescript.org/packages/purescript-httpure-contrib-biscotti).

This library provides a middleware that uses
[Biscotti.Cookie](https://github.com/drewolson/purescript-biscotti-cookie) and
[Biscotti.Session](https://github.com/drewolson/purescript-biscotti-session) to
add session handling to an
[HTTPure](https://github.com/cprussin/purescript-httpure) application. The
`Biscotti.middleware` function requires a session store and then behaves similar
to other `HTTPure` middleware.

Suppose the type of your session is:

```purescript
type Session = { currentUser :: String }
```

Note that _any_ type which implements `EncodeJson` and `DecodeJson` from
[Argonaut](https://github.com/purescript-contrib/purescript-argonaut) can be
used as your session type.

The primary difference from other middleware is that `Biscotti.middleware`
expects the next middleware in the stack to receive a `Maybe Session` along with the
`HTTPure.Request`.  It expects the return type to be an `MonadAff m => m (Tuple
HTTPure.Response (Maybe Session))` rather than just a `m HTTPure.Response`.

If you return `Nothing` for your `Session`, your session will be destroyed. If
you return a `Just Session`, your session will be created if it doesn't
currently exist, otherwise it will be updated.

Here's a small example application:

```purescript
import Biscotti.Session as Session
import HTTPure.Contrib.Biscotti as Biscotti

type Session = { currentUser :: String }

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

main :: Effect Unit
main = launchAff_ do
  let cookieName = "_test"
  store <- liftEffect $ Session.memoryStore cookieName
  let middleware = Biscotti.middleware cookieName store

  liftEffect $ HTTPure.server (middleware router) do
    log "Server running"
```

In a larger application, you may prefer to have another layer of middleware that
places the `Session` in a `StateT` to make it easier to access and modify within
your router.

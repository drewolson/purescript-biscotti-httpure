let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.13.3-20190831/packages.dhall sha256:852cd4b9e463258baf4e253e8524bcfe019124769472ca50b316fe93217c3a47

let overrides = {=}

let additions =
      { biscotti-cookie =
          { dependencies =
              [ "datetime"
              , "effect"
              , "either"
              , "foldable-traversable"
              , "formatters"
              , "gen"
              , "newtype"
              , "prelude"
              , "profunctor-lenses"
              , "psci-support"
              , "quickcheck"
              , "record"
              , "string-parsers"
              , "strings"
              , "test-unit"
              ]
          , repo =
              "https://github.com/drewolson/purescript-biscotti-cookie.git"
          , version =
              "7dde03494bf346440d2fd647a8fbd26078a05b82"
          }
      , biscotti-session =
          { dependencies =
              [ "aff"
              , "argonaut"
              , "biscotti-cookie"
              , "effect"
              , "newtype"
              , "ordered-collections"
              , "prelude"
              , "profunctor-lenses"
              , "psci-support"
              , "refs"
              , "test-unit"
              , "uuid"
              ]
          , repo =
              "https://github.com/drewolson/purescript-biscotti-session.git"
          , version =
              "3fbf33449127a786898554d0ea46c0cb19880d7f"
          }
      }

in  upstream // overrides // additions

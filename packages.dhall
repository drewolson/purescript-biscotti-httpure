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
              , "now"
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
              "fcd1fa9da245dfce36bcb9e790b6d6bcfa3843d0"
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
              "b9920c98e3054241892d155d39b3c2fef27d4d0b"
          }
      }

in  upstream // overrides // additions

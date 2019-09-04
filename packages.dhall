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
              "590a27bb601fa9d05d337e9e90b86dae325cfbc4"
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
              "538b5bd656235dcab50e87df86834724b9a7e16b"
          }
      }

in  upstream // overrides // additions

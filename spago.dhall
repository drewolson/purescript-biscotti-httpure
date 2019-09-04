{ name =
    "httpure-contrib-biscotti"
, dependencies =
    [ "aff"
    , "argonaut"
    , "biscotti-cookie"
    , "biscotti-session"
    , "effect"
    , "either"
    , "httpure"
    , "maybe"
    , "profunctor-lenses"
    , "psci-support"
    , "test-unit"
    , "tuples"
    , "type-equality"
    ]
, packages =
    ./packages.dhall
, sources =
    [ "src/**/*.purs", "test/**/*.purs" ]
}

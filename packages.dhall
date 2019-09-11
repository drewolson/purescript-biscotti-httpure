let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/f0109e1f1584dc7a93d446a1d99d1e5a08a899aa/src/packages.dhall sha256:38ef8e916a085413c2be52e9cfaf1e795d441f88c78cf960d7bb3de174dc70a9

let overrides = {=}

let additions = {=}

in  upstream // overrides // additions

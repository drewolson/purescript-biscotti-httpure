let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/d2388abb2dfcbaf7e0571b1a885e3e46688e0058/src/packages.dhall sha256:afca25aa0448e93aa6419da57ba03e85fd5f432f8d82e3c2a652ccb86e96a78e

let overrides = {=}

let additions = {=}

in  upstream // overrides // additions

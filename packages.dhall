let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/2dacd8208c3c910a330c7dab79d3add7b8bae802/src/packages.dhall sha256:37ff40bc9254f8df073d58733315ab88923f4a6d50bd18f52e634c70e6c5f675

let overrides = {=}

let additions = {=}

in  upstream // overrides // additions

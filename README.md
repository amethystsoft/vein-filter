
# VeinFilter
### What?
`VeinFilter` is an open-source back-port of the `FoundationEssentials.Predicate` and `FoundationMacros.Predicate`.

It's goals are to provide Predicate functionality starting at macOS v13 and iOS v14, because someone requested it for the [Amethyst Vein DB Framework](https://github.com/amethystsoft/vein.git).

### How?
It's based on the open-source [swift-foundation](https://github.com/swiftlang/swift-foundation.git). I copied the necessary files over, removed version constraints, renamed everything so it doesn't conflict with the real foundation and adjusted the implementation so it works with the older versions.

### How to use it?
Add it to your project via SwiftPM and use it like you would use a `#Predicate`, just that this one and it's internals are called `#Filter` and alike.

### Caveats
`VeinFilter` currently doesn't support all features the real predicate does. Missing are:
- `#Expression` and `Expression` as Vein doesn't need them and it would take additional effort to back-port (`repeat` and `each` keywords are used).
- `.filter()` and `PredicateExpressions.Filter` as Vein doesn't need them and it would take additional effort to back-port (`repeat` and `each` keywords are used).
- `StringContainsRegex` and the function as Vein (currently) doesn't need them and it would take additional effort to back-port (regex._literalPattern is only available starting macOS 15).

If you want to spend time and energy to support them, feel free to submit a PR.

---
Have fun with Predicates on a slightly older version lol

## Unreleased

- Add responsive component and state mixins, plus query and screen adapters,
  using parent width with optional tablet views.
- Resolve partial breakpoint overrides through components, nested scopes, and
  app configuration; install the app provider automatically in `AppModule.run`.
- **Breaking:** app configs and Flutter module/route/guard configuration type
  bounds now require `ResponsiveBreakpoints`. Existing configs can mix in
  `DefaultResponsiveBreakpoints` for 600/1024 logical-pixel defaults.

## 0.0.1

* TODO: Describe initial release.

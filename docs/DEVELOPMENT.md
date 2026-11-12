# Development

```bash
git clone https://github.com/Daaboulex/goxlr-hm-nix
cd goxlr-hm-nix
nix develop
nix fmt
nix flake check --no-build
```

`nix develop` enters the dev shell and installs the pre-commit hooks. `nix fmt`
formats the flake and the module. `nix flake check --no-build` evaluates the
checks without building them. This repository holds a module and no package.

## Checks

The flake declares one check of its own, `module-eval`. It instantiates the
Home Manager module with `programs.goxlr.enable = true`, so an error that only
shows once the module is enabled surfaces.

The formatter, the lint hooks and the dev shell come from the `std` input,
`github:Daaboulex/nix-packaging-standard`.

CI is [.github/workflows/ci.yml](../.github/workflows/ci.yml). It runs that
standard's package workflow on a push to the main branch and on a pull
request.

## Updating

This repository is original code. There is no upstream project, no upstream
license and nothing to track, which `.github/update.json` records as an
upstream of type `none`.

nixpkgs follows `nixos-unstable`.
[.github/workflows/maintenance.yml](../.github/workflows/maintenance.yml) runs
the standard's maintenance workflow on a schedule.

{
  description = "GoXLR Utility Home Manager module — declarative mixer configuration via goxlr-client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      homeManagerModules.default = import ./module.nix;
      homeManagerModules.goxlr = import ./module.nix;
    };
}

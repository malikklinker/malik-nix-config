{ inputs, pkgs, ... }:
let
  policy = import ../packages/user.nix { inherit inputs pkgs; };
in
{
  _module.args.userPkgs = policy.packages;
  home-manager.extraSpecialArgs.userPkgs = policy.packages;
}

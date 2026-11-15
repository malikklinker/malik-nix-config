{
  description = "NixOS configuration for Malik's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # User apps and development tools follow packages/user.nix; NixOS stays stable.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      codex-desktop-linux,
      ...
    }:
    {
      nixosConfigurations.zephyrus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/zephyrus
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Preserve pre-existing desktop configuration during activation.
            # Numbered backups also allow a later migration to run safely.
            home-manager.backupCommand = pkgs.writeShellScript "home-manager-backup" ''
              exec ${pkgs.coreutils}/bin/mv --backup=numbered -- "$1" "$1.before-home-manager"
            '';
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.sharedModules = [ codex-desktop-linux.homeManagerModules.default ];
            home-manager.users.malikk = import ./home/malikk.nix;
          })
        ];
      };

      # Compatibility alias for the former SDDM trial configuration.
      nixosConfigurations.zephyrus-sddm = inputs.self.nixosConfigurations.zephyrus;
    };
}

{
  description = "NixOS configuration for Malik's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Update this input independently for Hyprland/Aquamarine fixes.
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

  outputs = inputs@{ nixpkgs, home-manager, codex-desktop-linux, ... }: {
    nixosConfigurations.zephyrus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/zephyrus
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ codex-desktop-linux.homeManagerModules.default ];
          home-manager.users.malikk = import ./home/malikk.nix;
        }
      ];
    };

    # Explicit opt-in trial; the normal host keeps the text greeter for now.
    nixosConfigurations.zephyrus-sddm = inputs.self.nixosConfigurations.zephyrus.extendModules {
      modules = [ ./modules/greeter-sddm.nix ];
    };
  };
}

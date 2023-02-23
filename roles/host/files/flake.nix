{
  inputs.agenix.url = "github:ryantm/agenix";
  outputs = { self, nixpkgs, agenix }@attrs: {
    # replace 'joes-desktop' with your hostname here.
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./configuration.nix
        agenix.nixosModules.age
     ];
    };
  };
}

{
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.vinemetrics-irc.url = github:albinvass/vinemetrics?dir=vinemetrics-irc;
  outputs = { self, nixpkgs, vinemetrics-irc, agenix }@attrs: {
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

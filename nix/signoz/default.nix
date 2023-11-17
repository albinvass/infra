{ inputs, pkgs, ... }: {
  packages = {
      signoz-query-service = pkgs.buildGoModule rec {
        pname = "SigNoz";
        version = "0.34.0";
        vendorSha256 = "sha256-fCpIfPN3dBjTRAUlD15OKKMSl10aGafyd0RK3Eqtlfo=";
        checkPhase = false;
        # Onyl build query-service
        preBuild = ''
          cd pkg/query-service
        '';
        src = "${inputs.signoz-src}";
      };

      signoz-frontend = pkgs.mkYarnPackage rec {
        name = "signoz-frontend";
        src = "${inputs.signoz-src}/frontend";
        packageJson = "${src}/package.json";
        yarnLock = "${src}/yarn.lock";
        yarnNix = ./yarn.nix; 
        distPhase = "true";
        buildPhase = ''
          export HOME=$(mktemp -d)
          yarn --offline build
        '';
      };
  };
}

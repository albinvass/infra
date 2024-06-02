{ ... }:
{
  imports = [
    ../../modules/base
    ../../modules/development-tools
  ];

  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "-";
      value = "8192";
    }
  ];
}

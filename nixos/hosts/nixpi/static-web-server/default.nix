{ ... }:
{
  environment.etc."/static-web-server/index.html" = {
    text =
      ''
        <html>
        <div> Welcome! </div>
        <html>
      '';
    user = "static-web-server";
    group = "static-web-server";
  };
  services.static-web-server = {
    enable = true;
    root = "/etc/static-web-server/";
  };
}

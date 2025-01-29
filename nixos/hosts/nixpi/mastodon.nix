_: {
  services.mastodon = {
    enable = true;
    streamingProcesses = 1;
    localDomain = "mastodon.albinvass.se";
    trustedProxy = "127.0.0.1";
    smtp = {
      fromAddress = "mastodon@albinvass.se";
    };
  };
}

{ pkgs }:
pkgs.buildNpmPackage {
  pname = "pi-coding-agent";
  version = "0.52.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-0.52.0.tgz";
    hash = "sha256-LyaHd3tACAta7y74RFrvrjZCZxgQrZEZFdh43JEBUD4=";
  };

  postPatch = ''
    cp ${../vendor/pi-coding-agent/package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-R9b+AElS+0IeC1rX8DGWeDcK2p01zeLO90r9kShuq7k=";
  dontNpmBuild = true;
}

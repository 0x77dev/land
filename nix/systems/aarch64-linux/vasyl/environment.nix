{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.hermes-agent;

  # The agent workstation toolkit, scoped to this VM. Placement rule:
  # universal lightweight CLIs live in the shared home modules (all hosts,
  # incl. Darwin); everything heavy, Linux-only, or agent-specific stays
  # here. This list is wired into both the system PATH and the hermes
  # service PATH (extraPackages) because the hermes *service* user never
  # sees home-manager packages — agent-critical CLIs that also exist in
  # shared home modules (jq, ripgrep, duckdb, ...) are repeated here
  # deliberately for that user; same store paths, no real duplication.
  # ffmpeg is CPU-only: there is no practical GPU path in a headless microVM
  # on the NVIDIA proprietary driver (virtio-gpu/Venus targets display Vulkan
  # and remains unstable on NVIDIA; no NVENC over virtio; passing through the
  # host's only GPU is a non-starter) — revisit if virtio-GPU native contexts
  # for NVIDIA mature.
  # Deliberately broad so the agent rarely meets "command not found". Curated,
  # not pathological: every entry earns its place for coding, reverse
  # engineering, data, ops, or everyday work, and anything the base system or
  # the home modules already provide is omitted (noted at each group).
  workstation = with pkgs; [
    # Baseline (the common module ships vim/git/wget/curl/btop/htop/ncdu;
    # NixOS itself guarantees less/xz/zstd/curl and man pages)
    bat
    eza
    fd
    fff
    file
    fzf
    jq
    p7zip
    ripgrep
    rsync
    tmux
    tree
    unzip
    yq-go
    zip

    # Archives — tar/gzip/bzip2/xz/zstd are in the NixOS base and p7zip/zip/unzip
    # are above; unrar is the one unfree entry (proprietary RAR), pulled in only
    # because the flake enables allowUnfree.
    unrar

    # Coding: toolchains, runtimes, and cheap formatters/linters
    cargo
    clang
    clippy
    cmake
    gcc
    gh
    git-lfs
    gnumake
    go
    neovim
    nixfmt
    nodejs_24
    pkg-config
    pnpm
    ruff
    rustc
    rustfmt
    shellcheck
    shfmt
    uv

    # Coding agents. These must be on both the system PATH and Hermes service
    # PATH so Vasyl can delegate from Matrix/API sessions without per-user npm
    # installs or mutable ~/.local shims. Every agent comes from Numtide's
    # pinned, cache-backed package set; `code-cursor` is the editor, not an
    # additional agent distribution.
    pkgs.code-cursor
    pkgs.llm-agents.claude-code
    pkgs.llm-agents.codex
    pkgs.llm-agents.cursor-agent
    pkgs.llm-agents.gemini-cli
    pkgs.llm-agents.opencode
    pkgs.llm-agents.qwen-code

    # Code search, diffs, and watch/bench/task runners. ast-grep (structural
    # search/rewrite) is agent-critical, so it is repeated here for the service
    # user like ripgrep/fd despite living in the shared shell module. entr
    # covers watch loops on the service PATH (home-manager's watchexec only
    # reaches interactive users).
    ast-grep
    delta
    difftastic
    entr
    hyperfine
    just

    # Reverse engineering (Linux-only territory; ghidra skipped — too heavy
    # for an agent box and headless packaging is not clean on aarch64)
    binutils
    binwalk
    gdb
    hexyl
    ltrace
    nmap
    patchelf
    qemu-user
    rizin
    strace
    tcpdump
    xxd

    # Networking, HTTP, and APIs. dig/nslookup/host already come from `bind`
    # (common module); doggo is the modern adjunct.
    curlie
    doggo
    grpcurl
    httpie
    mtr
    socat
    websocat
    xh

    # Transfer, sync, and OCI images. rclone + minio-client (mc) cover
    # S3-compatible object storage without pulling the AWS SDK; croc is
    # ad-hoc p2p; skopeo/dive inspect container images.
    aria2
    croc
    dive
    minio-client
    rclone
    skopeo

    # Documents, media, OCR, everyday (ffmpeg is CPU-only here)
    ffmpeg
    graphviz
    imagemagick
    ocrmypdf
    pandoc
    poppler-utils
    qpdf
    taskwarrior3
    tesseract
    yt-dlp

    # Data analysis
    (python3.withPackages (
      ps: with ps; [
        jupyter
        matplotlib
        numpy
        pandas
        polars
      ]
    ))
    csvkit
    duckdb
    sqlite
    visidata

    # Structured text and pipeline plumbing — the building blocks for
    # throwaway one-shot pipelines (see NIX.md). moreutils (sponge/ts/vipe/…)
    # ranks below GNU parallel by design, so both share `parallel` cleanly.
    choose
    dasel
    datamash
    gron
    jaq
    jo
    miller
    moreutils
    parallel
    pv
    sd
  ];

  # Auto-generated environment briefing for the agent: rendered from this
  # config at build time and refreshed on every rebuild, so it never drifts and
  # needs no hand-maintained lists. Everything is derived from the `workstation`
  # list above and one-way config leaves — deliberately NOT from
  # config.environment.systemPackages, which would recurse since this document
  # ends up in that very list via the hermes service.
  #
  # Defensive throughout: not every package carries every meta field, so field
  # reads fall back to "" and risky shapes go through builtins.tryEval, so the
  # briefing always evaluates.
  tryStr =
    e:
    let
      r = builtins.tryEval e;
    in
    if r.success && builtins.isString r.value then r.value else "";

  metaStr = p: attr: tryStr (p.meta.${attr} or "");

  # Normalize a repo URL so it compares cleanly against meta.homepage (which is
  # often the very same repo): drop a trailing ".git" and slash.
  stripRepoUrl = url: lib.removeSuffix "/" (lib.removeSuffix ".git" url);

  # A comparison key for "is this the same repo": case- and scheme-insensitive,
  # since GitHub owners are case-insensitive and some homepages use http://. Used
  # only to decide whether a source link duplicates the homepage, never shown.
  repoKey =
    url: lib.toLower (lib.removePrefix "http://" (lib.removePrefix "https://" (stripRepoUrl url)));

  # A clean upstream *source repository* URL, only when the fetcher genuinely
  # exposes one: fetchFromGitHub/GitLab and fetchgit set `src.gitRepoUrl` to the
  # real repo (github/gitlab/…), which we keep. fetchurl tarballs and mirrors
  # don't, and we deliberately never synthesize a link from codeload/tarball
  # URLs — that is noise, not a repo. Guarded and tryEval'd like the meta
  # readers, so a srcless or throwing package yields "".
  srcRepoUrl =
    p:
    let
      raw = if p ? src then tryStr (p.src.gitRepoUrl or "") else "";
    in
    if lib.hasPrefix "http" raw then stripRepoUrl raw else "";

  # Markdown-table-safe: a raw pipe or newline would break a row.
  mdCell = lib.replaceStrings [ "|" "\n" "\r" ] [ "\\|" " " " " ];

  # One row per tool: name linked to its homepage (docs), plus a separate `src`
  # link only when the source repo is a distinct URL — most github-hosted tools
  # already point homepage at the repo, so that link is suppressed as a
  # duplicate | command (the real binary, from meta.mainProgram, else the
  # package name) | version | description.
  toolRow =
    p:
    let
      name = lib.getName p;
      main = p.meta.mainProgram or "";
      home = metaStr p "homepage";
      src = srcRepoUrl p;
      showSrc = src != "" && repoKey home != repoKey src;
      tool =
        (if home != "" then "[${name}](${home})" else name) + lib.optionalString showSrc " · [src](${src})";
      cmd = if main != "" then main else name;
      ver = lib.getVersion p;
    in
    "| ${tool} | `${cmd}` | ${if ver == "" then "—" else ver} | ${mdCell (metaStr p "description")} |";

  toolTable = lib.concatMapStringsSep "\n" toolRow (
    lib.sort (a: b: lib.getName a < lib.getName b) workstation
  );

  # The guest's tap edge, read back from the live network config instead of
  # restating addresses here.
  lan = config.systemd.network.networks."20-lan" or { };
  gateway = lan.networkConfig.Gateway or null;

  # A compact, parseable machine snapshot, single-sourced from config leaves
  # and serialized straight back to Nix with lib.generators.toPretty.
  facts = {
    machine = {
      host = config.networking.hostName;
      domain = config.networking.domain;
      system = pkgs.stdenv.hostPlatform.system;
      nixos = config.system.nixos.version;
      kernel = tryStr (config.boot.kernelPackages.kernel.version or "");
      timeZone = config.time.timeZone;
      hypervisor = config.microvm.hypervisor;
      vcpu = config.microvm.vcpu;
      memMiB = config.microvm.mem;
      storage = map (
        v: "${v.mountPoint} ${v.fsType} ${toString (v.size / 1024)}GiB"
      ) config.microvm.volumes;
    };
    network = {
      address = lan.address or [ ];
      inherit gateway;
      nameservers = config.networking.nameservers;
      firewall = config.networking.firewall.enable;
    };
    nix = {
      features = config.nix.settings.experimental-features or [ ];
      substituters = config.nix.settings.substituters or [ ];
      # Pinned flake registry names: each is a valid `nix shell <name>#pkg`
      # source resolved to the revision locked by this flake.
      registry = lib.attrNames config.nix.registry;
      store = {
        shares = map (s: "${s.source} -> ${s.mountPoint} (${s.proto})") config.microvm.shares;
        writableOverlay = config.microvm.writableStoreOverlay;
      };
    };
    hermes = {
      inherit (cfg) stateDir;
      workspace = cfg.workingDirectory;
    };
    users = {
      daemon = cfg.user;
      humans = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
    };
  };

  # Orientation notes: each config-derived bullet appears only when the
  # matching option is actually on, so the prose can never contradict the
  # system it describes. The trailing bullets are policy, not config.
  notes =
    lib.optional (config.microvm.writableStoreOverlay != null)
      "`/nix/store` is the host's (read-only share) plus a writable overlay at `${config.microvm.writableStoreOverlay}`, so `nix build`/`nix shell`/`nix develop` work in-guest — see NIX.md."
    ++ lib.optional config.programs.nix-ld.enable "Foreign (non-Nix) binaries run via `nix-ld` — rustup toolchains, uv-installed wheels, npm native deps all work."
    ++ lib.optional (
      gateway != null
    ) "Internet and DNS are NAT'd through the host at ${gateway}; DNS follows its upstreams."
    ++ lib.optional config.services.openssh.enable "SSH is up on port ${
      lib.concatMapStringsSep ", " toString config.services.openssh.ports
    }${
      lib.optionalString (
        (config.services.openssh.settings.PasswordAuthentication or true) == false
      ) ", pubkey auth only"
    }."
    ++ [
      "The toolkit is made to be composed — pipe freely, fan out with `xargs`/`parallel`, reshape structured data with `jq`/`mlr`/`dasel`; see NIX.md for the shell-composition guide."
      "Provider config is mutable at runtime; more providers can be layered in."
      "You own your user-systemd (lingering) and may manage `hermes-agent.service` and `nix-upper-gc.service` at system level; see NIX.md."
      "Rebuilt with the host: `nixos-rebuild switch` for `spark` (`.#spark`) updates and restarts vasyl. No imperative step."
    ];

  environmentDoc = ''
    # Environment (auto-generated)

    Rendered from `vasyl`'s NixOS configuration at build time and refreshed on
    every rebuild — the ground truth for this machine. Do not edit by hand.

    ## System

    A structured snapshot, serialized straight from the live Nix config:

    ```nix
    ${lib.generators.toPretty { } facts}
    ```

    ${lib.concatMapStringsSep "\n" (n: "- ${n}") notes}

    ## Toolkit

    Provisioned and on PATH for both you and the interactive shell (the base
    system — coreutils, git, vim, curl, man pages, … — is present but not
    listed). Versions and metadata are read from each package at build time:

    | Tool | Command | Version | Description |
    | --- | --- | --- | --- |
    ${toolTable}
  '';
in
{
  environment.systemPackages = workstation;

  services.hermes-agent = {
    extraPackages = workstation;
    documents."ENVIRONMENT.md" = environmentDoc;
  };
}

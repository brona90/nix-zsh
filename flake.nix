{
  description = "Gregory's Zsh configuration with oh-my-zsh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # These can be imported by home-manager
      mkZshConfig = pkgs: {
        aliases = {
          # PS
          psa = "ps aux";
          psg = "ps aux | grep ";
          psr = "ps aux | grep ruby";

          # Moving around
          cdb = "cd -";
          cls = "clear;ls";

          # Show human friendly numbers and colors
          df = "df -h";
          du = "du -h -d 2";
          ll = "ls -alh --color=auto";
          ls = "ls --color=auto";
          lsg = "ll | grep";

          # mimic vim functions
          ":q" = "exit";

          # Git Aliases
          gs = "git status";
          gstsh = "git stash";
          gst = "git stash";
          gsp = "git stash pop";
          gsa = "git stash apply";
          gsh = "git show";
          gshw = "git show";
          gshow = "git show";
          gi = "vim .gitignore";
          gcm = "git commit -m";
          gcim = "git commit -m";
          gci = "git commit";
          gco = "git checkout";
          gcp = "git cherry-pick";
          ga = "git add -A";
          gap = "git add -p";
          guns = "git restore --staged";
          gunc = "git reset --soft HEAD~1";
          gm = "git merge";
          gms = "git merge --squash";
          gam = "git commit --amend --reset-author";
          grv = "git remote -v";
          grr = "git remote rm";
          grad = "git remote add";
          gr = "git rebase";
          gra = "git rebase --abort";
          grc = "git rebase --continue";
          gbi = "git rebase --interactive";
          gl = "git log --oneline --graph";
          glg = "git log --oneline --graph";
          glog = "git log --oneline --graph";
          co = "git checkout";
          gf = "git fetch";
          gfp = "git fetch --prune";
          gfa = "git fetch --all";
          gfap = "git fetch --all --prune";
          gfch = "git fetch";
          gd = "git diff";
          gb = "git branch";
          gdc = "git diff --cached -w";
          gds = "git diff --staged -w";
          gpl = "git pull";
          gplr = "git pull --rebase";
          gps = "git push";
          gpsh = "git push -u origin `git rev-parse --abbrev-ref HEAD`";
          gnb = "git checkout -b";
          grs = "git reset";
          grsh = "git reset --hard";
          gcln = "git clean";
          gclndf = "git clean -df";
          gclndfx = "git clean -dfx";
          gsm = "git submodule";
          gsmi = "git submodule init";
          gsmu = "git submodule update";
          gt = "git tag";
          gbg = "git bisect good";
          gbb = "git bisect bad";
          gdmb = "git branch --merged | grep -v \"\\*\" | xargs -n 1 git branch -d";

          # Common shell functions
          less = "less -r";
          tf = "tail -f";
          l = "less";
          lh = "ls -alt | head";
          screen = "TERM=screen screen";
          cl = "clear";

          # Zippin
          gz = "tar -zcvf";

          # Kill aliases
          ka9 = "killall -9";
          k9 = "kill -9";
        };

        ohMyZsh = {
          enable = true;
          plugins = [ "git" "z" "direnv" ];
          extraConfig = ''
            # Update settings
            zstyle ':omz:update' mode auto
            
            # Enable command auto-correction
            ENABLE_CORRECTION="true"
            
            # Completion waiting dots
            COMPLETION_WAITING_DOTS="true"
          '';
        };

        plugins = [
          {
            name = "zsh-syntax-highlighting";
            src = pkgs.zsh-syntax-highlighting;
            file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
          }
          {
            name = "zsh-history-substring-search";
            src = pkgs.zsh-history-substring-search;
            file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
          }
        ];

        initExtra = ''
          # Enable vi mode
          bindkey -v
          export KEYTIMEOUT=1
          
          # History substring search highlighting
          HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=green,fg=white,bold'
          HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
          
          # History substring search keybindings
          bindkey '^[[A' history-substring-search-up
          bindkey '^[[B' history-substring-search-down
          bindkey -M vicmd 'k' history-substring-search-up
          bindkey -M vicmd 'j' history-substring-search-down
          
          # Environment variables
          export EDITOR='emacs -nw'
        '';

        sessionVariables = {
          EDITOR = "emacs -nw";
        };
      };

    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        config = mkZshConfig pkgs;

        # Build a standalone zshrc from the config
        aliasesText = pkgs.lib.concatStringsSep "\n" 
          (pkgs.lib.mapAttrsToList (name: value: "alias ${name}='${value}'") config.aliases);

        zshConfig = pkgs.writeText "zshrc" ''
          # Oh-My-Zsh configuration
          export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
          
          ${config.ohMyZsh.extraConfig}
          
          # Plugins
          plugins=(${pkgs.lib.concatStringsSep " " config.ohMyZsh.plugins})
          
          source $ZSH/oh-my-zsh.sh
          
          # Zsh plugins from nixpkgs
          ${pkgs.lib.concatMapStringsSep "\n" 
            (plugin: "source ${plugin.src}/${plugin.file}") 
            config.plugins}
          
          # Starship prompt
          eval "$(${pkgs.starship}/bin/starship init zsh)"
          
          # Mise activation
          eval "$(${pkgs.mise}/bin/mise activate zsh)"
          
          # Custom aliases
          ${aliasesText}
          
          ${config.initExtra}
        '';

        # Wrapper that sets up zsh with config
        zshWrapper = pkgs.writeShellScriptBin "zsh-with-config" ''
          export ZDOTDIR="$HOME/.config/zsh"
          mkdir -p "$ZDOTDIR"
          
          # Link config if not exists or outdated
          if [ ! -f "$ZDOTDIR/.zshrc" ] || [ "$(readlink -f "$ZDOTDIR/.zshrc")" != "${zshConfig}" ]; then
            ln -sf ${zshConfig} "$ZDOTDIR/.zshrc"
          fi
          
          exec ${pkgs.zsh}/bin/zsh "$@"
        '';

      in
      {
        packages = {
          default = zshWrapper;
          zsh = zshWrapper;
          config = zshConfig;
        };

        apps.default = {
          type = "app";
          program = "${zshWrapper}/bin/zsh-with-config";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.zsh
            pkgs.oh-my-zsh
            pkgs.zsh-syntax-highlighting
            pkgs.zsh-history-substring-search
            pkgs.starship
            pkgs.mise
            pkgs.direnv
            zshWrapper
          ];

          shellHook = ''
            echo "Zsh development environment"
            echo ""
            echo "Available commands:"
            echo "  zsh-with-config  - Launch zsh with your configuration"
            echo ""
            echo "Included:"
            echo "  - Oh-My-Zsh with git, vi-mode, z, direnv plugins"
            echo "  - Syntax highlighting"
            echo "  - History substring search"
            echo "  - Starship prompt"
            echo "  - Mise runtime manager"
            echo "  - Custom Git aliases and shell shortcuts"
          '';
        };

        # Export the config for home-manager to use
        lib.zshConfig = mkZshConfig pkgs;

        formatter = pkgs.nixfmt;
      }
    ) // {
      # Make mkZshConfig available to home-manager
      lib.mkZshConfig = mkZshConfig;
    };
}
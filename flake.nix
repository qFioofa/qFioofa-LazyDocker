{
  description = "qFioofa LazyDocker config — Home Manager module";

  outputs = { self }: {
    homeManagerModules.default = { config, lib, pkgs, ... }:
      let
        pyEnv = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
        cfgTheme = config."lazydocker-config".theme;

        mergedConfig = pkgs.runCommand "lazydocker-config.yml" {
          buildInputs = [ pyEnv ];
          src = ./src;
        } ''
          python3 -c "
          import sys, glob, os, yaml

          src = '$src'
          out = '$out'
          theme = '${cfgTheme}'

          def merge(a, b):
              for k, v in b.items():
                  if isinstance(v, dict) and isinstance(a.get(k), dict):
                      merge(a[k], v)
                  else:
                      a[k] = v
              return a

          def load_palette(path):
              with open(path) as fh:
                  data = yaml.safe_load(fh) or {}
              return data.get('palette', {})

          def resolve(value, palette):
              if isinstance(value, str) and value.startswith('@'):
                  key = value[1:]
                  if key not in palette:
                      raise SystemExit('unknown palette token: ' + value)
                  return palette[key]
              if isinstance(value, list):
                  return [resolve(v, palette) for v in value]
              if isinstance(value, dict):
                  return {k: resolve(v, palette) for k, v in value.items()}
              return value

          palette = load_palette(os.path.join(src, 'themes', 'palette.yml'))
          theme_path = os.path.join(src, 'themes', theme + '.yml')
          if not os.path.exists(theme_path):
              raise SystemExit('unknown theme: ' + theme)

          files = [os.path.join(src, 'config.yml'), theme_path]

          result = {}
          for f in files:
              with open(f) as fh:
                  merge(result, yaml.safe_load(fh) or {})

          result = resolve(result, palette)

          with open(out, 'w') as fh:
              yaml.safe_dump(result, fh, sort_keys=False, allow_unicode=True)
          "
        '';
      in
      {
        options."lazydocker-config".theme = lib.mkOption {
          type = lib.types.str;
          default = "yugen-ash";
          description = "Theme file (without .yml) under src/themes to merge.";
        };

        config.xdg.configFile."lazydocker/config.yml".source = mergedConfig;
      };
  };
}

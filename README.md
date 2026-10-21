# WSL Ubuntu development baseline

`wsl-dev.dsc.yaml` describes the Ubuntu packages used for this WSL development setup: PowerShell, Git and GitHub CLI, download tools, JSON tooling, build helpers, Python, fzf, and zoxide.

## Check the current machine

From this directory, run:

```bash
dsc config test --file ./wsl-dev.dsc.yaml
```

A result with `inDesiredState: true` means that package is installed. This check does not install or upgrade anything.
The Apt resource does not support DSC's `--what-if` option, so use `config test` to review drift before applying changes.

For a compact PowerShell table, run:

```powershell
./Test-WslDsc.ps1
```

Use `./Test-WslDsc.ps1 -Quiet` to show one success line or only resources with drift. The script exits with code `0` when everything matches, `1` for drift, and `2` for an error. It accepts `-ConfigPath` to test another DSC file.

## Apply missing packages

Review the YAML, then run:

```bash
sudo apt update
sudo dsc config set --file ./wsl-dev.dsc.yaml
```

The Apt resource installs packages that are missing. Package versions are intentionally unspecified, so the configuration checks for presence rather than a particular version. It does not perform a general system upgrade.

PowerShell comes from the Microsoft Ubuntu 24.04 apt repository, which must already be configured. The configuration does not add apt repositories.

## Scope

`helm` and `argocd` are installed under `/usr/local/bin`, and `kubectl` and `terraform` are installed through Snap on this machine. They are outside the scope of the Apt resource. PowerShell profile files and PowerShell Gallery modules are also managed separately.

The installed `dsc` package is intentionally omitted: this apt repository currently offers a newer preview as its default candidate, while this setup uses stable DSC 3.3.0.

The built-in `DSC.PackageManagement/Apt` resource is documented as a proof of concept by Microsoft. This baseline is for a personal WSL environment, not a production Linux fleet.

- [Microsoft DSC Apt resource](https://learn.microsoft.com/powershell/dsc/reference/resources/dsc/packagemanagement/apt/)
- [DSC configuration commands](https://learn.microsoft.com/powershell/dsc/reference/cli/config/)
# dsc-wsl
# dsc-wsl

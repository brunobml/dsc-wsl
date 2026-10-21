# WSL Ubuntu development baseline

`wsl-dev.dsc.yaml` describes the Ubuntu packages used for this WSL development setup. `shells.dsc.yaml` configures Bash, PowerShell, Oh My Posh, and Terminal-Icons for the current user.

## Set up a fresh Ubuntu 24.04 instance

Clone this repository and run the bootstrap as your normal user:

```bash
sudo apt-get update
sudo apt-get install -y git
mkdir -p ~/repos
git clone https://github.com/brunobml/dsc-wsl.git ~/repos/dsc-wsl
cd ~/repos/dsc-wsl
bash ./bootstrap.sh
```

The bootstrap installs Microsoft's Ubuntu package repository, stable DSC 3.3.0, PowerShell, and the baseline APT packages. It then applies the shell configuration through DSC as your user and tests both configurations. It is safe to run again to repair drift. It does not install WSL itself or change Windows Terminal settings.

The shell configuration keeps existing `~/.bashrc` and PowerShell profile content. It adds one source line to each and manages `~/.config/dsc-wsl/bashrc` and `~/.config/dsc-wsl/powershell.ps1`. The fragments initialize zoxide, Kubernetes and Helm completions when those tools are present, and use a readable `~/.kube/config` if one exists. They use a local Kushal Oh My Posh theme. Terminal-Icons 0.11.0 is installed from PowerShell Gallery for the current user.

## Check the current machine

From this directory, run:

```bash
pwsh -NoProfile -File ./Test-WslDsc.ps1 -Quiet
```

An `OK` result means the package and shell resources match the configuration. This check does not install or upgrade anything.
The Apt resource does not support DSC's `--what-if` option. In DSC 3.3.0, its missing-package result also contains a string where the schema requires a boolean, so `config test` fails when a package is absent. Use `bootstrap.sh` to install missing baseline packages before testing.

For a compact PowerShell table, run:

```powershell
./Test-WslDsc.ps1
```

Use `./Test-WslDsc.ps1 -Quiet` to show one success line or only resources with drift. The script exits with code `0` when everything matches, `1` for drift, and `2` for an error. It accepts `-ConfigPath` to test one or more DSC files.

## Reapply the setup

Review the YAML, then run:

```bash
bash ./bootstrap.sh
```

The bootstrap installs missing packages through APT. Package versions are intentionally unspecified, so the DSC configuration checks for presence rather than a particular version. It does not perform a general system upgrade.

PowerShell comes from the Microsoft Ubuntu 24.04 apt repository. `bootstrap.sh` configures that repository on a new instance.

## Scope

`helm`, `argocd`, `kubectl`, and `terraform` are not installed by this baseline. The completion setup is conditional on each command being available. Machine credentials, SSH keys, Kubernetes contexts, and Windows-side fonts are not included.

APT package versions and the Oh My Posh binary version follow their upstream repositories; DSC 3.3.0 and Terminal-Icons 0.11.0 are pinned. The Kushal theme is exported to a local file on first setup.

The installed `dsc` package is intentionally omitted: this apt repository currently offers a newer preview as its default candidate, while this setup uses stable DSC 3.3.0.

The built-in `DSC.PackageManagement/Apt` resource is documented as a proof of concept by Microsoft. This baseline is for a personal WSL environment, not a production Linux fleet.

- [Microsoft DSC Apt resource](https://learn.microsoft.com/powershell/dsc/reference/resources/dsc/packagemanagement/apt/)
- [DSC configuration commands](https://learn.microsoft.com/powershell/dsc/reference/cli/config/)
- [PowerShellScript resource](https://learn.microsoft.com/powershell/dsc/reference/resources/microsoft/dsc/transitional/powershellscript/)

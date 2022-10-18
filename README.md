# update-dependabot-config
Holds the PowerShell and bash scripts to update a repository's dependabot.yml file
Interval and target branch can be altered in the scripts.

Save a copy and run the script from the git repository's top level directory.

Example usage for powershell script:
```
./update-dependabot.ps1 -targetBranch dev -outputFile ./.github/dependabot.yml
```
target branch defaults to dev. Output file must be specified. In order to edit interval, you must edit the script or dependabot.yml ouptut file directly.

Example usage for bash script:
```
./update-dependabot.sh
```
Automatically saves to .github/dependabot.yml. In order to edit target branch and interval, you must edit the script or dependabot.yml ouptut directly.

Additionally, make sure dependabot alerts are enabled. You can enable these in **Security** >>> **Dependabot Alerts** >> **Enable Dependabot alerts**.

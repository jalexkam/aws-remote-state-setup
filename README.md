
# aws-remote-state-setup

/terraform-failed-to-install-provider-doesnt-match-checksums-from-dependency-l
https://stackoverflow.com/questions/67204811/terraform-failed-to-install-provider-doesnt-match-checksums-from-dependency-l
The issue is that my local workstation is a Mac which uses the darwin platform, so all of the providers are downloaded for darwin and the hashes stored in the lockfile for that platform. When the CI system, which is running on Linux runs, it attempts to retrieve the providers listed in the lockfile, but the checksums don't match because they use a different platform.

The solution is to use the following command locally to generate a new terraform dependency lock file with all of the platforms for terraform, other systems running on different platforms will then be able to obey the dependency lock file.

terraform providers lock -platform=windows_amd64 -platform=darwin_amd64 -platform=linux_amd64


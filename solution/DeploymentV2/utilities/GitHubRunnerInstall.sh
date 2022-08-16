sudo apt-get update  && \
sudo apt-get install -y wget apt-transport-https software-properties-common && \
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb  && \
sudo dpkg -i packages-microsoft-prod.deb  && \
sudo apt-get update  && \
sudo apt-get install -y powershell  && \
rm ./packages-microsoft-prod.deb  && \
sudo apt install -y dotnet-sdk-6.0  && \
wget https://github.com/google/go-jsonnet/releases/download/v0.17.0/jsonnet-go_0.17.0_linux_amd64.deb  && \
sudo dpkg -i jsonnet-go_0.17.0_linux_amd64.deb && \
sudo rm jsonnet-go_0.17.0_linux_amd64.deb && \
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
sudo apt-get update && sudo apt-get install terraform && \
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.35.14/terragrunt_linux_amd64 && \
sudo mv terragrunt_linux_amd64 terragrunt && \
sudo chmod u+x terragrunt && \
sudo mv terragrunt /usr/local/bin/terragrunt && \
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bashaz 
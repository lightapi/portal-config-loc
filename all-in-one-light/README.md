# All-in-one Light

## Overview
This doc covers how to use the light version of the all-in-one. It's meant for developers who are working on services.
It removes HA deployments from the configuration, making the resources required to run much lower.


## How To Set Up On Windows
1. Install Docker Desktop
    1.1. You can download Docker Desktop from [here](https://www.docker.com/products/docker-desktop)
    1.2. You will need to enable WSL2 during the installation process.
2. Modify the Windows hosts file
   2.1. Use the following Powershell command:
   ```powershell
      Start-Process -FilePath notepad.exe -Verb runas -ArgumentList "$env:SystemRoot\system32\drivers\etc\hosts"
   ```
   2.2. You will need to run the above command as an administrator.
   2.3. Add the following line to the hosts file: ```<local-ip>  local.lightapi.net devsignin.lightapi.net devoauth.lightapi.net```
   2.4. Replace `<local-ip>` with the local IP address of the machine.
3. Download all service jars by using the `copy-service-jars.ps1` script. This downloads the latest SNAPSHOT jars and moves them to the correct directory.
4. Start docker compose:
    3.1. Use the following Powershell command:
    ```powershell
       docker compose up
    ```
5. Access the services using the following URL: [http://localhost:3000](http://localhost:3000)

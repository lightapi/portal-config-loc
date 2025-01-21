# All-in-one Light

## Overview
This doc covers how to use the light version of the all-in-one. It's meant for developers who are working on services. 
It removes HA deployments from the configuration, making the resources required to run much lower.


## How To Set Up On Windows
1. Install Docker Desktop
2. Install WSL2
3. Modify the Windows hosts file under using the following powershell command.
    ```powershell
    Start-Process -FilePath notepad.exe -Verb runas -ArgumentList "$env:SystemRoot\system32\drivers\etc\hosts"
    ```
4. Add the following line: ```192.168.5.75  local.lightapi.net devsignin.lightapi.net devoauth.lightapi.net```
5. Start the docker compose file using the following docker command:
    ```powershell
    docker compose up
    ```
6. Access the services using the following URL: [http://localhost:3000](http://localhost:3000)
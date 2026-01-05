# all-in-light

## Overview
This doc covers how to use the light version of the light-portal. It's meant for developers who are working on services.
It removes HA deployments from the configuration, making the resources required to run much lower. Here is the memory usage on my Ubuntu 24.04 Desktop.

```
CONTAINER ID   NAME             CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O     PIDS
4c85499b556d   config-server    0.04%     153.9MiB / 91.94GiB   0.16%     17.1kB / 5.29kB   0B / 106kB    46
529c4aacaba4   hybrid-query1    0.17%     297.7MiB / 91.94GiB   0.32%     2.33MB / 1.44MB   0B / 188kB    67
70d6938e378c   hybrid-command   0.04%     217.8MiB / 91.94GiB   0.23%     17.1kB / 5.29kB   0B / 115kB    46
7cb6a65b23bd   reference        0.03%     159.1MiB / 91.94GiB   0.17%     17.2kB / 5.29kB   0B / 106kB    46
3127941de8f9   oauth-kafka      0.03%     278.7MiB / 91.94GiB   0.30%     87.8kB / 73.6kB   0B / 270kB    60
e0b288922735   postgres         0.07%     591MiB / 91.94GiB     0.63%     5.82MB / 2.71MB   0B / 6.75MB   26
01df312fd331   light-gateway    0.03%     255.4MiB / 91.94GiB   0.27%     91.2kB / 76.5kB   0B / 197kB    59
```

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

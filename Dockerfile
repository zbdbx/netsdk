FROM amd64/buildpack-deps:buster-scm

# ENV \
#     # Enable detection of running in a container
#     DOTNET_RUNNING_IN_CONTAINER=true \
#     # Enable correct mode for dotnet watch (only mode supported in a container)
#     DOTNET_USE_POLLING_FILE_WATCHER=true \
#     # Skip extraction of XML docs - generally not useful within an image/container - helps performance
#     NUGET_XMLDOC_MODE=skip \
#     # PowerShell telemetry for docker image usage
#     POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetCoreSDK-Debian-10 \
#     # Configure web servers to bind to port 80 when present
#     ASPNETCORE_URLS=http://+:80


# # Install .NET CLI dependencies
# RUN sed -i "s@http://deb.debian.org@https://mirrors.163.com@g" /etc/apt/sources.list \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends \
#         libc6 \
#         libgcc1 \
#         libgssapi-krb5-2 \
#         libicu63 \
#         libssl1.1 \
#         libstdc++6 \
#         zlib1g \
#     && rm -rf /var/lib/apt/lists/*
 
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb
RUN sed -i "s@http://deb.debian.org@https://mirrors.163.com@g" /etc/apt/sources.list && apt-get update
RUN apt-get install -y apt-transport-https
RUN apt-get install -y dotnet-sdk-2.1
RUN dotnet --info
RUN apt-get install -y dotnet-sdk-3.1
RUN dotnet --info

# Install PowerShell global tool
RUN powershell_version=7.0.3 \
    && curl -SL --output PowerShell.Linux.x64.$powershell_version.nupkg https://pwshtool.blob.core.windows.net/tool/$powershell_version/PowerShell.Linux.x64.$powershell_version.nupkg \
    && powershell_sha512='580f405d26df40378f3abff3ec7e4ecaa46bb0e46bcb2b3c16eff2ead28fde5aaa55c19501f73315b454e68d98c9ef49f8887c36e7c733d7c8ea3dd70977da2f' \
    && echo "$powershell_sha512  PowerShell.Linux.x64.$powershell_version.nupkg" | sha512sum -c - \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.x64 \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux.x64.$powershell_version.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    && chmod 755 /usr/share/powershell/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm
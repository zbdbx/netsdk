FROM amd64/buildpack-deps:buster-scm

ENV \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetCoreSDK-Debian-10 \
    # Configure web servers to bind to port 80 when present
    ASPNETCORE_URLS=http://+:80


# Install .NET CLI dependencies
RUN sed -i "s@http://deb.debian.org@https://mirrors.163.com@g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu63 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*


RUN dotnet_sdk_version=2.1.811 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='ddc6a583c90405a1cf57c33b2ee285ce34d59f82c4f7bc01900f4ce87c45e295de96a0293ad51937ac1935611b87bc73cdafa8acd93b6fda5a2c624b00070326' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet$dotnet_sdk_version \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet$dotnet_sdk_version \
    && rm dotnet.tar.gz 
    #&& ln -s /usr/share/dotnet/dotnet$dotnet_sdk_version /usr/bin/dotnet

# Install .NET Core SDK
RUN dotnet_sdk_version=3.1.404 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='94d8eca3b4e2e6c36135794330ab196c621aee8392c2545a19a991222e804027f300d8efd152e9e4893c4c610d6be8eef195e30e6f6675285755df1ea49d3605' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet$dotnet_sdk_version \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet$dotnet_sdk_version \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet$dotnet_sdk_version /usr/bin/dotnet \
    # Trigger first run experience by running arbitrary cmd
    && dotnet --info && dotnet help

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
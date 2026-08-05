# 1. Use the official Fedora Silverblue base
FROM quay.io/fedora/fedora-silverblue:44

# 2. Add Third-Party Repositories
# Add Microsoft's official YUM repository for VS Code
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    printf "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" > /etc/yum.repos.d/vscode.repo

# 3. Add RPM Fusion (Free and Non-Free) for Steam, Discord, and Codecs
RUN dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf clean all

# 4. AMD Freeworld Drivers & Multimedia Codecs
# Swap restricted ffmpeg and 64-bit Vulkan drivers for their full freeworld versions.
RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf swap -y mesa-vulkan-drivers mesa-vulkan-drivers-freeworld --allowerasing && \
    dnf install -y \
        mesa-va-drivers-freeworld \
        mesa-va-drivers-freeworld.i686 \
        gstreamer1-plugins-ugly \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-libav \
        gstreamer1-plugin-openh264 \
        libva-utils && \
    dnf clean all

# 5. 'Fix' /opt for Third-Party RPMs
# Silverblue symlinks /opt to /var/opt. RPMs like Discord fail to install because cpio expects a real directory.
RUN rm /opt && mkdir /opt

# 6. Install 32-bit AMD Drivers, Utilities, & Desktop Applications
RUN dnf install -y \
    git \
    mesa-vulkan-drivers-freeworld.i686 \
    mesa-dri-drivers.i686 \
    vulkan-loader.i686 \
    code \
    discord \
    steam && \
    dnf clean all

# 7. Configure Discord Default Settings
# Bypasses mandatory startup update checks so Discord won't lock you out between OS updates.
RUN mkdir -p /etc/skel/.config/discord && \
    echo '{"SKIP_HOST_UPDATE": true}' > /etc/skel/.config/discord/settings.json

# 8. Service Enablement
# Ensure the pre-installed SSH daemon starts on boot.
RUN systemctl enable sshd.service

# 9. Validation
# Lint the final container image to prevent easy-to-catch bootc build issues.
RUN bootc container lint

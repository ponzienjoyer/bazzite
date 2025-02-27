# vim: set ft=make :

# Fix the default Steam config to improve download speeds
fix-steam-download-speed:
    mkdir -p $HOME/.local/share/Steam
    rm -f $HOME/.local/share/Steam/steam_dev.cfg
    bash -c 'printf "@nClientDownloadEnableHTTP2PlatformLinux 0\n@fDownloadRateImprovementToAddAnotherConnection 1.0\n" > $HOME/.local/share/Steam/steam_dev.cfg'

# Restore the default Terminal
restore-original-terminal:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
        rm -f $HOME/.local/share/applications/org.gnome.Terminal.desktop
        cp /usr/share/applications/org.gnome.Terminal.desktop $HOME/.local/share/applications/org.gnome.Terminal.desktop
        sed -i '/NoDisplay=true/d' $HOME/.local/share/applications/org.gnome.Terminal.desktop
    else
        rm -f $HOME/.local/share/applications/org.kde.konsole.desktop
        cp /usr/share/applications/org.kde.konsole.desktop $HOME/.local/share/applications/org.kde.konsole.desktop
        sed -i '/NoDisplay=true/d' $HOME/.local/share/applications/org.kde.konsole.desktop
        echo "Done. Change your default Terminal in System Settings to complete the swap."
    fi

# Install Bazzite's Steam Game Mode Startup Video
install-gamemode-video:
    mkdir -p $HOME/.local/share/Steam/config/uioverrides/movies
    rm -f $HOME/.local/share/Steam/config/uioverrides/movies/deck_startup.webm
    ln -s /usr/share/ublue-os/bazzite/bazzite.webm $HOME/.local/share/Steam/config/uioverrides/movies/deck_startup.webm

# Remove all waydroid-related files in your user folders
reset-waydroid:
    bash -c 'sudo rm -rf /var/lib/waydroid /home/.waydroid ~/waydroid ~/.share/waydroid ~/.local/share/applications/*aydroid* ~/.local/share/waydroid'

# Quickly initialize a waydroid image
init-waydroid:
    #!/usr/bin/bash
    sudo waydroid init -c 'https://ota.waydro.id/system' -v 'https://ota.waydro.id/vendor'

# Launch Waydroid configuration helper
configure-waydroid:
    #!/usr/bin/bash
    git clone https://github.com/ublue-os/waydroid_script.git --depth 1 /tmp/waydroid_script
    python -m venv /tmp/waydroid_script/venv
    source /tmp/waydroid_script/venv/bin/activate
    sudo pip install -r /tmp/waydroid_script/requirements.txt
    sudo /tmp/waydroid_script/main.py
    deactivate
    sudo rm -rf /tmp/waydroid_script

# Install Sunshine
install-sunshine:
    #!/usr/bin/bash
    systemctl enable sunshine-workaround.service
    ublue-update --wait
    rpm-ostree install -y https://github.com/LizardByte/Sunshine/releases/download/nightly-dev/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm
    echo "Sunshine is installed!"

# Remove Sunshine
remove-sunshine:
    #!/usr/bin/bash
    systemctl disable sunshine-workaround.service
    ublue-update --wait
    rpm-ostree remove -y sunshine
    echo "Sunshine has been uninstalled."

# Autostart Sunshine
autostart-sunshine:
    #!/usr/bin/bash
    systemctl enable --user --now sunshine.service

# Install LACT for overclocking & undervolting AMD GPUs
install-lact:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    ublue-update --wait
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
        echo 'Installing LACT Libadwaita...'
        wget \
          $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
          jq -r ".assets[] | select(.name | test(\"lact-libadwaita.*fedora-$(rpm -E %fedora)\")) | .browser_download_url") \
          -O /tmp/lact.rpm
    else
        echo 'Installing LACT...'
        wget \
          $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
          jq -r ".assets[] | select(.name | test(\"lact-[0-9].*fedora-$(rpm -E %fedora)\")) | .browser_download_url") \
          -O /tmp/lact.rpm
    fi
    rpm-ostree install --apply-live -y /tmp/lact.rpm
    sudo systemctl enable --now lactd
    rm /tmp/lact.rpm
    echo 'Complete.'

# Install SteamCMD (https://developer.valvesoftware.com/wiki/SteamCMD)
get-steamcmd:
    echo 'Installing SteamCMD...'
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -O /tmp/steamcmd.tar.gz
    mkdir -p ~/.steam
    tar -xvzf /tmp/steamcmd.tar.gz -C ~/.steam
    rm /tmp/steamcmd.tar.gz

# Install OpenRazer for Razer gaming hardware
install-openrazer:
    sudo wget https://download.opensuse.org/repositories/hardware:/razer/Fedora_$(rpm -E %fedora)/hardware:razer.repo -O /etc/yum.repos.d/hardware:razer.repo && \
    ublue-update --wait && \
    rpm-ostree install -y openrazer-meta razergenie && \
    if ! grep -q "plugdev" /etc/group; then \
      sudo bash -c 'grep "plugdev" /lib/group >> /etc/group' \
    ; fi && \
    sudo usermod -a -G plugdev $USER && \
    echo "Please reboot to apply needed changes."

# Install Wootility for configuring Wooting Keyboards
get-wootility:
    #!/usr/bin/bash
    if grep -q 'it.mijorus.gearlever' <<< $(flatpak list); then
      wget "https://api.wooting.io/public/wootility/download?os=linux&branch=lekker" -O $HOME/Downloads/wootility.AppImage
      flatpak run it.mijorus.gearlever $HOME/Downloads/wootility.AppImage
    else
      wget "https://api.wooting.io/public/wootility/download?os=linux&branch=lekker" -O $HOME/Desktop/wootility.AppImage
      chmod +x $HOME/Desktop/wootility.AppImage
    fi

# Enable Supergfxctl, a Nvidia GPU switcher for hybrid laptops
enable-supergfxctl:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    IMAGE_FLAVOR=$(jq -r '."image-flavor"' < $IMAGE_INFO)
    if [[ "$IMAGE_FLAVOR" =~ "nvidia" ]]; then
      systemctl enable --now supergfxd.service
    else
      echo "This requires an Nvidia image."
    fi

# Patch a bug in some 32-bit Source 1.x titles that causes them to crash at startup
patch-source1-tcmalloc:
    #!/usr/bin/bash
    echo 'Add the following as a launch option in Steam:'
    echo 'LD_PRELOAD=/usr/lib/libtcmalloc_and_profiler.so.4 %command%'
    echo "Delete libtcmalloc_minimal.so.x in the game's bin folder if present."

# Patch GMod's 64-bit beta to work properly on Linux (https://github.com/solsticegamestudios/GModCEFCodecFix)
patch-gmod:
    #!/usr/bin/bash
    mkdir -p /tmp/patch-gmod
    wget \
      $(curl -s https://api.github.com/repos/solsticegamestudios/GModCEFCodecFix/releases/latest | \
      jq -r ".assets[] | select(.name | test(\"GModCEFCodecFix-Linux\")) | .browser_download_url") \
      -P /tmp/patch-gmod
    chmod +x /tmp/patch-gmod/GModCEFCodecFix-Linux
    /tmp/patch-gmod/GModCEFCodecFix-Linux
    rm -rf /tmp/patch-gmod

# Install Adwaita-for-Steam theme for CSS Loader (https://github.com/tkashkin/Adwaita-for-Steam)
install-adwaita-for-steam:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
      if [ -d "$HOME/homebrew/themes" ]; then
        git clone https://github.com/tkashkin/Adwaita-for-Steam.git --single-branch "$HOME/homebrew/themes/Adwaita-for-Steam"
      else
        echo 'Please install Decky Loader & CSS Loader first'
      fi
    else 
      echo "This is only supported under GNOME."
    fi

# Force-enable AMD pstate
pstate-force-enable:
    rpm-ostree kargs --append-if-missing=amd_pstate=active

# Set system to boot without showing the grub screen with options
hide-grub:
    #!/usr/bin/bash
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
    echo 'GRUB_TIMEOUT_STYLE=hidden' | sudo tee -a /etc/default/grub 1>/dev/null
    echo 'GRUB_HIDDEN_TIMEOUT=1' | sudo tee -a /etc/default/grub 1>/dev/null
    if [ -d /sys/firmware/efi ]; then
      sudo grub2-mkconfig -o /etc/grub2-efi.cfg
    else
      sudo grub2-mkconfig -o /etc/grub2.cfg
    fi

# Set system to boot with the grub screen showing options (Default)
unhide-grub:
    #!/usr/bin/bash
    sudo sed -i '/GRUB_HIDDEN_TIMEOUT=1/d' /etc/default/grub
    sudo sed -i '/GRUB_TIMEOUT_STYLE=hidden/d' /etc/default/grub
    sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/g' /etc/default/grub
    if [ -d /sys/firmware/efi ]; then
      sudo grub2-mkconfig -o /etc/grub2-efi.cfg
    else
      sudo grub2-mkconfig -o /etc/grub2.cfg
    fi

# Add user to "input" group required by certain controller drivers
add-user-to-input-group:
    #!/usr/bin/bash
    if ! grep -q "input" /etc/group; then
      sudo bash -c 'grep "input" /lib/group >> /etc/group'
    fi
    sudo usermod -a -G input $USER

# Enable Virtualization and add workaround for a specific windows VM crash
enable-virtualization:
    #!/usr/bin/bash
    virt_test=$(rpm-ostree status | grep -A 4 "●" | grep "virt-manager")
    if [[ -z ${virt_test} ]]; then
      echo "Installing QEMU and virt-manager..."
      rpm-ostree install -y virt-manager edk2-ovmf qemu
      rpm-ostree kargs \
      --append-if-missing="kvm.ignore_msrs=1" \
      --append-if-missing="kvm.report_ignored_msrs=0"
      echo 'Please re-run "ujust enable-virtualization" after the reboot to finish setup'
    else
      echo "Enabling libvirtd service"
      sudo systemctl enable --now libvirtd
      echo "libvirtd enabled! If virt-manager says libvirtd.sock is not available after a big update, re-run this command."
    fi

# Enable VFIO on the system if virtualization is enabled
enable-vfio:
    #!/usr/bin/bash
    echo "Enabling VFIO..."
    VIRT_TEST=$(rpm-ostree kargs)
    CPU_VENDOR=$(grep "vendor_id" "/proc/cpuinfo" | uniq | awk -F": " '{ print $2 }')
    VENDOR_KARG="unset"
    if [[ ${VIRT_TEST} == *kvm.report_ignored_msrs* ]]; then
      echo 'add_drivers+=" vfio vfio_iommu_type1 vfio-pci "' | sudo tee /etc/dracut.conf.d/vfio.conf
      sudo touch /etc/bazzite/initramfs/rebuild
      if [[ ${CPU_VENDOR} == "AuthenticAMD" ]]; then
        VENDOR_KARG="amd_iommu=on"
      elif [[ ${CPU_VENDOR} == "GenuineIntel" ]]; then
        VENDOR_KARG="intel_iommu=on"  
      fi
      if [[ ${VENDOR_KARG} == "unset" ]]; then
        echo "Failed to get CPU vendor, exiting..."
        exit 1
      else
        rpm-ostree kargs \
          --append-if-missing="${VENDOR_KARG}" \
          --append-if-missing="iommu=pt" \
          --append-if-missing="rd.driver.pre=vfio_pci" \
          --append-if-missing="vfio_pci.disable_vga=1"
        echo "VFIO will be enabled on next boot, make sure you enable IOMMU, VT-d or AMD-v in your BIOS!"
        echo "Please understand that since this is such a niche use case, support will be very limited!"
        echo "To add your unused/second GPU device ids to the vfio driver by running"
        echo 'rpm-ostree kargs --append-if-missing="vfio-pci.ids=xxxx:yyyy,xxxx:yyzz"'
        echo "NOTE: Your second GPU will not be usable by the host after you do this!"
      fi
    else
      echo "Enable virtualization with ujust enable-virtualization before running ujust enable-vfio."
    fi

# Enable watchdog (default, recovers the system in the event of a malfunction, possible impact to performance due to interrupts)
enable-watchdog:
    #!/usr/bin/bash
    CPU_MODEL=$(lscpu --json | jq -r '."lscpu"[7]."data"')
    WATCHDOG_KARGS="--delete-if-present=nowatchdog"
    if [[ "$CPU_MODEL" =~ "Intel" ]]; then
      WATCHDOG_KARGS="$WATCHDOG_KARGS --delete-if-present=modprobe.blacklist=iTCO_wdt"
    elif [[ "$CPU_MODEL" =~ "AMD" ]]; then
      WATCHDOG_KARGS="$WATCHDOG_KARGS --delete-if-present=modprobe.blacklist=sp5100_tco"
    fi
    rpm-ostree kargs $WATCHDOG_KARGS

# Disable watchdog (potential performance improvement due to fewer interrupts)
disable-watchdog:
    #!/usr/bin/bash
    CPU_MODEL=$(lscpu --json | jq -r '."lscpu"[7]."data"')
    WATCHDOG_KARGS="--append-if-missing=nowatchdog"
    if [[ "$CPU_MODEL" =~ "Intel" ]]; then
      WATCHDOG_KARGS="$WATCHDOG_KARGS --append-if-missing=modprobe.blacklist=iTCO_wdt"
    elif [[ "$CPU_MODEL" =~ "AMD" ]]; then
      WATCHDOG_KARGS="$WATCHDOG_KARGS --append-if-missing=modprobe.blacklist=sp5100_tco"
    fi
    rpm-ostree kargs $WATCHDOG_KARGS

# Install Oversteer for Logitech steering wheels
install-oversteer: distrobox-check-fedora
    distrobox enter -n fedora -- bash -c 'sudo dnf copr enable -y kylegospo/oversteer && \
      sudo dnf install -y oversteer && \
      distrobox-export --app oversteer'

# Install Solaar for Logitech Mice, Keyboards, and Trackpads
install-solaar: distrobox-check-fedora
    distrobox-enter -n fedora -- bash -c 'sudo dnf install -y \
      solaar && \
      distrobox-export --app solaar' && \
    mkdir -p ~/.config/autostart && \
    rm -f ~/.config/autostart/fedora-solaar.desktop && \
    cp ~/.local/share/applications/fedora-solaar.desktop ~/.config/autostart/fedora-solaar.desktop

# Install Resilio Sync, a file synchronization utility powered by BitTorrent
install-resilio-sync: distrobox-check-fedora
    distrobox-enter -n fedora -- 'sudo rpm --import https://linux-packages.resilio.com/resilio-sync/key.asc' && \
    distrobox-enter -n fedora -- 'sudo wget https://raw.githubusercontent.com/ublue-os/bazzite/main/post_install_files/resilio_sync/resilio-sync.repo -O /etc/yum.repos.d/resilio-sync.repo' && \
    distrobox-enter -n fedora -- 'sudo dnf install -y resilio-sync' && \
    mkdir -p ~/.config/systemd/user/ && \
    rm -f ~/.config/systemd/user/fedora-resilio-sync.service && \
    wget https://raw.githubusercontent.com/ublue-os/bazzite/main/post_install_files/resilio_sync/fedora-resilio-sync.service -O ~/.config/systemd/user/fedora-resilio-sync.service && \
    systemctl --user daemon-reload && \
    systemctl enable --user --now fedora-resilio-sync.service

# Install scrcpy, a utility that mirrors Android devices (video and audio) connected via USB or over TCP/IP
install-scrcpy: distrobox-check-fedora
    distrobox enter -n fedora -- bash -c 'sudo dnf copr enable -y zeno/scrcpy && \
      sudo dnf install -y scrcpy && \
      distrobox-export --app scrcpy'

# Install OpenTabletDriver, an open source, cross-platform, user-mode tablet driver
install-opentabletdriver:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    if grep -qvz "arch" <<< $(distrobox list); then \
      Assemble noconfirmcreate "" "arch"; \
    fi && \
    distrobox enter -n arch -- ' paru -S opentabletdriver --noconfirm' && \
    mkdir -p ~/.config/systemd/user/ && \
    rm -f ~/.config/systemd/user/arch-opentabletdriver.service && \
    wget https://raw.githubusercontent.com/ublue-os/bazzite/main/post_install_files/OpenTabletDriver/opentabletdriver.service -O ~/.config/systemd/user/arch-opentabletdriver.service && \
    systemctl --user daemon-reload && \
    systemctl enable --user --now arch-opentabletdriver.service && \
    distrobox enter -n arch -- 'distrobox-export --app otd-gui'

# Add virtual audio channels/sinks named Game, Voice, Browser and Music which you can split audio to using qpwgraph, helvum, carla or other pipewire patchbays for use in OBS and other use cases
setup-virtual-channels:
    #!/bin/bash
    mkdir -p ~/.config/pipewire/pipewire.conf.d
    cat << 'EOL' > ~/.config/pipewire/pipewire.conf.d/virtual-channels.conf
    context.modules = [
        { name = libpipewire-module-loopback
            args = {
                node.description = "Game"
                capture.props = {
                    node.name      = "game_output"
                    media.class    = "Audio/Sink"
                    audio.position = [ FL FR ]
                }
                playback.props = {
                    node.name      = "playback.game_output"
                    audio.position = [ FL FR ]
                    node.passive   = true
                }
            }
        }
        { name = libpipewire-module-loopback
            args = {
                node.description = "Voice"
                capture.props = {
                    node.name      = "voice_output"
                    media.class    = "Audio/Sink"
                    audio.position = [ FL FR ]
                }
                playback.props = {
                    node.name      = "playback.voice_output"
                    audio.position = [ FL FR ]
                    node.passive   = true
                }
            }
        }
        { name = libpipewire-module-loopback
            args = {
                node.description = "Browser"
                capture.props = {
                    node.name      = "browser_output"
                    media.class    = "Audio/Sink"
                    audio.position = [ FL FR ]
                }
                playback.props = {
                    node.name      = "playback.browser_output"
                    audio.position = [ FL FR ]
                    node.passive   = true
                }
            }
        }
        { name = libpipewire-module-loopback
            args = {
                node.description = "Music"
                capture.props = {
                    node.name      = "music_output"
                    media.class    = "Audio/Sink"
                    audio.position = [ FL FR ]
                }
                playback.props = {
                    node.name      = "playback.music_output"
                    audio.position = [ FL FR ]
                    node.passive   = true
                }
            }
        }
    ]
    EOL
    echo "Next time you log in, you will have audio channels for Game, Voice, Browser, Music that you can route game audio to"
    echo "using programs like qpwgraph, helvum or carla."
    echo "You can also add these channels to OBS audio mixer for separate audio control for yourself and your viewers."
    echo "NOTE: It is recommended to mute the virtual channels so you do not have to listen to them twice if you are not exclusively routing the audio through said channel instead of splitting audio to them."

# Remove the virtual audio sinks
remove-virtual-channels:
    rm ~/.config/pipewire/pipewire.conf.d/virtual-channels.conf
    echo "Virtual audio channels config removed, the channels will be removed next time you login."

# Setup a simple Virtual Surround 7.1 sink using the ASH Control Room 1 convolver file (you can change this yourself after setup)
setup-virtual-surround-71:
    #!/bin/bash
    mkdir -p ~/.config/pipewire/pipewire.conf.d
    mkdir -p ~/.config/pipewire/hrir_hesuvi
    echo "Downloading HeSuVi convolver profile Control Room 1 from https://github.com/ShanonPearce/ASH-Listening-Set"
    wget -O ~/.config/pipewire/hrir_hesuvi/Control_Room_1.wav https://github.com/ShanonPearce/ASH-Listening-Set/raw/main/HeSuVi/hrir/_Control_Room_1.wav
    cat << HESUVI > ~/.config/pipewire/pipewire.conf.d/virtual-surround-71.conf
    context.modules = [
        { name = libpipewire-module-filter-chain
            flags = [ nofail ]
            args = {
                node.description = "Virtual Surround 7.1"
                media.name       = "Virtual Surround 7.1"
                filter.graph = {
                    nodes = [
                        # Duplicate inputs
                        { type = builtin label = copy name = copyFL  }
                        { type = builtin label = copy name = copyFR  }
                        { type = builtin label = copy name = copyFC  }
                        { type = builtin label = copy name = copyRL  }
                        { type = builtin label = copy name = copyRR  }
                        { type = builtin label = copy name = copySL  }
                        { type = builtin label = copy name = copySR  }
                        { type = builtin label = copy name = copyLFE }

                        # Apply hrir - HeSuVi 14-channel WAV (not the *-.wav variants) (note: */44/* in HeSuVi are the same, but resampled to 44100)
                        # The file paths HAS to be absolute paths
                        { type = builtin label = convolver name = convFL_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  0 } }
                        { type = builtin label = convolver name = convFL_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  1 } }
                        { type = builtin label = convolver name = convSL_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  2 } }
                        { type = builtin label = convolver name = convSL_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  3 } }
                        { type = builtin label = convolver name = convRL_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  4 } }
                        { type = builtin label = convolver name = convRL_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  5 } }
                        { type = builtin label = convolver name = convFC_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  6 } }
                        { type = builtin label = convolver name = convFR_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  7 } }
                        { type = builtin label = convolver name = convFR_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  8 } }
                        { type = builtin label = convolver name = convSR_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  9 } }
                        { type = builtin label = convolver name = convSR_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel = 10 } }
                        { type = builtin label = convolver name = convRR_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel = 11 } }
                        { type = builtin label = convolver name = convRR_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel = 12 } }
                        { type = builtin label = convolver name = convFC_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel = 13 } }

                        # Treat LFE as FC
                        { type = builtin label = convolver name = convLFE_L config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel =  6 } }
                        { type = builtin label = convolver name = convLFE_R config = { filename = "$HOME/.config/pipewire/hrir_hesuvi/Control_Room_1.wav" channel = 13 } }

                        # Stereo output
                        { type = builtin label = mixer name = mixL }
                        { type = builtin label = mixer name = mixR }
                    ]
                    links = [
                        # Input
                        { output = "copyFL:Out"  input="convFL_L:In"  }
                        { output = "copyFL:Out"  input="convFL_R:In"  }
                        { output = "copySL:Out"  input="convSL_L:In"  }
                        { output = "copySL:Out"  input="convSL_R:In"  }
                        { output = "copyRL:Out"  input="convRL_L:In"  }
                        { output = "copyRL:Out"  input="convRL_R:In"  }
                        { output = "copyFC:Out"  input="convFC_L:In"  }
                        { output = "copyFR:Out"  input="convFR_R:In"  }
                        { output = "copyFR:Out"  input="convFR_L:In"  }
                        { output = "copySR:Out"  input="convSR_R:In"  }
                        { output = "copySR:Out"  input="convSR_L:In"  }
                        { output = "copyRR:Out"  input="convRR_R:In"  }
                        { output = "copyRR:Out"  input="convRR_L:In"  }
                        { output = "copyFC:Out"  input="convFC_R:In"  }
                        { output = "copyLFE:Out" input="convLFE_L:In" }
                        { output = "copyLFE:Out" input="convLFE_R:In" }

                        # Output
                        { output = "convFL_L:Out"  input="mixL:In 1" }
                        { output = "convFL_R:Out"  input="mixR:In 1" }
                        { output = "convSL_L:Out"  input="mixL:In 2" }
                        { output = "convSL_R:Out"  input="mixR:In 2" }
                        { output = "convRL_L:Out"  input="mixL:In 3" }
                        { output = "convRL_R:Out"  input="mixR:In 3" }
                        { output = "convFC_L:Out"  input="mixL:In 4" }
                        { output = "convFC_R:Out"  input="mixR:In 4" }
                        { output = "convFR_R:Out"  input="mixR:In 5" }
                        { output = "convFR_L:Out"  input="mixL:In 5" }
                        { output = "convSR_R:Out"  input="mixR:In 6" }
                        { output = "convSR_L:Out"  input="mixL:In 6" }
                        { output = "convRR_R:Out"  input="mixR:In 7" }
                        { output = "convRR_L:Out"  input="mixL:In 7" }
                        { output = "convLFE_R:Out" input="mixR:In 8" }
                        { output = "convLFE_L:Out" input="mixL:In 8" }
                    ]
                    inputs  = [ "copyFL:In" "copyFR:In" "copyFC:In" "copyLFE:In" "copyRL:In" "copyRR:In", "copySL:In", "copySR:In" ]
                    outputs = [ "mixL:Out" "mixR:Out" ]
                }
                capture.props = {
                    node.name      = "effect_input.virtual-surround-7.1-hesuvi"
                    media.class    = Audio/Sink
                    audio.channels = 8
                    audio.position = [ FL FR FC LFE RL RR SL SR ]
                }
                playback.props = {
                    node.name      = "effect_output.virtual-surround-7.1-hesuvi"
                    node.passive   = true
                    audio.channels = 2
                    audio.position = [ FL FR ]
                }
            }
        }
    ]
    HESUVI
    echo "Virtual Surround 7.1 has now been set up with a basic convolver file, either restart pipewire or reboot for it to take effect."
    echo "Then select the Virtual Surround 7.1 audio output as your default audio output."
    echo "If you want something like DTS, Atmos or OpenAL, you will have to acquire those convolver wav files yourself and edit ~/.config/pipewire/pipewire.conf.d/virtual-surround.conf to point to the one you want to use."

# Remove Virtual Surround 7.1 sink
remove-virtual-surround-71:
    rm ~/.config/pipewire/pipewire.conf.d/virtual-surround-71.conf
    rm ~/.config/pipewire/hrir_hesuvi/Control_Room_1.wav
    echo "Virtual Surround 7.1 removed, please reboot or restart pipewire for it to take effect."

# Restore Bazzite Breeze GTK4 theme (KDE Only)
restore-bazzite-breeze-gtk-theme:
    rm -f $HOME/.config/gtk-4.0/gtk.css
    rm -f $HOME/.config/gtk-4.0/kde_window_geometry.css
    cp /usr/etc/skel/.config/gtk-4.0/gtk.css $HOME/.config/gtk-4.0/gtk.css
    cp /usr/etc/skel/.config/gtk-4.0/kde_window_geometry.css $HOME/.config/gtk-4.0/kde_window_geometry.css

# Blacklist K10 Temp and switch to Zenpower3
switch-to-zenpower:
    sudo bash -c 'sudo echo -e "\n# replaced with zenpower\nblacklist k10temp" >> /etc/modprobe.d/amdcpu.conf'

# Restore Bazzite customized DE settings (GNOME only)
restore-gnome-de-settings:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
      dconf load / < /usr/etc/dconf/db/local.d/02-bazzite-global
      dconf load / < /usr/etc/dconf/db/local.d/03-bazzite-dash
      dconf load / < /usr/etc/dconf/db/local.d/05-bazzite-extensions
      dconf load / < /usr/etc/dconf/db/local.d/06-bazzite-theme
    else
      echo 'This command may only be used on GNOME.'
    fi

# Restore Bazzite customized applications folders (GNOME only)
restore-gnome-folders:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
      dconf load / < /usr/etc/dconf/db/local.d/04-bazzite-folders
    else
      echo 'This command may only be used on GNOME.'
    fi

# Create fedora distrobox if it doesn't exist
[private]
distrobox-check-fedora:
    #!/bin/env bash
    source /usr/lib/ujust/ujust.sh
    if grep -qvz "fedora" <<< $(distrobox list); then
      echo "Setting up Fedora distrobox"
      Assemble noconfirmcreate "" "fedora"
    fi

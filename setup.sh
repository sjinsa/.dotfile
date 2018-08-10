#!/bin/bash

# shellcheck source=./logger.sh
source "$PWD/logger.sh"

is_sudo() {
    if sudo echo; then
        error "This script must be run by root or a sudo'er"
        exit 1
    fi
}

check_os_type() {
    case "${OSTYPE}" in
        linux*)   lsb_release -i | awk -F"\\t" '{print $2}';;
        darwin*)  echo "Mac" ;;
        win*)     echo "Windows" ;;
        cygwin*)  echo "Cygwin" ;;
        bsd*)     echo "Bsd" ;;
        solaris*) echo "Solaris" ;;
        *)        echo "Unknown: $OSTYPE" ;;
    esac
}

program_already_installed() {
    if command -v "$@" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

install_program() {
    local os
    os=$(check_os_type)
    local program_name=$1
    info "you os is ${os}, install ${program_name}"
    if [ "$os" = "Ubuntu" ]; then
        sudo apt install ${program_name}
    elif [ "$os" = "Arch" ]; then
        sudo pacman -Sy ${program_name}
    elif [ "$os" = "Mac" ]; then
        brew list ${program_name} &>/dev/null || brew install ${program_name}
    elif [ "$os" = "CentOS" ]; then
        sudo yum install ${program_name}
    fi
    if [ $? -ne 0 ]; then
        error "${program_name} install failed!"
        exit 1
    fi
    info "${program_name} is install successfully!"
}

bak_file() {
    src_dir="$1"
    filename="$2"
    dst_dir="$3"
    src_file="${src_dir}/${filename}"
    if [ -f "${src_file}" ] || [ -d "${src_file}" ]; then
        info "bak ${src_file} to $dst_dir/${filename}_$(date -d now +%Y%m%d%H%M%S)_dotfile"
        mv "${src_file}" "$dst_dir/${filename}_$(date -d now +%Y%m%d%H%M%S)_dotfile"
    fi
}

install_program_list_required() {
    applist_all_os=( global curl git vim zsh tmux wget cmake python jq tldr shellcheck rlwrap )
    #fix ycm arch bug
    if [ "$(check_os_type)" == "Arch" ]; then
        applist_all_os+=( arch-audit expac ncurses5-compat-libs ctags powerline-fonts the_silver_searcher go )
        applist_all_os+=( alacritty-git alacritty-terminfo-git )
        applist_all_os+=( flake8 yapf python-isort )
    fi

    if [ "$(check_os_type)" == "Ubuntu" ]; then
        applist_all_os+=( exuberant-ctags fonts-powerline silversearcher-ag golang )
    fi

    if [ "$(check_os_type)" == "CentOS" ]; then
        applist_all_os+=( ctags powerline-fonts the_silver_searcher golang )
    fi

    if [ "$(check_os_type)" != "Mac" ]; then
        applist_all_os+=( python-setuptools python-appdirs python-pyparsing python-setuptools python-six python-pip )
        # For tip
        # applist_all_os+=( xmlstarlet pandoc cowsay lolcat xsel )
        # applist_all_os+=( eslint typescript alex )
        # applist_all_os+=( bcc-git bcc-tools-git python-bcc-git sysdig)
        applist_all_os+=( arpwatch sysstat audit rkhunter progress lynis netdata )
        applist_all_os+=( xlockmore progress )

    fi
    install_program "${applist_all_os[*]}"
    if [ "$(check_os_type)" != "Arch" ]; then
        sudo pip install pep8 flake8 pyflakes isort yapf
    fi
    sudo pip install cheat howdoi
}

bak_config() {
    bakdir=~/.bakconfig
    [ -d "${bakdir}" ] || mkdir "${bakdir}"
    bak_file ~ .vimrc "${bakdir}"
    bak_file ~ .zshrc "${bakdir}"
    bak_file ~ .tmux.conf "${bakdir}"
    bak_file ~ .tmux "${bakdir}"
    bak_file ~ .gdbinit "${bakdir}"
    bak_file ~ .oh-my-zsh "${bakdir}"
    bak_file ~ .vim_runtime "${bakdir}"
    bak_file ~ .ssh "${bakdir}"
    bak_file ~/.config/alacritty alacritty.yml "${bakdir}"
    bak_file ~ .fzf_custom.zsh "${bakdir}"
    bak_file ~ .xprofile "${bakdir}"
    bak_file ~ .xinitrc "${bakdir}"
    bak_file ~ .Xresources "${bakdir}"
    bak_file ~ .pacman_cmd.zsh "${bakdir}"
    bak_file ~ .cht.sh "${bakdir}"
    bak_file ~ .fzf-scripts "${bakdir}"
    info "bak all file successfully"
}

install_dotfile() {
    bak_config
    ## alacritty
    if program_already_installed alacritty ; then
        if cp "$PWD/.alacritty.yml" ~/.config/alacritty/alacritty.yml; then
            info "dotfile:alacritty install successfully!"
        else
            error "dotfile:alacritty install failed!"
        fi
    fi

    if [ "$(check_os_type)" == "Arch" ]; then
        #pacman cmd
        cp "$PWD/.pacman_cmd.zsh" ~
        info "dotfile:pacman_cmd install successfully!"
    fi

    ### tmux
    if git clone https://github.com/gpakosz/.tmux.git ~/.tmux; then
        ln -s -f .tmux/.tmux.conf ~/.tmux.conf
        cp "$PWD/.tmux.conf.local" ~
        info "dotfile:tmux.conf install successfully!"
    else
        error "dotfile:zshrc install failed"
    fi

    ### ssh
    [ ! -d ~/.ssh ] && mkdir -p ~/.ssh && cp "$PWD/.sshconfig" ~/.ssh/config
    info "dotfile:ssh config install successfully!"

    ### ideavim
    cp "$PWD/.ideavimrc" ~/.ideavimrc
    info "dotfile:ideavimrc install successfully!"

    ### gdbinit
    if wget -P ~ git.io/.gdbinit; then
        info "dotfile:gdbinit install successfully!"
    else
        info "dotfile:gdbinit install failed!"
    fi

    ## oh-my-zsh
    if git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh; then
        cp "$PWD"/.zshrc ~
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
        info "dotfile:zshrc install successfully!"
    else
        error "dotfile:zshrc install failed!"
    fi

    ## fzf
    cp "$PWD/.fzf_custom.zsh" ~
    if git clone https://github.com/DanielFGray/fzf-scripts.git ~/.fzf-scripts; then
        info "dotfile:fzf_custom install successfully!"
    else
        error "dotfile:fzf_custom install failed!"
    fi

    #Xconfig
    cp "$PWD/.xprofile" ~
    cp "$PWD/.Xresources" ~
    cp "$PWD/.xinitrc" ~
    info "dotfile:xconfig install successfully!"

    #cheat.sh
    mkdir -p ~/.cht.sh/bin
    curl https://cht.sh/:cht.sh > ~/.cht.sh/bin/cht.sh
    chmod u+x ~/.cht.sh/bin/cht.sh
    info "dotfile:cheat.sh install successfully!"

    #切换到zsh
    if sudo chsh -s /bin/zsh; then
        info "change zsh successfully!"
    else
        error "change zsh failed!"
    fi

    ## vim
    if git clone https://github.com/leihuxi/vimrc.git ~/.vim_runtime; then
        sh ~/.vim_runtime/install_awesome_vimrc.sh
        info "dotifile:vimrc install successfully!"
    else
        error "dotfile:vimrc install failed!"
    fi
    info "all installed successfully, Please reboot your shell!"
}

main() {
    #install_required_program
    install_program_list_required
    install_dotfile
}

main

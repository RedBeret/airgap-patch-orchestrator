FROM almalinux:9

RUN dnf -y install openssh-server python3 sudo dnf-utils createrepo_c \
    && dnf clean all \
    && rm -f /etc/ssh/ssh_host_* \
    && useradd --create-home --shell /bin/bash ansible \
    && echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible \
    && chmod 0440 /etc/sudoers.d/ansible \
    && mkdir -p /home/ansible/.ssh

COPY ssh/authorized_keys /home/ansible/.ssh/authorized_keys
RUN chown -R ansible:ansible /home/ansible/.ssh \
    && chmod 0700 /home/ansible/.ssh \
    && chmod 0600 /home/ansible/.ssh/authorized_keys

EXPOSE 22
CMD ["bash", "-lc", "ssh-keygen -A && exec /usr/sbin/sshd -D -e"]

FROM alexagency/centos6-gnome
MAINTAINER Alex

RUN yum -y update && \
    yum -y install xorg-x11-server-utils which prelink git wget tar bzip2 firefox meld && \
    yum clean all && rm -rf /tmp/* && \
    dbus-uuidgen > /var/lib/dbus/machine-id

# JDK x64
ENV JDK_URL http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.rpm
RUN wget -c --no-cookies  --no-check-certificate  --header \
"Cookie: oraclelicense=accept-securebackup-cookie" $JDK_URL -O jdk.rpm && \
    rpm -i jdk.rpm && rm -fv jdk.rpm
# Firefox x64 Java plugin
RUN alternatives --install /usr/lib64/mozilla/plugins/libjavaplugin.so libjavaplugin.so.x86_64 \
    /usr/java/latest/jre/lib/amd64/libnpjp2.so 200000
# Visual VM
RUN echo -e "\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Visual VM\n\
Comment=Visual VM\n\
Exec=/usr/java/latest/bin/jvisualvm\n\
Icon=gnome-panel-fish\n\
Categories=Application;Development;Java\n\
Version=1.0\n\
Type=Application\n\
Terminal=0"\
>> /usr/share/applications/jvisualvm.desktop

# Sublime Text 3
ENV SUBLIME_URL http://c758482.r82.cf2.rackcdn.com/sublime_text_3_build_3083_x64.tar.bz2
RUN wget $SUBLIME_URL && \
    tar -vxjf `echo "${SUBLIME_URL##*/}"` -C /usr && \
    ln -s /usr/sublime_text_3/sublime_text /usr/bin/sublime3 && \
    rm -f `echo "${SUBLIME_URL##*/}"` && \
echo -e "\
[Desktop Entry]\n\
Name=Sublime 3\n\
Exec=sublime3\n\
Terminal=false\n\
Icon=/usr/sublime_text_3/Icon/48x48/sublime-text.png\n\
Type=Application\n\
Categories=TextEditor;IDE;Development\n\
X-Ayatana-Desktop-Shortcuts=NewWindow\n\
[NewWindow Shortcut Group]\n\
Name=New Window\n\
Exec=sublime -n\n\
TargetEnvironment=Unity"\
>> /usr/share/applications/sublime3.desktop && \
    mkdir /root/.config && \
    touch /root/.config/sublime-text-3 && \
    chown -R root:root /root/.config/sublime-text-3 && \
    sed -i 's@gedit.desktop@gedit.desktop;sublime3.desktop@g' /usr/share/applications/defaults.list

# Eclipse Luna x64
ENV ECLIPSE_URL http://ftp.fau.de/eclipse/technology/epp/downloads/\
release/mars/1/eclipse-jee-mars-1-linux-gtk-x86_64.tar.gz
RUN wget $ECLIPSE_URL && \
    tar -zxvf `echo "${ECLIPSE_URL##*/}"` -C /usr/ && \
    ln -s /usr/eclipse/eclipse /usr/bin/eclipse && \
    rm -f `echo "${ECLIPSE_URL##*/}"` && \
    sed -i s@-vmargs@-vm\\n/usr/java/latest/jre/bin/java\\n-vmargs@g /usr/eclipse/eclipse.ini

# Configure profile
RUN echo "xhost +" >> /home/user/.bashrc && \
    echo "alias install='sudo yum install'" >> /home/user/.bashrc && \
    echo "alias docker='sudo docker'" >> /home/user/.bashrc && \
    echo -e '\
alias dockerX11run="docker run -ti --rm \
--add-host=localhost:`hostname --ip-address` \
-e DISPLAY=`hostname --ip-address`$DISPLAY" '\
>> /home/user/.bashrc && \
    echo -e '\n\
X86_HOSTMANE=`hostname`-x86 \n\
X86_RUNNING=$(docker inspect -f {{.State.Running}} $X86_HOSTMANE 2> /dev/null) \n\
if [ "$X86_RUNNING" == "true" ]; then \n\
    alias workstation-x86="docker exec -ti $X86_HOSTMANE" \n\
else \n\
    alias workstation-x86="dockerX11run \
--hostname $X86_HOSTMANE \
--name $X86_HOSTMANE \
--link `hostname`:$X86_HOSTMANE \
-v /shared/Downloads:/home/user/Downloads \
alexagency/centos6-workstation-x86" \n\
fi \n '\
>> /home/user/.bashrc && \
    shopt -s expand_aliases

# Firefox x86
RUN echo -e '\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Firefox x86\n\
Exec=sh -c "source /home/user/.bashrc;eval workstation-x86 firefox"\n\
Icon=gnome-panel-fish\n\
Terminal=true\n\
Type=Application\n\
Categories=Network;WebBrowser;'\
>> /usr/share/applications/firefox-x86.desktop

# Eclipse x86
RUN echo -e '\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Eclipse x86\n\
Comment=Eclipse\n\
Exec=sh -c "source /home/user/.bashrc;eval workstation-x86 eclipse"\n\
Icon=/usr/eclipse/icon.xpm\n\
Categories=Application;Development;Java;IDE\n\
Version=1.0\n\
Type=Application\n\
Terminal=true'\
>> /usr/share/applications/eclipse-x86.desktop

# Visual VM x86
RUN echo -e '\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Visual VM x86\n\
Comment=Visual VM\n\
Exec=sh -c "source /home/user/.bashrc;eval /usr/java/latest/bin/jvisualvm"\n\
Icon=gnome-panel-fish\n\
Categories=Application;Development;Java\n\
Version=1.0\n\
Type=Application\n\
Terminal=true'\
>> /usr/share/applications/jvisualvm-x86.desktop

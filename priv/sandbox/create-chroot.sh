#!/bin/bash
# script to automate the creation of chroot jail
# w/ minimal executables to run git

export CHROOT=/var/chroot

function copy_binary() {
    for i in $(ldd $*|grep -v dynamic|cut -d " " -f 3|sed 's/://'|sort|uniq)
      do
        cp --parents $i $CHROOT
      done

    # ARCH amd64
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
       cp --parents /lib64/ld-linux-x86-64.so.2 $CHROOT
    fi

    # ARCH i386
    if [ -f  /lib/ld-linux.so.2 ]; then
       cp --parents /lib/ld-linux.so.2 $CHROOT
    fi
}

# setup directory layout
mkdir $CHROOT
mkdir -p $CHROOT/{dev,etc,home,tmp,proc,root,var}

# setup device
mknod $CHROOT/dev/null c 1 3
mknod $CHROOT/dev/zero c 1 5
mknod $CHROOT/dev/tty  c 5 0
mknod $CHROOT/dev/random c 1 8
mknod $CHROOT/dev/urandom c 1 9
chmod 0666 $CHROOT/dev/{null,tty,zero}
chown root.tty $CHROOT/dev/tty

# copy programs and libraries
copy_binary /bin/{ls,cp,rm,mkdir,ln,sed} /usr/bin/{head,tail,which,id,find,xargs} `which python3` /usr/lib/x86_64-linux-gnu/libffi.so.8 /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libsqlite3.so.0

# copy basic system level files
cp --parents /etc/nsswitch.conf $CHROOT
cp --parents /etc/resolv.conf $CHROOT
cp --parents /etc/hosts $CHROOT
cp -r --parents /usr/share/terminfo $CHROOT
cp -r --parents /usr/lib/python3.9 $CHROOT
cp -r --parents /usr/lib/python3.9/lib-dynload/* $CHROOT
cp -r --parents /usr/local/lib/python3.9/dist-packages/* $CHROOT
cp -r --parents /usr/local/lib/python3.9/dist-packages/**/* $CHROOT
cp -r --parents /usr/lib/python3/dist-packages/**/* $CHROOT
cp -r --parents /usr/lib/python3.9/dist-packages/**/* $CHROOT
cp -r --parents /usr/lib/python3/dist-packages/* /var/chroot//usr/lib/python3/dist-packages/
cp -r --parents /usr/local/share/ca-certificates/ $CHROOT
cp -r --parents /usr/lib/ssl/certs/ $CHROOT
cp -r --parents /etc/ssl/certs $CHROOT
echo "chroot jail is created. type: chroot $CHROOT to access it"

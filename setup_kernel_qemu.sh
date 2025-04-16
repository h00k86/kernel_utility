


function download_kernel(){
  git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
}


function compile_kernel(){
  cd linux
  make O=OUTPUTDIR defconfig
  make O=OUTPUTDIR -j$(nproc)
  cd ..
}



function create_ramdiskimg(){

  create_hd_kernel
  mkinitcpio -g ramdisk.img

  cd ../../../../../
 
  echo "mi trovo in $(pwd)"
}

function create_hd_kernel(){

  cd linux/OUTPUTDIR/arch/x86_64/boot

  qemu-img create -f raw rootfs.img 1G
  mkfs.ext4 rootfs.img
}


function mount_rootfs() {
    mount -o loop rootfs.img /mnt/rootfs
    echo "Filesystem root montato con successo!"
}

# Creare /sbin/init e altri file necessari
function setup_init() {
    echo "Configurando il sistema root..."

    # Creare una directory di base
    mkdir -p /mnt/rootfs/bin /mnt/rootfs/sbin /mnt/rootfs/etc/init.d

    # Copiare BusyBox
    cp /usr/bin/busybox /mnt/rootfs/bin/busybox
    ln -s /bin/busybox /mnt/rootfs/sbin/init
    ln -s /bin/busybox /mnt/rootfs/bin/sh
    chmod +x /mnt/rootfs/sbin/init


    mkdir -p /mnt/rootfs/dev
    mknod /mnt/rootfs/dev/tty5 c 4 5

    # Creare uno script di inizializzazione di base
    echo -e "#!/bin/sh" >> /mnt/rootfs/etc/init.d/rcS
    echo -e "/bin/sh"   >> /mnt/rootfs/etc/init.d/rcS
    chmod +x /mnt/rootfs/etc/init.d/rcS
    echo -e "/dev/sda / ext4 defaults 0 1" > /mnt/rootfs/etc/fstab
    echo "Sistema root configurato!"
}

# Smontare il filesystem
function unmount_rootfs() {
    umount /mnt/rootfs
    echo "Filesystem smontato!"
}










function start_qemu(){
  qemu-system-x86_64 -kernel bzImage -initrd ramdisk.img -drive file=rootfs.img,format=raw -append "root=/dev/sda rw console=ttyS0 console=tty0 init=/sbin/init " -vga  std  -m 4048 -S -gdb tcp::1234 

}


function main(){
  mount_rootfs 
  setup_init
  unmount_rootfs
}


function help(){
    echo """Usage: ./setup_kernel_qemu COMMAND 
    help    : show this info
    compile : compile kernel with default config
    create  : create ram disk
    build   : NEED TO BE ROOT. Build the rootfs and init file
    start   : start qemu vm"""
}


function command(){

  if [ "$1" == "help" ] ; then
    help

  elif [ "$1" == "compile" ]; then
    compile_kernel

  
  elif [ "$1" == "build" ]; then
    main
  elif [ "$1" == "create" ]; then
    create_ramdiskimg
  elif [ "$1" == "start" ];then
    start_qemu 
  else
    echo "ERROR, COMMAND $1 didnt recognize, try again"
    help
  fi
}


command $1

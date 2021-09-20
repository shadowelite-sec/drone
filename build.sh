#!/usr/bin/env bash

# @shadowelite personal kernel build script, for whyred newcam



wd=$(pwd)
out=$wd"/out"
config="whyred-nh-newcam_defconfig"
KERNEL_DIR=$wd
ANYKERNEL_DIR="/AnyKernel3"
IMG=$out"/arch/arm64/boot/Image.gz-dtb"
DATE="`date +%d%m%Y-%aH%M%S`"
grp_chat_id="-503257964"
chat_id="872750064"
token="1255724852:AAEHO-nozQbC2WFaI5WsvVht_p_WeFzTIv0"
TC=/usr/bin/aarch64-linux-gnu-gcc

function path_clang()
{
        export ARCH=arm64

        export SUBARCH=arm64

        export CC=clang

        export CLANG_PATH="/usr/bin"

        export CLANG TRIPLE=aarch64-linux-gnu-

        export CROSS_COMPILE="/usr/bin/aarch64-linux-gnu-"

        export CROSS_COMPILE_ARM32="/usr/bin/arm-linux-gnueabi-"
}


function build_clang()
{
	path_clang

        tg_inform

	make clean mrproper
        make CC=clang O="${out}" clean
        make CC=clang O="${out}" mrproper
        rm -rf "${out}"
        sleep 0.2
        mkdir out
        make CC=clang O="${out}" "${config}"

	tg_menu
        make CC=clang O="${out}" menuconfig

	tg_started
        BUILD_START=$(date +"%s")
        make CC=clang O="${out}" -j"$(nproc --all)" 2>&1 | tee "${out}"/build.log

	#modules
	make CC=clang O="${out}" modules_install INSTALL_MOD_PATH=modules_out

        BUILD_END=$(date +"%s")
        DIFF=$(($BUILD_END - $BUILD_START))

        if [ -f "${IMG}" ]; then
                echo -e "Build completed in $(($DIFF / 60)) minutse(s) and $(($DIFF % 60)) second(s)."
                flash_zip

        else
		#tg_push_log
                tg_push_error
		#clear
                echo "Build failed, please fix the errors first ! "
		#cat "${out}"/build.log
        fi
}

function flash_zip()
{
    echo -e "Now making a flashable zip of kernel with AnyKernel3"

    tg_ziping

    export ZIPNAME=ShadowElite-Nethunter-Newcam-$DATE.zip

    # Checkout anykernel3 dir
    cd "$ANYKERNEL_DIR"

    # Cleanup and copy Image.gz-dtb to dir.
    rm -f ShadowElite-*.zip
    rm -f Image.gz-dtb

    #copy modules
    cp -r $out/modules_out/* $ANYKERNEL_DIR/modules/

    # Copy Image.gz-dtb to dir.
    cp $out/arch/arm64/boot/Image.gz-dtb ${ANYKERNEL_DIR}/
    rm $ANYKERNEL_DIR/modules/lib/modules/*/source
    rm $ANYKERNEL_DIR/modules/lib/modules/*/build

    # Build a flashable zip
    zip -r9 $ZIPNAME *
    MD5=$(md5sum ShadowElite-*.zip | cut -d' ' -f1)
    tg_sending
    tg_push
}

function tg_menu()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>Making menuconfig ... .</b>"
}

function tg_started()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b> 🔨 Build Started .....</b>"
}

function tg_inform()
{
        curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>⚒️ New CI build has been triggered"'!'" ⚒️</b>%0A%0A<b>Linux Version • </b><code>$(make kernelversion)</code>%0A<b>Compiler • </b><code>$(${TC} --version --version | head -n 1)</code>%0A<b>At • </b><code>$(TZ=Asia/Kolkata date)</code>%0A"  
}

function tg_push()
{
    ZIP="${ANYKERNEL_DIR}"/$(echo ShadowElite-*.zip)
    curl -F document=@"${ZIP}" "https://api.telegram.org/bot${token}/sendDocument" \
      -F chat_id="$chat_id" \
      -F "disable_web_page_preview=true" \
      -F "parse_mode=html" \
            -F caption="🛠️ Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | <b>MD5 checksum</b> • <code>${MD5}</code>"
}

function tg_push_error()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>❌ Build failed after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s).</b>"
}

function tg_push_log()
{
    LOG=$out/build.log
  curl -F document=@"${LOG}" "https://api.telegram.org/bot$token/sendDocument" \
      -F chat_id="$chat_id" \
      -F "disable_web_page_preview=true" \
      -F "parse_mode=html" \
            -F caption="🛠️ Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). @shadowelite"
}

function tg_ziping()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b> Building flashable zip ....</b>"
}

function tg_sending()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>Sending flashable zip wait ...</b>"
}

# Start Build (build_clang or build_gcc)
build_clang
# build_gcc
# Post build logs
tg_push_log

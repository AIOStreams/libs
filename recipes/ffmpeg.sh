mkdir -p $build_dir && cd $build_dir
# What no stream carries: game and console media, screen and webcam capture, telephony,
# rare stills, text-mode art and editing intermediates.
decoders=(
	anm argo avs bethsoftvid bfi bink 'binkaudio_*' 'bmv_*' c93 cdtoons cdxl cri dfa 'dsicin*' dxa
	eacmv eamad eatgq eatgv eatqi escape124 escape130 flic fourxm gdv hca hnm4_video idcin 'interplay_*'
	ipu jv kgv1 kmvc mdec mmvideo mobiclip motionpixels mvdv mvha 'paf_*' pdv rl2 roq sanm sga
	simbiosis_imx smackaud smacker thp tiertexseqvideo tmv 'truemotion*' txd 'vmd*' vqa vqc ws_snd1
	'xan_*' yop atrac9 xma1 xma2 ahx '*_dpcm'
	adpcm_4xm adpcm_adx adpcm_afc adpcm_agm adpcm_aica adpcm_argo adpcm_circus adpcm_dtk 'adpcm_ea*'
	adpcm_ima_acorn adpcm_ima_alp adpcm_ima_apc adpcm_ima_apm adpcm_ima_cunning 'adpcm_ima_ea_*'
	adpcm_ima_escape 'adpcm_ima_hvqm*' adpcm_ima_iss adpcm_ima_moflex adpcm_ima_mtf adpcm_ima_pda
	adpcm_ima_rad adpcm_ima_ssi adpcm_ima_ws adpcm_ima_xbox adpcm_mtaf adpcm_n64 'adpcm_psx*'
	'adpcm_thp*' adpcm_vima adpcm_xa adpcm_xmd adpcm_zork
	arbc cscd dxtory fic fmvc fraps g2m lscr mscc mwsc rasc rscc scpr screenpresso srgc tdsc vmix vmnc
	wcmv zmbv mimic cpia mxpeg
	acelp_kelvin dss_sp g723_1 g728 g729 ilbc metasound misc4 msnsiren siren truespeech
	twinvq wmavoice dfpwm sbc 'aptx*'
	apac bonk dolby_e fastaudio ftr hcom on2avc osq qoa ralf rka wavarc
	alias_pix brender_pix dds dpx exr fits gem hdr pam pbm pcx pfm pgm pgmyuv pgx phm photocd pictor
	ppm psd ptx qoi sgi sgirle sunrast vbn wbmp xbm xpm xwd xface
	ansi bintext idf xbin
	cllc dxv hap hq_hqa hqx 'imm*' media100 notchlc pixlet prosumer sheervideo mvc1 mvc2
	aura aura2 cyuv lead qpeg rtv1 ulti vcr1 wnv1 xl snow ffwavesynth smvjpeg
)
demuxers=(
	adp ads adx afc aix alp anm apc apm 'argo_*' ast avs bethsoftvid bfi bfstm bink binka bmv boa brstm
	c93 cdxl dcstr derf dfa dsicin dxa ea ea_cdata fourxm flic fsb fwse gdv genh hca hnm idcin ipmovie
	ipu iss jv kvag mca mgsts mm mods moflex msf mtaf musx mvi paf pdv pp_bnk rl2 roq rpl rsd scd sdns
	segafilm sga siff simbiosis_imx smacker smush sol str svag svs thp threedostr tiertexseq tmv txd usm
	vag vmd voc vpk wady wc3 wsaud wsvqa xa xmd xmv xvag xwma yop
	cine dhav hxvs ifv ingenient iv8 lmlm4 luodat lvf mlv msnwc_tcp mxg nc r3d ser
	act bit dss g723_1 g728 g729 ilbc nistsphere nsp pvf sbc sdr2 sln dfpwm 'aptx*'
	adf apac avr bintext bonk epaf filmstrip fits frm hcom idf ircam ktx laf msp mtv mv osq qoa
	redspark rka rso sbg sds sdx sox tty vividas vivo wavarc wve xbin
	image2_alias_pix image2_brender_pix image_cri_pipe image_dds_pipe image_dpx_pipe image_exr_pipe
	image_gem_pipe image_hdr_pipe image_pam_pipe image_pbm_pipe image_pcx_pipe image_pfm_pipe
	image_pgm_pipe image_pgmyuv_pipe image_pgx_pipe image_phm_pipe image_photocd_pipe image_pictor_pipe
	image_ppm_pipe image_psd_pipe image_qdraw_pipe image_qoi_pipe image_rw2_pipe image_sgi_pipe
	image_sunrast_pipe image_vbn_pipe image_xbm_pipe image_xpm_pipe image_xwd_pipe
)
args=(
	--enable-cross-compile --cc="$CC" --pkg-config=pkg-config
	--disable-static --enable-shared --enable-{gpl,version3} --disable-{doc,programs}
	--disable-{encoders,devices,muxers}
	# for screenshots, and AC-3 to re-encode surround sound for S/PDIF
	--enable-encoder=mjpeg,png,ac3
	# for S/PDIF, and what --stream-record writes
	--enable-muxer=spdif,matroska,webm,mov,mp4,mpegts,ogg
	"--disable-decoder=$(IFS=,; echo "${decoders[*]}")"
	"--disable-demuxer=$(IFS=,; echo "${demuxers[*]}")"
	--enable-{libdav1d,libxml2} --disable-vulkan
)
case $platform in
	android)
		cpu=armv7-a cflags=
		case $host in
			arm*) cflags="-mfpu=neon -mcpu=cortex-a8" ;;
			aarch64*) cpu=armv8-a ;;
			x86_64*) cpu=generic ;;
			i686*) cpu="i686 --disable-asm" ;;
		esac
		args+=(
			--target-os=android --cross-prefix=$host- --nm=llvm-nm --arch=${host%%-*} --cpu=$cpu
			--extra-cflags="-I$prefix_dir/include $cflags" --extra-ldflags="-L$prefix_dir/lib"
			--enable-{jni,mediacodec,mbedtls} --disable-stripping
		)
		;;
	windows)
		args+=(
			--target-os=mingw32 --cross-prefix=$host- --arch=$arch --pkg-config-flags=--static
			--enable-{zlib,ffnvcodec,nvdec} --disable-avdevice
			# the one part needing C++
			--disable-filter=gfxcapture
		)
		;;
	macos)
		args+=(
			--target-os=darwin --arch=$arch --pkg-config-flags=--static
			--enable-{videotoolbox,audiotoolbox,securetransport} --disable-avdevice
			--extra-cflags="$(pkg-config --cflags dovi)" --extra-libs="$(pkg-config --libs --static dovi)"
			# room for the packaging's install names
			--extra-ldflags=-Wl,-headerpad_max_install_names
			# make install can relink, which would put DESTDIR in the names
			--install-name-dir=/usr/local/lib
		)
		;;
esac
# The AC-3 encoder queues its frames, which configure doesn't select for it.
grep -q '^ac3_encoder_select=.*audio_frame_queue' ../configure ||
	${SED:-sed} -i 's/^ac3_encoder_select="/&audio_frame_queue /' ../configure
../configure "${args[@]}"
make -j$cores
make DESTDIR="$dest" install

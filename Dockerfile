FROM debian:bookworm

ARG git_delta_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG DELTA_RELEASE
ARG DELTA_SRC
ARG DELTA_DEPENDS

RUN mkdir -p /output/DEBIAN

# Upstream's .deb, extracted by build_debian.sh: only usr/bin/delta is kept
# (its doc directory is replaced by ours below)
COPY ${DELTA_RELEASE}/usr/bin/delta /output/usr/bin/delta
RUN chmod 755 /output/usr/bin/delta

# Shell completions and the themes helper, from upstream's source at the same
# tag. themes.gitconfig sits where Debian's own git-delta puts it (a conffile in
# /etc/delta, symlinked from /usr/share/delta), so a git config that includes
# either path keeps working after switching packages.
COPY ${DELTA_SRC}/etc/completion/completion.bash /output/usr/share/bash-completion/completions/delta
COPY ${DELTA_SRC}/etc/completion/completion.zsh /output/usr/share/zsh/vendor-completions/_delta
COPY ${DELTA_SRC}/etc/completion/completion.fish /output/usr/share/fish/vendor_completions.d/delta.fish
COPY ${DELTA_SRC}/themes.gitconfig /output/etc/delta/themes.gitconfig
RUN mkdir -p /output/usr/share/delta && ln -s /etc/delta/themes.gitconfig /output/usr/share/delta/themes.gitconfig
RUN mkdir -p /output/usr/share/doc/git-delta

COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/conffiles /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/git-delta/
COPY output/changelog.Debian /output/usr/share/doc/git-delta/
COPY output/README.md /output/usr/share/doc/git-delta/

RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/git-delta/changelog.Debian
RUN sed -i "s/git_delta_VERSION/$git_delta_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control
RUN sed -i "s/DELTA_DEPENDS/$DELTA_DEPENDS/" /output/DEBIAN/control

# Normalise modes: COPY keeps the build host's (a 002 umask makes files group-writable)
RUN chmod -R u=rwX,go=rX /output && chmod 755 /output/usr/bin/delta /output/DEBIAN/postinst

RUN dpkg-deb -Zxz --build /output /git-delta_${FULL_VERSION}.deb

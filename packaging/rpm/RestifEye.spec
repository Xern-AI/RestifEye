# Binary RPM built in CI from the prebuilt Flutter bundle.
# (A from-source spec for COPR is planned post-1.0.)
%global debug_package %{nil}
%global __strip /bin/true

# Fallback for distros that don't define _metainfodir (e.g. Ubuntu rpmbuild).
%{!?_metainfodir:%global _metainfodir %{_datadir}/metainfo}

Name:           RestifEye
Version:        %{?pkg_version}%{!?pkg_version:0.1.0}
Release:        1%{?dist}
Summary:        Break reminders that respect your flow
License:        LicenseRef-PolyForm-Shield-1.0.0
URL:            https://github.com/Xern-AI/restifeye
Source0:        RestifEye-bundle.tar.gz
BuildArch:      x86_64
Requires:       gtk3, pipewire-utils

%description
RestifEye reminds you to rest your eyes and move at healthy intervals.
It defers breaks during calls, credits breaks you take on your own,
warns before taking the screen, and shows an illustrated exercise with
every break. Local-only analytics and advice. No telemetry.

%prep
%setup -q -c

%install
mkdir -p %{buildroot}/opt/RestifEye
cp -r bundle/* %{buildroot}/opt/RestifEye/
mkdir -p %{buildroot}%{_bindir}
ln -s /opt/RestifEye/RestifEye %{buildroot}%{_bindir}/RestifEye
install -Dm644 assets/com.xernai.restifeye.desktop \
  %{buildroot}%{_datadir}/applications/com.xernai.restifeye.desktop
install -Dm644 assets/com.xernai.restifeye.svg \
  %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/com.xernai.restifeye.svg
install -Dm644 assets/com.xernai.restifeye.metainfo.xml \
  %{buildroot}%{_metainfodir}/com.xernai.restifeye.metainfo.xml

%files
/opt/RestifEye
%{_bindir}/RestifEye
%{_datadir}/applications/com.xernai.restifeye.desktop
%{_datadir}/icons/hicolor/scalable/apps/com.xernai.restifeye.svg
%{_metainfodir}/com.xernai.restifeye.metainfo.xml

%changelog
* Mon Jul 13 2026 Xernai <xernaitech@gmail.com> - 0.1.0-1
- Initial release

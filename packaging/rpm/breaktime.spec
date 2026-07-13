# Binary RPM built in CI from the prebuilt Flutter bundle.
# (A from-source spec for COPR is planned post-1.0.)
%global debug_package %{nil}
%global __strip /bin/true

Name:           breaktime
Version:        %{?pkg_version}%{!?pkg_version:0.1.0}
Release:        1%{?dist}
Summary:        Break reminders that respect your flow
License:        GPL-3.0-or-later
URL:            https://github.com/xernai/breaktime
Source0:        breaktime-bundle.tar.gz
BuildArch:      x86_64
Requires:       gtk3, pipewire-utils

%description
BreakTime reminds you to rest your eyes and move at healthy intervals.
It defers breaks during calls, credits breaks you take on your own,
warns before taking the screen, and shows an illustrated exercise with
every break. Local-only analytics and advice. No telemetry.

%prep
%setup -q -c

%install
mkdir -p %{buildroot}/opt/breaktime
cp -r bundle/* %{buildroot}/opt/breaktime/
mkdir -p %{buildroot}%{_bindir}
ln -s /opt/breaktime/breaktime %{buildroot}%{_bindir}/breaktime
install -Dm644 assets/com.xernai.breaktime.desktop \
  %{buildroot}%{_datadir}/applications/com.xernai.breaktime.desktop
install -Dm644 assets/com.xernai.breaktime.svg \
  %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/com.xernai.breaktime.svg
install -Dm644 assets/com.xernai.breaktime.metainfo.xml \
  %{buildroot}%{_metainfodir}/com.xernai.breaktime.metainfo.xml

%files
/opt/breaktime
%{_bindir}/breaktime
%{_datadir}/applications/com.xernai.breaktime.desktop
%{_datadir}/icons/hicolor/scalable/apps/com.xernai.breaktime.svg
%{_metainfodir}/com.xernai.breaktime.metainfo.xml

%changelog
* Mon Jul 13 2026 Xernai <breaktime@xernai.dev> - 0.1.0-1
- Initial release

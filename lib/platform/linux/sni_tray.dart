import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

import '../interfaces/tray_indicator.dart';

/// StatusNotifierItem tray icon implemented directly over D-Bus — no native
/// appindicator libraries needed, which keeps the AppImage dependency-free.
///
/// Works out of the box on KDE, XFCE, Cinnamon and MATE. GNOME needs the
/// AppIndicator extension; without a StatusNotifierWatcher on the bus this
/// class idles silently and re-registers if one appears later.
class SniTrayIndicator implements TrayIndicator {
  SniTrayIndicator(this._bus);

  static const _watcherName = 'org.kde.StatusNotifierWatcher';

  final DBusClient _bus;
  final _actions = StreamController<TrayAction>.broadcast();

  _SniItemObject? _item;
  _DbusMenuObject? _menu;
  StreamSubscription<DBusSignal>? _watcherSub;
  bool _registeredWithWatcher = false;

  @override
  Stream<TrayAction> get actions => _actions.stream;

  @override
  Future<void> init({required List<TrayPixmap> icons}) async {
    _item = _SniItemObject(icons: icons, onActivate: () => _emit(TrayAction.open));
    _menu = _DbusMenuObject(onSelect: _emit);
    await _bus.registerObject(_item!);
    await _bus.registerObject(_menu!);

    // libappindicator convention; hosts also accept plain unique names.
    await _bus.requestName('org.kde.StatusNotifierItem-$pid-1');

    // The watcher (shell/extension) can restart or appear late; re-register
    // whenever it gains an owner.
    final ownerChanges = DBusSignalStream(
      _bus,
      sender: 'org.freedesktop.DBus',
      interface: 'org.freedesktop.DBus',
      name: 'NameOwnerChanged',
      signature: DBusSignature('sss'),
    );
    _watcherSub = ownerChanges.listen((signal) {
      if (signal.values[0].asString() != _watcherName) return;
      _registeredWithWatcher = false;
      if (signal.values[2].asString().isNotEmpty) {
        unawaited(_registerWithWatcher());
      }
    }, onError: (Object _) {});

    await _registerWithWatcher();
  }

  Future<void> _registerWithWatcher() async {
    if (_registeredWithWatcher) return;
    try {
      final watcher = DBusRemoteObject(
        _bus,
        name: _watcherName,
        path: DBusObjectPath('/StatusNotifierWatcher'),
      );
      await watcher.callMethod(_watcherName, 'RegisterStatusNotifierItem', [
        DBusString(_bus.uniqueName),
      ], replySignature: DBusSignature(''));
      _registeredWithWatcher = true;
    } on Exception {
      // No status area on this desktop right now (or a bus hiccup) — stay
      // dormant; the NameOwnerChanged listener retries when a host appears.
    }
  }

  void _emit(TrayAction action) {
    if (!_actions.isClosed) _actions.add(action);
  }

  @override
  Future<void> setPaused(bool paused) async => _menu?.setPaused(paused);

  @override
  Future<void> dispose() async {
    await _watcherSub?.cancel();
    final item = _item;
    if (item != null) await _bus.unregisterObject(item);
    final menu = _menu;
    if (menu != null) await _bus.unregisterObject(menu);
    await _actions.close();
  }
}

/// org.kde.StatusNotifierItem at /StatusNotifierItem.
class _SniItemObject extends DBusObject {
  _SniItemObject({required this.icons, required this.onActivate})
    : super(DBusObjectPath('/StatusNotifierItem'));

  static const _iface = 'org.kde.StatusNotifierItem';

  final List<TrayPixmap> icons;
  final void Function() onActivate;

  DBusValue get _pixmaps => DBusArray(
    DBusSignature('(iiay)'),
    icons.map(
      (p) => DBusStruct([
        DBusInt32(p.width),
        DBusInt32(p.height),
        DBusArray.byte(p.argb32),
      ]),
    ),
  );

  Map<String, DBusValue> get _properties => {
    'Category': const DBusString('ApplicationStatus'),
    'Id': const DBusString('com.xernai.breaktime'),
    'Title': const DBusString('BreakTime'),
    'Status': const DBusString('Active'),
    'WindowId': const DBusUint32(0),
    'IconName': const DBusString('com.xernai.breaktime'),
    'IconPixmap': _pixmaps,
    'OverlayIconName': const DBusString(''),
    'OverlayIconPixmap': DBusArray(DBusSignature('(iiay)'), const []),
    'AttentionIconName': const DBusString(''),
    'AttentionIconPixmap': DBusArray(DBusSignature('(iiay)'), const []),
    'AttentionMovieName': const DBusString(''),
    'ToolTip': DBusStruct([
      const DBusString(''),
      DBusArray(DBusSignature('(iiay)'), const []),
      const DBusString('BreakTime'),
      const DBusString('Running — breaks on schedule'),
    ]),
    'ItemIsMenu': const DBusBoolean(false),
    'Menu': DBusObjectPath('/MenuBar'),
  };

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface != _iface) return DBusMethodErrorResponse.unknownInterface();
    final value = _properties[name];
    if (value == null) return DBusMethodErrorResponse.unknownProperty();
    return DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async =>
      DBusGetAllPropertiesResponse(interface == _iface ? _properties : {});

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != _iface) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    switch (methodCall.name) {
      case 'Activate':
      case 'SecondaryActivate':
        onActivate();
        return DBusMethodSuccessResponse();
      case 'ContextMenu':
      case 'Scroll':
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

/// com.canonical.dbusmenu at /MenuBar: Open / Pause / Quit.
class _DbusMenuObject extends DBusObject {
  _DbusMenuObject({required this.onSelect})
    : super(DBusObjectPath('/MenuBar'));

  static const _iface = 'com.canonical.dbusmenu';
  static const _idRoot = 0;
  static const _idOpen = 1;
  static const _idPause = 2;
  static const _idSeparator = 3;
  static const _idQuit = 4;

  final void Function(TrayAction) onSelect;

  bool _paused = false;
  int _revision = 1;

  void setPaused(bool paused) {
    if (_paused == paused) return;
    _paused = paused;
    _revision += 1;
    unawaited(
      emitSignal(_iface, 'LayoutUpdated', [
        DBusUint32(_revision),
        const DBusInt32(_idRoot),
      ]),
    );
  }

  Map<String, DBusValue> _itemProps(int id) => switch (id) {
    _idRoot => {'children-display': const DBusString('submenu')},
    _idOpen => {'label': const DBusString('Open BreakTime')},
    _idPause => {
      'label': DBusString(_paused ? 'Resume breaks' : 'Pause breaks'),
    },
    _idSeparator => {'type': const DBusString('separator')},
    _idQuit => {'label': const DBusString('Quit BreakTime')},
    _ => {},
  };

  DBusStruct _layoutFor(int id) => DBusStruct([
    DBusInt32(id),
    DBusDict.stringVariant(_itemProps(id)),
    DBusArray.variant(
      id == _idRoot
          ? [
              _layoutFor(_idOpen),
              _layoutFor(_idPause),
              _layoutFor(_idSeparator),
              _layoutFor(_idQuit),
            ]
          : const [],
    ),
  ]);

  void _handleEvent(int id, String eventId) {
    if (eventId != 'clicked') return;
    switch (id) {
      case _idOpen:
        onSelect(TrayAction.open);
      case _idPause:
        onSelect(TrayAction.togglePause);
      case _idQuit:
        onSelect(TrayAction.quit);
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface != _iface) return DBusMethodErrorResponse.unknownInterface();
    return switch (name) {
      'Version' => DBusGetPropertyResponse(const DBusUint32(3)),
      'Status' => DBusGetPropertyResponse(const DBusString('normal')),
      'TextDirection' => DBusGetPropertyResponse(const DBusString('ltr')),
      'IconThemePath' => DBusGetPropertyResponse(DBusArray.string(const [])),
      _ => DBusMethodErrorResponse.unknownProperty(),
    };
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async =>
      DBusGetAllPropertiesResponse(
        interface == _iface
            ? {
                'Version': const DBusUint32(3),
                'Status': const DBusString('normal'),
                'TextDirection': const DBusString('ltr'),
                'IconThemePath': DBusArray.string(const []),
              }
            : {},
      );

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != _iface) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    switch (methodCall.name) {
      case 'GetLayout':
        return DBusMethodSuccessResponse([
          DBusUint32(_revision),
          _layoutFor(methodCall.values[0].asInt32()),
        ]);
      case 'GetGroupProperties':
        final ids = methodCall.values[0].asInt32Array();
        return DBusMethodSuccessResponse([
          DBusArray(
            DBusSignature('(ia{sv})'),
            ids.map(
              (id) => DBusStruct([
                DBusInt32(id),
                DBusDict.stringVariant(_itemProps(id)),
              ]),
            ),
          ),
        ]);
      case 'GetProperty':
        final props = _itemProps(methodCall.values[0].asInt32());
        final value = props[methodCall.values[1].asString()];
        return DBusMethodSuccessResponse([
          DBusVariant(value ?? const DBusString('')),
        ]);
      case 'Event':
        _handleEvent(
          methodCall.values[0].asInt32(),
          methodCall.values[1].asString(),
        );
        return DBusMethodSuccessResponse();
      case 'EventGroup':
        for (final event in methodCall.values[0].asArray()) {
          final fields = (event as DBusStruct).children;
          _handleEvent(fields[0].asInt32(), fields[1].asString());
        }
        return DBusMethodSuccessResponse([DBusArray.int32(const [])]);
      case 'AboutToShow':
        return DBusMethodSuccessResponse([const DBusBoolean(false)]);
      case 'AboutToShowGroup':
        return DBusMethodSuccessResponse([
          DBusArray.int32(const []),
          DBusArray.int32(const []),
        ]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

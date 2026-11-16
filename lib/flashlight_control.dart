import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

/// Lightweight abstraction so flashlight behavior can be widget-tested without
/// native camera hardware. No video/camera images are accessed or recorded.
abstract class FlashHardware {
  Future<bool> available();
  Future<void> enable();
  Future<void> disable();
}

class PhoneFlashHardware implements FlashHardware {
  const PhoneFlashHardware();

  @override
  Future<bool> available() => TorchLight.isTorchAvailable();

  @override
  Future<void> enable() => TorchLight.enableTorch();

  @override
  Future<void> disable() => TorchLight.disableTorch();
}

/// Lives in HomeScreen's AppBar, which remains mounted when another route is
/// pushed. Thus the torch can stay on while consulting help/resources.
/// It is automatically switched off when app enters background or is disposed.
class FlashlightAction extends StatefulWidget {
  const FlashlightAction({super.key, this.hardware = const PhoneFlashHardware()});

  final FlashHardware hardware;

  @override
  State<FlashlightAction> createState() => _FlashlightActionState();
}

class _FlashlightActionState extends State<FlashlightAction>
    with WidgetsBindingObserver {
  bool enabled = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _switchOff();
    }
  }

  Future<void> _switchOff() async {
    if (!enabled) return;
    // Update state before awaiting the device; errors mean we no longer
    // claim that the light remains on.
    enabled = false;
    if (mounted) setState(() {});
    try {
      await widget.hardware.disable();
    } catch (_) {
      // Torch may already have been claimed by another application.
    }
  }

  Future<void> _toggle() async {
    if (busy) return;
    if (enabled) {
      setState(() => busy = true);
      await _switchOff();
      if (mounted) setState(() => busy = false);
      return;
    }
    setState(() => busy = true);
    try {
      if (!await widget.hardware.available()) {
        if (mounted) await _screenLightFallback();
        return;
      }
      await widget.hardware.enable();
      if (mounted) {
        setState(() => enabled = true);
      } else {
        await widget.hardware.disable();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo usar el flash. Puedes iluminar con la pantalla.'),
        ));
        await _screenLightFallback();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _screenLightFallback() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => const _ScreenLantern(),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Fire-and-forget cleanup: dispose cannot await.
    _switchOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('flashlight-action'),
    tooltip: enabled ? 'Apagar linterna' : 'Encender linterna',
    onPressed: busy ? null : _toggle,
    icon: Icon(enabled ? Icons.flashlight_on : Icons.flashlight_off),
    color: enabled ? const Color(0xFFB07800) : null,
  );
}

class _ScreenLantern extends StatelessWidget {
  const _ScreenLantern();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              left: 18,
              right: 18,
              top: 26,
              child: Text(
                'Luz de pantalla · no usa el flash',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 22,
              child: FilledButton.icon(
                key: const ValueKey('close-screen-lantern'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Apagar luz y volver a Artemis'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF14283B),
                  minimumSize: const Size.fromHeight(58),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/duel_theme.dart';
import '../widgets/dialogs.dart';

/// หน้าเข้าสู่ระบบ / สมัครสมาชิก (สลับโหมดในหน้าเดียว)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _setMode(bool reg) {
    if (_busy || reg == _register) return;
    setState(() {
      _register = reg;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final err = _register
        ? await auth.register(
            name: _name.text, email: _email.text, password: _pass.text)
        : await auth.signIn(_email.text, _pass.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AuthService>().signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  Future<void> _forgot() async {
    final email = await promptText(
      context,
      title: 'ลืมรหัสผ่าน',
      initial: _email.text.trim(),
      hint: 'อีเมลที่ใช้สมัคร',
      okLabel: 'ส่งลิงก์',
      maxLength: 80,
    );
    if (email == null || !mounted) return;
    if (!_emailRe.hasMatch(email.trim())) {
      showToast(context, 'รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }
    final err = await context.read<AuthService>().sendPasswordReset(email);
    if (!mounted) return;
    showToast(
        context,
        err ??
            'ส่งคำขอแล้ว หากอีเมลนี้มีบัญชี จะได้รับลิงก์รีเซ็ตรหัสผ่าน (ดูในกล่องจดหมายขยะด้วย)');
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1.4]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: DL.muted),
      prefixIcon: Icon(icon, color: DL.cyan),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0A2258),
      border: b(DL.edge),
      enabledBorder: b(DL.edge),
      focusedBorder: b(DL.cyan, 2),
      errorBorder: b(DL.red),
      focusedErrorBorder: b(DL.red, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reg = _register;
    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: ShapeDecoration(
                        shape: duelShape(cut: 14, color: DL.cyan, width: 2),
                        color: DL.panelLight,
                      ),
                      child: const Icon(Icons.style, size: 38),
                    ),
                    const SizedBox(height: 12),
                    const Text('Duel-Links Cards',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(reg ? 'สร้างบัญชีใหม่' : 'เข้าสู่ระบบเพื่อใช้งาน',
                        style: const TextStyle(color: DL.muted)),
                    const SizedBox(height: 18),
                    DuelPanel(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DuelButton(
                                    label: 'เข้าสู่ระบบ',
                                    selected: !reg,
                                    onTap: () => _setMode(false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DuelButton(
                                    label: 'สมัครสมาชิก',
                                    selected: reg,
                                    onTap: () => _setMode(true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (reg) ...[
                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                decoration: _dec('ชื่อที่แสดง', Icons.person),
                                validator: (v) => (v ?? '').trim().isEmpty
                                    ? 'กรุณากรอกชื่อ'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _dec('อีเมล', Icons.email),
                              validator: (v) =>
                                  _emailRe.hasMatch((v ?? '').trim())
                                      ? null
                                      : 'รูปแบบอีเมลไม่ถูกต้อง',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pass,
                              obscureText: _hide,
                              textInputAction:
                                  reg ? TextInputAction.next : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!reg) _submit();
                              },
                              decoration: _dec(
                                'รหัสผ่าน',
                                Icons.lock,
                                suffix: IconButton(
                                  icon: Icon(
                                      _hide
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: DL.muted),
                                  onPressed: () =>
                                      setState(() => _hide = !_hide),
                                ),
                              ),
                              validator: (v) => (v ?? '').length < 6
                                  ? 'รหัสผ่านอย่างน้อย 6 ตัวอักษร'
                                  : null,
                            ),
                            if (reg) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _pass2,
                                obscureText: _hide,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _dec(
                                    'ยืนยันรหัสผ่าน', Icons.lock_outline),
                                validator: (v) => v != _pass.text
                                    ? 'รหัสผ่านไม่ตรงกัน'
                                    : null,
                              ),
                            ],
                            if (!reg)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _forgot,
                                  child: const Text('ลืมรหัสผ่าน?',
                                      style: TextStyle(color: DL.cyan)),
                                ),
                              ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: DL.red, fontSize: 13.5)),
                            ],
                            const SizedBox(height: 14),
                            DuelButton(
                              label: _busy
                                  ? 'กำลังดำเนินการ...'
                                  : (reg ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ'),
                              icon: reg ? Icons.person_add : Icons.login,
                              green: true,
                              onTap: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Expanded(child: Divider(color: DL.edge)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('หรือ',
                                      style: TextStyle(color: DL.muted)),
                                ),
                                Expanded(child: Divider(color: DL.edge)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DuelButton(
                              label: 'ดำเนินการต่อด้วย Google',
                              icon: Icons.account_circle,
                              onTap: _busy ? null : _google,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

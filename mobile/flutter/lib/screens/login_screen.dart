import 'package:flutter/material.dart';
import '../widgets/voice_fab.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  bool _isDriver        = true; // toggle: driver vs fleet manager

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Bottom nav ──────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, int current) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A0E1A),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white38,
      currentIndex: current,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        const routes = ['/home', '/camera', '/voice', '/dashboard'];
        if (i != current) Navigator.pushNamed(context, routes[i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home),           label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), label: 'Monitor'),
        BottomNavigationBarItem(icon: Icon(Icons.mic),            label: 'Assistant'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard),      label: 'Dashboard'),
      ],
    );
  }

  // ── Login logic (stub — wire Firebase Auth here) ────────────
  Future<void> _handleLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ── TODO: Replace with real FirebaseAuth.instance.signInWithEmailAndPassword ──
    await Future.delayed(const Duration(seconds: 2)); // simulated network call

    if (!mounted) return;
    setState(() => _isLoading = false);

    // On success, route based on role
    final route = _isDriver ? '/home' : '/dashboard';
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    // ── TODO: Replace with GoogleSignIn + FirebaseAuth ──────────
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      floatingActionButton: const VoiceFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context, 0),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo / branding ───────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1565C0),
                              Color(0xFF0D47A1)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('NexDrive',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      Text('Driver Safety Platform',
                          style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Role toggle ───────────────────────────
                const Text('Sign in as',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      _RoleTab(
                        label: '🚗  Driver',
                        selected: _isDriver,
                        onTap: () =>
                            setState(() => _isDriver = true),
                      ),
                      _RoleTab(
                        label: '👥  Fleet Manager',
                        selected: !_isDriver,
                        onTap: () =>
                            setState(() => _isDriver = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Email ─────────────────────────────────
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),

                // ── Password ──────────────────────────────
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle:
                        const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Colors.blueAccent, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.blue.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Colors.blueAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: implement forgot password
                    },
                    child: const Text('Forgot password?',
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Sign in button ────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding:
                          const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Text('Sign In',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Divider ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: Colors.white.withOpacity(0.1))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13)),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white.withOpacity(0.1))),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Google sign-in ────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.g_mobiledata,
                        color: Colors.white70, size: 24),
                    label: const Text('Continue with Google',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 15)),
                    onPressed:
                        _isLoading ? null : _handleGoogleSignIn,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Register link ─────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('New to NexDrive?  ',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13)),
                      GestureDetector(
                        onTap: () {
                          // TODO: push register screen
                        },
                        child: const Text('Create account',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Info footer ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock,
                          color: Colors.blueAccent, size: 16),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your data is encrypted and never shared. '
                          'NexDrive complies with local privacy regulations.',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon:
            Icon(icon, color: Colors.blueAccent, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1F2E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Role toggle tab ─────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTab(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.blueAccent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
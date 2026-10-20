import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'content/lessons.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/lesson_screen.dart';

void main() {
  runApp(const FlutterQuestApp());
}

class FlutterQuestApp extends StatelessWidget {
  const FlutterQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Quest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/lesson': (_) => const LessonScreen(lessonIndex: 0),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // Sempre abre na tela de login - não restaura sessão automaticamente
    return const LoginScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          _buildLessonsTab(),
          _buildProgressTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Lição',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progresso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final lesson = allLessons.first;

        return Scaffold(
          appBar: AppBar(
            title: Text(lesson.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                },
                tooltip: 'Sair',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: LinearProgressIndicator(
                value: 1 / allLessons.first.exercises.length,
                minHeight: 6,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Olá, ${user?.username ?? 'Desenvolvedor'}! 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6750A4),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue aprendendo Flutter!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima Lição',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allLessons.first.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6750A4),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allLessons.first.concept,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/lesson'),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Começar Lição'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Todas as Lições',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = allLessons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6750A4),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(lesson.title),
                        subtitle: Text(lesson.concept),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/lesson'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Color(0xFF6750A4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'XP Total',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${user?.xp ?? 0} XP',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6750A4),
                              ),
                        ),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: 0.3,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF6750A4)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '30% até o próximo nível',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Conquistas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ..._buildAchievements(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAchievements() {
    final achievements = [
      {'title': 'Primeiro Passo', 'desc': 'Complete sua primeira lição', 'icon': Icons.looks_one, 'unlocked': true},
      {'title': 'Mestre das Variáveis', 'desc': 'Complete a lição de variáveis', 'icon': Icons.code, 'unlocked': false},
      {'title': 'Decisões', 'desc': 'Aprenda if/else', 'icon': Icons.call_split, 'unlocked': false},
      {'title': 'Widget Master', 'desc': 'Crie seu primeiro widget', 'icon': Icons.widgets, 'unlocked': false},
      {'title': 'Layout Master', 'desc': 'Domine Row e Column', 'icon': Icons.view_module, 'unlocked': false},
      {'title': 'Estado', 'desc': 'Use setState pela primeira vez', 'icon': Icons.refresh, 'unlocked': false},
    ];

    return achievements.map((a) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: a['unlocked'] as bool ? const Color(0xFF6750A4) : Colors.grey[300],
            child: Icon(
              a['icon'] as IconData,
              color: a['unlocked'] as bool ? Colors.white : Colors.grey[600],
            ),
          ),
          title: Text(
            a['title'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: a['unlocked'] as bool ? Colors.black : Colors.grey[600],
            ),
          ),
          subtitle: Text(a['desc'] as String),
          trailing: Icon(
            a['unlocked'] as bool ? Icons.lock_open : Icons.lock,
            color: a['unlocked'] as bool ? Colors.green : Colors.grey[400],
          ),
        );
    }).toList();
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6750A4),
                  child: Text(
                    user?.username?.substring(0, 1).toUpperCase() ?? 'D',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.username ?? 'Desenvolvedor',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'email@exemplo.com',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text('Membro desde ${user!.createdAt.toString().split(' ')[0] ?? '2024'}'),
                  backgroundColor: const Color(0xFF6750A4).withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: const Text('Progresso das Lições'),
                        trailing: Text(
                          '1/${allLessons.length}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6750A4),
                              ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.stars_outlined),
                        title: const Text('XP Total'),
                        trailing: Text(
                          '0 XP',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6750A4),
                              ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.emoji_events_outlined),
                        title: const Text('Conquistas Desbloqueadas'),
                        trailing: Text(
                          '0/6',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6750A4),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
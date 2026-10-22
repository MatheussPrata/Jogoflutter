import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../domain/entities/transaction.dart';
import '../lesson/lesson_screen.dart';
import '../transactions/transactions_screen.dart';
import '../widgets/add_transaction_fab.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/admin_context.dart';

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
          _buildTransactionsTab(),
          _buildProgressTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: AddTransactionFab(
        onPressed: () => showAddTransactionSheet(context),
      ),
      floatingActionButtonLocation: const _EllipseFabLocation(),
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
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transações',
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
    return Consumer2<AuthProvider, LessonProvider>(
      builder: (context, authProvider, lessonProvider, child) {
        final user = authProvider.currentUser;
        final lessons = lessonProvider.lessons;
        final isAdmin = context.isAdmin;

        if (lessonProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (lessons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Nenhuma lição disponível'),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showLessonDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar primeira lição'),
                  ),
                ],
              ],
            ),
          );
        }

        final currentLesson = lessons.first;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentLesson.title),
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showLessonDialog(context),
                  tooltip: 'Criar lição',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showLessonListDialog(context),
                  tooltip: 'Gerenciar lições',
                ),
              ],
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
                value: 1 / currentLesson.exercises.length,
                minHeight: 6,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => lessonProvider.loadLessons(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Olá, ${user?.username ?? 'Desenvolvedor'}! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentLesson.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentLesson.concept,
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showLessonDialog(context, existingLesson: lesson),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _confirmDeleteLesson(context, index),
                                  tooltip: 'Excluir',
                                ),
                              ],
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => LessonScreen(lessonIndex: index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Admin: Dialog para criar nova lição
  void _showLessonDialog(BuildContext context, {Lesson? existingLesson}) {
    final isEditing = existingLesson != null;
    final titleController = TextEditingController(text: existingLesson?.title ?? '');
    final conceptController = TextEditingController(text: existingLesson?.concept ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Editar Lição' : 'Criar Nova Lição'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: conceptController,
                    decoration: const InputDecoration(
                      labelText: 'Conceito',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing
                      ? 'Lição atualizada (simulação - precisa implementar API)'
                      : 'Lição criada (simulação - precisa implementar API)'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
              // TODO: Implementar chamada para API do backend
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  // Admin: Dialog para listar e gerenciar lições
  void _showLessonListDialog(BuildContext context) {
    final lessonProvider = context.read<LessonProvider>();
    final lessons = lessonProvider.lessons;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gerenciar Lições'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lessons.length,
            itemBuilder: (_, index) {
              final lesson = lessons[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text('${index + 1}',
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(lesson.title),
                subtitle: Text(lesson.concept),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showLessonDialog(context, existingLesson: lesson);
                      },
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteLesson(context, index),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLesson(BuildContext context, int index) {
    final lessonProvider = context.read<LessonProvider>();
    final lesson = lessonProvider.lessons[index];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Lição?'),
        content: Text('Tem certeza que deseja excluir "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lição excluída (simulação - precisa implementar API)'),
                  backgroundColor: Colors.red,
                ),
              );
              // TODO: Implementar chamada para API do backend
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Tela completa',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const TransactionsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildBalanceCard(provider),
                const SizedBox(height: 20),
                Text(
                  'Todos os itens',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (provider.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma transação ainda',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use o botão + para começar.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else
                  ...provider.transactions.map(_buildTransactionTile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(TransactionProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              'R\$ ${provider.balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: provider.balance >= 0 ? scheme.primary : Colors.red,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    label: 'Receitas',
                    value: provider.totalIncome,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    label: 'Despesas',
                    value: provider.totalExpense,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    final color = t.isIncome ? Colors.green : Colors.red;
    final sign = t.isIncome ? '+' : '-';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            t.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(t.category, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          '$sign R\$ ${t.amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          return RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'XP Total',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${user?.xp ?? 0} XP',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 24),
                          LinearProgressIndicator(
                            value: 0.3,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '30% até o próximo nível',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Conquistas',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._buildAchievements(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAchievements(BuildContext context) {
    final achievements = [
      {'title': 'Primeiro Passo', 'desc': 'Complete sua primeira lição', 'icon': Icons.looks_one, 'unlocked': true},
      {'title': 'Mestre das Variáveis', 'desc': 'Complete a lição de variáveis', 'icon': Icons.code, 'unlocked': false},
      {'title': 'Decisões', 'desc': 'Aprenda if/else', 'icon': Icons.call_split, 'unlocked': false},
      {'title': 'Widget Master', 'desc': 'Crie seu primeiro widget', 'icon': Icons.widgets, 'unlocked': false},
      {'title': 'Layout Master', 'desc': 'Domine Row e Column', 'icon': Icons.view_module, 'unlocked': false},
      {'title': 'Estado', 'desc': 'Use setState pela primeira vez', 'icon': Icons.refresh, 'unlocked': false},
    ];

    return achievements.map((a) {
      final unlocked = a['unlocked'] as bool;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: unlocked
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300],
            child: Icon(
              a['icon'] as IconData,
              color: unlocked ? Colors.white : Colors.grey[600],
            ),
          ),
          title: Text(
            a['title'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: unlocked ? Colors.black : Colors.grey[600],
            ),
          ),
          subtitle: Text(a['desc'] as String),
          trailing: Icon(
            unlocked ? Icons.lock_open : Icons.lock,
            color: unlocked ? Colors.green : Colors.grey[400],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Consumer2<AuthProvider, LessonProvider>(
        builder: (context, authProvider, lessonProvider, child) {
          final user = authProvider.currentUser;
          final lessons = lessonProvider.lessons;
          return RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'email@exemplo.com',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  if (user?.isAdmin == true) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: const Text('Administrador'),
                      backgroundColor: Colors.amber.withOpacity(0.2),
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      'Membro desde ${user?.createdAt.toIso8601String().split('T').first ?? '2024'}',
                    ),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
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
                            '1/${lessons.length}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.stars_outlined),
                          title: const Text('XP Total'),
                          trailing: Text(
                            '${user?.xp ?? 0} XP',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.emoji_events_outlined),
                          title: const Text('Conquistas Desbloqueadas'),
                          trailing: Text(
                            '0/6',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
            ),
          );
        },
      ),
    );
  }
}

/// Posiciona o FAB no centro, levemente para fora da barra de navegação.
class _EllipseFabLocation extends StandardFabLocation
    with FabCenterOffsetX, FabFloatOffsetY {
  const _EllipseFabLocation();

  @override
  double getOffsetY(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    final fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final snackBarHeight = scaffoldGeometry.snackBarSize.height;
    final contentBottom = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.minInsets.bottom;
    final fabY = contentBottom -
        fabHeight / 2 -
        kBottomNavigationBarHeight +
        AddTransactionFab.verticalLift;
    return fabY + (snackBarHeight > 0 ? -snackBarHeight : 0);
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EstocadosApp());
}

class EstocadosApp extends StatelessWidget {
  const EstocadosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estocados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _pages = const [CooperadosPage(), ConfiguracoesPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estocados')),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Estocados'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Configuração'),
        ],
      ),
    );
  }
}

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _url.text = prefs.getString('db_url') ?? '';
    _token.text = prefs.getString('db_token') ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_url', _url.text.trim());
    await prefs.setString('db_token', _token.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuração salva com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Informe a URL da base Turso (libsql://...) e o token para habilitar as consultas.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Database URL',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _token,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Token',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Salvando...' : 'Salvar configuração'),
        ),
      ],
    );
  }
}

class CooperadosPage extends StatefulWidget {
  const CooperadosPage({super.key});

  @override
  State<CooperadosPage> createState() => _CooperadosPageState();
}

class _CooperadosPageState extends State<CooperadosPage> {
  late Future<List<EstocadoItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<List<EstocadoItem>> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('db_url') ?? '';
    final token = prefs.getString('db_token') ?? '';
    if (url.isEmpty || token.isEmpty) {
      throw Exception('Configure a URL e token na aba Configuração.');
    }
    return TursoRepository(url: url, token: token).buscarEstocados();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EstocadoItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Erro: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _future = _carregar()),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: FilledButton(
              onPressed: () => setState(() => _future = _carregar()),
              child: const Text('Recarregar (sem dados)'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _carregar()),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.produto),
                subtitle: Text('Cooperado: ${item.cooperado}'),
                trailing: Text(item.quantidade.toString()),
              );
            },
          ),
        );
      },
    );
  }
}

class EstocadoItem {
  final String produto;
  final String cooperado;
  final int quantidade;

  EstocadoItem({required this.produto, required this.cooperado, required this.quantidade});
}

class TursoRepository {
  final String url;
  final String token;

  TursoRepository({required this.url, required this.token});

  Future<List<EstocadoItem>> buscarEstocados() async {
    final uri = Uri.parse('${_toHttp(url)}/v2/pipeline');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'type': 'execute',
            'stmt': {
              'sql': 'SELECT produto, cooperado, quantidade FROM estocados_cooperados WHERE ativo = 1 ORDER BY cooperado, produto',
              'want_rows': true,
            },
          }
        ]
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha HTTP ${response.statusCode}: ${response.body}');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (map['results']?[0]?['response']?['result']?['rows'] as List<dynamic>? ?? []);
    return rows.map((row) {
      final values = (row as List<dynamic>).map((v) => (v['value'] ?? '').toString()).toList();
      return EstocadoItem(
        produto: values[0],
        cooperado: values[1],
        quantidade: int.tryParse(values[2]) ?? 0,
      );
    }).toList();
  }

  String _toHttp(String dbUrl) {
    final clean = dbUrl.trim();
    if (clean.startsWith('libsql://')) {
      return 'https://${clean.substring('libsql://'.length)}';
    }
    if (clean.startsWith('https://')) return clean;
    throw Exception('URL inválida: use libsql:// ou https://');
  }
}

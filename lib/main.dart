import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EstocadosApp());
}

// Paleta escura inspirada no painel web.
const kBackground = Color(0xFF0E1117);
const kSurface = Color(0xFF161D29);
const kCard = Color(0xFF131A24);
const kBorder = Color(0xFF2A3543);
const kAccentBlue = Color(0xFF4DA3FF);
const kSaldoColor = Color(0xFFFF4B4B);
const kEntradaColor = Color(0xFF21C55D);
const kSaidaColor = Color(0xFFFF4B4B);
const kLabelColor = Color(0xFF8B98A9);

class EstocadosApp extends StatelessWidget {
  const EstocadosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kAccentBlue,
      brightness: Brightness.dark,
      surface: kSurface,
    );
    return MaterialApp(
      title: 'Estocados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: kSurface,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kBorder),
          ),
        ),
      ),
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
  final _pages = const [EstocadosPage(), ConfiguracoesPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📦', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Estocados', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
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
          decoration: const InputDecoration(labelText: 'Database URL'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _token,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Token'),
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

class EstocadosPage extends StatefulWidget {
  const EstocadosPage({super.key});

  @override
  State<EstocadosPage> createState() => _EstocadosPageState();
}

class _EstocadosPageState extends State<EstocadosPage> {
  late Future<List<MaterialTerceiro>> _future;

  static const _todos = 'Todos';
  String _armazem = _todos;
  String _tipo = _todos;
  String _cooperado = _todos;
  String _produto = _todos;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<List<MaterialTerceiro>> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('db_url') ?? '';
    final token = prefs.getString('db_token') ?? '';
    if (url.isEmpty || token.isEmpty) {
      throw Exception('Configure a URL e token na aba Configuração.');
    }
    return TursoRepository(url: url, token: token).buscarMateriais();
  }

  void _recarregar() {
    setState(() => _future = _carregar());
  }

  List<String> _opcoes(List<MaterialTerceiro> itens, String Function(MaterialTerceiro) campo) {
    final valores = itens.map(campo).where((v) => v.isNotEmpty).toSet().toList()..sort();
    return [_todos, ...valores];
  }

  List<MaterialTerceiro> _filtrar(List<MaterialTerceiro> itens) {
    return itens.where((i) {
      if (_armazem != _todos && i.armazem != _armazem) return false;
      if (_tipo != _todos && i.tipo != _tipo) return false;
      if (_cooperado != _todos && i.cooperado != _cooperado) return false;
      if (_produto != _todos && i.produto != _produto) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MaterialTerceiro>>(
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
                  Text('Erro: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _recarregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final todosItens = snapshot.data ?? [];
        if (todosItens.isEmpty) {
          return Center(
            child: FilledButton(
              onPressed: _recarregar,
              child: const Text('Recarregar (sem dados)'),
            ),
          );
        }

        final filtrados = _filtrar(todosItens);
        final grupos = <String, List<MaterialTerceiro>>{};
        for (final item in filtrados) {
          grupos.putIfAbsent(item.cooperado, () => []).add(item);
        }

        return RefreshIndicator(
          onRefresh: () async => _recarregar(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _Filtros(
                armazens: _opcoes(todosItens, (i) => i.armazem),
                tipos: _opcoes(todosItens, (i) => i.tipo),
                cooperados: _opcoes(todosItens, (i) => i.cooperado),
                produtos: _opcoes(todosItens, (i) => i.produto),
                armazem: _armazem,
                tipo: _tipo,
                cooperado: _cooperado,
                produto: _produto,
                onChanged: (armazem, tipo, cooperado, produto) => setState(() {
                  _armazem = armazem;
                  _tipo = tipo;
                  _cooperado = cooperado;
                  _produto = produto;
                }),
              ),
              const SizedBox(height: 12),
              Text(
                '${filtrados.length} linha(s) · Armazém: $_armazem · '
                'Tipo: $_tipo · Cooperado: $_cooperado',
                style: const TextStyle(color: kLabelColor, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (filtrados.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhum item encontrado para os filtros selecionados.',
                      style: TextStyle(color: kLabelColor),
                    ),
                  ),
                ),
              for (final entry in grupos.entries)
                _GrupoCooperado(cooperado: entry.key, itens: entry.value),
            ],
          ),
        );
      },
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.armazens,
    required this.tipos,
    required this.cooperados,
    required this.produtos,
    required this.armazem,
    required this.tipo,
    required this.cooperado,
    required this.produto,
    required this.onChanged,
  });

  final List<String> armazens;
  final List<String> tipos;
  final List<String> cooperados;
  final List<String> produtos;
  final String armazem;
  final String tipo;
  final String cooperado;
  final String produto;
  final void Function(String armazem, String tipo, String cooperado, String produto) onChanged;

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> opcoes,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kLabelColor, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: opcoes.contains(value) ? value : opcoes.first,
          isExpanded: true,
          dropdownColor: kSurface,
          items: [
            for (final opcao in opcoes)
              DropdownMenuItem(
                value: opcao,
                child: Text(opcao, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => onSelected(v ?? opcoes.first),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dropdown(
                label: 'Armazém',
                value: armazem,
                opcoes: armazens,
                onSelected: (v) => onChanged(v, tipo, cooperado, produto),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdown(
                label: 'Tipo',
                value: tipo,
                opcoes: tipos,
                onSelected: (v) => onChanged(armazem, v, cooperado, produto),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Cooperado',
          value: cooperado,
          opcoes: cooperados,
          onSelected: (v) => onChanged(armazem, tipo, v, produto),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Produto',
          value: produto,
          opcoes: produtos,
          onSelected: (v) => onChanged(armazem, tipo, cooperado, v),
        ),
      ],
    );
  }
}

class _GrupoCooperado extends StatelessWidget {
  const _GrupoCooperado({required this.cooperado, required this.itens});

  final String cooperado;
  final List<MaterialTerceiro> itens;

  @override
  Widget build(BuildContext context) {
    final saldoTotal = itens.fold<double>(0, (soma, i) => soma + i.saldo);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: kAccentBlue, width: 3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          collapsedIconColor: kLabelColor,
          iconColor: kLabelColor,
          title: Row(
            children: [
              const Text('🏢', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  cooperado,
                  style: const TextStyle(
                    color: kAccentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: kLabelColor, fontSize: 12),
                children: [
                  TextSpan(text: '${itens.length} item(s) · Saldo: '),
                  TextSpan(
                    text: formatQuantidade(saldoTotal),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' un.'),
                ],
              ),
            ),
          ),
          children: [
            for (final item in itens) _ItemCard(item: item),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final MaterialTerceiro item;

  TextSpan _campo(String label, String valor) {
    return TextSpan(
      children: [
        TextSpan(text: '$label: ', style: const TextStyle(color: kLabelColor)),
        TextSpan(
          text: valor,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entrada = item.isEntrada;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.produto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: kSaldoColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(text: 'Saldo: '),
                    TextSpan(text: '${formatQuantidade(item.saldo)} un.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.codigo.isNotEmpty)
                Text.rich(_campo('Cod', item.codigo), style: const TextStyle(fontSize: 12)),
              if (item.armazem.isNotEmpty)
                Text.rich(_campo('Arm', item.armazem), style: const TextStyle(fontSize: 12)),
              if (item.documento.isNotEmpty)
                Text.rich(_campo('Doc', item.documento), style: const TextStyle(fontSize: 12)),
              if (item.emissao.isNotEmpty)
                Text.rich(
                  _campo('Emissão', formatData(item.emissao)),
                  style: const TextStyle(fontSize: 12),
                ),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12),
                  children: [
                    _campo('Orig', formatQuantidade(item.original)),
                    const TextSpan(text: ' → ', style: TextStyle(color: kLabelColor)),
                    _campo('Entregue', formatQuantidade(item.entregue)),
                  ],
                ),
              ),
              if (item.tipo.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entrada ? Icons.move_to_inbox : Icons.outbox,
                      size: 15,
                      color: entrada ? kEntradaColor : kSaidaColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.tipoDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: entrada ? kEntradaColor : kSaidaColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formata quantidades com separador de milhar; omite decimais quando inteiro.
String formatQuantidade(double valor) {
  final inteiro = valor.truncate();
  final decimais = (valor - inteiro).abs();
  final texto = inteiro.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  final sinal = valor < 0 ? '-' : '';
  if (decimais < 0.005) return '$sinal$buffer';
  return '$sinal$buffer,${(decimais * 100).round().toString().padLeft(2, '0')}';
}

/// Converte datas ISO (yyyy-mm-dd...) para dd/mm/yyyy; outros formatos passam direto.
String formatData(String valor) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(valor.trim());
  if (match == null) return valor;
  return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
}

class MaterialTerceiro {
  final String cooperado;
  final String produto;
  final String codigo;
  final String armazem;
  final String documento;
  final String emissao;
  final double original;
  final double entregue;
  final double saldo;
  final String tipo;

  MaterialTerceiro({
    required this.cooperado,
    required this.produto,
    required this.codigo,
    required this.armazem,
    required this.documento,
    required this.emissao,
    required this.original,
    required this.entregue,
    required this.saldo,
    required this.tipo,
  });

  bool get isEntrada => tipo.toLowerCase().startsWith('e');

  /// Exibe "Entrada"/"Saída" mesmo quando o banco guarda apenas "E"/"S".
  String get tipoDisplay {
    final t = tipo.trim().toLowerCase();
    if (t.isEmpty) return '';
    if (t.startsWith('e')) return 'Entrada';
    if (t.startsWith('s')) return 'Saída';
    return tipo;
  }
}

class TursoRepository {
  final String url;
  final String token;

  TursoRepository({required this.url, required this.token});

  Future<List<MaterialTerceiro>> buscarMateriais() async {
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
              'sql': 'SELECT * FROM materiais_terceiros WHERE saldo > 0 '
                  'ORDER BY razao_social, descricao',
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
    final result = map['results']?[0]?['response']?['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw Exception('Resposta inesperada do banco: ${response.body}');
    }
    final cols = (result['cols'] as List<dynamic>? ?? [])
        .map((c) => (c['name'] ?? '').toString().toLowerCase())
        .toList();
    final rows = result['rows'] as List<dynamic>? ?? [];

    String texto(List<String> valores, List<String> nomes) {
      for (final nome in nomes) {
        final i = cols.indexOf(nome);
        if (i >= 0 && valores[i].isNotEmpty) return valores[i];
      }
      return '';
    }

    double numero(List<String> valores, List<String> nomes) {
      return double.tryParse(texto(valores, nomes).replaceAll(',', '.')) ?? 0;
    }

    return rows.map((row) {
      final valores = (row as List<dynamic>)
          .map((v) => (v is Map ? v['value'] : v)?.toString() ?? '')
          .toList();
      return MaterialTerceiro(
        cooperado: texto(valores, ['razao_social', 'cooperado', 'cliente']),
        produto: texto(valores, ['descricao', 'produto', 'descricao_produto']),
        codigo: texto(valores, ['codigo', 'cod', 'codigo_produto', 'cod_produto', 'produto_codigo']),
        armazem: texto(valores, ['armazem', 'arm', 'cod_armazem', 'codigo_armazem']),
        documento: texto(valores, ['documento', 'doc', 'num_doc', 'numero_documento', 'nota', 'num_nota']),
        emissao: texto(valores, ['emissao', 'data_emissao', 'dt_emissao', 'data', 'data_entrada']),
        original: numero(valores, ['quantidade_original', 'qtd_original', 'quantidade', 'qtd', 'qtde', 'orig']),
        entregue: numero(valores, ['entregue', 'qtd_entregue', 'quantidade_entregue']),
        saldo: numero(valores, ['saldo']),
        tipo: texto(valores, ['tipo', 'tipo_movimento', 'movimento', 'operacao']),
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

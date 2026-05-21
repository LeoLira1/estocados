# Estocados App (Flutter)

Aplicativo Flutter para consultar a tabela `estocados_cooperados` na base Turso.

## Funcionalidades
- Configurar URL do banco (`libsql://...`) e token diretamente no app.
- Listar produtos estocados por cooperado em ordem de cooperado/produto.
- Atualização por pull-to-refresh.

## Como rodar local
```bash
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk --release
```

## CI/CD e Release automático
Este repositório possui workflow GitHub Actions para:
1. Compilar APK release em toda tag `v*`.
2. Criar/atualizar Release no GitHub com o APK anexado.

Para disparar:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Depois, baixe o APK na aba **Releases** do GitHub.

## Query usada
```sql
SELECT produto, cooperado, quantidade
FROM estocados_cooperados
WHERE ativo = 1
ORDER BY cooperado, produto;
```

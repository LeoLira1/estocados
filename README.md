# Estocados App (Flutter)

Aplicativo Flutter para consultar a tabela `estocados_cooperados` na base Turso.

## Funcionalidades
- Configurar URL do banco (`libsql://...`) e token diretamente no app.
- Listar produtos estocados por cooperado em ordem de cooperado/produto.
- Atualização por pull-to-refresh.

## APK sem passo manual de tag
O release do APK acontece **automaticamente** também em push para `main`/`master`:
- Push em `main`/`master`: gera release automático `auto-<run_number>` como **pre-release**.
- Push de tag `v*` (ex.: `v1.0.0`): gera release versionado final (não pre-release).

Não precisa criar tag para já ter um link de APK; a tag fica opcional para versionamento oficial.

## Como rodar local
```bash
flutter pub get
flutter run
```

## Build APK local
```bash
flutter build apk --release
```

## CI/CD e Release automático
O workflow `.github/workflows/android-release.yml` faz:
1. Setup Flutter + Java,
2. `flutter create . --platforms=android` caso a pasta Android ainda não exista,
3. `flutter pub get`,
4. `flutter test`,
5. `flutter build apk --release`,
6. Criação/atualização de release no GitHub com `app-release.apk`.

## Query usada
```sql
SELECT produto, cooperado, quantidade
FROM estocados_cooperados
WHERE ativo = 1
ORDER BY cooperado, produto;
```

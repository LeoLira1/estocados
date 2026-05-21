# Estocados App (Flutter)

Aplicativo Flutter para consultar a tabela `estocados_cooperados` na base Turso.

## Funcionalidades
- Configurar URL do banco (`libsql://...`) e token diretamente no app.
- Listar produtos estocados por cooperado em ordem de cooperado/produto.
- Atualização por pull-to-refresh.

## Situação atual do APK de release
Atualmente o APK **ainda não está publicado** neste repositório.

Ele será gerado automaticamente no GitHub Actions quando você:
1. subir este código para o GitHub,
2. criar uma tag no formato `v*` (ex.: `v1.0.0`),
3. aguardar o workflow `Android Release APK` terminar com sucesso.

Após isso, o arquivo `app-release.apk` ficará disponível na aba **Releases**.

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
6. publicação do APK no Release da tag.

Para disparar por tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

## Query usada
```sql
SELECT produto, cooperado, quantidade
FROM estocados_cooperados
WHERE ativo = 1
ORDER BY cooperado, produto;
```
